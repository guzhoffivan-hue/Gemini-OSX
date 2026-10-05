#import "AppDelegate+Internal.h"
#import <Security/Security.h>

static NSString * const GMKeychainService = @"GeminiMacClient";
static NSString * const GMKeychainAccount = @"GeminiAPIKey";

static NSDictionary *GMKeychainKeyQuery(void) {
    return [NSDictionary dictionaryWithObjectsAndKeys:
            (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
            GMKeychainService, (__bridge id)kSecAttrService,
            GMKeychainAccount, (__bridge id)kSecAttrAccount,
            nil];
}

static NSString *GMReadAPIKey(void) {
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithDictionary:GMKeychainKeyQuery()];
    [query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    [query setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status != errSecSuccess || result == NULL) return nil;
    
    NSData *data = (__bridge_transfer NSData *)result;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

static BOOL GMSaveAPIKey(NSString *key) {
    NSData *data = [key dataUsingEncoding:NSUTF8StringEncoding];
    if (data == nil) return NO;
    
    NSDictionary *query = GMKeychainKeyQuery();
    NSDictionary *update = [NSDictionary dictionaryWithObject:data forKey:(__bridge id)kSecValueData];
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)update);
    if (status == errSecItemNotFound) {
        NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:query];
        [item setObject:data forKey:(__bridge id)kSecValueData];
        status = SecItemAdd((__bridge CFDictionaryRef)item, NULL);
    }
    return status == errSecSuccess;
}

@implementation AppDelegate (GeminiAPI)

- (BOOL)requestAPIKey {
    if (self.apiKey.length > 0) return YES;
    
    NSString *savedKey = GMReadAPIKey();
    if (savedKey.length > 0) {
        self.apiKey = savedKey;
        return YES;
    }
    
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Ключ Gemini API";
    alert.informativeText = @"Введите ключ API. Он будет сохранён в Связке ключей macOS.";
    [alert addButtonWithTitle:@"Продолжить"];
    [alert addButtonWithTitle:@"Отмена"];
    NSSecureTextField *keyField = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 24)];
    alert.accessoryView = keyField;
    NSInteger result = [alert runModal];
    NSString *key = keyField.stringValue;
    if (result != NSAlertFirstButtonReturn) return NO;
    key = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (key.length == 0) return NO;
    
    self.apiKey = key;
    if (!GMSaveAPIKey(key)) {
        NSLog(@"Не удалось сохранить Gemini API key в Keychain.");
    }
    return YES;
}

- (void)loadModelsAndContinue {
    [self loadModelsThenSend:YES];
}

// Кнопка справа вверху: заново запрашивает список моделей у Gemini API.
- (void)refreshModels:(id)sender {
    if (self.requestInProgress) return;
    if (self.apiKey.length == 0 && ![self requestAPIKey]) return;
    [self loadModelsThenSend:NO];
}

- (void)loadModelsThenSend:(BOOL)send {
    NSURL *url = [NSURL URLWithString:@"https://generativelanguage.googleapis.com/v1beta/models"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:45.0];
    [request setValue:self.apiKey forHTTPHeaderField:@"x-goog-api-key"];
    self.requestInProgress = YES;
    self.inputField.enabled = NO;
    self.statusLabel.stringValue = @"Загружаю список моделей…";
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (error || data.length == 0) {
                                   self.requestInProgress = NO;
                                   self.inputField.enabled = YES;
                                   self.statusLabel.stringValue = @"";
                                   [self showError:error.localizedDescription ?: @"Не удалось получить список моделей."];
                                   return;
                               }
                               NSError *parseError = nil;
                               NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
                               NSArray *models = [json objectForKey:@"models"];
                               NSMutableArray *available = [NSMutableArray array];
                               for (NSDictionary *modelInfo in models) {
                                   NSArray *methods = [modelInfo objectForKey:@"supportedGenerationMethods"];
                                   NSString *fullName = [modelInfo objectForKey:@"name"];
                                   if ([methods containsObject:@"generateContent"] && [fullName hasPrefix:@"models/"]) {
                                       [available addObject:[fullName substringFromIndex:7]];
                                   }
                               }
                               if (available.count == 0) {
                                   self.requestInProgress = NO;
                                   self.inputField.enabled = YES;
                                   self.statusLabel.stringValue = @"";
                                   NSDictionary *apiError = [json objectForKey:@"error"];
                                   [self showError:[apiError objectForKey:@"message"] ?: parseError.localizedDescription ?: @"Для этого API-ключа не найдено доступных моделей."];
                                   return;
                               }
                               
                               [available sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
                               NSString *previous = self.modelPopup.titleOfSelectedItem;
                               [self.modelPopup removeAllItems];
                               [self.modelPopup addItemsWithTitles:available];
                               if (previous.length && [available containsObject:previous]) {
                                   [self.modelPopup selectItemWithTitle:previous];
                               } else if ([available containsObject:@"gemini-2.5-flash"]) {
                                   [self.modelPopup selectItemWithTitle:@"gemini-2.5-flash"];
                               }
                               self.modelsLoaded = YES;
                               self.requestInProgress = NO;
                               self.inputField.enabled = YES;
                               if (send) {
                                   self.statusLabel.stringValue = @"";
                                   [self sendMessage:nil];
                               } else {
                                   self.statusLabel.stringValue = [NSString stringWithFormat:@"Моделей: %lu", (unsigned long)available.count];
                                   [self.inputField.window makeFirstResponder:self.inputField];
                               }
                           }];
}

- (void)showError:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Не удалось получить ответ";
    alert.informativeText = message ?: @"Проверьте подключение и API-ключ.";
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
}

- (void)sendMessage:(id)sender {
    if (self.requestInProgress) return;
    NSString *message = [self.inputField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (message.length == 0) return;
    if (self.apiKey.length == 0) {
        if (![self requestAPIKey]) return;
        [self loadModelsAndContinue];
        return;
    }
    if (!self.currentConversation) [self createNewConversation:nil];
    
    NSMutableArray *messages = [self.currentConversation objectForKey:@"messages"];
    NSDictionary *userMessage = [NSDictionary dictionaryWithObjectsAndKeys:@"user", @"role", message, @"text", nil];
    [messages addObject:userMessage];
    if ([[self.currentConversation objectForKey:@"title"] isEqualToString:@"Новое сообщение"] ||
        [[self.currentConversation objectForKey:@"title"] isEqualToString:@"Новый чат"]) {
        NSString *title = message.length > 32 ? [[message substringToIndex:32] stringByAppendingString:@"…"] : message;
        [self.currentConversation setObject:title forKey:@"title"];
    }
    [self reloadChatList];
    self.inputField.stringValue = @"";
    self.requestInProgress = YES;
    self.inputField.enabled = NO;
    self.statusLabel.stringValue = @"Gemini отвечает…";
    [self renderCurrentConversation];
    
    NSMutableArray *contents = [NSMutableArray array];
    for (NSDictionary *item in messages) {
        NSString *text = [item objectForKey:@"text"] ?: @"";
        NSString *role = [item objectForKey:@"role"] ?: @"user";
        NSDictionary *part = [NSDictionary dictionaryWithObject:text forKey:@"text"];
        NSDictionary *content = [NSDictionary dictionaryWithObjectsAndKeys:role, @"role", [NSArray arrayWithObject:part], @"parts", nil];
        [contents addObject:content];
    }
    NSDictionary *body = [NSDictionary dictionaryWithObject:contents forKey:@"contents"];
    NSError *jsonError = nil;
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:body options:0 error:&jsonError];
    if (!bodyData) {
        self.requestInProgress = NO;
        self.inputField.enabled = YES;
        self.statusLabel.stringValue = @"";
        [self showError:jsonError.localizedDescription];
        return;
    }
    
    NSString *model = self.modelPopup.titleOfSelectedItem;
    if (model.length == 0) model = @"gemini-2.5-flash";
    NSString *urlString = [NSString stringWithFormat:@"https://generativelanguage.googleapis.com/v1beta/models/%@:generateContent", model];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:90.0];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:self.apiKey forHTTPHeaderField:@"x-goog-api-key"];
    request.HTTPBody = bodyData;
    
    NSMutableDictionary *conversationForReply = self.currentConversation;
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               self.requestInProgress = NO;
                               self.inputField.enabled = YES;
                               self.statusLabel.stringValue = @"";
                               if (error || data.length == 0) {
                                   [self showError:error.localizedDescription ?: @"Сервер не прислал ответ."];
                                   return;
                               }
                               
                               NSError *parseError = nil;
                               NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&parseError];
                               if (![json isKindOfClass:[NSDictionary class]]) {
                                   [self showError:parseError.localizedDescription ?: @"Не удалось разобрать ответ сервера."];
                                   return;
                               }
                               NSDictionary *apiError = [json objectForKey:@"error"];
                               if (apiError) {
                                   [self showError:[apiError objectForKey:@"message"] ?: @"Ошибка Gemini API."];
                                   return;
                               }
                               NSArray *candidates = [json objectForKey:@"candidates"];
                               NSDictionary *candidate = [candidates count] ? [candidates objectAtIndex:0] : nil;
                               NSDictionary *content = [candidate objectForKey:@"content"];
                               NSArray *parts = [content objectForKey:@"parts"];
                               NSMutableString *answer = [NSMutableString string];
                               for (NSDictionary *part in parts) {
                                   NSString *text = [part objectForKey:@"text"];
                                   if (text.length > 0) [answer appendString:text];
                               }
                               if (answer.length == 0) {
                                   [self showError:@"Gemini вернул пустой ответ."];
                                   return;
                               }
                               NSMutableArray *replyMessages = [conversationForReply objectForKey:@"messages"];
                               [replyMessages addObject:[NSDictionary dictionaryWithObjectsAndKeys:@"model", @"role", answer, @"text", nil]];
                               [self reloadChatList];
                               if (self.currentConversation == conversationForReply) [self renderCurrentConversation];
                           }];
}

@end

#import "AppDelegate+Internal.h"
#import <Foundation/Foundation.h>

static NSString *GMConversationsFilePath(void) {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *supportDirectory = [paths count] ? [paths objectAtIndex:0] : NSHomeDirectory();
    NSString *appDirectory = [supportDirectory stringByAppendingPathComponent:@"GeminiMacClient"];
    return [appDirectory stringByAppendingPathComponent:@"conversations.json"];
}

@implementation AppDelegate (Chats)

- (void)loadConversations {
    NSString *path = GMConversationsFilePath();
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSArray *saved = nil;
    if (data) {
        id object = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:NULL];
        if ([object isKindOfClass:[NSArray class]]) saved = object;
    }
    
    self.conversations = [NSMutableArray array];
    for (id item in saved) {
        if (![item isKindOfClass:[NSDictionary class]]) continue;
        NSString *title = [item objectForKey:@"title"];
        NSArray *messages = [item objectForKey:@"messages"];
        if (![title isKindOfClass:[NSString class]] || ![messages isKindOfClass:[NSArray class]]) continue;
        NSMutableArray *validMessages = [NSMutableArray array];
        for (id message in messages) {
            if (![message isKindOfClass:[NSDictionary class]]) continue;
            NSString *role = [message objectForKey:@"role"];
            NSString *text = [message objectForKey:@"text"];
            if ([role isKindOfClass:[NSString class]] && [text isKindOfClass:[NSString class]]) {
                [validMessages addObject:[NSDictionary dictionaryWithObjectsAndKeys:role, @"role", text, @"text", nil]];
            }
        }
        // Пустые черновики не считаются сохранёнными чатами.
        if (validMessages.count == 0) continue;
        [self.conversations addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       title, @"title", validMessages, @"messages", nil]];
    }
    self.visibleConversations = self.conversations;
}

- (void)saveConversations {
    if (!self.conversations) return;
    NSString *path = GMConversationsFilePath();
    NSString *directory = [path stringByDeletingLastPathComponent];
    NSError *directoryError = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:directory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&directoryError];
    NSMutableArray *savedConversations = [NSMutableArray array];
    for (NSDictionary *conversation in self.conversations) {
        NSArray *messages = [conversation objectForKey:@"messages"];
        if (messages.count > 0) [savedConversations addObject:conversation];
    }
    NSError *writeError = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:savedConversations options:NSJSONWritingPrettyPrinted error:&writeError];
    if (data && ![data writeToFile:path options:NSDataWritingAtomic error:&writeError]) {
        NSLog(@"Не удалось сохранить чаты: %@", writeError.localizedDescription);
    } else if (!data) {
        NSLog(@"Не удалось подготовить чаты к сохранению: %@", writeError.localizedDescription);
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return (NSInteger)self.visibleConversations.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row < 0 || row >= (NSInteger)self.visibleConversations.count) return @"";
    return [[self.visibleConversations objectAtIndex:(NSUInteger)row] objectForKey:@"title"];
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    return [[GMChatRowView alloc] initWithFrame:NSMakeRect(0, 0, tableView.bounds.size.width, tableView.rowHeight)];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row < 0 || row >= (NSInteger)self.visibleConversations.count) return nil;
    NSDictionary *conversation = [self.visibleConversations objectAtIndex:(NSUInteger)row];
    GMChatCellView *cell = [[GMChatCellView alloc] initWithFrame:NSMakeRect(0, 0, tableColumn.width, tableView.rowHeight)];
    cell.title = [conversation objectForKey:@"title"];
    NSArray *messages = [conversation objectForKey:@"messages"];
    if (messages.count) cell.preview = [[messages lastObject] objectForKey:@"text"];
    return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    if (self.updatingList) return;
    NSInteger row = self.chatList.selectedRow;
    if (row < 0 || row >= (NSInteger)self.visibleConversations.count) return;
    NSMutableDictionary *selectedConversation = [self.visibleConversations objectAtIndex:(NSUInteger)row];
    NSMutableDictionary *previousConversation = self.currentConversation;
    if (previousConversation && previousConversation != selectedConversation &&
        [[previousConversation objectForKey:@"messages"] count] == 0) {
        [self.conversations removeObjectIdenticalTo:previousConversation];
        self.currentConversation = selectedConversation;
        [self searchChanged:nil];
        [self renderCurrentConversation];
        return;
    }
    self.currentConversation = selectedConversation;
    self.statusLabel.stringValue = @"";
    [self renderCurrentConversation];
}

// reloadData сбрасывает выделение — возвращаем его на текущий разговор,
// чтобы синяя строка в списке не пропадала.
- (void)reloadChatList {
    self.updatingList = YES;
    [self.chatList reloadData];
    NSUInteger index = self.currentConversation
    ? [self.visibleConversations indexOfObjectIdenticalTo:self.currentConversation]
    : NSNotFound;
    if (index != NSNotFound) {
        [self.chatList selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    }
    self.updatingList = NO;
    [self saveConversations];
}

- (void)createNewConversation:(id)sender {
    NSIndexSet *emptyIndexes = [self.conversations indexesOfObjectsPassingTest:^BOOL(NSDictionary *conversation, NSUInteger idx, BOOL *stop) {
        return [[conversation objectForKey:@"messages"] count] == 0;
    }];
    if (emptyIndexes.count > 0) [self.conversations removeObjectsAtIndexes:emptyIndexes];
    
    NSMutableDictionary *conversation = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         @"Новое сообщение", @"title", [NSMutableArray array], @"messages", nil];
    [self.conversations insertObject:conversation atIndex:0];
    self.visibleConversations = self.conversations;
    [self.chatList reloadData];
    [self.chatList selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    self.currentConversation = conversation;
    [self saveConversations];
    [self renderCurrentConversation];
    [self.inputField.window makeFirstResponder:self.inputField];
}

- (NSMutableDictionary *)conversationForMenuItem:(id)sender {
    id conversation = [sender representedObject];
    return [conversation isKindOfClass:[NSMutableDictionary class]] ? conversation : nil;
}

- (NSMutableDictionary *)conversationAtVisibleIndex:(NSInteger)index {
    if (index < 0 || index >= (NSInteger)self.visibleConversations.count) return nil;
    return [self.visibleConversations objectAtIndex:(NSUInteger)index];
}

- (void)renameConversation:(id)sender {
    NSMutableDictionary *conversation = [self conversationForMenuItem:sender];
    if (!conversation) return;
    
    NSTextField *nameField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 280, 24)];
    nameField.stringValue = [conversation objectForKey:@"title"] ?: @"";
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Переименовать чат";
    alert.informativeText = @"Введите новое название:";
    alert.accessoryView = nameField;
    [alert addButtonWithTitle:@"Сохранить"];
    [alert addButtonWithTitle:@"Отмена"];
    if ([alert runModal] != NSAlertFirstButtonReturn) return;
    
    NSString *title = [nameField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (title.length == 0) return;
    [conversation setObject:title forKey:@"title"];
    [self reloadChatList];
}

- (void)deleteConversation:(id)sender {
    NSMutableDictionary *conversation = [self conversationForMenuItem:sender];
    if (!conversation) return;
    
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Удалить чат?";
    alert.informativeText = [NSString stringWithFormat:@"Чат «%@» и вся его переписка будут удалены.", [conversation objectForKey:@"title"] ?: @""];
    [alert addButtonWithTitle:@"Удалить"];
    [alert addButtonWithTitle:@"Отмена"];
    if ([alert runModal] != NSAlertFirstButtonReturn) return;
    
    BOOL wasCurrent = (self.currentConversation == conversation);
    [self.conversations removeObjectIdenticalTo:conversation];
    if (self.conversations.count == 0) {
        self.currentConversation = nil;
        [self createNewConversation:nil];
        return;
    }
    if (wasCurrent) self.currentConversation = [self.conversations objectAtIndex:0];
    [self searchChanged:nil];
    if (wasCurrent) [self renderCurrentConversation];
}

- (void)exportConversation:(id)sender {
    NSDictionary *conversation = [self conversationForMenuItem:sender];
    if (!conversation) return;
    
    NSMutableString *export = [NSMutableString stringWithFormat:@"%@\n\n", [conversation objectForKey:@"title"] ?: @"Чат"];
    for (NSDictionary *message in [conversation objectForKey:@"messages"]) {
        NSString *role = [message objectForKey:@"role"];
        NSString *speaker = [role isEqualToString:@"user"] ? @"Вы" : @"Gemini";
        [export appendFormat:@"%@:\n%@\n\n", speaker, [message objectForKey:@"text"] ?: @""];
    }
    
    NSSavePanel *panel = [NSSavePanel savePanel];
    NSString *fileName = [[conversation objectForKey:@"title"] ?: @"Чат" stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    panel.nameFieldStringValue = [NSString stringWithFormat:@"%@.txt", fileName];
    panel.allowedFileTypes = [NSArray arrayWithObject:@"txt"];
    if ([panel runModal] != NSOKButton) return;
    NSError *error = nil;
    if (![export writeToURL:panel.URL atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
        NSAlert *errorAlert = [[NSAlert alloc] init];
        errorAlert.messageText = @"Не удалось экспортировать чат";
        errorAlert.informativeText = error.localizedDescription ?: @"Ошибка записи файла.";
        [errorAlert addButtonWithTitle:@"OK"];
        [errorAlert runModal];
    }
}

- (void)searchChanged:(id)sender {
    NSString *query = [self.searchField.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (query.length == 0) {
        self.visibleConversations = self.conversations;
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *conversation, NSDictionary *bindings) {
            return [[conversation objectForKey:@"title"] rangeOfString:query options:NSCaseInsensitiveSearch].location != NSNotFound;
        }];
        self.visibleConversations = [self.conversations filteredArrayUsingPredicate:predicate];
    }
    [self reloadChatList];
}

- (void)renderCurrentConversation {
    NSArray *messages = [self.currentConversation objectForKey:@"messages"] ?: @[];
    CGFloat width = self.transcriptScrollView.contentView.bounds.size.width;
    self.transcriptView.minimumHeight = self.transcriptScrollView.contentView.bounds.size.height;
    [self.transcriptView setFrameSize:NSMakeSize(MAX(width, 240.0), self.transcriptView.frame.size.height)];
    self.transcriptView.messages = messages;
    [self.transcriptScrollView.contentView scrollToPoint:NSMakePoint(0, 0)];
    [self.transcriptScrollView reflectScrolledClipView:self.transcriptScrollView.contentView];
}

- (void)windowDidResize:(NSNotification *)notification {
    if (self.transcriptScrollView) [self renderCurrentConversation];
}

@end

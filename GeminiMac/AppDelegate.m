#import "AppDelegate+Internal.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSWindow *window = self.window;
    if (!window) {
        window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 610, 523)
                                             styleMask:NSTitledWindowMask | NSClosableWindowMask |
                  NSMiniaturizableWindowMask | NSResizableWindowMask
                                               backing:NSBackingStoreBuffered defer:NO];
        self.window = window;
    }
    // Весь экран окна на эталоне 610×543, из них ~20 пт — заголовок.
    [window setContentSize:NSMakeSize(610, 523)];
    window.title = @"Gemini";
    window.minSize = NSMakeSize(520, 420);
    window.delegate = self;
    // Кнопка полноэкранного режима в правом углу заголовка (как на скриншоте).
    [window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
    [window center];
    
    [self loadConversations];
    [self buildInterface];
    if (self.conversations.count == 0) {
        [self createNewConversation:nil];
    } else {
        self.visibleConversations = self.conversations;
        self.currentConversation = [self.conversations objectAtIndex:0];
        [self reloadChatList];
        [self renderCurrentConversation];
    }
    [window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}


@end

@implementation AppDelegate (Termination)

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end

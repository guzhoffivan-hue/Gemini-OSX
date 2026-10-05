#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

@interface GMChatRowView : NSTableRowView
@end

@interface GMChatCellView : NSView
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *preview;
@end

@interface GMTranscriptView : NSView
@property (nonatomic, copy) NSArray *messages;
@property (nonatomic, assign) CGFloat minimumHeight;
- (void)setMessages:(NSArray *)messages;
@end

@interface AppDelegate () <NSTableViewDataSource, NSTableViewDelegate, NSSplitViewDelegate, NSWindowDelegate>
@property (nonatomic, strong) NSString *apiKey;
@property (nonatomic, strong) NSMutableArray *conversations;
@property (nonatomic, strong) NSArray *visibleConversations;
@property (nonatomic, strong) NSMutableDictionary *currentConversation;
@property (nonatomic, strong) NSSplitView *splitView;
@property (nonatomic, strong) NSTableView *chatList;
@property (nonatomic, strong) NSSearchField *searchField;
@property (nonatomic, strong) NSScrollView *transcriptScrollView;
@property (nonatomic, strong) GMTranscriptView *transcriptView;
@property (nonatomic, strong) NSTextField *inputField;
@property (nonatomic, strong) NSPopUpButton *modelPopup;
@property (nonatomic, strong) NSTextField *statusLabel;
@property (nonatomic, assign) BOOL modelsLoaded;
@property (nonatomic, assign) BOOL requestInProgress;
@property (nonatomic, assign) BOOL updatingList;

- (void)buildInterface;
- (void)reloadChatList;
- (void)createNewConversation:(id)sender;
- (void)searchChanged:(id)sender;
- (void)renderCurrentConversation;
- (void)loadConversations;
- (void)saveConversations;
- (void)renameConversation:(id)sender;
- (void)deleteConversation:(id)sender;
- (void)exportConversation:(id)sender;
- (NSMutableDictionary *)conversationAtVisibleIndex:(NSInteger)index;
- (BOOL)requestAPIKey;
- (void)loadModelsAndContinue;
- (void)refreshModels:(id)sender;
- (void)loadModelsThenSend:(BOOL)send;
- (void)showError:(NSString *)message;
- (void)sendMessage:(id)sender;
@end

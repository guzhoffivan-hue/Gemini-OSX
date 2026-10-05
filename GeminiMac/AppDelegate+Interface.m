#import "AppDelegate+Internal.h"

// Цвета заданы в Device RGB, чтобы на экране получались ровно те значения,
// которые были измерены на эталонном скриншоте.
#define GMRGB(r, g, b) [NSColor colorWithDeviceRed:(r) / 255.0 green:(g) / 255.0 blue:(b) / 255.0 alpha:1.0]
#define GMRGBA(r, g, b, a) [NSColor colorWithDeviceRed:(r) / 255.0 green:(g) / 255.0 blue:(b) / 255.0 alpha:(a)]

static const CGFloat GMSidebarWidth = 211.0;
static const CGFloat GMHeaderHeight = 34.0;   // шапка сайдбара (поиск + кнопка), включая нижнюю линию
static const CGFloat GMTopBarHeight = 35.0;   // строка «Кому:», включая линию и блик под ней
static const CGFloat GMComposerHeight = 40.0; // нижняя область с полем ввода
static const CGFloat GMRowHeight = 56.0;

static CGFloat GMTextHeight(NSString *text, CGFloat width, NSFont *font) {
    if (text.length == 0) return 24.0;
    NSDictionary *attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
    CGRect rect = [text boundingRectWithSize:NSMakeSize(MAX(40.0, width), CGFLOAT_MAX)
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                  attributes:attributes];
    return MAX(24.0, ceil(rect.size.height));
}

static NSColor *GMBlend(CGFloat r0, CGFloat g0, CGFloat b0, CGFloat r1, CGFloat g1, CGFloat b1, CGFloat t) {
    return GMRGB(r0 + (r1 - r0) * t, g0 + (g1 - g0) * t, b0 + (b1 - b0) * t);
}

// Фон правой части: (227,231,238) с лёгким «льняным» зерном.
static NSColor *GMLinenColor(void) {
    static NSColor *color = nil;
    if (color == nil) {
        const NSInteger size = 64;
        NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
                                                                        pixelsWide:size
                                                                        pixelsHigh:size
                                                                     bitsPerSample:8
                                                                   samplesPerPixel:4
                                                                          hasAlpha:YES
                                                                          isPlanar:NO
                                                                    colorSpaceName:NSDeviceRGBColorSpace
                                                                       bytesPerRow:0
                                                                      bitsPerPixel:0];
        unsigned char *data = [rep bitmapData];
        NSInteger stride = [rep bytesPerRow];
        static const int offsets[6] = {-3, -2, -1, -1, 0, 1};
        unsigned int seed = 20121;
        for (NSInteger y = 0; y < size; y++) {
            for (NSInteger x = 0; x < size; x++) {
                seed = seed * 1664525u + 1013904223u;
                int n = offsets[(seed >> 16) % 6];
                unsigned char *p = data + y * stride + x * 4;
                p[0] = (unsigned char)(227 + n);
                p[1] = (unsigned char)(231 + n);
                p[2] = (unsigned char)(238 + n);
                p[3] = 255;
            }
        }
        NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(size, size)];
        [image addRepresentation:rep];
        color = [NSColor colorWithPatternImage:image];
    }
    return color;
}

// Значок «новое сообщение»: квадрат с карандашом.
static NSImage *GMComposeIcon(void) {
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(21.0, 18.0)];
    [image lockFocus];
    
    NSBezierPath *frame = [NSBezierPath bezierPath];
    [frame moveToPoint:NSMakePoint(10.5, 15.5)];
    [frame lineToPoint:NSMakePoint(3.5, 15.5)];
    [frame curveToPoint:NSMakePoint(1.5, 13.5) controlPoint1:NSMakePoint(2.4, 15.5) controlPoint2:NSMakePoint(1.5, 14.6)];
    [frame lineToPoint:NSMakePoint(1.5, 3.5)];
    [frame curveToPoint:NSMakePoint(3.5, 1.5) controlPoint1:NSMakePoint(1.5, 2.4) controlPoint2:NSMakePoint(2.4, 1.5)];
    [frame lineToPoint:NSMakePoint(13.5, 1.5)];
    [frame curveToPoint:NSMakePoint(15.5, 3.5) controlPoint1:NSMakePoint(14.6, 1.5) controlPoint2:NSMakePoint(15.5, 2.4)];
    [frame lineToPoint:NSMakePoint(15.5, 8.5)];
    [frame setLineWidth:1.7];
    [frame setLineCapStyle:NSRoundLineCapStyle];
    [frame setLineJoinStyle:NSRoundLineJoinStyle];
    [GMRGB(128, 128, 128) setStroke];
    [frame stroke];
    
    NSBezierPath *pencil = [NSBezierPath bezierPath];
    [pencil moveToPoint:NSMakePoint(6.73, 6.27)];
    [pencil lineToPoint:NSMakePoint(15.23, 14.77)];
    [pencil lineToPoint:NSMakePoint(17.77, 12.23)];
    [pencil lineToPoint:NSMakePoint(9.27, 3.73)];
    [pencil lineToPoint:NSMakePoint(6.23, 3.23)];
    [pencil closePath];
    [GMRGB(176, 176, 176) setFill];
    [pencil fill];
    [pencil setLineWidth:1.0];
    [pencil setLineJoinStyle:NSRoundLineJoinStyle];
    [GMRGB(128, 128, 128) setStroke];
    [pencil stroke];
    
    [image unlockFocus];
    return image;
}

// Синяя круглая кнопка «обновить список моделей» справа в верхней строке.
static NSImage *GMRefreshModelsIcon(void) {
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(21.0, 21.0)];
    [image lockFocus];
    CGFloat cx = 10.5, cy = 10.5;
    
    [GMRGBA(0, 0, 0, 0.10) setFill];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(cx - 10.0, cy - 11.5, 20.0, 20.0)] fill];
    [GMRGBA(0, 0, 0, 0.12) setFill];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(cx - 9.5, cy - 10.5, 19.0, 19.0)] fill];
    
    NSBezierPath *outline = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(cx - 9.5, cy - 9.5, 19.0, 19.0)];
    NSGradient *outlineGradient = [[NSGradient alloc] initWithStartingColor:GMRGB(126, 128, 132)
                                                                endingColor:GMRGB(193, 197, 203)];
    [outlineGradient drawInBezierPath:outline angle:90.0];
    
    [GMRGB(254, 254, 254) setFill];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(cx - 8.5, cy - 8.5, 17.0, 17.0)] fill];
    
    NSBezierPath *disc = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(cx - 7.5, cy - 7.5, 15.0, 15.0)];
    [NSGraphicsContext saveGraphicsState];
    [disc addClip];
    [GMRGB(34, 111, 216) setFill];
    NSRectFill(NSMakeRect(0, 0, 21.0, cy));
    [GMRGB(102, 155, 228) setFill];
    NSRectFill(NSMakeRect(0, cy, 21.0, 11.0));
    [NSGraphicsContext restoreGraphicsState];
    
    // белая круговая стрелка
    NSBezierPath *arc = [NSBezierPath bezierPath];
    [arc appendBezierPathWithArcWithCenter:NSMakePoint(cx, cy) radius:3.6 startAngle:20.0 endAngle:310.0];
    [arc setLineWidth:1.8];
    [[NSColor whiteColor] setStroke];
    [arc stroke];
    
    CGFloat endAngle = 310.0 * M_PI / 180.0;
    NSPoint end = NSMakePoint(cx + 3.6 * cos(endAngle), cy + 3.6 * sin(endAngle));
    NSPoint tangent = NSMakePoint(-sin(endAngle), cos(endAngle));
    NSPoint normal = NSMakePoint(-tangent.y, tangent.x);
    NSBezierPath *head = [NSBezierPath bezierPath];
    [head moveToPoint:NSMakePoint(end.x + tangent.x * 3.0, end.y + tangent.y * 3.0)];
    [head lineToPoint:NSMakePoint(end.x + normal.x * 2.6, end.y + normal.y * 2.6)];
    [head lineToPoint:NSMakePoint(end.x - normal.x * 2.6, end.y - normal.y * 2.6)];
    [head closePath];
    [[NSColor whiteColor] setFill];
    [head fill];
    
    [image unlockFocus];
    return image;
}

@interface GMColorView : NSView
@property (nonatomic, strong) NSColor *backgroundColor;
@end

@implementation GMColorView
- (void)drawRect:(NSRect)dirtyRect {
    [self.backgroundColor setFill];
    NSRectFill(dirtyRect);
}
@end

// Разделитель между списком и перепиской: тонкий, цвет (180,180,180).
@interface GMSplitView : NSSplitView
@end

@implementation GMSplitView
- (NSColor *)dividerColor {
    return GMRGB(180, 180, 180);
}
@end

// Левая колонка: фон (242,242,242) и тёмная линия под шапкой.
@interface GMSidebarView : NSView
@end

@implementation GMSidebarView
- (void)drawRect:(NSRect)dirtyRect {
    [GMRGB(242, 242, 242) setFill];
    NSRectFill(dirtyRect);
    [GMRGB(181, 181, 181) setFill];
    NSRectFill(NSMakeRect(0, self.bounds.size.height - GMHeaderHeight, self.bounds.size.width, 1.0));
}
@end

// Правая часть: «льняной» фон и лёгкая тень у разделителя.
@interface GMMainView : NSView
@end

@implementation GMMainView
- (void)drawRect:(NSRect)dirtyRect {
    [GMLinenColor() setFill];
    NSRectFill(dirtyRect);
    CGFloat h = self.bounds.size.height;
    [GMRGBA(0, 0, 0, 0.105) setFill];
    NSRectFillUsingOperation(NSMakeRect(0, 0, 1.0, h), NSCompositeSourceOver);
    [GMRGBA(0, 0, 0, 0.026) setFill];
    NSRectFillUsingOperation(NSMakeRect(1.0, 0, 1.0, h), NSCompositeSourceOver);
}
@end

// Строка «Кому:» — прозрачная, рисует только линию снизу и блик под ней.
@interface GMTopBarView : NSView
@end

@implementation GMTopBarView
- (void)drawRect:(NSRect)dirtyRect {
    CGFloat w = self.bounds.size.width;
    [GMRGB(237, 239, 244) setFill];
    NSRectFill(NSMakeRect(0, 0, w, 1.0));
    [GMRGB(196, 201, 212) setFill];
    NSRectFill(NSMakeRect(0, 1.0, w, 1.0));
}
@end

@interface GMChatTableView : NSTableView
@end

@implementation GMChatTableView
- (NSMenu *)menuForEvent:(NSEvent *)event {
    NSPoint point = [self convertPoint:event.locationInWindow fromView:nil];
    NSInteger row = [self rowAtPoint:point];
    if (row < 0) return nil;
    
    if (![self isRowSelected:row]) {
        [self selectRowIndexes:[NSIndexSet indexSetWithIndex:(NSUInteger)row] byExtendingSelection:NO];
    }
    
    id target = self.delegate;
    NSMutableDictionary *conversation = [target conversationAtVisibleIndex:row];
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Чат"];
    NSArray *titles = [NSArray arrayWithObjects:@"Переименовать", @"Удалить", @"Экспортировать…", nil];
    NSArray *actions = [NSArray arrayWithObjects:NSStringFromSelector(@selector(renameConversation:)),
                        NSStringFromSelector(@selector(deleteConversation:)),
                        NSStringFromSelector(@selector(exportConversation:)), nil];
    for (NSUInteger i = 0; i < titles.count; i++) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:[titles objectAtIndex:i]
                                                      action:NSSelectorFromString([actions objectAtIndex:i])
                                               keyEquivalent:@""];
        item.target = target;
        item.representedObject = conversation;
        [menu addItem:item];
    }
    return menu;
}

// Линии между строками продолжаются и в пустой части списка, как в «Сообщениях».
- (void)drawBackgroundInClipRect:(NSRect)clipRect {
    [GMRGB(242, 242, 242) setFill];
    NSRectFill(clipRect);
    NSInteger first = MAX(0, (NSInteger)floor(clipRect.origin.y / GMRowHeight));
    NSInteger last = (NSInteger)ceil(NSMaxY(clipRect) / GMRowHeight);
    for (NSInteger i = first; i <= last; i++) {
        CGFloat top = i * GMRowHeight;
        if (i > 0) {
            [GMRGB(252, 252, 252) setFill];
            NSRectFill(NSMakeRect(clipRect.origin.x, top, clipRect.size.width, 1.0));
        }
        [GMRGB(219, 215, 212) setFill];
        NSRectFill(NSMakeRect(clipRect.origin.x, top + GMRowHeight - 1.0, clipRect.size.width, 1.0));
    }
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect {
    // Выделение рисует GMChatRowView.
}
@end

@implementation GMChatRowView
- (BOOL)isFlipped { return YES; }

- (void)drawRect:(NSRect)dirtyRect {
    NSRect b = self.bounds;
    CGFloat w = b.size.width;
    [GMRGB(242, 242, 242) setFill];
    NSRectFill(b);
    if (self.isSelected) {
        // 54 строки градиента между верхней и нижней линиями
        for (NSInteger i = 0; i < 54; i++) {
            CGFloat t = i / 53.0;
            [GMBlend(202, 210, 221, 180, 188, 202, t) setFill];
            NSRectFill(NSMakeRect(0, 1.0 + i, w, 1.0));
        }
        [GMRGB(232, 232, 232) setFill];
        NSRectFill(NSMakeRect(0, 0, w, 1.0));
        [GMRGB(163, 167, 187) setFill];
        NSRectFill(NSMakeRect(0, b.size.height - 1.0, w, 1.0));
    } else {
        [GMRGB(252, 252, 252) setFill];
        NSRectFill(NSMakeRect(0, 0, w, 1.0));
        [GMRGB(219, 215, 212) setFill];
        NSRectFill(NSMakeRect(0, b.size.height - 1.0, w, 1.0));
    }
}
@end

@implementation GMChatCellView
- (BOOL)isFlipped { return YES; }

- (void)drawAvatarAtX:(CGFloat)ax y:(CGFloat)ay {
    NSBezierPath *box = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(ax + 0.5, ay + 0.5, 40.0, 40.0)
                                                        xRadius:3.0 yRadius:3.0];
    [NSGraphicsContext saveGraphicsState];
    [box addClip];
    
    // фон и внутренние тени
    [GMRGB(237, 237, 237) setFill];
    NSRectFill(NSMakeRect(ax, ay, 41.0, 41.0));
    [GMRGB(232, 232, 232) setFill];
    NSRectFill(NSMakeRect(ax + 1.0, ay + 1.0, 1.0, 39.0));
    [GMRGB(219, 219, 219) setFill];
    NSRectFill(NSMakeRect(ax + 1.0, ay + 1.0, 39.0, 1.0));
    [GMRGB(227, 227, 227) setFill];
    NSRectFill(NSMakeRect(ax + 1.0, ay + 2.0, 39.0, 1.0));
    [GMRGB(233, 233, 233) setFill];
    NSRectFill(NSMakeRect(ax + 1.0, ay + 3.0, 39.0, 1.0));
    
    // силуэт: голова и плечи
    NSBezierPath *head = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(ax + 13.0, ay + 9.5, 15.0, 16.0)];
    NSBezierPath *body = [NSBezierPath bezierPath];
    [body moveToPoint:NSMakePoint(ax + 16.0, ay + 24.0)];
    [body lineToPoint:NSMakePoint(ax + 16.0, ay + 29.0)];
    [body curveToPoint:NSMakePoint(ax + 8.0, ay + 33.0)
         controlPoint1:NSMakePoint(ax + 16.0, ay + 31.0) controlPoint2:NSMakePoint(ax + 11.5, ay + 31.5)];
    [body curveToPoint:NSMakePoint(ax + 2.0, ay + 39.0)
         controlPoint1:NSMakePoint(ax + 5.0, ay + 34.0) controlPoint2:NSMakePoint(ax + 2.5, ay + 36.0)];
    [body lineToPoint:NSMakePoint(ax + 2.0, ay + 42.0)];
    [body lineToPoint:NSMakePoint(ax + 39.0, ay + 42.0)];
    [body lineToPoint:NSMakePoint(ax + 39.0, ay + 39.0)];
    [body curveToPoint:NSMakePoint(ax + 33.0, ay + 33.0)
         controlPoint1:NSMakePoint(ax + 38.5, ay + 36.0) controlPoint2:NSMakePoint(ax + 36.0, ay + 34.0)];
    [body curveToPoint:NSMakePoint(ax + 25.0, ay + 29.0)
         controlPoint1:NSMakePoint(ax + 29.5, ay + 31.5) controlPoint2:NSMakePoint(ax + 25.0, ay + 31.0)];
    [body lineToPoint:NSMakePoint(ax + 25.0, ay + 24.0)];
    [body closePath];
    
    NSArray *shapes = [NSArray arrayWithObjects:head, body, nil];
    for (NSBezierPath *shape in shapes) {
        [NSGraphicsContext saveGraphicsState];
        [shape addClip];
        for (NSInteger i = 0; i < 41; i++) {
            [GMBlend(199, 204, 213, 212, 216, 223, i / 40.0) setFill];
            NSRectFill(NSMakeRect(ax, ay + i, 41.0, 1.0));
        }
        [NSGraphicsContext restoreGraphicsState];
        [shape setLineWidth:1.0];
        [GMRGBA(190, 196, 206, 0.8) setStroke];
        [shape stroke];
    }
    [NSGraphicsContext restoreGraphicsState];
    
    // рамка
    [box setLineWidth:1.0];
    [GMRGB(183, 183, 181) setStroke];
    [box stroke];
}

- (void)drawRect:(NSRect)dirtyRect {
    [self drawAvatarAtX:13.0 y:7.0];
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineBreakMode:NSLineBreakByTruncatingTail];
    NSDictionary *titleAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSFont boldSystemFontOfSize:13.0], NSFontAttributeName,
                                GMRGB(0, 0, 0), NSForegroundColorAttributeName,
                                style, NSParagraphStyleAttributeName, nil];
    NSDictionary *previewAttrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSFont systemFontOfSize:11.0], NSFontAttributeName,
                                  GMRGB(82, 82, 82), NSForegroundColorAttributeName,
                                  style, NSParagraphStyleAttributeName, nil];
    
    CGFloat textWidth = MAX(30.0, self.bounds.size.width - 61.0 - 10.0);
    [self.title drawInRect:NSMakeRect(61.0, 5.0, textWidth, 17.0) withAttributes:titleAttrs];
    if (self.preview.length) {
        [self.preview drawInRect:NSMakeRect(61.0, 24.0, textWidth, 15.0) withAttributes:previewAttrs];
    }
}
@end

// Нижняя область: поле ввода в форме капсулы с «хвостиком», смайлик и стрелка.
@interface GMComposerView : NSView
@end

@implementation GMComposerView
- (void)drawRect:(NSRect)dirtyRect {
    CGFloat w = self.bounds.size.width;
    
    // блик под капсулой
    NSBezierPath *shine = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(13.5, 9.5, w - 30.0, 21.0)
                                                          xRadius:10.5 yRadius:10.5];
    [shine setLineWidth:1.0];
    [GMRGBA(255, 255, 255, 0.9) setStroke];
    [shine stroke];
    
    // хвостик справа внизу
    NSBezierPath *tail = [NSBezierPath bezierPath];
    [tail moveToPoint:NSMakePoint(w - 16.6, 19.5)];
    [tail curveToPoint:NSMakePoint(w - 12.0, 10.5)
         controlPoint1:NSMakePoint(w - 16.2, 15.0) controlPoint2:NSMakePoint(w - 14.3, 11.6)];
    [tail lineToPoint:NSMakePoint(w - 27.0, 10.5)];
    [tail lineToPoint:NSMakePoint(w - 27.0, 19.5)];
    [tail closePath];
    [GMRGB(251, 251, 252) setFill];
    [tail fill];
    [tail setLineWidth:1.0];
    [GMRGB(181, 184, 192) setStroke];
    [tail stroke];
    
    // капсула: рамка-градиент, заливка-градиент, тень под верхним краем
    NSBezierPath *outer = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(13.0, 10.0, w - 29.0, 22.0)
                                                          xRadius:11.0 yRadius:11.0];
    NSGradient *borderGradient = [[NSGradient alloc] initWithStartingColor:GMRGB(198, 200, 206)
                                                               endingColor:GMRGB(168, 172, 179)];
    [borderGradient drawInBezierPath:outer angle:90.0];
    
    NSBezierPath *inner = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(14.0, 11.0, w - 31.0, 20.0)
                                                          xRadius:10.0 yRadius:10.0];
    NSGradient *fillGradient = [[NSGradient alloc] initWithStartingColor:GMRGB(254, 254, 254)
                                                             endingColor:GMRGB(243, 244, 247)];
    [fillGradient drawInBezierPath:inner angle:90.0];
    [NSGraphicsContext saveGraphicsState];
    [inner addClip];
    [GMRGB(224, 225, 228) setFill];
    NSRectFill(NSMakeRect(0, 30.0, w, 1.0));
    [GMRGB(235, 237, 239) setFill];
    NSRectFill(NSMakeRect(0, 29.0, w, 1.0));
    [NSGraphicsContext restoreGraphicsState];
    
    // смайлик
    CGFloat cx = w - 29.5, cy = 20.5;
    NSBezierPath *face = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(cx - 7.5, cy - 7.5, 15.0, 15.0)];
    [GMRGB(255, 255, 254) setFill];
    [face fill];
    [face setLineWidth:1.2];
    [GMRGB(124, 127, 123) setStroke];
    [face stroke];
    [GMRGB(124, 127, 123) setFill];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(cx - 4.2, cy + 0.8, 1.6, 2.6)] fill];
    [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(cx + 2.6, cy + 0.8, 1.6, 2.6)] fill];
    NSBezierPath *smile = [NSBezierPath bezierPath];
    [smile appendBezierPathWithArcWithCenter:NSMakePoint(cx, cy + 1.0) radius:5.0 startAngle:205.0 endAngle:335.0];
    [smile setLineWidth:1.2];
    [smile setLineCapStyle:NSRoundLineCapStyle];
    [GMRGB(124, 127, 123) setStroke];
    [smile stroke];
    
    // стрелочка слева от смайлика
    NSBezierPath *arrow = [NSBezierPath bezierPath];
    [arrow moveToPoint:NSMakePoint(w - 44.7, 22.5)];
    [arrow lineToPoint:NSMakePoint(w - 39.3, 22.5)];
    [arrow lineToPoint:NSMakePoint(w - 42.0, 19.2)];
    [arrow closePath];
    [GMRGB(124, 127, 123) setFill];
    [arrow fill];
}
@end

@interface GMBubbleView : NSView
@property (nonatomic, copy) NSString *messageText;
@property (nonatomic, assign) BOOL outgoing;
- (id)initWithFrame:(NSRect)frame text:(NSString *)text outgoing:(BOOL)isOutgoing;
@end

@implementation GMBubbleView

- (id)initWithFrame:(NSRect)frame text:(NSString *)text outgoing:(BOOL)isOutgoing {
    self = [super initWithFrame:frame];
    if (self) {
        _messageText = [text copy];
        _outgoing = isOutgoing;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    NSRect bubbleRect = NSInsetRect(self.bounds, 1.0, 1.0);
    CGFloat w = NSMaxX(bubbleRect);
    CGFloat h = NSMaxY(bubbleRect);
    CGFloat radius = 14.0;
    NSBezierPath *bubblePath = [NSBezierPath bezierPath];
    
    if (self.outgoing) {
        // Синий пузырь пользователя с хвостиком справа, как в iOS-клиенте.
        [bubblePath moveToPoint:NSMakePoint(radius + 1.0, h - 1.0)];
        [bubblePath lineToPoint:NSMakePoint(w - 10.0 - radius, h - 1.0)];
        [bubblePath curveToPoint:NSMakePoint(w - 10.0, h - radius - 1.0)
                   controlPoint1:NSMakePoint(w - 10.0 - radius / 3.0, h - 1.0)
                   controlPoint2:NSMakePoint(w - 10.0, h - radius / 3.0)];
        [bubblePath lineToPoint:NSMakePoint(w - 10.0, 14.0)];
        [bubblePath curveToPoint:NSMakePoint(w - 1.0, 1.0)
                   controlPoint1:NSMakePoint(w - 8.0, 7.0)
                   controlPoint2:NSMakePoint(w - 4.0, 1.0)];
        [bubblePath curveToPoint:NSMakePoint(w - 13.0, 1.0)
                   controlPoint1:NSMakePoint(w - 5.0, 1.0)
                   controlPoint2:NSMakePoint(w - 9.0, 1.0)];
        [bubblePath lineToPoint:NSMakePoint(radius + 1.0, 1.0)];
        [bubblePath curveToPoint:NSMakePoint(1.0, radius + 1.0)
                   controlPoint1:NSMakePoint(1.0, 1.0)
                   controlPoint2:NSMakePoint(1.0, radius / 2.0)];
        [bubblePath lineToPoint:NSMakePoint(1.0, h - radius - 1.0)];
        [bubblePath curveToPoint:NSMakePoint(radius + 1.0, h - 1.0)
                   controlPoint1:NSMakePoint(1.0, h - 1.0)
                   controlPoint2:NSMakePoint(radius / 2.0, h - 1.0)];
        [bubblePath closePath];
    } else {
        // Светлый пузырь Gemini с хвостиком слева.
        [bubblePath moveToPoint:NSMakePoint(10.0 + radius, h - 1.0)];
        [bubblePath lineToPoint:NSMakePoint(w - radius - 1.0, h - 1.0)];
        [bubblePath curveToPoint:NSMakePoint(w - 1.0, h - radius - 1.0)
                   controlPoint1:NSMakePoint(w - radius / 3.0, h - 1.0)
                   controlPoint2:NSMakePoint(w - 1.0, h - radius / 3.0)];
        [bubblePath lineToPoint:NSMakePoint(w - 1.0, radius + 1.0)];
        [bubblePath curveToPoint:NSMakePoint(w - radius - 1.0, 1.0)
                   controlPoint1:NSMakePoint(w - 1.0, radius / 2.0)
                   controlPoint2:NSMakePoint(w - radius / 3.0, 1.0)];
        [bubblePath lineToPoint:NSMakePoint(13.0, 1.0)];
        [bubblePath curveToPoint:NSMakePoint(1.0, 1.0)
                   controlPoint1:NSMakePoint(10.0, 1.0)
                   controlPoint2:NSMakePoint(5.0, 1.0)];
        [bubblePath curveToPoint:NSMakePoint(10.0, 14.0)
                   controlPoint1:NSMakePoint(3.0, 4.0)
                   controlPoint2:NSMakePoint(10.0, 8.0)];
        [bubblePath lineToPoint:NSMakePoint(10.0, h - radius - 1.0)];
        [bubblePath curveToPoint:NSMakePoint(10.0 + radius, h - 1.0)
                   controlPoint1:NSMakePoint(10.0, h - 1.0)
                   controlPoint2:NSMakePoint(10.0 + radius / 2.0, h - 1.0)];
        [bubblePath closePath];
    }
    
    NSColor *topColor = self.outgoing ? GMRGB(105, 175, 248) : GMRGB(250, 250, 252);
    NSColor *bottomColor = self.outgoing ? GMRGB(24, 110, 230) : GMRGB(214, 216, 222);
    NSGradient *fill = [[NSGradient alloc] initWithStartingColor:topColor endingColor:bottomColor];
    
    [NSGraphicsContext saveGraphicsState];
    [bubblePath addClip];
    [fill drawInRect:bubbleRect angle:90.0];
    
    // Полупрозрачный блик по верхней половине пузыря.
    CGFloat left = self.outgoing ? 2.0 : 12.0;
    CGFloat right = self.outgoing ? w - 12.0 : w - 2.0;
    CGFloat glossBottom = h / 2.0;
    NSBezierPath *glossShape = [NSBezierPath bezierPath];
    [glossShape moveToPoint:NSMakePoint(left + radius - 1.0, h - 1.5)];
    [glossShape lineToPoint:NSMakePoint(right - radius + 1.0, h - 1.5)];
    [glossShape curveToPoint:NSMakePoint(right, h - radius)
               controlPoint1:NSMakePoint(right - 5.0, h - 1.5)
               controlPoint2:NSMakePoint(right, h - 6.0)];
    [glossShape lineToPoint:NSMakePoint(right, glossBottom)];
    [glossShape lineToPoint:NSMakePoint(left, glossBottom)];
    [glossShape lineToPoint:NSMakePoint(left, h - radius)];
    [glossShape curveToPoint:NSMakePoint(left + radius - 1.0, h - 1.5)
               controlPoint1:NSMakePoint(left, h - 6.0)
               controlPoint2:NSMakePoint(left + 5.0, h - 1.5)];
    [glossShape closePath];
    
    CGFloat glossStartAlpha = self.outgoing ? 0.50 : 0.65;
    CGFloat glossEndAlpha = self.outgoing ? 0.08 : 0.12;
    NSGradient *gloss = [[NSGradient alloc]
                         initWithStartingColor:GMRGBA(255, 255, 255, glossStartAlpha)
                         endingColor:GMRGBA(255, 255, 255, glossEndAlpha)];
    [glossShape addClip];
    [gloss drawInRect:bubbleRect angle:90.0];
    [NSGraphicsContext restoreGraphicsState];
    
    NSColor *strokeColor = self.outgoing
    ? GMRGBA(14, 78, 175, 0.95)
    : GMRGB(158, 158, 158);
    [strokeColor setStroke];
    [bubblePath setLineWidth:1.0];
    [bubblePath stroke];
    
    NSColor *textColor = self.outgoing ? [NSColor whiteColor] : [NSColor blackColor];
    NSFont *font = [NSFont systemFontOfSize:15.0];
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                font, NSFontAttributeName,
                                textColor, NSForegroundColorAttributeName,
                                nil];
    CGFloat textLeft = self.outgoing ? 11.0 : 17.0;
    CGFloat textRight = self.outgoing ? 12.0 : 4.0;
    NSRect textRect = NSMakeRect(textLeft, 4.0,
                                 MAX(20.0, bubbleRect.size.width - textLeft - textRight),
                                 MAX(18.0, bubbleRect.size.height - 12.0));
    [self.messageText drawWithRect:textRect
                           options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                        attributes:attributes];
}

@end

// Прозрачный: фон рисует GMMainView.
@implementation GMTranscriptView

- (BOOL)isFlipped { return NO; }

- (void)setMessages:(NSArray *)messages {
    _messages = [messages copy];
    [self rebuildBubbles];
}

- (void)rebuildBubbles {
    for (NSView *view in [self.subviews copy]) {
        [view removeFromSuperview];
    }
    
    CGFloat viewWidth = MAX(240.0, self.frame.size.width);
    CGFloat maxBubbleWidth = MIN(430.0, viewWidth * 0.72);
    NSFont *font = [NSFont systemFontOfSize:15.0];
    CGFloat totalHeight = 18.0;
    for (NSDictionary *item in self.messages) {
        NSString *text = [item objectForKey:@"text"];
        CGFloat textHeight = GMTextHeight(text, maxBubbleWidth - 26.0, font);
        totalHeight += textHeight + 20.0 + 12.0;
    }
    totalHeight = MAX(totalHeight, MAX(300.0, self.minimumHeight));
    [self setFrameSize:NSMakeSize(viewWidth, totalHeight)];
    
    CGFloat cursor = totalHeight - 12.0;
    for (NSDictionary *item in self.messages) {
        NSString *text = [item objectForKey:@"text"] ?: @"";
        BOOL outgoing = [[item objectForKey:@"role"] isEqualToString:@"user"];
        CGFloat textHeight = GMTextHeight(text, maxBubbleWidth - 26.0, font);
        CGFloat bubbleHeight = MAX(textHeight + 18.0, 36.0);
        CGFloat bubbleWidth = MIN(maxBubbleWidth, MAX(64.0, [text sizeWithAttributes:@{NSFontAttributeName:font}].width + 34.0));
        
        // Long messages use the full available bubble width.
        if (textHeight > 34.0) bubbleWidth = maxBubbleWidth;
        cursor -= bubbleHeight;
        CGFloat x = outgoing ? viewWidth - bubbleWidth - 18.0 : 18.0;
        GMBubbleView *bubble = [[GMBubbleView alloc] initWithFrame:NSMakeRect(x, cursor, bubbleWidth, bubbleHeight)
                                                              text:text outgoing:outgoing];
        [self addSubview:bubble];
        cursor -= 12.0;
    }
}

@end


@implementation AppDelegate (Interface)

- (void)buildInterface {
    NSView *content = self.window.contentView;
    for (NSView *view in [content.subviews copy]) {
        [view removeFromSuperview];
    }
    
    NSRect bounds = content.bounds;
    GMSplitView *split = [[GMSplitView alloc] initWithFrame:bounds];
    self.splitView = split;
    split.vertical = YES;
    split.dividerStyle = NSSplitViewDividerStyleThin;
    split.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    split.delegate = self;
    [content addSubview:split];
    
    // ---------- Левая колонка ----------
    GMSidebarView *sidebar = [[GMSidebarView alloc] initWithFrame:NSMakeRect(0, 0, GMSidebarWidth, bounds.size.height)];
    sidebar.autoresizingMask = NSViewHeightSizable;
    [split addSubview:sidebar];
    
    // Правая часть начинается после 1-пиксельного разделителя.
    GMMainView *main = [[GMMainView alloc] initWithFrame:NSMakeRect(GMSidebarWidth + 1.0, 0,
                                                                    bounds.size.width - GMSidebarWidth - 1.0,
                                                                    bounds.size.height)];
    main.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [split addSubview:main];
    [split setPosition:GMSidebarWidth ofDividerAtIndex:0];
    
    CGFloat sidebarHeight = sidebar.bounds.size.height;
    
    self.searchField = [[NSSearchField alloc] initWithFrame:NSMakeRect(12, sidebarHeight - 28, 147, 22)];
    [[self.searchField cell] setPlaceholderString:@"Поиск"];
    self.searchField.target = self;
    self.searchField.action = @selector(searchChanged:);
    self.searchField.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
    [sidebar addSubview:self.searchField];
    
    NSButton *newChatButton = [[NSButton alloc] initWithFrame:NSMakeRect(167, sidebarHeight - 28, 32, 22)];
    newChatButton.title = @"";
    newChatButton.image = GMComposeIcon();
    newChatButton.imagePosition = NSImageOnly;
    newChatButton.bezelStyle = NSTexturedRoundedBezelStyle;
    newChatButton.target = self;
    newChatButton.action = @selector(createNewConversation:);
    newChatButton.autoresizingMask = NSViewMinXMargin | NSViewMinYMargin;
    [sidebar addSubview:newChatButton];
    
    NSScrollView *listScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, GMSidebarWidth, sidebarHeight - GMHeaderHeight)];
    listScroll.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    listScroll.hasVerticalScroller = YES;
    listScroll.autohidesScrollers = NO;
    listScroll.scrollerStyle = NSScrollerStyleLegacy; // полоса прокрутки видна всегда, как на скриншоте
    listScroll.borderType = NSNoBorder;
    listScroll.drawsBackground = YES;
    listScroll.backgroundColor = GMRGB(242, 242, 242);
    
    GMChatTableView *table = [[GMChatTableView alloc] initWithFrame:listScroll.contentView.bounds];
    self.chatList = table;
    self.chatList.headerView = nil;
    self.chatList.rowHeight = GMRowHeight;
    self.chatList.intercellSpacing = NSMakeSize(0, 0); // иначе шаг строк 58 вместо 56
    self.chatList.backgroundColor = GMRGB(242, 242, 242);
    self.chatList.selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular;
    self.chatList.gridStyleMask = NSTableViewGridNone;
    self.chatList.dataSource = self;
    self.chatList.delegate = self;
    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"title"];
    column.width = GMSidebarWidth - 15.0;
    column.minWidth = 40.0;
    column.resizingMask = NSTableColumnAutoresizingMask;
    [self.chatList addTableColumn:column];
    listScroll.documentView = self.chatList;
    [sidebar addSubview:listScroll];
    
    // ---------- Правая часть ----------
    CGFloat mainWidth = main.bounds.size.width;
    CGFloat mainHeight = main.bounds.size.height;
    
    GMTopBarView *topBar = [[GMTopBarView alloc] initWithFrame:NSMakeRect(0, mainHeight - GMTopBarHeight, mainWidth, GMTopBarHeight)];
    topBar.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
    [main addSubview:topBar];
    
    // Выбор модели вместо строки «Кому:»
    self.modelPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(8, 5, 215, 26) pullsDown:NO];
    [self.modelPopup addItemsWithTitles:@[@"gemini-2.5-flash", @"gemini-2.5-pro"]];
    self.modelPopup.autoresizingMask = NSViewMaxXMargin;
    [topBar addSubview:self.modelPopup];
    
    // Кнопка «получить новые модели»
    NSButton *refreshButton = [[NSButton alloc] initWithFrame:NSMakeRect(mainWidth - 31.0, 8, 21, 21)];
    refreshButton.title = @"";
    refreshButton.image = GMRefreshModelsIcon();
    refreshButton.imagePosition = NSImageOnly;
    refreshButton.bordered = NO;
    refreshButton.toolTip = @"Обновить список моделей";
    [[refreshButton cell] setImageScaling:NSImageScaleNone];
    refreshButton.target = self;
    refreshButton.action = @selector(refreshModels:);
    refreshButton.autoresizingMask = NSViewMinXMargin;
    [topBar addSubview:refreshButton];
    
    self.statusLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(231, 8, MAX(40.0, mainWidth - 231.0 - 40.0), 16)];
    self.statusLabel.stringValue = @"";
    self.statusLabel.editable = NO;
    self.statusLabel.selectable = NO;
    self.statusLabel.bezeled = NO;
    self.statusLabel.drawsBackground = NO;
    self.statusLabel.font = [NSFont systemFontOfSize:12.0];
    self.statusLabel.textColor = GMRGB(112, 121, 145);
    self.statusLabel.autoresizingMask = NSViewWidthSizable | NSViewMaxXMargin;
    [topBar addSubview:self.statusLabel];
    
    self.transcriptScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, GMComposerHeight, mainWidth,
                                                                               mainHeight - GMTopBarHeight - GMComposerHeight)];
    self.transcriptScrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    self.transcriptScrollView.hasVerticalScroller = YES;
    self.transcriptScrollView.autohidesScrollers = YES;
    self.transcriptScrollView.borderType = NSNoBorder;
    self.transcriptScrollView.drawsBackground = NO;
    self.transcriptView = [[GMTranscriptView alloc] initWithFrame:NSMakeRect(0, 0, mainWidth, 300)];
    self.transcriptView.messages = @[];
    self.transcriptScrollView.documentView = self.transcriptView;
    [main addSubview:self.transcriptScrollView];
    
    GMComposerView *composer = [[GMComposerView alloc] initWithFrame:NSMakeRect(0, 0, mainWidth, GMComposerHeight)];
    composer.autoresizingMask = NSViewWidthSizable | NSViewMaxYMargin;
    [main addSubview:composer];
    
    self.inputField = [[NSTextField alloc] initWithFrame:NSMakeRect(24, 12, mainWidth - 73, 18)];
    self.inputField.bezeled = NO;
    self.inputField.drawsBackground = NO;
    self.inputField.focusRingType = NSFocusRingTypeNone;
    self.inputField.autoresizingMask = NSViewWidthSizable | NSViewMaxYMargin;
    self.inputField.target = self;
    self.inputField.action = @selector(sendMessage:);
    [composer addSubview:self.inputField];
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex {
    return 175.0;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex {
    return 245.0;
}

// При изменении размера окна ширина списка остаётся прежней, тянется только переписка.
- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize {
    NSArray *subviews = splitView.subviews;
    if (subviews.count != 2) {
        [splitView adjustSubviews];
        return;
    }
    NSView *left = [subviews objectAtIndex:0];
    NSView *right = [subviews objectAtIndex:1];
    CGFloat thickness = splitView.dividerThickness;
    NSSize size = splitView.bounds.size;
    CGFloat leftWidth = MIN(left.frame.size.width, MAX(0.0, size.width - thickness));
    left.frame = NSMakeRect(0, 0, leftWidth, size.height);
    right.frame = NSMakeRect(leftWidth + thickness, 0, MAX(0.0, size.width - leftWidth - thickness), size.height);
}



@end

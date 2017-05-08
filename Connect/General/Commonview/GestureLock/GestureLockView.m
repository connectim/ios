//
//  GestureLockView.m
//  app
//
//  Created by 余钦 on 16/5/4.
//
//

#import "GestureLockView.h"
#import "GestureLockItem.h"

#define ButtonW AUTO_WIDTH(140)


@interface GestureLockView ()
@property (nonatomic, strong) NSMutableArray *selectedButtons;
@property (nonatomic, assign) CGPoint currentMovePoint;
@end


@implementation GestureLockView
- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        [self SetupSubviews];
    }
    return self;
}

- (NSMutableArray *)selectedButtons
{
    if (_selectedButtons == nil) {
        _selectedButtons = [NSMutableArray array];
    }
    return _selectedButtons;
}

- (void)SetupSubviews{
    for (int nIndex = 0; nIndex < 9; nIndex++) {
        GestureLockItem *btn = [[GestureLockItem alloc] init];
        btn.tag = nIndex;
        btn.userInteractionEnabled = NO;
        [self addSubview:btn];
    }
}

- (void)layoutSubviews{
    [super layoutSubviews];
    
    for (int index = 0; index<self.subviews.count; index++) {
        // Remove the button
        UIButton *btn = self.subviews[index];
        
        // set frame
        CGFloat btnW = ButtonW;
        CGFloat btnH = ButtonW;
    
        int totalColumns = 3;
        int col = index % totalColumns;
        int row = index / totalColumns;
        CGFloat marginX = (self.frame.size.width - totalColumns * btnW) / (totalColumns - 1);
        CGFloat marginY = (self.frame.size.height - totalColumns * btnW) / (totalColumns - 1);;
        
        CGFloat btnX = col * (btnW + marginX);
        CGFloat btnY = row * (btnH + marginY);
        btn.frame = CGRectMake(btnX, btnY, btnW, btnH);
    }
}
/**
  *  According to the touches collection to obtain the corresponding touch point position
 */
- (CGPoint)pointWithTouches:(NSSet *)touches
{
    UITouch *touch = [touches anyObject];
    return [touch locationInView:touch.view];
}

/**
  * According to the touch point location to get the corresponding button
 */
- (UIButton *)buttonWithPoint:(CGPoint)point
{
    for (UIButton *btn in self.subviews) {
        if (CGRectContainsPoint(btn.frame, point)) {
            return btn;
        }
    }
    return nil;
}

#pragma mark - Touch method
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // nofication delegate
    if ([self.delegate respondsToSelector:@selector(lockView:BeganTouch:)]) {
        [self.delegate lockView:self BeganTouch:touches];
    }

    // Empty the current touch point
    self.currentMovePoint = CGPointMake(-10, -10);
    
    // 1.Get touch point
    CGPoint pos = [self pointWithTouches:touches];
    
    // 2.get touch methods
    UIButton *btn = [self buttonWithPoint:pos];
    
    // 3. set methods
    if (btn && btn.selected == NO) {
        btn.selected = YES;
        [self.selectedButtons objectAddObject:btn];
    }
    
    // 4.refresh
    [self setNeedsDisplay];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    // 1.get touch point
    CGPoint pos = [self pointWithTouches:touches];
    
    // 2.
    UIButton *btn = [self buttonWithPoint:pos];
    
    // 3.set status
    if (btn && btn.selected == NO) {
        btn.selected = YES;
        [self.selectedButtons objectAddObject:btn];
    } else {
        self.currentMovePoint = pos;
    }
    
    // 4.refresh
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // nofication delegate
    if ([self.delegate respondsToSelector:@selector(lockView:didFinishPath:)]) {
        NSMutableString *path = [NSMutableString string];
        for (UIButton *btn in self.selectedButtons) {
            [path appendFormat:@"%ld", (long)btn.tag];
        }
        [self.delegate lockView:self didFinishPath:path];
    }
    
    // Uncheck all buttons
    for (UIButton *btn in self.selectedButtons) {
        [btn setSelected:NO];
    }
    
    [self.selectedButtons makeObjectsPerformSelector:@selector(setSelected:) withObject:@(NO)];
    
    // Empty the selected button
    [self.selectedButtons removeAllObjects];
    [self setNeedsDisplay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self touchesEnded:touches withEvent:event];
}

#pragma mark - Drawing
- (void)drawRect:(CGRect)rect
{
    if (self.selectedButtons.count == 0) return;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    // Traverse all the buttons
    for (int index = 0; index<self.selectedButtons.count; index++) {
        UIButton *btn = self.selectedButtons[index];
        
        if (index == 0) {
            [path moveToPoint:btn.center];
        } else {
            [path addLineToPoint:btn.center];
        }
    }
    
    // connect
    if (CGPointEqualToPoint(self.currentMovePoint, CGPointMake(-10, -10)) == NO) {
        [path addLineToPoint:self.currentMovePoint];
    }
    
    // draw
    path.lineWidth = 5;
    
    path.lineJoinStyle = kCGLineJoinBevel;
    [GestureColor set];
    [path stroke];
}

@end

//
//  PopMeunView.m
//  WeixinPopMeunView
//
//  Created by MoHuilin on 16/6/13.
//  Copyright © 2016年 bitmian. All rights reserved.
//

#import "PopMeunView.h"

#define screenWidth  [UIScreen mainScreen].bounds.size.width
#define screenHeight  [UIScreen mainScreen].bounds.size.height

@interface PopMeunView ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, assign) CGPoint origin;

@property (nonatomic, assign) CGFloat height;

@property (nonatomic, assign) CGFloat width;


@property (nonatomic, assign) PopMeunDirectionType directionType;

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation PopMeunView


- (instancetype)initWithOrigin:(CGPoint)origin width:(CGFloat)width height:(CGFloat)height type:(PopMeunDirectionType)directionType color:(UIColor *)color{
    if (self = [super initWithFrame:CGRectMake(0, 0, screenWidth, screenHeight)]) {
        self.backgroundColor = [UIColor clearColor];
        self.directionType = directionType;
        self.origin = origin;
        self.height = height;
        self.width = width;
        
        self.backgroudView = [[UIView alloc] initWithFrame:CGRectMake(origin.x, origin.y, width, height)];
        self.backgroudView.layer.cornerRadius = 3;
        self.backgroudView.layer.masksToBounds = YES;
        self.backgroudView.backgroundColor = color;
        [self addSubview:self.backgroudView];
        
        [self.backgroudView addSubview:self.tableView];
        
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.rowHeight = 44;
        self.fontSize = 14;
        self.titleColor = [UIColor redColor];
    }
    
    return self;
}

- (void)popView{
    
//    return;
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    [window addSubview:self];
    
    switch (self.directionType) {
        case PopMeunDirectionTypeLeftUp:
        {
            self.backgroudView.frame = CGRectMake(self.origin.x, self.origin.y,0,0);
            [self startAnimationWithSize:CGRectMake(self.origin.x + 5, self.origin.y - 15, self.width, self.height)];
        }
            break;
        case PopMeunDirectionTypeLeftCenter:
        {
            self.backgroudView.frame = CGRectMake(self.origin.x, self.origin.y,0,0);
            [self startAnimationWithSize:CGRectMake(self.origin.x + 5, self.origin.y - self.height / 2, self.width, self.height)];
        }
            break;
        case PopMeunDirectionTypeLeftDown:
        {
            self.backgroudView.frame = CGRectMake(self.origin.x, self.origin.y,0,0);
            [self startAnimationWithSize:CGRectMake(self.origin.x + 5, self.origin.y + 15, self.width, -self.height)];
        }
            break;
            
            
        case PopMeunDirectionTypeRithtUp:
        {
            self.backgroudView.frame = CGRectMake(self.origin.x, self.origin.y,0,0);
            [self startAnimationWithSize:CGRectMake(self.origin.x - 5, self.origin.y - 15, -self.width, self.height)];
        }
            break;
        case PopMeunDirectionTypeRithtCenter:
        {
            self.backgroudView.frame = CGRectMake(self.origin.x, self.origin.y,0,0);
            [self startAnimationWithSize:CGRectMake(self.origin.x - 5, self.origin.y - self.height / 2, -self.width, self.height)];
        }
            break;
        case PopMeunDirectionTypeRithtDown:
        {
            self.backgroudView.frame = CGRectMake(self.origin.x, self.origin.y,0,0);
            [self startAnimationWithSize:CGRectMake(self.origin.x - 5, self.origin.y + 15, -self.width, -self.height)];
        }
            break;
            
            
        case PopMeunDirectionTypeUpLeft:
        {
            self.backgroudView.frame = CGRectMake(self.origin.x, self.origin.y,0,0);
            [self startAnimationWithSize:CGRectMake(self.origin.x - 15, self.origin.y + 5, self.width, self.height)];
        }
            break;
        case PopMeunDirectionTypeUpCenter:
        {
            self.backgroudView.frame = CGRectMake(self.origin.x, self.origin.y,0,0);
            [self startAnimationWithSize:CGRectMake(self.origin.x - self.width / 2, self.origin.y + 5, self.width, self.height)];
        }
            break;
        case PopMeunDirectionTypeUpRight:
        {
            self.backgroudView.frame = CGRectMake(self.origin.x, self.origin.y,0,0);
            [self startAnimationWithSize:CGRectMake(self.origin.x + 15, self.origin.y + 5, -self.width, self.height)];
        }
            break;
            
            
        case PopMeunDirectionTypeDownLeft:
        {
            self.backgroudView.frame = CGRectMake(self.origin.x, self.origin.y,0,0);
            [self startAnimationWithSize:CGRectMake(self.origin.x - 15, self.origin.y - 5, self.width, -self.height)];
        }
            break;
        case PopMeunDirectionTypeDownCenter:
        {
            self.backgroudView.frame = CGRectMake(self.origin.x, self.origin.y,0,0);
            [self startAnimationWithSize:CGRectMake(self.origin.x - self.width / 2, self.origin.y - 5, self.width, -self.height)];
        }
            break;
        case PopMeunDirectionTypeDownRight:
        {
            self.backgroudView.frame = CGRectMake(self.origin.x, self.origin.y,0,0);
            [self startAnimationWithSize:CGRectMake(self.origin.x + 15, self.origin.y - 5, -self.width, -self.height)];
        }
            break;

        default:
            break;
    }
}

#pragma mark -
- (void)drawRect:(CGRect)rect{
    // Gets the context of the current view
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    switch (self.directionType) {
        case PopMeunDirectionTypeLeftUp:
        case PopMeunDirectionTypeLeftCenter:
        case PopMeunDirectionTypeLeftDown:
        {
            CGFloat startX = self.origin.x;
            CGFloat startY = self.origin.y;
            CGContextMoveToPoint(context, startX, startY);
            CGContextAddLineToPoint(context, startX + 5, startY + 5);
            CGContextAddLineToPoint(context, startX + 5, startY - 5);
        }
            break;
        case PopMeunDirectionTypeRithtUp:
        case PopMeunDirectionTypeRithtCenter:
        case PopMeunDirectionTypeRithtDown:
        {
            CGFloat startX = self.origin.x;
            CGFloat startY = self.origin.y;
            CGContextMoveToPoint(context, startX, startY);
            CGContextAddLineToPoint(context, startX - 5, startY + 5);
            CGContextAddLineToPoint(context, startX - 5, startY - 5);
        }
            break;
        case PopMeunDirectionTypeUpLeft:
        case PopMeunDirectionTypeUpCenter:
        case PopMeunDirectionTypeUpRight:
        {
            CGFloat startX = self.origin.x;
            CGFloat startY = self.origin.y;
            CGContextMoveToPoint(context, startX, startY);
            CGContextAddLineToPoint(context, startX + 5, startY + 5);
            CGContextAddLineToPoint(context, startX - 5, startY + 5);
        }
            break;
        case PopMeunDirectionTypeDownLeft:
        case PopMeunDirectionTypeDownRight:
        case PopMeunDirectionTypeDownCenter:
        {
            CGFloat startX = self.origin.x;
            CGFloat startY = self.origin.y;
            CGContextMoveToPoint(context, startX, startY);
            CGContextAddLineToPoint(context, startX + 5, startY - 5);
            CGContextAddLineToPoint(context, startX - 5, startY - 5);
        }
            break;
            
        default:
            break;
    }
    
    CGContextClosePath(context);
    [self.backgroudView.backgroundColor setFill];
    [self.backgroundColor setStroke];
    CGContextDrawPath(context, kCGPathFillStroke);
}


#pragma mark - privte Method

- (UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.backgroudView.frame.size.width, self.backgroudView.frame.size.height) style:UITableViewStylePlain];
        _tableView.dataSource = self;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.delegate = self;
        [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"com.mhl.meunCellId"];
        _tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _tableView.frame.size.width, 1)];
        
        [_tableView setSeparatorColor:[UIColor colorWithWhite:0.8 alpha:0.4]];
    }
    return _tableView;
}

- (void)setTitles:(NSArray *)titles{
    _titles = titles;
    [self.tableView reloadData];
}


#pragma mark - UITableView
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.titles.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.rowHeight < 44) {
        return 44;
    }
    return self.rowHeight;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsMake(0, 10, 0, 10)];
    }
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"com.mhl.meunCellId" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    if (self.images.count == self.titles.count) {
        cell.imageView.image = [UIImage imageNamed:self.images[indexPath.row]];
    }
    
    cell.textLabel.text = self.titles[indexPath.row];
    cell.textLabel.font = [UIFont systemFontOfSize:self.fontSize];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.textColor = self.titleColor;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self dismiss];
    if ([self.delegate respondsToSelector:@selector(selectIndex:)]) {
        [self.delegate selectIndex:indexPath.row];
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (![[touches anyObject].view isEqual:self.backgroudView]) {
        [self dismiss];
    }
}

- (void)dismiss{

    [UIView animateWithDuration:.25f animations:^{
        self.alpha = 0;
        self.backgroudView.frame = CGRectMake(self.origin.x, self.origin.y, 0, 0);
    } completion:^(BOOL finished) {
        for (UIView *subView in self.backgroudView.subviews) {
            [subView removeFromSuperview];
        }
        [self removeFromSuperview];
    }];
}

- (void)startAnimationWithSize:(CGRect)frame
{
    [UIView animateWithDuration:.0f animations:^{
        self.backgroudView.frame = frame;
    } completion:^(BOOL finished) {
        
    }];
}

@end

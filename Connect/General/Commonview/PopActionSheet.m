//
//  PopActionSheet.m
//  Connect
//
//  Created by MoHuilin on 16/7/27.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "PopActionSheet.h"

@interface PopActionSheet ()
{
    CGSize size;
}

@property (nonatomic, strong) UIView *bgkView;

@property (nonatomic ,copy) NSString *destructiveTitle;


@end

@implementation PopActionSheet

- (instancetype)initWithFrame:(CGRect)frame titleArr:(NSArray *)titleArr {
    self = [super initWithFrame:frame];
    size = [UIScreen mainScreen].bounds.size;
    [self setBackgroundColor:[UIColor colorWithWhite:0.5 alpha:0.5]];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hiddenSheet)];
    [self addGestureRecognizer:tap];
    [self makeBaseUIWithTitleArr:titleArr];
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame titleArr:(NSArray *)titleArr destructive:(NSString *)title{
    self = [super initWithFrame:frame];
    size = [UIScreen mainScreen].bounds.size;
    self.destructiveTitle = title;
    [self setBackgroundColor:[UIColor colorWithWhite:0.5 alpha:0.5]];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hiddenSheet)];
    [self addGestureRecognizer:tap];
    [self makeBaseUIWithTitleArr:titleArr];
    
    return self;
}
- (void)makeBaseUIWithTitleArr:(NSArray *)titleArr{
    
    self.bgkView = [[UIView alloc] initWithFrame:CGRectMake(0, size.height, size.width, titleArr.count * 50 + 55)];
    _bgkView.backgroundColor = [UIColor colorWithRed:0xe9/255.0 green:0xe9/255.0 blue:0xe9/255.0 alpha:1.0];
    [self addSubview:_bgkView];
    
    CGFloat y = [self createBtnWithTitle:LMLocalizedString(@"Common Cancel",nil) origin_y: _bgkView.frame.size.height - 50 tag:-1 action:@selector(hiddenSheet)] - 55;
    NSMutableArray *arrM = [NSMutableArray array];

    if (titleArr.count > 0) {
        [arrM addObjectsFromArray:titleArr];
    }
    if (self.destructiveTitle) {
        [arrM objectAddObject:self.destructiveTitle];
    }
    for (int i = 0; i < arrM.count; i++) {
        y = [self createBtnWithTitle:arrM[i] origin_y:y tag:i action:@selector(click:)];
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        CGRect frame = _bgkView.frame;
        frame.origin.y -= frame.size.height;
        _bgkView.frame = frame;
    }];
    
}

- (CGFloat)createBtnWithTitle:(NSString *)title origin_y:(CGFloat)y tag:(NSInteger)tag action:(SEL)method {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.frame = CGRectMake(0, y, size.width, 50);
    btn.backgroundColor = [UIColor whiteColor];
    if ([title isEqualToString:self.destructiveTitle]) {
        [btn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    } else{
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    btn.tag = tag;
    [btn addTarget:self action:method forControlEvents:UIControlEventTouchUpInside];
    [_bgkView addSubview:btn];
    return y -= tag == -1 ? 0 : 50.4;
}
- (void)hiddenSheet {
    [UIView animateWithDuration:0.3 animations:^{
        CGRect frame = _bgkView.frame;
        frame.origin.y += frame.size.height;
        _bgkView.frame = frame;
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self removeFromSuperview];
    });
}

- (void)click:(UIButton *)btn {
    if (self.Click) {
        _Click(btn.tag);
    }
}
@end

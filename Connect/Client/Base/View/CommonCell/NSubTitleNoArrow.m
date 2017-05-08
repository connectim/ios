//
//  NSubTitleNoArrow.m
//  Connect
//
//  Created by MoHuilin on 16/8/4.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "NSubTitleNoArrow.h"

@interface NSubTitleNoArrow ()
@property (weak, nonatomic) IBOutlet UILabel *CTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *CSubtitleLabel;

@end

@implementation NSubTitleNoArrow

- (void)awakeFromNib{
    [super awakeFromNib];
    
    self.CSubtitleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longpress)];
    [self addGestureRecognizer:longPress];
}

- (void)setData:(id)data{
    [super setData:data];
    
    
    
    CellItem *item = (CellItem *)data;
    self.CTitleLabel.text = item.title;
    self.CSubtitleLabel.text = item.subTitle;
}

- (void)longpress{
    [self becomeFirstResponder];
    UIMenuController *popMenu = [UIMenuController sharedMenuController];
    UIMenuItem *item1 = [[UIMenuItem alloc] initWithTitle:LMLocalizedString(@"Set Copy", nil) action:@selector(operation:)];
    NSArray *menuItems = @[item1];
    [popMenu setMenuItems:menuItems];
    [popMenu setArrowDirection:UIMenuControllerArrowDown];
    [popMenu setTargetRect:self.CSubtitleLabel.frame inView:self];
    [popMenu setMenuVisible:YES animated:YES];

}

- (void)operation:(UIMenuItem *)item
{
    
    CellItem *model = (CellItem *)self.data;

    if (model.innerOperation) {
        model.innerOperation();
    }
}



@end

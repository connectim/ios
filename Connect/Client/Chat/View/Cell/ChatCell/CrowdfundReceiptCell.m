//
//  CrowdfundReceiptCell.m
//  Connect
//
//  Created by MoHuilin on 16/8/28.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "CrowdfundReceiptCell.h"

@interface CrowdfundReceiptCell ()
@property(nonatomic, strong) UIImageView *payIconView;

@property(nonatomic, strong) GJCFCoreTextContentView *payOrReceiptTipView;

@property(nonatomic, strong) GJCFCoreTextContentView *subTipLabel;

@property(nonatomic, strong) GJCFCoreTextContentView *statusLabel;

@property(nonatomic, assign) CGFloat contentInnerMargin; //margin


@end

@implementation CrowdfundReceiptCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

        self.contentInnerMargin = 10.f;

        self.bubbleBackImageView.width = AUTO_WIDTH(425);
        self.bubbleBackImageView.height = AUTO_HEIGHT(151);
        self.contentSize = self.bubbleBackImageView.size;

        self.payIconView = [[UIImageView alloc] init];
        self.payIconView.image = GJCFQuickImage(@"payment");
        self.payIconView.width = AUTO_WIDTH(42);
        self.payIconView.height = AUTO_HEIGHT(60);
        self.payIconView.top = AUTO_HEIGHT(15);
        [self.bubbleBackImageView addSubview:self.payIconView];


        self.payOrReceiptTipView = [[GJCFCoreTextContentView alloc] init];
        self.payOrReceiptTipView.width = AUTO_WIDTH(300);
        self.payOrReceiptTipView.height = AUTO_HEIGHT(72);
        self.payOrReceiptTipView.contentBaseWidth = self.payOrReceiptTipView.width;
        self.payOrReceiptTipView.contentBaseHeight = self.payOrReceiptTipView.height;
        self.payOrReceiptTipView.backgroundColor = [UIColor clearColor];
        [self.bubbleBackImageView addSubview:self.payOrReceiptTipView];

        self.subTipLabel = [[GJCFCoreTextContentView alloc] init];
        self.subTipLabel.width = AUTO_WIDTH(245);
        self.subTipLabel.height = AUTO_HEIGHT(33);
        self.subTipLabel.contentBaseWidth = self.subTipLabel.width;
        self.subTipLabel.contentBaseHeight = self.subTipLabel.height;
        self.subTipLabel.backgroundColor = [UIColor clearColor];
        [self.bubbleBackImageView addSubview:self.subTipLabel];


        self.statusLabel = [[GJCFCoreTextContentView alloc] init];
        self.statusLabel.width = self.bubbleBackImageView.width;
        self.statusLabel.height = AUTO_HEIGHT(33);
        self.statusLabel.contentBaseWidth = self.statusLabel.width;
        self.statusLabel.contentBaseHeight = self.statusLabel.height;
        self.statusLabel.backgroundColor = [UIColor clearColor];
        [self.bubbleBackImageView addSubview:self.statusLabel];
        self.statusLabel.textColor = [UIColor colorWithRed:0.000 green:0.502 blue:1.000 alpha:1.000];


        //tap
        UITapGestureRecognizer *tapR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnSelf)];
        tapR.numberOfTapsRequired = 1;
        [self.bubbleBackImageView addGestureRecognizer:tapR];

    }
    return self;
}

- (void)setContentModel:(GJGCChatContentBaseModel *)contentModel {
    if (!contentModel) {
        return;
    }
    [super setContentModel:contentModel];

    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) contentModel;
    self.isFromSelf = chatContentModel.isFromSelf;

    self.payOrReceiptTipView.contentAttributedString = chatContentModel.payOrReceiptMessage;
    self.payOrReceiptTipView.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:chatContentModel.payOrReceiptMessage forBaseContentSize:self.payOrReceiptTipView.contentBaseSize];

    self.subTipLabel.contentAttributedString = chatContentModel.payOrReceiptSubTipMessage;
    self.subTipLabel.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:chatContentModel.payOrReceiptSubTipMessage forBaseContentSize:self.subTipLabel.contentBaseSize];

    self.statusLabel.contentAttributedString = chatContentModel.payOrReceiptStatusMessage;
    self.statusLabel.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:chatContentModel.payOrReceiptStatusMessage forBaseContentSize:self.statusLabel.contentBaseSize];


    [self adjustContent];


    self.payIconView.left = ImageIconInnerMargin;

    self.payOrReceiptTipView.left = self.payIconView.right + self.contentInnerMargin;
    self.payOrReceiptTipView.top = self.payIconView.top;

    if (self.isFromSelf) {
        self.statusLabel.right = self.bubbleBackImageView.width - (BubbleLeftRightMargin + BubbleLeftRight);
        self.subTipLabel.left = BubbleLeftRightMargin;
    } else {
        self.statusLabel.right = self.bubbleBackImageView.width - BubbleLeftRightMargin;
        self.subTipLabel.left = BubbleLeftRightMargin + BubbleLeftRight;
    }
    self.subTipLabel.bottom = self.bubbleBackImageView.height - BubbleContentBottomMargin;
    self.statusLabel.bottom = self.bubbleBackImageView.height - BubbleContentBottomMargin;

}

- (void)tapOnSelf {
    if (self.delegate && [self.delegate respondsToSelector:@selector(crowdfundReceiptCellDidTap:)]) {
        [self.delegate crowdfundReceiptCellDidTap:self];
    }
}

- (void)goToShowLongPressMenu:(UILongPressGestureRecognizer *)sender {
    [super goToShowLongPressMenu:sender];
    if (sender.state == UIGestureRecognizerStateBegan) {
        //
        [self becomeFirstResponder];
        UIMenuController *popMenu = [UIMenuController sharedMenuController];
        UIMenuItem *item1 = [[UIMenuItem alloc] initWithTitle:LMLocalizedString(@"Link Delete", nil) action:@selector(deleteMessage:)];
        NSArray *menuItems = @[item1];
        [popMenu setMenuItems:menuItems];
        [popMenu setArrowDirection:UIMenuControllerArrowDown];

        [popMenu setTargetRect:self.bubbleBackImageView.frame inView:self];
        [popMenu setMenuVisible:YES animated:YES];

    }
}

+ (CGFloat)cellHeightForContentModel:(GJGCChatContentBaseModel *)contentModel {
    CGSize nameSize = CGSizeZero;
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) contentModel;
    if (chatContentModel.isGroupChat && !chatContentModel.isFromSelf) {
        NSAttributedString *name = [[NSAttributedString alloc] initWithString:chatContentModel.senderName];
        nameSize = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:name forBaseContentSize:CGSizeMake(DEVICE_SIZE.width - AUTO_WIDTH(150), 25)];
        nameSize.height += 3;
    }

    return AUTO_HEIGHT(151) + BOTTOM_CELL_MARGIN + nameSize.height;
}

@end

//
//  ChatTransferCell.m
//  Connect
//
//  Created by MoHuilin on 16/7/25.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ChatTransferCell.h"

@interface ChatTransferCell ()

@property(nonatomic, strong) UIImageView *payIconView;

@property(nonatomic, strong) GJCFCoreTextContentView *transferTipView;

@property(nonatomic, strong) GJCFCoreTextContentView *subTipLabel;

@property(nonatomic, strong) GJCFCoreTextContentView *statusLabel;

@property(nonatomic, assign) CGFloat contentInnerMargin; //margin


@end

@implementation ChatTransferCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

        self.contentInnerMargin = 10.f;

        self.bubbleBackImageView.width = AUTO_WIDTH(425);
        self.bubbleBackImageView.height = AUTO_HEIGHT(151);

        self.payIconView = [[UIImageView alloc] init];
        self.payIconView.image = GJCFQuickImage(@"chat_bar_trasfer");
        self.payIconView.width = AUTO_WIDTH(80);
        self.payIconView.height = AUTO_WIDTH(80);
        self.payIconView.top = AUTO_HEIGHT(15);
        [self.bubbleBackImageView addSubview:self.payIconView];


        self.transferTipView = [[GJCFCoreTextContentView alloc] init];
        self.transferTipView.width = AUTO_WIDTH(300);
        self.transferTipView.height = AUTO_HEIGHT(72);
        self.transferTipView.top = self.payIconView.top;
        self.transferTipView.contentBaseWidth = self.transferTipView.width;
        self.transferTipView.contentBaseHeight = self.transferTipView.height;
        self.transferTipView.backgroundColor = [UIColor clearColor];
        [self.bubbleBackImageView addSubview:self.transferTipView];

        self.subTipLabel = [[GJCFCoreTextContentView alloc] init];
        self.subTipLabel.width = AUTO_WIDTH(300);
        self.subTipLabel.height = AUTO_HEIGHT(33);
        self.subTipLabel.contentBaseWidth = self.subTipLabel.width;
        self.subTipLabel.contentBaseHeight = self.subTipLabel.height;
        self.subTipLabel.backgroundColor = [UIColor clearColor];
        [self.bubbleBackImageView addSubview:self.subTipLabel];


        self.statusLabel = [[GJCFCoreTextContentView alloc] init];
        self.statusLabel.width = AUTO_WIDTH(300);
        self.statusLabel.height = AUTO_HEIGHT(33);
        self.statusLabel.contentBaseWidth = self.statusLabel.width;
        self.statusLabel.contentBaseHeight = self.statusLabel.height;
        self.statusLabel.backgroundColor = [UIColor clearColor];
        [self.bubbleBackImageView addSubview:self.statusLabel];

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
    self.transferTipView.contentAttributedString = chatContentModel.transferMessage;
    self.transferTipView.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:chatContentModel.transferMessage forBaseContentSize:self.transferTipView.contentBaseSize];

    self.subTipLabel.contentAttributedString = chatContentModel.transferSubTipMessage;
    self.subTipLabel.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:chatContentModel.transferSubTipMessage forBaseContentSize:self.subTipLabel.contentBaseSize];

    self.statusLabel.contentAttributedString = chatContentModel.transferStatusMessage;
    self.statusLabel.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:chatContentModel.transferStatusMessage forBaseContentSize:self.statusLabel.contentBaseSize];


    CGSize sizeLimit = self.statusLabel.size;
    if (sizeLimit.width > AUTO_WIDTH(150)) {
        sizeLimit.width = AUTO_WIDTH(150);
    }
    self.statusLabel.gjcf_size = sizeLimit;

    CGSize sizeLimitSub = self.subTipLabel.size;
    if (sizeLimitSub.width > self.bubbleBackImageView.width - 25 - self.statusLabel.gjcf_size.width) {
        sizeLimitSub.width = self.bubbleBackImageView.width - 25 - self.statusLabel.gjcf_size.width;
    }
    self.subTipLabel.gjcf_size = sizeLimitSub;

    [self adjustContent];

    if (self.isFromSelf) {
        self.statusLabel.right = self.bubbleBackImageView.width - (BubbleLeftRightMargin + BubbleLeftRight);
        self.subTipLabel.left = BubbleLeftRightMargin;
        //set payIconView 和 transferTipView
        self.payIconView.left = ImageIconInnerMargin;
    } else {
        self.statusLabel.right = self.bubbleBackImageView.width - BubbleLeftRightMargin;
        self.subTipLabel.left = BubbleLeftRightMargin + BubbleLeftRight;
        //set payIconView 和 transferTipView
        self.payIconView.left = ImageIconInnerMargin + BubbleLeftRight;
    }
    self.transferTipView.left = self.payIconView.right + ImageIconInnerMargin;
    self.subTipLabel.bottom = self.bubbleBackImageView.height - BubbleContentBottomMargin;
    self.statusLabel.bottom = self.bubbleBackImageView.height - BubbleContentBottomMargin;
}

- (void)tapOnSelf {
    if (self.delegate && [self.delegate respondsToSelector:@selector(transforCellDidTap:)]) {
        [self.delegate transforCellDidTap:self];
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

//
//  LMWalletLinkCell.m
//  Connect
//
//  Created by MoHuilin on 2017/2/13.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMWalletLinkCell.h"
#import "NSString+Size.h"

#define WalletLinkCellHeight AUTO_WIDTH(180)
#define IconImageHeight AUTO_WIDTH(90)

#define MaxTitleHeight AUTO_WIDTH(80)
#define MaxSubTitleHeight AUTO_WIDTH(110)

@interface LMWalletLinkCell ()
@property(nonatomic, copy) NSString *contentCopyString;
@property(nonatomic, strong) UIImageView *iconImageView;
@property(nonatomic, strong) UILabel *titleLable;
@property(nonatomic, strong) UILabel *subTipLabel;

@end

@implementation LMWalletLinkCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

        self.contentSize = CGSizeMake(AUTO_WIDTH(460), WalletLinkCellHeight);

        self.bubbleBackImageView.width = AUTO_WIDTH(460);
        self.bubbleBackImageView.height = WalletLinkCellHeight;

        self.iconImageView = [[UIImageView alloc] init];
        self.iconImageView.width = IconImageHeight;
        self.iconImageView.height = IconImageHeight;
        self.iconImageView.right = self.contentSize.width - BubbleLeftRightMargin;
        self.iconImageView.bottom = self.contentSize.height - BubbleLeftRightMargin;
        [self.bubbleBackImageView addSubview:self.iconImageView];

        self.titleLable = [[UILabel alloc] init];
        self.titleLable.numberOfLines = 2;
        self.titleLable.font = [UIFont boldSystemFontOfSize:FONT_SIZE(30)];
        self.titleLable.top = AUTO_HEIGHT(30);
        [self.bubbleBackImageView addSubview:self.titleLable];

        self.subTipLabel = [[UILabel alloc] init];
        self.subTipLabel.numberOfLines = 3;
        self.subTipLabel.font = [UIFont systemFontOfSize:FONT_SIZE(25)];
        self.subTipLabel.textColor = LMBasicDarkGray;
        [self.bubbleBackImageView addSubview:self.subTipLabel];

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
    self.contentCopyString = chatContentModel.originTextMessage;
    switch (chatContentModel.walletLinkType) {
        case LMWalletlinkTypeOuterPacket: {
            self.titleLable.text = LMLocalizedString(@"Wallet Send a lucky packet", nil);
            self.subTipLabel.text = LMLocalizedString(@"Wallet Click to open lucky packet", nil);
            self.iconImageView.image = [UIImage imageNamed:@"message_send_luckymoney"];
        }
            break;
        case LMWalletlinkTypeOuterTransfer: {
            self.titleLable.text = LMLocalizedString(@"Wallet Wallet Out Send Share", nil);
            self.subTipLabel.text = LMLocalizedString(@"Wallet Click to recive payment", nil);
            self.iconImageView.image = [UIImage imageNamed:@"message_send_bitcoin"];
        }
            break;

        case LMWalletlinkTypeOuterCollection: {
            self.titleLable.text = LMLocalizedString(@"Wallet Send the payment connection", nil);
            self.subTipLabel.text = LMLocalizedString(@"Wallet Click to transfer bitcoin", nil);
            self.iconImageView.image = [UIImage imageNamed:@"message_send_payment"];
        }
            break;
        case LMWalletlinkTypeOuterOther: {
            self.titleLable.text = chatContentModel.linkTitle;
            self.subTipLabel.text = chatContentModel.linkSubtitle;
            [self.iconImageView setLinkUrlIconImageWithUrl:chatContentModel.linkImageUrl placeholder:@"message_link"];
        }
            break;
        default:
            break;
    }
    CGSize size = [self.titleLable.text sizeWithFont:self.titleLable.font constrainedToWidth:AUTO_WIDTH(460) - BubbleLeftRightMargin * 2];
    if (size.height > MaxTitleHeight) {
        size.height = MaxTitleHeight;
    }
    self.titleLable.size = size;

    size = [self.subTipLabel.text sizeWithFont:self.subTipLabel.font constrainedToWidth:AUTO_WIDTH(460) - BubbleLeftRightMargin * 3.2 - IconImageHeight];
    if (size.height > MaxSubTitleHeight) {
        size.height = MaxSubTitleHeight;
    }
    self.subTipLabel.size = size;
    self.subTipLabel.top = self.titleLable.bottom;
    CGFloat height = self.subTipLabel.bottom + BOTTOM_CELL_MARGIN / 2;
    BOOL heightTooSmall = height < WalletLinkCellHeight;
    if (heightTooSmall) {
        height = WalletLinkCellHeight;
    }
    self.contentSize = CGSizeMake(AUTO_WIDTH(460), height);
    self.bubbleBackImageView.height = self.contentSize.height;

    [self adjustContent];
    if (heightTooSmall) {
        if (chatContentModel.isGroupChat && !self.isFromSelf) {
            self.iconImageView.top = self.subTipLabel.top;
        } else {
            self.iconImageView.bottom = self.bubbleBackImageView.bottom - 5;
        }
    } else {
        self.iconImageView.bottom = self.subTipLabel.bottom;
    }

    if (self.isFromSelf) {
        //set payIconView 和 transferTipView
        self.iconImageView.right = self.contentSize.width - BubbleLeftRightMargin - BubbleLeftRight;
        self.titleLable.left = BubbleLeftRightMargin;
        self.subTipLabel.left = BubbleLeftRightMargin;
    } else {
        //set payIconView 和 transferTipView
        self.iconImageView.right = self.contentSize.width - BubbleLeftRightMargin;
        self.titleLable.left = BubbleLeftRightMargin + BubbleLeftRightMargin;
        self.subTipLabel.left = BubbleLeftRightMargin + BubbleLeftRightMargin;
    }
}

- (void)tapOnSelf {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatCellDidTapWalletLinkMessage:)]) {
        [self.delegate chatCellDidTapWalletLinkMessage:self];
    }
}

- (void)goToShowLongPressMenu:(UILongPressGestureRecognizer *)sender {
    [super goToShowLongPressMenu:sender];
    if (sender.state == UIGestureRecognizerStateBegan) {
        //
        [self becomeFirstResponder];
        UIMenuController *popMenu = [UIMenuController sharedMenuController];
        UIMenuItem *copyItem = [[UIMenuItem alloc] initWithTitle:LMLocalizedString(@"Set Copy", nil) action:@selector(copyContent:)];
        UIMenuItem *retweetItem = [[UIMenuItem alloc] initWithTitle:LMLocalizedString(@"Chat Retweet", nil) action:@selector(retweetMessage:)];
        UIMenuItem *item1 = [[UIMenuItem alloc] initWithTitle:LMLocalizedString(@"Link Delete", nil) action:@selector(deleteMessage:)];
        NSArray *menuItems = @[copyItem, retweetItem, item1];
        [popMenu setMenuItems:menuItems];
        [popMenu setArrowDirection:UIMenuControllerArrowDown];

        [popMenu setTargetRect:self.bubbleBackImageView.frame inView:self];
        [popMenu setMenuVisible:YES animated:YES];

    }
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(deleteMessage:) ||
            action == @selector(copyContent:) ||
            action == @selector(retweetMessage:)) {
        return YES;
    }
    return NO;
}


- (void)copyContent:(UIMenuItem *)item {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setString:self.contentCopyString];
}


+ (CGFloat)cellHeightForContentModel:(GJGCChatContentBaseModel *)contentModel {
    NSString *titleString = nil;
    NSString *subTitleString = nil;
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) contentModel;
    switch (chatContentModel.walletLinkType) {
        case LMWalletlinkTypeOuterPacket: {
            titleString = LMLocalizedString(@"Wallet Send a lucky packet", nil);
            subTitleString = LMLocalizedString(@"Wallet Click to open lucky packet", nil);
        }
            break;
        case LMWalletlinkTypeOuterTransfer: {
            titleString = LMLocalizedString(@"Wallet Wallet Out Send Share", nil);
            subTitleString = LMLocalizedString(@"Wallet Click to recive payment", nil);
        }
            break;

        case LMWalletlinkTypeOuterCollection: {
            titleString = LMLocalizedString(@"Wallet Send the payment connection", nil);
            subTitleString = LMLocalizedString(@"Wallet Click to transfer bitcoin", nil);
        }
            break;
        case LMWalletlinkTypeOuterOther: {
            titleString = chatContentModel.linkTitle;
            subTitleString = chatContentModel.linkSubtitle;
        }
            break;
        default:
            break;
    }
    CGSize titleSize = [titleString sizeWithFont:[UIFont boldSystemFontOfSize:FONT_SIZE(30)] constrainedToWidth:AUTO_WIDTH(460) - BubbleLeftRightMargin * 2];
    if (titleSize.height > MaxTitleHeight) {
        titleSize.height = MaxTitleHeight;
    }
    CGSize subTitleSize = [subTitleString sizeWithFont:[UIFont boldSystemFontOfSize:FONT_SIZE(25)] constrainedToWidth:AUTO_WIDTH(460) - BubbleLeftRightMargin * 3.2 - IconImageHeight];
    if (subTitleSize.height > MaxSubTitleHeight) {
        subTitleSize.height = MaxSubTitleHeight;
    }


    CGSize nameSize = CGSizeZero;
    if (chatContentModel.isGroupChat && !chatContentModel.isFromSelf) {
        NSAttributedString *name = [[NSAttributedString alloc] initWithString:chatContentModel.senderName];
        nameSize = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:name forBaseContentSize:CGSizeMake(DEVICE_SIZE.width - AUTO_WIDTH(150), 25)];
        nameSize.height += 3;
    }


    CGFloat height = AUTO_HEIGHT(30) + titleSize.height + subTitleSize.height + BOTTOM_CELL_MARGIN * 1.5f;
    if (height <= WalletLinkCellHeight + BubbleLeftRightMargin * 1.5) {
        height = WalletLinkCellHeight + BubbleLeftRightMargin * 1.5;
    }
    return height + nameSize.height;
}


@end

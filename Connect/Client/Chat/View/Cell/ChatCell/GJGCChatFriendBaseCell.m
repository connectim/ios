//
//  GJGCChatFirendBaseCell.m
//  Connect
//
//  Created by KivenLin on 14-11-10.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatFriendBaseCell.h"
#import "UIGestureRecognizer+Cancel.h"

@interface GJGCChatFriendBaseCell () <UIAlertViewDelegate>

@end

@implementation GJGCChatFriendBaseCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

        self.selectionStyle = UITableViewCellSelectionStyleNone;

        self.cellMargin = BOTTOM_CELL_MARGIN;
        self.contentBordMargin = AUTO_WIDTH(30);
        self.headView = [[GJGCCommonHeadView alloc] init];
        self.headView.width = AUTO_WIDTH(80);
        self.headView.height = AUTO_WIDTH(80);
        //tap head
        UITapGestureRecognizer *tapR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnHeadView:)];
        [self.headView addGestureRecognizer:tapR];

        //long press head
        UILongPressGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressOnHeadView:)];
        longTap.numberOfTouchesRequired = 1;
        longTap.minimumPressDuration = 0.5;
        [self.headView addGestureRecognizer:longTap];

        [self.contentView addSubview:self.headView];

        self.nameLabel = [[GJCFCoreTextContentView alloc] init];
        self.nameLabel.top = 0.f;
        self.nameLabel.width = GJCFSystemScreenWidth - self.headView.width - 3 * self.contentBordMargin;
        self.nameLabel.height = 20.f;
        self.nameLabel.contentBaseWidth = self.nameLabel.width;
        self.nameLabel.contentBaseHeight = 20.f;
        self.nameLabel.backgroundColor = [UIColor clearColor];
        self.nameLabel.hidden = YES;
        [self.contentView addSubview:self.nameLabel];

        self.snapChatTimeoutProgressView = [[DACircularProgressView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
        self.snapChatTimeoutProgressView.hidden = YES;
        self.snapChatTimeoutProgressView.thicknessRatio = 0.2f;
        self.snapChatTimeoutProgressView.roundedCorners = YES;

        [self.contentView addSubview:self.snapChatTimeoutProgressView];
        self.snapChatTimeoutProgressView.trackTintColor = LMBasicGreen;
        self.snapChatTimeoutProgressView.progressTintColor = [UIColor colorWithWhite:0.800 alpha:1.000];
        self.snapChatTimeoutProgressView.clockwiseProgress = YES;


        self.sexIconView = [[UIImageView alloc] init];
        self.sexIconView.frame = (CGRect) {0, 0, 15, 15};
        self.sexIconView.hidden = YES;
        [self.contentView addSubview:self.sexIconView];

        self.bubbleBackImageView = [[UIImageView alloc] init];
        self.bubbleBackImageView.left = self.contentBordMargin;
        self.bubbleBackImageView.width = 5;
        self.bubbleBackImageView.height = 40;
        self.bubbleBackImageView.userInteractionEnabled = YES;
        [self.contentView addSubview:self.bubbleBackImageView];


        self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.statusButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.statusButton.width = 18;
        self.statusButton.height = 18;
        self.statusButton.userInteractionEnabled = NO;
        self.statusButton.hidden = YES;
        [self.statusButton addTarget:self action:@selector(reSendMessage) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:self.statusButton];
        [self.contentView addSubview:self.indicatorView];
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(goToShowLongPressMenu:)];
        longPress.minimumPressDuration = 0.25;
        [self.bubbleBackImageView addGestureRecognizer:longPress];

        [GJCFNotificationCenter addObserver:self selector:@selector(popMenuDidHidden:) name:UIMenuControllerWillHideMenuNotification object:nil];

    }
    return self;
}


- (void)dealloc {
    [GJCFNotificationCenter removeObserver:self];
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];
    [self.bubbleBackImageView setHighlighted:highlighted];
}

- (UIImage *)bubbleImageByRole:(NSString *)imageName {
    UIImage *image = [UIImage imageNamed:imageName];
    CGSize imageSize = image.size;

    UIImage *resizeImage = nil;

    resizeImage = GJCFImageResize(image, imageSize.height / 2.f + 10, 5, imageSize.width / 2.f, imageSize.width / 2.f);

    return resizeImage;
}

- (void)setContentModel:(GJGCChatContentBaseModel *)contentModel {
    _contentModel = contentModel;
    if (!contentModel) {
        return;
    }
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) contentModel;
    self.isFromSelf = chatContentModel.isFromSelf;
    self.sendStatus = chatContentModel.sendStatus;
    self.isGroupChat = chatContentModel.isGroupChat;
    self.faildType = chatContentModel.faildType;
    self.faildReason = chatContentModel.faildReason;
    self.talkType = chatContentModel.talkType;
    self.contentType = chatContentModel.contentType;
    self.isSnapChatMode = chatContentModel.isSnapChatMode;
    self.readState = chatContentModel.readState;

    if (!self.isSnapChatMode) {
        self.headView.width = AUTO_WIDTH(80);
        if (self.isFromSelf) {
            [self.headView setHeadUrl:[[LKUserCenter shareCenter] currentLoginUser].avatar];
        } else {
            [self.headView setHeadUrl:chatContentModel.headUrl];
        }
    } else {
        self.headView.width = 0;
        //内存优化
        [self.headView setHeadImage:nil];
    }

    if (self.isGroupChat && !self.isFromSelf) {
        self.nameLabel.hidden = NO;
        NSAttributedString *name = [[NSAttributedString alloc] initWithString:chatContentModel.senderName];
        self.nameLabel.contentAttributedString = name;
        self.nameLabel.size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:name forBaseContentSize:self.nameLabel.contentBaseSize];
    } else {
        self.nameLabel.hidden = YES;
    }
    self.snapChatTimeoutProgressView.progress = contentModel.snapProgress;
}

- (void)adjustContent {
    if (self.isFromSelf) {

        if (self.contentType == GJGCChatFriendContentTypeRedEnvelope) {
            self.bubbleBackImageView.image = [self bubbleImageByRole:@"message_redbag_sender"];
            self.bubbleBackImageView.highlightedImage = [self bubbleImageByRole:@"message_redbag_sender"];
        } else if (self.contentType == GJGCChatFriendContentTypeNameCard || self.contentType == GJGCChatInviteToGroup || self.contentType == GJGCChatApplyToJoinGroup) {
            self.bubbleBackImageView.image = [self bubbleImageByRole:@"message_box_contact_sender"];
            self.bubbleBackImageView.highlightedImage = [self bubbleImageByRole:@"message_box_contact_sender"];
        } else if (self.contentType == GJGCChatFriendContentTypeMapLocation ||
                self.contentType == GJGCChatWalletLink) {
            self.bubbleBackImageView.image = [self bubbleImageByRole:@"message_link_right"];
            self.bubbleBackImageView.highlightedImage = [self bubbleImageByRole:@"message_link_right"];
        } else if (self.contentType == GJGCChatFriendContentTypeTransfer) {
            self.bubbleBackImageView.image = [self bubbleImageByRole:@"message_transfer_sender"];
            self.bubbleBackImageView.highlightedImage = [self bubbleImageByRole:@"message_transfer_sender"];
        } else if (self.contentType == GJGCChatFriendContentTypePayReceipt) {
            self.bubbleBackImageView.image = [self bubbleImageByRole:@"request_payment"];
            self.bubbleBackImageView.highlightedImage = [self bubbleImageByRole:@"request_payment"];
        } else if (self.contentType == GJGCChatFriendContentTypeAudio) {
            self.bubbleBackImageView.image = [self bubbleImageByRole:@"sender_message_box_green"];
            self.bubbleBackImageView.highlightedImage = [self bubbleImageByRole:@"sender_message_box_green"];
        } else {
            self.bubbleBackImageView.image = [self bubbleImageByRole:@"sender_message_blue"];
            self.bubbleBackImageView.highlightedImage = [self bubbleImageByRole:@"sender_message_blue"];
        }

        self.headView.right = GJCFSystemScreenWidth - self.contentBordMargin;
        self.bubbleBackImageView.height = self.bubbleBackImageView.image.size.height > self.bubbleBackImageView.height ? self.bubbleBackImageView.image.size.height : self.bubbleBackImageView.height;
        self.bubbleBackImageView.width = self.bubbleBackImageView.image.size.width > self.bubbleBackImageView.width ? self.bubbleBackImageView.image.size.width : self.bubbleBackImageView.width;
        self.bubbleBackImageView.right = self.headView.left - 3;

    } else {

        if (self.contentType == GJGCChatFriendContentTypeRedEnvelope) {
            self.bubbleBackImageView.image = [self bubbleImageByRole:@"message_redbag_other"];
            self.bubbleBackImageView.highlightedImage = [self bubbleImageByRole:@"message_redbag_other"];
        } else if (self.contentType == GJGCChatFriendContentTypeNameCard || self.contentType == GJGCChatInviteToGroup || self.contentType == GJGCChatApplyToJoinGroup) {
            self.bubbleBackImageView.image = [self bubbleImageByRole:@"message_box_contact_other"];
            self.bubbleBackImageView.highlightedImage = [self bubbleImageByRole:@"message_box_contact_other"];
        } else if (self.contentType == GJGCChatFriendContentTypeMapLocation ||
                self.contentType == GJGCChatWalletLink) {
            self.bubbleBackImageView.image = [self bubbleImageByRole:@"message_link_left"];
            self.bubbleBackImageView.highlightedImage = [self bubbleImageByRole:@"message_link_left"];
        } else if (self.contentType == GJGCChatFriendContentTypeTransfer) {
            self.bubbleBackImageView.image = [self bubbleImageByRole:@"message_transfer_other"];
            self.bubbleBackImageView.highlightedImage = [self bubbleImageByRole:@"message_transfer_other"];
        } else if (self.contentType == GJGCChatFriendContentTypePayReceipt) {
            self.bubbleBackImageView.image = [self bubbleImageByRole:@"send_bitcoin_messages"];
            self.bubbleBackImageView.highlightedImage = [self bubbleImageByRole:@"send_bitcoin_messages"];
        } else if (self.contentType == GJGCChatFriendContentTypeAudio) {
            self.bubbleBackImageView.image = [self bubbleImageByRole:@"reciver_message_white"];
            self.bubbleBackImageView.highlightedImage = [self bubbleImageByRole:@"reciver_message_white"];
        } else {
            self.bubbleBackImageView.image = [self bubbleImageByRole:@"reciver_message_white"];
            self.bubbleBackImageView.highlightedImage = [self bubbleImageByRole:@"reciver_message_white"];
        }
        self.headView.left = self.contentBordMargin;
        self.bubbleBackImageView.height = self.bubbleBackImageView.image.size.height > self.bubbleBackImageView.height ? self.bubbleBackImageView.image.size.height : self.bubbleBackImageView.height;
        self.bubbleBackImageView.width = self.bubbleBackImageView.image.size.width > self.bubbleBackImageView.width ? self.bubbleBackImageView.image.size.width : self.bubbleBackImageView.width;
        self.bubbleBackImageView.left = self.headView.right + 3;

    }

    if (self.isGroupChat && !self.isFromSelf) {

        self.nameLabel.top = 0.f;
        self.nameLabel.left = self.headView.right + self.contentBordMargin;
        self.headView.top = 0.f;
        self.bubbleBackImageView.top = self.nameLabel.bottom + 3;

    } else {

        self.headView.top = 0.f;
        self.bubbleBackImageView.top = self.headView.top;

    }

    self.statusButton.top = self.bubbleBackImageView.top;
    self.statusButton.userInteractionEnabled = NO;

    switch (self.sendStatus) {
        case GJGCChatFriendSendMessageStatusSuccess: {
            [self successSendingAnimation];
        }
            break;
        case GJGCChatFriendSendMessageStatusSending: {
            [self startSendingAnimation];
        }
            break;
        case GJGCChatFriendSendMessageStatusFaild:
        case GJGCChatFriendSendMessageStatusSuccessUnArrive:
        case GJGCChatFriendSendMessageStatusFailByNoRelationShip:
        case GJGCChatFriendSendMessageStatusFailByNotInGroup: {
            [self faildSendingAnimation];
        }
            break;
        default:
            break;
    }
    if (!self.isFromSelf) {
        self.statusButton.hidden = YES;
        self.indicatorView.hidden = YES;
    }
}

- (void)showOrHidenSnapchatProgerssView {
    if (self.isFromSelf) {
        if (self.contentModel.snapTime > 0 && self.contentModel.sendStatus == GJGCChatFriendSendMessageStatusSuccess) {
            self.snapChatTimeoutProgressView.hidden = NO;
            self.snapChatTimeoutProgressView.centerY = self.bubbleBackImageView.height / 2;
            self.snapChatTimeoutProgressView.right = self.bubbleBackImageView.left - 5;

        } else {
            self.snapChatTimeoutProgressView.hidden = YES;
        }
    } else {
        if (self.contentModel.snapTime > 0 && self.contentModel.sendStatus == GJGCChatFriendSendMessageStatusSuccess) {
            self.snapChatTimeoutProgressView.hidden = NO;
            self.snapChatTimeoutProgressView.centerY = self.bubbleBackImageView.height / 2;
            self.snapChatTimeoutProgressView.left = self.bubbleBackImageView.right + 5;
        } else {
            self.snapChatTimeoutProgressView.hidden = YES;
        }
    }

}

- (CGFloat)heightForContentModel:(GJGCChatContentBaseModel *)contentModel {
    return self.bubbleBackImageView.bottom + self.cellMargin;
}

- (NSArray *)myAudioPlayIndicatorImages {
    return @[
            GJCFQuickImage(@"chat_icon_video1_green.png"),
            GJCFQuickImage(@"chat_icon_video2_green.png"),
            GJCFQuickImage(@"chat_icon_video_green.png"),
    ];
}

- (NSArray *)otherAudioPlayIndicatorImages {
    return @[
            GJCFQuickImage(@"chat_icon_video1_grey.png"),
            GJCFQuickImage(@"chat_icon_video2_grey.png"),
            GJCFQuickImage(@"chat_icon_video_grey.png"),

    ];
}

- (BOOL)canBecomeFirstResponder {
    if (self.contentModel.snapTime > 0) {
        return NO;
    } else {
        return YES;
    }

}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(copyContent:) || action == @selector(deleteMessage:) || action == @selector(reSendMessage) || action == @selector(retweetMessage:)) {
        return YES;
    }
    return NO;
}

- (void)goToShowLongPressMenu:(UILongPressGestureRecognizer *)sender {


    [self becomeFirstResponder];
    [self.bubbleBackImageView setHighlighted:YES];

}

- (void)copyContent:(UIMenuItem *)item {

}

- (void)popMenuDidHidden:(NSNotification *)noti {
    if (self.bubbleBackImageView.isHighlighted) {

        [self.bubbleBackImageView setHighlighted:NO];

    }
}

- (void)retweetMessage:(UIMenuItem *)item {
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) self.contentModel;
    BOOL flag = YES;
    if (chatContentModel.contentType == GJGCChatFriendContentTypeVideo) {
        flag = chatContentModel.videoIsDownload;
    } else if (chatContentModel.contentType == GJGCChatFriendContentTypeImage) {
        flag = chatContentModel.isDownloadImage && chatContentModel.isDownloadThumbImage;
    } else if (chatContentModel.contentType == GJGCChatFriendContentTypeText) {
        flag = YES;
    }
    if (flag && self.delegate && [self.delegate respondsToSelector:@selector(chatCellDidChooseRetweetMessage:)]) {
        [self.delegate chatCellDidChooseRetweetMessage:self];
    }
    [self.bubbleBackImageView setHighlighted:NO];
}

- (void)deleteMessage:(UIMenuItem *)item {
    if (self.sendStatus == GJGCChatFriendSendMessageStatusSending) {
        [self.bubbleBackImageView setHighlighted:NO];
        return;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatCellDidChooseDeleteMessage:)]) {
        [self.delegate chatCellDidChooseDeleteMessage:self];
    }
    [self.bubbleBackImageView setHighlighted:NO];
}

- (void)reSendMessage {
    UIAlertView *al = [[UIAlertView alloc] initWithTitle:LMLocalizedString(@"Set tip title", nil) message:LMLocalizedString(@"Chat Resend this message", nil) delegate:self cancelButtonTitle:LMLocalizedString(@"Login Resend", nil) otherButtonTitles:LMLocalizedString(@"Common Cancel", nil), nil];
    [al show];
}

- (void)setSendStatus:(GJGCChatFriendSendMessageStatus)sendStatus {
    _sendStatus = sendStatus;

    switch (sendStatus) {
        case GJGCChatFriendSendMessageStatusSuccess: {
            [self successSendingAnimation];
        }
            break;
        case GJGCChatFriendSendMessageStatusSending: {
            [self startSendingAnimation];
        }
            break;
        case GJGCChatFriendSendMessageStatusSuccessUnArrive:
        case GJGCChatFriendSendMessageStatusFaild:
        case GJGCChatFriendSendMessageStatusFailByNoRelationShip:
        case GJGCChatFriendSendMessageStatusFailByNotInGroup: {
            [self faildSendingAnimation];
        }
            break;
        default:
            break;
    }
}

- (void)startSendingAnimation {
    self.statusButton.hidden = YES;
    if (self.isFromSelf) {
        self.statusButton.right = self.bubbleBackImageView.left - 10;
        self.statusButton.centerY = self.bubbleBackImageView.centerY;
        self.statusButton.userInteractionEnabled = NO;
        self.indicatorView.center = self.statusButton.center;
        self.snapChatTimeoutProgressView.hidden = YES;
        [self.indicatorView startAnimating];
    }
}

- (void)successSendingAnimation {
    self.statusButton.hidden = YES;
    [self.indicatorView stopAnimating];
    self.indicatorView.hidden = YES;
    self.snapChatTimeoutProgressView.hidden = YES;
    [self showOrHidenSnapchatProgerssView];
}

- (void)faildSendingAnimation {
    [self.indicatorView stopAnimating];
    self.indicatorView.hidden = YES;
    self.statusButton.right = self.bubbleBackImageView.left - 10;
    [self.statusButton setImage:GJCFQuickImage(@"attention_message") forState:UIControlStateNormal];
    self.statusButton.centerY = self.bubbleBackImageView.centerY;
    self.statusButton.userInteractionEnabled = YES;
    self.statusButton.hidden = NO;
    self.snapChatTimeoutProgressView.hidden = YES;
}

- (void)faildWithType:(NSInteger)faildType andReason:(NSString *)reason {
    self.faildType = faildType;
    self.faildReason = reason;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];

    if ([title isEqualToString:LMLocalizedString(@"Login Resend", nil)]) {

        if (self.delegate && [self.delegate respondsToSelector:@selector(chatCellDidChooseReSendMessage:)]) {

            [self startSendingAnimation];

            [self.delegate chatCellDidChooseReSendMessage:self];

        }
    }
}

- (void)tapOnHeadView:(UITapGestureRecognizer *)tapR {
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatCellDidTapOnHeadView:)]) {
        [self.delegate chatCellDidTapOnHeadView:self];
    }
}

- (void)longPressOnHeadView:(UILongPressGestureRecognizer *)longPressGesture {
    if (longPressGesture.state == UIGestureRecognizerStateBegan) {
        [GCDQueue executeInMainQueue:^{
            [longPressGesture cancel];
        }             afterDelaySecs:longPressGesture.minimumPressDuration];
    } else if (longPressGesture.state == UIGestureRecognizerStateEnded ||
            longPressGesture.state == UIGestureRecognizerStateCancelled) {
        /* 不可以@自己 */
        if (!self.isFromSelf) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(chatCellDidLongPressOnHeadView:)]) {
                [self.delegate chatCellDidLongPressOnHeadView:self];
            }
        }
    }
}

- (void)setUploadProgress:(float)progress {
}

- (void)downloadProgress:(float)progress {

}


+ (CGFloat)cellHeightForContentModel:(GJGCChatContentBaseModel *)contentModel {
    return 0;
}


- (void)updateMessageUploadStatus {
    switch (self.contentModel.sendStatus) {
        case GJGCChatFriendSendMessageStatusSending:
            self.statusButton.hidden = YES;
            self.indicatorView.hidden = NO;
            [self.indicatorView startAnimating];
            break;
        case GJGCChatFriendSendMessageStatusSuccess:
            self.statusButton.hidden = YES;
            self.indicatorView.hidden = YES;
            [self.indicatorView stopAnimating];
            break;
        case GJGCChatFriendSendMessageStatusFaild:
            self.statusButton.hidden = NO;
            self.indicatorView.hidden = YES;
            [self.indicatorView stopAnimating];
            break;
        default:
            break;
    }
}

@end

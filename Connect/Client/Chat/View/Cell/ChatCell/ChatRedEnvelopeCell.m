//
//  ChatRedEnvelopeCell.m
//  Connect
//
//  Created by MoHuilin on 16/7/27.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ChatRedEnvelopeCell.h"

#define InterMargen AUTO_WIDTH(20)

@interface ChatRedEnvelopeCell ()

@property(nonatomic, strong) UIImageView *redBagIconView;

@property(nonatomic, strong) GJCFCoreTextContentView *redEnvelTipView;

@property(nonatomic, strong) GJCFCoreTextContentView *subTipLabel;

@property(nonatomic, assign) CGFloat contentInnerMargin;


@end

@implementation ChatRedEnvelopeCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

        self.contentInnerMargin = 10.f;

        self.bubbleBackImageView.width = AUTO_WIDTH(425);
        self.bubbleBackImageView.height = AUTO_HEIGHT(151);

        self.contentSize = CGSizeMake(AUTO_WIDTH(425), AUTO_HEIGHT(151));

        self.redBagIconView = [[UIImageView alloc] init];
        self.redBagIconView.image = GJCFQuickImage(@"chat_bar_redbag");
        self.redBagIconView.width = AUTO_WIDTH(80);
        self.redBagIconView.height = AUTO_WIDTH(80);
        self.redBagIconView.top = AUTO_HEIGHT(15);
        [self.bubbleBackImageView addSubview:self.redBagIconView];


        self.redEnvelTipView = [[GJCFCoreTextContentView alloc] init];
        self.redEnvelTipView.width = AUTO_WIDTH(300);
        self.redEnvelTipView.height = AUTO_HEIGHT(72);
        self.redEnvelTipView.contentBaseWidth = self.redEnvelTipView.width;
        self.redEnvelTipView.contentBaseHeight = self.redEnvelTipView.height;
        self.redEnvelTipView.backgroundColor = [UIColor clearColor];
        [self.bubbleBackImageView addSubview:self.redEnvelTipView];

        self.redEnvelTipView.left = self.redBagIconView.right + self.contentInnerMargin;
        self.redEnvelTipView.top = self.redBagIconView.top;


        self.subTipLabel = [[GJCFCoreTextContentView alloc] init];
        self.subTipLabel.width = DEVICE_SIZE.width;
        self.subTipLabel.height = AUTO_HEIGHT(33);
        self.subTipLabel.contentBaseWidth = self.subTipLabel.width;
        self.subTipLabel.contentBaseHeight = self.subTipLabel.height;
        self.subTipLabel.backgroundColor = [UIColor clearColor];
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
    self.redEnvelTipView.contentAttributedString = chatContentModel.redBagTipMessage;
    self.redEnvelTipView.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:chatContentModel.redBagTipMessage forBaseContentSize:self.redEnvelTipView.contentBaseSize];

    self.subTipLabel.contentAttributedString = chatContentModel.redBagSubTipMessage;

    self.subTipLabel.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:chatContentModel.redBagSubTipMessage forBaseContentSize:self.subTipLabel.contentBaseSize];

    CGSize sizeLimit = self.subTipLabel.gjcf_size;
    if (sizeLimit.width > self.bubbleBackImageView.width - 20) {
        sizeLimit.width = self.bubbleBackImageView.width - 20;
    }
    self.subTipLabel.gjcf_size = sizeLimit;


    [self adjustContent];
    if (self.isFromSelf) {
        self.subTipLabel.left = BubbleLeftRightMargin;
        //set payIconView 和 transferTipView
        self.redBagIconView.left = InterMargen;
        self.redEnvelTipView.left = self.redBagIconView.right + InterMargen;
    } else {
        self.subTipLabel.left = BubbleLeftRightMargin + BubbleLeftRight;
        //set payIconView 和 transferTipView
        self.redBagIconView.left = InterMargen + BubbleLeftRightMargin;
        self.redEnvelTipView.left = self.redBagIconView.right + InterMargen;
    }
    self.subTipLabel.bottom = self.bubbleBackImageView.height - BubbleContentBottomMargin;
}

- (void)tapOnSelf {
    if (self.delegate && [self.delegate respondsToSelector:@selector(redBagCellDidTap:)]) {
        [self.delegate redBagCellDidTap:self];
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

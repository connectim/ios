//
//  ChatStatusTipCell.m
//  Connect
//
//  Created by MoHuilin on 16/8/9.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ChatStatusTipCell.h"
#import "GJGCChatFriendContentModel.h"

@interface ChatStatusTipCell ()

@property(nonatomic, strong) GJCFCoreTextContentView *statusTipLabelView;

@property(nonatomic, strong) UIImageView *tipIconImageView;

@property(nonatomic, strong) UIView *myContentView;

@end

@implementation ChatStatusTipCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.cellMargin = 7.f;

        UIView *myContentView = [[UIView alloc] init];
        self.myContentView = myContentView;
        [self.contentView addSubview:myContentView];
        self.myContentView.height = AUTO_HEIGHT(40);
        self.myContentView.width = AUTO_WIDTH(750);
        self.myContentView.backgroundColor = LMBasicBackGroudDarkGray;
        self.myContentView.layer.cornerRadius = 3;
        self.myContentView.layer.masksToBounds = YES;

        self.tipIconImageView = [[UIImageView alloc] init];
        [myContentView addSubview:self.tipIconImageView];
        self.tipIconImageView.size = AUTO_SIZE(24, 30);
        self.tipIconImageView.left = AUTO_WIDTH(17);
        self.tipIconImageView.centerY = self.myContentView.centerY;

        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.statusTipLabelView = [[GJCFCoreTextContentView alloc] init];
        self.statusTipLabelView.gjcf_width = AUTO_WIDTH(500);
        self.statusTipLabelView.gjcf_height = AUTO_HEIGHT(40);
        self.statusTipLabelView.contentBaseWidth = self.statusTipLabelView.gjcf_width;
        self.statusTipLabelView.contentBaseHeight = self.statusTipLabelView.gjcf_height;
        self.statusTipLabelView.backgroundColor = [UIColor clearColor];

        [myContentView addSubview:self.statusTipLabelView];

    }

    return self;
}

- (void)setContentModel:(GJGCChatContentBaseModel *)contentModel {
    if (!contentModel || !contentModel.statusMessageString) {
        return;
    }

    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) contentModel;
    if (chatContentModel.hashID) {
        NSString *tipString = [NSString stringWithFormat:@"%@%@", contentModel.statusMessageString.string, LMLocalizedString(@"Wallet Detail", nil)];
        NSMutableAttributedString *temArrtString = [[NSMutableAttributedString alloc] initWithString:tipString];
        [temArrtString addAttribute:NSFontAttributeName
                              value:[UIFont systemFontOfSize:FONT_SIZE(22)]
                              range:NSMakeRange(0, temArrtString.length)];
        [temArrtString addAttribute:NSForegroundColorAttributeName
                              value:LMAssociateTextColor
                              range:NSMakeRange(0, temArrtString.length)];
        GJCFCoreTextKeywordAttributedStringStyle *changePassTip = [[GJCFCoreTextKeywordAttributedStringStyle alloc] init];
        changePassTip.keyword = LMLocalizedString(@"Wallet Detail", nil);
        changePassTip.preGap = 3.0;
        changePassTip.endGap = 3.0;
        changePassTip.font = [UIFont systemFontOfSize:FONT_SIZE(22)];
        changePassTip.keywordColor = LMBasicTextButtonColor;
        [temArrtString setKeywordEffectByStyle:changePassTip];
        self.statusTipLabelView.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:temArrtString forBaseContentSize:self.statusTipLabelView.contentBaseSize];
        self.statusTipLabelView.contentAttributedString = temArrtString;
        __weak __typeof(&*self) weakSelf = self;
        [self.statusTipLabelView appenTouchObserverForKeyword:changePassTip.keyword withHanlder:^(NSString *keyword, NSRange keywordRange) {
            [weakSelf tapDetailAction];
        }];
    } else {
        self.statusTipLabelView.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:contentModel.statusMessageString forBaseContentSize:self.statusTipLabelView.contentBaseSize];
        self.statusTipLabelView.contentAttributedString = contentModel.statusMessageString;
    }

    UIImage *icomImage = GJCFQuickImage(contentModel.statusIcon);
    if (!icomImage) {
        self.tipIconImageView.frame = CGRectZero;
        self.statusTipLabelView.left = self.cellMargin;
        self.myContentView.width = self.statusTipLabelView.width + self.cellMargin * 2;
        if (self.statusTipLabelView.height > AUTO_HEIGHT(40)) {
            self.myContentView.height = self.statusTipLabelView.size.height + 6;
        } else {
            self.myContentView.height = AUTO_HEIGHT(40);
        }
        self.myContentView.centerX = DEVICE_SIZE.width / 2;
        self.statusTipLabelView.centerY = self.myContentView.centerY + AUTO_HEIGHT(2);
    } else {
        self.tipIconImageView.image = icomImage;
        self.tipIconImageView.size = AUTO_SIZE(24, 30);
        self.statusTipLabelView.left = self.tipIconImageView.right + self.cellMargin;
        self.myContentView.width = self.statusTipLabelView.right + self.cellMargin;
        if (self.statusTipLabelView.height > AUTO_HEIGHT(40)) {
            self.myContentView.height = self.statusTipLabelView.size.height + 6;
        } else {
            self.myContentView.height = AUTO_HEIGHT(40);

        }
        self.myContentView.centerX = DEVICE_SIZE.width / 2;
        self.tipIconImageView.centerY = self.myContentView.centerY;
        self.statusTipLabelView.centerY = self.myContentView.centerY + AUTO_HEIGHT(2);
    }
}

- (CGFloat)heightForContentModel:(GJGCChatContentBaseModel *)contentModel {
    return self.myContentView.gjcf_bottom + self.cellMargin;
}

- (void)tapDetailAction {
    if ([self.delegate respondsToSelector:@selector(chatCellDidTapDetail:)]) {
        [self.delegate chatCellDidTapDetail:self];
    }
}

+ (CGFloat)cellHeightForContentModel:(GJGCChatContentBaseModel *)contentModel {
    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) contentModel;
    CGSize contentSize = CGSizeZero;
    if (chatContentModel.hashID) {
        NSString *tipString = [NSString stringWithFormat:@"%@%@", contentModel.statusMessageString.string, LMLocalizedString(@"Wallet Detail", nil)];
        NSMutableAttributedString *temArrtString = [[NSMutableAttributedString alloc] initWithString:tipString];
        [temArrtString addAttribute:NSFontAttributeName
                              value:[UIFont systemFontOfSize:FONT_SIZE(27)]
                              range:NSMakeRange(0, temArrtString.length)];
        GJCFCoreTextKeywordAttributedStringStyle *changePassTip = [[GJCFCoreTextKeywordAttributedStringStyle alloc] init];
        changePassTip.keyword = LMLocalizedString(@"Wallet Detail", nil);
        changePassTip.preGap = 3.0;
        changePassTip.endGap = 3.0;
        changePassTip.font = [UIFont systemFontOfSize:FONT_SIZE(27)];
        changePassTip.keywordColor = [UIColor colorWithRed:0.000 green:0.502 blue:1.000 alpha:1.000];
        [temArrtString setKeywordEffectByStyle:changePassTip];
        contentSize = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:temArrtString forBaseContentSize:CGSizeMake(AUTO_WIDTH(500), AUTO_HEIGHT(40))];
    } else {
        contentSize = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:contentModel.statusMessageString forBaseContentSize:CGSizeMake(AUTO_WIDTH(500), AUTO_HEIGHT(40))];
    }
    CGSize nameSize = CGSizeZero;
    if (chatContentModel.isGroupChat && !chatContentModel.isFromSelf && !GJCFStringIsNull(chatContentModel.senderName)) {
        NSAttributedString *name = [[NSAttributedString alloc] initWithString:chatContentModel.senderName];
        nameSize = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:name forBaseContentSize:CGSizeMake(DEVICE_SIZE.width - AUTO_WIDTH(150), 25)];
        nameSize.height += 3;
    }

    return contentSize.height + BOTTOM_CELL_MARGIN + nameSize.height;
}

@end

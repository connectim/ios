//
//  NoRelationShipTipCell.m
//  Connect
//
//  Created by MoHuilin on 16/9/1.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "NoRelationShipTipCell.h"

@interface NoRelationShipTipCell ()

@property(nonatomic, strong) GJCFCoreTextContentView *noRelationShipTipCell; //提示文字

@end

@implementation NoRelationShipTipCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

        self.cellMargin = 7.f;
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        self.noRelationShipTipCell = [[GJCFCoreTextContentView alloc] init];
        self.noRelationShipTipCell.gjcf_centerX = GJCFSystemScreenWidth / 2;
        self.noRelationShipTipCell.gjcf_top = 7.f;
        self.noRelationShipTipCell.gjcf_width = GJCFSystemScreenWidth;
        self.noRelationShipTipCell.gjcf_height = AUTO_HEIGHT(42);
        self.noRelationShipTipCell.contentBaseWidth = self.noRelationShipTipCell.gjcf_width;
        self.noRelationShipTipCell.contentBaseHeight = self.noRelationShipTipCell.gjcf_height;
        self.noRelationShipTipCell.backgroundColor = [UIColor clearColor];

        GJCFCoreTextAttributedStringStyle *stringStyle = [[GJCFCoreTextAttributedStringStyle alloc] init];
        stringStyle.foregroundColor = [GJGCCommonFontColorStyle detailBigTitleColor];
        stringStyle.font = [UIFont systemFontOfSize:FONT_SIZE(22)];

        GJCFCoreTextParagraphStyle *paragrpahStyle = [[GJCFCoreTextParagraphStyle alloc] init];
        paragrpahStyle.lineBreakMode = kCTLineBreakByCharWrapping;
        paragrpahStyle.maxLineSpace = 5.f;
        paragrpahStyle.minLineSpace = 5.f;

        NSString *passTip = LMLocalizedString(@"Chat Add as a friend to chat", nil);
        NSMutableAttributedString *passTipAtt = [[NSMutableAttributedString alloc] initWithString:passTip attributes:[stringStyle attributedDictionary]];
        [passTipAtt addAttributes:[paragrpahStyle paragraphAttributedDictionary] range:NSMakeRange(0, passTipAtt.string.length)];

        GJCFCoreTextKeywordAttributedStringStyle *changePassTip = [[GJCFCoreTextKeywordAttributedStringStyle alloc] init];
        changePassTip.keyword = LMLocalizedString(@"Link Add as a friend", nil);
        changePassTip.preGap = 3.0;
        changePassTip.endGap = 3.0;
        changePassTip.font = [UIFont systemFontOfSize:FONT_SIZE(22)];
        changePassTip.keywordColor = LMBasicBlue;
        [passTipAtt setKeywordEffectByStyle:changePassTip];
        self.noRelationShipTipCell.contentAttributedString = passTipAtt;

        __weak __typeof(&*self) weakSelf = self;
        [self.noRelationShipTipCell appenTouchObserverForKeyword:changePassTip.keyword withHanlder:^(NSString *keyword, NSRange keywordRange) {
            if ([weakSelf.delegate respondsToSelector:@selector(noRelationShipTapAddFriend:)]) {
                [weakSelf.delegate noRelationShipTapAddFriend:weakSelf];
            }
        }];

        CGSize size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:passTipAtt forBaseContentSize:self.noRelationShipTipCell.contentBaseSize];
        self.noRelationShipTipCell.size = CGSizeMake(size.width, size.height + 5);

        self.noRelationShipTipCell.centerX = GJCFSystemScreenWidth / 2;

        UIView *backGroudView = [[UIView alloc] init];
        backGroudView.frame = self.noRelationShipTipCell.frame;
        backGroudView.backgroundColor = GJCFQuickHexColor(@"E2E4E6");
        backGroudView.width += 20;
        backGroudView.centerX = GJCFSystemScreenWidth / 2;
        backGroudView.top = 5;
        backGroudView.layer.cornerRadius = 3;
        backGroudView.layer.masksToBounds = YES;


        [self.contentView addSubview:backGroudView];
        [self.contentView addSubview:self.noRelationShipTipCell];

    }

    return self;
}

- (void)setContentModel:(GJGCChatContentBaseModel *)contentModel {

}

- (CGFloat)heightForContentModel:(GJGCChatContentBaseModel *)contentModel {
    return self.noRelationShipTipCell.gjcf_bottom + self.cellMargin;
}

+ (CGFloat)cellHeightForContentModel:(GJGCChatContentBaseModel *)contentModel {

    GJCFCoreTextAttributedStringStyle *stringStyle = [[GJCFCoreTextAttributedStringStyle alloc] init];
    stringStyle.foregroundColor = [GJGCCommonFontColorStyle detailBigTitleColor];
    stringStyle.font = [UIFont systemFontOfSize:FONT_SIZE(22)];

    GJCFCoreTextParagraphStyle *paragrpahStyle = [[GJCFCoreTextParagraphStyle alloc] init];
    paragrpahStyle.lineBreakMode = kCTLineBreakByCharWrapping;
    paragrpahStyle.maxLineSpace = 5.f;
    paragrpahStyle.minLineSpace = 5.f;

    NSString *passTip = LMLocalizedString(@"Chat Add as a friend to chat", nil);
    NSMutableAttributedString *passTipAtt = [[NSMutableAttributedString alloc] initWithString:passTip attributes:[stringStyle attributedDictionary]];
    [passTipAtt addAttributes:[paragrpahStyle paragraphAttributedDictionary] range:NSMakeRange(0, passTipAtt.string.length)];

    GJCFCoreTextKeywordAttributedStringStyle *changePassTip = [[GJCFCoreTextKeywordAttributedStringStyle alloc] init];
    changePassTip.keyword = LMLocalizedString(@"Link Add as a friend", nil);
    changePassTip.preGap = 3.0;
    changePassTip.endGap = 3.0;
    changePassTip.font = [UIFont systemFontOfSize:FONT_SIZE(22)];
    changePassTip.keywordColor = LMBasicBlue;
    [passTipAtt setKeywordEffectByStyle:changePassTip];

    CGSize size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:passTipAtt forBaseContentSize:CGSizeMake(GJCFSystemScreenWidth, AUTO_HEIGHT(42))];
    return size.height + 5 + BOTTOM_CELL_MARGIN;
}

@end

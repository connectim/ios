//
//  NewSecureChatTipCell.m
//  Connect
//
//  Created by MoHuilin on 16/9/4.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "NewSecureChatTipCell.h"

@interface NewSecureChatTipCell ()

@property(nonatomic, strong) GJCFCoreTextContentView *tipLabel;

@property(nonatomic, strong) UIImageView *tipIconImageView;

@property(nonatomic, strong) UIView *myContentView;

@end

@implementation NewSecureChatTipCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

        self.cellMargin = 7.f;

        self.myContentView = [[UIView alloc] init];
        self.myContentView.backgroundColor = GJCFQuickHexColor(@"E2E4E6");
        self.myContentView.layer.cornerRadius = 5;
        self.myContentView.layer.masksToBounds = YES;
        self.myContentView.top = 5;
        self.myContentView.width = AUTO_WIDTH(550);

        [self.contentView addSubview:self.myContentView];

        self.tipIconImageView = [[UIImageView alloc] init];
        self.tipIconImageView.image = [UIImage imageNamed:@"chat_type_lock"];
        self.tipIconImageView.size = AUTO_SIZE(25, 31);
        self.tipIconImageView.top = 5 + 5;
        [self.contentView addSubview:self.tipIconImageView];


        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.tipLabel = [[GJCFCoreTextContentView alloc] init];
        self.tipLabel.gjcf_top = self.tipIconImageView.bottom + 5;
        self.tipLabel.gjcf_width = GJCFSystemScreenWidth * 0.75; //限制
        self.tipLabel.gjcf_height = AUTO_HEIGHT(200);
        self.tipLabel.contentBaseWidth = self.tipLabel.gjcf_width;
        self.tipLabel.contentBaseHeight = self.tipLabel.gjcf_height;

        [self.contentView addSubview:self.tipLabel];

        NSMutableAttributedString *tipString = [[NSMutableAttributedString alloc] initWithString:LMLocalizedString(@"Chat You are start encrypt chat Messages encrypted", nil)];

        //设置字体和设置字体的范围
        [tipString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:FONT_SIZE(28)] range:NSMakeRange(0, LMLocalizedString(@"Set Start encrypted messaging", nil).length)];
        [tipString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:FONT_SIZE(22)] range:NSMakeRange(LMLocalizedString(@"Set Start encrypted messaging", nil).length, tipString.string.length - (LMLocalizedString(@"Set Start encrypted messaging", nil).length))];

        NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
        paragraph.alignment = NSTextAlignmentCenter;//设置对齐方式
        [tipString addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, tipString.string.length)];

        self.tipLabel.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:tipString forBaseContentSize:self.tipLabel.contentBaseSize];
        self.tipLabel.contentAttributedString = tipString;
        CGFloat width = self.myContentView.width;
        if (self.tipLabel.width > self.myContentView.width) {
            width = self.tipLabel.width;
        }
        self.myContentView.size = CGSizeMake(width, self.tipLabel.height + self.tipIconImageView.height + 3 * self.cellMargin);
        self.myContentView.centerX = GJCFSystemScreenWidth / 2;
        self.tipLabel.gjcf_centerX = GJCFSystemScreenWidth / 2;
        self.tipIconImageView.centerX = GJCFSystemScreenWidth / 2;


    }

    return self;
}

- (void)setContentModel:(GJGCChatContentBaseModel *)contentModel {

}

- (CGFloat)heightForContentModel:(GJGCChatContentBaseModel *)contentModel {
    return self.myContentView.gjcf_bottom + self.cellMargin;
}


+ (CGFloat)cellHeightForContentModel:(GJGCChatContentBaseModel *)contentModel {
    NSMutableAttributedString *tipString = [[NSMutableAttributedString alloc] initWithString:LMLocalizedString(@"Chat You are start encrypt chat Messages encrypted", nil)];

    [tipString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:FONT_SIZE(28)] range:NSMakeRange(0, LMLocalizedString(@"Set Start encrypted messaging", nil).length)];
    [tipString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:FONT_SIZE(22)] range:NSMakeRange(LMLocalizedString(@"Set Start encrypted messaging", nil).length, tipString.string.length - (LMLocalizedString(@"Set Start encrypted messaging", nil).length))];

    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = NSTextAlignmentCenter;//设置对齐方式
    [tipString addAttribute:NSParagraphStyleAttributeName value:paragraph range:NSMakeRange(0, tipString.string.length)];

    CGSize contentSize = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:tipString forBaseContentSize:CGSizeMake(GJCFSystemScreenWidth * 0.75, AUTO_HEIGHT(200))];

    return contentSize.height + 7 * 3 + AUTO_HEIGHT(25) + BOTTOM_CELL_MARGIN * 1.5;
}


@end

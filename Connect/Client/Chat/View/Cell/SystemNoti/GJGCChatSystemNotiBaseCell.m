//
//  GJGCChatBaseCell.m
//  ZYChat
//
//  Created by KivenLin on 14-10-17.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import "GJGCChatSystemNotiBaseCell.h"
#import "GJGCChatSystemNotiModel.h"
#import "UIImage+Color.h"

@interface GJGCChatSystemNotiBaseCell ()

@property(nonatomic, assign) BOOL canShowHighlightState;

@end

@implementation GJGCChatSystemNotiBaseCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {

        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        self.timeContentMargin = 13.f;
        self.contentBordMargin = 13.f;
        self.contentInnerMargin = 13.f;
        self.cellMargin = 13.f;


        self.stateContentView = [[UIImageView alloc] init];
        self.stateContentView.gjcf_left = self.contentBordMargin;
        self.stateContentView.gjcf_width = GJCFSystemScreenWidth - 2 * self.contentBordMargin;
        self.stateContentView.gjcf_top = self.timeLabel.gjcf_bottom + self.timeContentMargin;
        self.stateContentView.gjcf_height = 144;
        self.stateContentView.userInteractionEnabled = YES;
        self.stateContentView.layer.cornerRadius = 6;
        self.stateContentView.layer.masksToBounds = YES;
        self.stateContentView.layer.borderWidth = 0.3;
        self.stateContentView.layer.borderColor = [UIColor grayColor].CGColor;


        UIImage *normal = [UIImage imageWithColor:[UIColor whiteColor]];
        UIImage *highlight = [UIImage imageWithColor:[UIColor grayColor]];
        self.stateContentView.image = GJCFImageResize(normal, 12, 12, 12, 12);
        self.stateContentView.highlightedImage = GJCFImageResize(highlight, 12, 12, 12, 12);
        [self.contentView addSubview:self.stateContentView];



        self.titleLabel = [[GJCFCoreTextContentView alloc] init];
        self.titleLabel.gjcf_top = self.contentBordMargin;
        self.titleLabel.gjcf_left = self.contentBordMargin;
        self.titleLabel.contentBaseWidth = self.stateContentView.gjcf_width - 2 * self.contentBordMargin;
        self.titleLabel.contentBaseHeight = 30;
        self.titleLabel.backgroundColor = [UIColor clearColor];
        [self.stateContentView addSubview:self.titleLabel];


        self.timeLabel = [[GJCFCoreTextContentView alloc] init];
        self.timeLabel.gjcf_top = self.titleLabel.bottom + self.contentBordMargin;
        self.timeLabel.gjcf_left = self.contentBordMargin;
        self.timeLabel.contentBaseWidth = self.stateContentView.gjcf_width - 2 * self.contentBordMargin;
        self.timeLabel.contentBaseHeight = 30;
        self.timeLabel.backgroundColor = [UIColor clearColor];
        [self.stateContentView addSubview:self.timeLabel];

        self.activeImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"image_message_placeholder"]];
        self.activeImageView.gjcf_left = self.contentBordMargin;
        self.activeImageView.gjcf_top = self.timeLabel.gjcf_bottom + self.contentInnerMargin;
        self.activeImageView.gjcf_width = self.stateContentView.gjcf_width - 2 * self.contentBordMargin;
        self.activeImageView.gjcf_height = self.activeImageView.gjcf_width * 0.6; //10:6
        [self.stateContentView addSubview:self.activeImageView];

        self.contentLabel = [[GJCFCoreTextContentView alloc] init];
        self.contentLabel.backgroundColor = [UIColor clearColor];
        self.contentLabel.gjcf_top = self.contentInnerMargin;
        self.contentLabel.gjcf_left = self.contentInnerMargin;
        self.contentLabel.gjcf_width = self.stateContentView.gjcf_width - 2 * self.contentInnerMargin;
        self.contentLabel.contentBaseWidth = self.contentLabel.gjcf_width;
        self.contentLabel.contentBaseHeight = kMaxContentHeight;
        self.contentLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [self.stateContentView addSubview:self.contentLabel];

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapCell)];
        self.stateContentView.userInteractionEnabled = YES;
        [self.stateContentView addGestureRecognizer:tap];
    }
    return self;
}

- (void)tapCell {

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];


}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];

    if (self.canShowHighlightState) {
        [self.stateContentView setHighlighted:highlighted];
    }
}

- (void)showOrHiddenIndicatorViewByContentType:(GJGCChatSystemNotiType)notiType {
    switch (notiType) {
        case GJGCChatSystemNotiTypeSystemActiveGuide:{
            self.accessoryIndicator.hidden = NO;
        }
            break;
        default:
            break;
    }
}

- (void)setShowAccesoryIndicator:(BOOL)showAccesoryIndicator {
    if (_showAccesoryIndicator == showAccesoryIndicator) {
        return;
    }
    _showAccesoryIndicator = showAccesoryIndicator;
    self.accessoryIndicator.hidden = !_showAccesoryIndicator;
}

- (void)setContentModel:(GJGCChatContentBaseModel *)contentModel {
    if (!contentModel) {
        return;
    }

    GJGCChatSystemNotiModel *notiModel = (GJGCChatSystemNotiModel *) contentModel;
    self.canShowHighlightState = notiModel.canShowHighlightState;

    self.timeLabel.contentAttributedString = notiModel.timeString;
    self.timeLabel.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:notiModel.timeString forBaseContentSize:self.timeLabel.contentBaseSize];
    self.timeLabel.gjcf_centerX = GJCFSystemScreenWidth / 2;

    [self showOrHiddenIndicatorViewByContentType:notiModel.notiType];

    self.contentLabel.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:notiModel.systemOperationTip forBaseContentSize:self.contentLabel.contentBaseSize];
    self.contentLabel.contentAttributedString = notiModel.systemOperationTip;

    self.stateContentView.gjcf_height = self.contentLabel.gjcf_bottom + self.contentInnerMargin;
}

- (CGFloat)cellHeight {
    return self.stateContentView.gjcf_bottom + self.cellMargin;
}

- (CGFloat)heightForContentModel:(GJGCChatContentBaseModel *)contentModel {
    return [self cellHeight];
}

@end

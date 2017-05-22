//
//  RecentChatCell.m
//  Connect
//
//  Created by MoHuilin on 16/6/2.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "RecentChatCell.h"
#import "RecentChatModel.h"
#import "RecentChatStyle.h"

#import "GJGCChatContentEmojiParser.h"

#import "UIView+WZLBadge.h"
#import "NSString+Size.h"


@interface RecentChatCell ()

@property(weak, nonatomic) IBOutlet UIImageView *disAbleNotiImgeview;
@property(weak, nonatomic) IBOutlet UIImageView *avatarView;
@property(weak, nonatomic) IBOutlet UILabel *nameLabel;
@property(weak, nonatomic) IBOutlet UILabel *timeLabel;
@property(weak, nonatomic) IBOutlet UIImageView *privacyImageView;
@property(weak, nonatomic) IBOutlet UIView *avatarContentView;
@property(weak, nonatomic) IBOutlet UILabel *contentLabel;
@property(weak, nonatomic) IBOutlet UILabel *strangerLabel;
@property(nonatomic, strong) UILabel *badgeLabel;
@property(weak, nonatomic) IBOutlet UIImageView *topChatStickImageView;

@end

@implementation RecentChatCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }

    return self;
}

- (void)setup {


    self.layoutMargins = UIEdgeInsetsZero;
    self.separatorInset = UIEdgeInsetsZero;

    self.avatarContentView.backgroundColor = [UIColor clearColor];
    self.avatarView.layer.cornerRadius = 5;
    self.avatarView.layer.masksToBounds = YES;
    self.nameLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE(32)];
    self.timeLabel.textColor = GJCFQuickHexColor(@"D0D2D6");
    self.contentLabel.textColor = LMBasicDarkGray;
    self.strangerLabel.layer.cornerRadius = 3;
    self.strangerLabel.layer.masksToBounds = YES;
    self.strangerLabel.text = LMLocalizedString(@"Link Stranger", nil);
    self.strangerLabel.textAlignment = NSTextAlignmentCenter;
    [self.strangerLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        CGSize size = [self.strangerLabel.text sizeWithFont:self.strangerLabel.font constrainedToHeight:AUTO_HEIGHT(40)];
        make.width.mas_equalTo(size.width + AUTO_WIDTH(20));
    }];
}

- (void)setData:(id)data {
    [super setData:data];
    RecentChatModel *model = (RecentChatModel *) data;
    self.nameLabel.text = model.name;

    switch (model.talkType) {
        case GJGCChatFriendTalkTypePostSystem: {
            self.strangerLabel.hidden = YES;
            self.avatarView.image = [UIImage imageNamed:@"connect_logo"];
            self.nameLabel.textColor = GJCFQuickHexColor(@"00C400");
        }
            break;

        case GJGCChatFriendTalkTypeGroup: {
            self.nameLabel.textColor = GJCFQuickHexColor(@"161A21");
            self.avatarView.image = [UIImage imageNamed:@"default_user_avatar"];
            // TODO group avatar server change ,cannot use ip address
            [self.avatarView setPlaceholderImageWithAvatarUrl:[NSString stringWithFormat:@"%@/avatar/%@/group/%@.jpg",baseServer,APIVersion,model.identifier]];
            self.strangerLabel.hidden = YES;
        }
            break;

        case GJGCChatFriendTalkTypePrivate: {
            self.nameLabel.textColor = GJCFQuickHexColor(@"161A21");
            self.strangerLabel.hidden = !model.stranger;
            [self.avatarView setImageWithAvatarUrl:model.headUrl];
        }
            break;
        default:
            break;
    }

    NSDictionary *parseDict = GJCFNSCacheGetValue(model.content);
    if (!parseDict) {
        parseDict = [[GJGCChatContentEmojiParser sharedParser] parseContent:model.content];
    }

    //time
    int long long sendTime = [model.time integerValue];
    NSAttributedString *timeA = [RecentChatStyle formateTime:sendTime / 1000];
    self.timeLabel.text = timeA.string;
    //last content
    self.contentLabel.attributedText = model.contentAttrStr;
    [self reloadCellLastStatusWithModel:model];
}

- (void)setUncountRead:(int)unreadCount {
    [self.avatarContentView clearBadge];
    self.avatarContentView.badge = nil;
    self.avatarContentView.badgeFont = [UIFont systemFontOfSize:FONT_SIZE(20)];
    self.avatarContentView.badgeCenterOffset = CGPointMake(0, 0);
    if (unreadCount >= 99) {
        [self.avatarContentView showBadge];
    } else if (unreadCount > 0 && unreadCount < 99) {
        [self.avatarContentView showBadgeWithStyle:WBadgeStyleNumber value:unreadCount animationType:WBadgeAnimTypeNone];
    } else {
        [self.avatarContentView clearBadge];
        self.avatarContentView.badge = nil;
    }
}

- (void)reloadCellLastStatusWithModel:(id)model {
    [self setNeedsLayout];
    [self layoutIfNeeded];

    RecentChatModel *recentModel = (RecentChatModel *) model;
    if (recentModel.notifyStatus && recentModel.unReadCount > 0) {
        [self setUncountRead:101];
    } else {
        [self setUncountRead:recentModel.unReadCount];
    }
    [self setStatusImageViewWithModel:recentModel];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    UIColor *color = self.avatarContentView.badge.backgroundColor;
    [super setSelected:selected animated:animated];

    if (selected) {
        self.avatarContentView.badge.backgroundColor = color;
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    UIColor *color = self.avatarContentView.badge.backgroundColor;
    [super setHighlighted:highlighted animated:animated];

    if (highlighted) {
        self.avatarContentView.badge.backgroundColor = color;
    }
}

- (void)setStatusImageViewWithModel:(RecentChatModel *)model {
    if (model.snapChatDeleteTime > 0) {
        [self.privacyImageView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(self.privacyImageView.image.size);
        }];
    } else {
        [self.privacyImageView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeZero);
        }];
    }

    if (model.isTopChat) {
        [self.topChatStickImageView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(self.topChatStickImageView.image.size);
        }];
    } else {
        [self.topChatStickImageView mas_updateConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeZero);
        }];
    }
    if (model.notifyStatus) {
        [self.disAbleNotiImgeview mas_updateConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(self.disAbleNotiImgeview.image.size);
        }];
    } else {
        [self.disAbleNotiImgeview mas_updateConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeZero);
        }];
    }

}

@end

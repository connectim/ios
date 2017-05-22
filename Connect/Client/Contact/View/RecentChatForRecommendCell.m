//
//  RecentChatForRecommendCell.m
//  Connect
//
//  Created by MoHuilin on 16/10/11.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "RecentChatForRecommendCell.h"
#import "RecentChatModel.h"

@interface RecentChatForRecommendCell ()
@property(weak, nonatomic) IBOutlet UIImageView *displayImageView;
@property(weak, nonatomic) IBOutlet UILabel *displayLable;


@end

@implementation RecentChatForRecommendCell


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.displayLable.font = [UIFont systemFontOfSize:FONT_SIZE(30)];
        self.displayImageView.layer.cornerRadius = 6;
        self.displayImageView.layer.masksToBounds = YES;
    }

    return self;
}

- (void)setData:(id)data {
    [super setData:data];
    RecentChatModel *model = (RecentChatModel *) data;
    if (model.isTopChat) {
        self.backgroundColor = [UIColor colorWithHexString:@"f1f1f1"];
    } else {
        self.backgroundColor = [UIColor clearColor];
    }
    __weak __typeof(&*self) weakSelf = self;
    self.displayLable.textColor = [UIColor blackColor];
    self.displayImageView.image = [UIImage imageNamed:@"default_user_avatar"];
    
    switch (model.talkType) {
        case GJGCChatFriendTalkTypeGroup:
        {
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] init];
            // name
            NSString *name = model.name;
            NSAttributedString *attr0 = [[NSAttributedString alloc] initWithString:name];
            [attributedString appendAttributedString:attr0];
            
            NSString *total = [NSString stringWithFormat:LMLocalizedString(@"Chat members", nil), (int) model.chatGroupInfo.groupMembers.count];
            // set font color
            NSDictionary *totalColor = @{NSForegroundColorAttributeName: [UIColor lightGrayColor]};
            NSAttributedString *attr1 = [[NSAttributedString alloc] initWithString:total attributes:totalColor];
            [attributedString appendAttributedString:attr1];
            // set font range
            self.displayLable.attributedText = attributedString;            
            [self.displayImageView setPlaceholderImageWithAvatarUrl:[NSString stringWithFormat:@"%@/avatar/%@/group/%@.jpg",baseServer,APIVersion,model.identifier]];
        }
            break;
        default:
        {
            self.displayLable.text = model.name;
            NSString *avatar = model.headUrl;
            [self.displayImageView setPlaceholderImageWithAvatarUrl:avatar];
        }
            break;
    }
}
@end

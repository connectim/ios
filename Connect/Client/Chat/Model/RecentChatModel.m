//
//  RecentChatModel.m
//  Connect
//
//  Created by MoHuilin on 16/6/25.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "RecentChatModel.h"
#import "UserDBManager.h"
#import "GroupDBManager.h"

@implementation RecentChatModel

@synthesize draft = _draft;
@synthesize content = _content;

- (BOOL)isEqual:(id)object {
    if (object == self) {
        return YES;
    }
    if (![object isKindOfClass:[RecentChatModel class]]) {
        return NO;
    }
    RecentChatModel *entity = (RecentChatModel *) object;
    if ([entity.identifier isEqualToString:self.identifier]) {
        return YES;
    } else {
        return NO;
    }
}

- (NSString *)name{
    if (!_name) {
        _name = @"";
    }
    return _name;
}

- (NSString *)draft{
    if (!_draft) {
        _draft = @"";
    }
    return _draft;
}

- (NSString *)time{
    if (!_time) {
        _time = @"";
    }
    return _time;
}

- (NSString *)content{
    if (!_content) {
        _content = @"";
    }
    return _content;
}

- (AccountInfo *)chatUser{
    if (!_chatUser && self.talkType != GJGCChatFriendTalkTypeGroup) {
        if (self.stranger) {
            _chatUser = [AccountInfo new];
            _chatUser.pub_key = self.identifier;
            _chatUser.address = [KeyHandle getAddressByPubkey:self.identifier];
            _chatUser.username = self.name;
            _chatUser.avatar = self.headUrl;
            _chatUser.stranger = YES;
        } else{
            _chatUser = [[UserDBManager sharedManager] getUserByPublickey:self.identifier];
        }
    }
    return _chatUser;
}

- (LMGroupInfo *)chatGroupInfo{
    if (!_chatGroupInfo && self.talkType == GJGCChatFriendTalkTypeGroup) {
        _chatGroupInfo = [[GroupDBManager sharedManager] getgroupByGroupIdentifier:self.identifier];
    }
    return _chatGroupInfo;
}


- (NSString *)headUrl{
    if (!_headUrl) {
        if (self.talkType == GJGCChatFriendTalkTypeGroup) {
            _headUrl = [NSString stringWithFormat:@"%@/avatar/%@/group/%@.jpg",baseServer,APIVersion,self.identifier];
        } else{
            _headUrl = DefaultHeadUrl;
        }
    }
    return _headUrl;
}

- (NSComparisonResult)comparedata:(RecentChatModel *)r2 {

    RecentChatModel *r1 = self;
    int long long time1 = [r1.time longLongValue];
    int long long time2 = [r2.time longLongValue];

    if (r1.isTopChat && r2.isTopChat) {
        if (time1 > time2) {
            return NSOrderedAscending;
        } else if (time1 == time2) {
            return NSOrderedSame;
        } else {
            return NSOrderedDescending;
        }
    } else if (r1.isTopChat && !r2.isTopChat) {
        return NSOrderedAscending;
    } else if (!r1.isTopChat && r2.isTopChat) {
        return NSOrderedDescending;
    } else {
        if (time1 > time2) {
            return NSOrderedAscending;
        } else if (time1 == time2) {
            return NSOrderedSame;
        } else {
            return NSOrderedDescending;
        }
    }
}

- (void)setContent:(NSString *)content{
    _content = content;
    _contentAttrStr = nil;
}

- (void)setDraft:(NSString *)draft{
    _draft = draft;
    _contentAttrStr = nil;
}

- (void)setGroupNoteMyself:(BOOL)groupNoteMyself{
    _groupNoteMyself = groupNoteMyself;
    _contentAttrStr = nil;
}

- (void)setSnapChatDeleteTime:(int)snapChatDeleteTime{
    _snapChatDeleteTime = snapChatDeleteTime;
    _contentAttrStr = nil;
}

- (NSMutableAttributedString *)contentAttrStr{
    if (!_contentAttrStr) {
        _contentAttrStr = [[NSMutableAttributedString alloc] init];

        if (GJCFStringIsNull(self.draft)) {
            if (self.groupNoteMyself) {
                NSString *str = [NSString stringWithFormat:@"%@%@",LMLocalizedString(@"Chat Someone note me", nil),self.content];

                NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:str];

                [attrStr addAttribute:NSFontAttributeName
                                value:[UIFont systemFontOfSize:FONT_SIZE(27)]
                                range:NSMakeRange(0, str.length)];
                NSInteger len = LMLocalizedString(@"Chat Someone note me", nil).length;

                [attrStr addAttribute:NSForegroundColorAttributeName
                                value:GJCFQuickHexColor(@"F14C60")
                                range:NSMakeRange(0, len)];
                [attrStr addAttribute:NSForegroundColorAttributeName
                                value:LMBasicDarkGray
                                range:NSMakeRange(len, str.length - len)];
                _contentAttrStr = attrStr;
            } else{
                NSString *str = self.snapChatDeleteTime > 0?LMLocalizedString(@"Chat You received snapchat message", nil):self.content;
                NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:str];
                NSInteger len = str.length;

                [attrStr addAttribute:NSForegroundColorAttributeName
                                value:LMBasicDarkGray
                                range:NSMakeRange(0, len)];
                _contentAttrStr = attrStr;
            }
        } else{
            if (self.groupNoteMyself) {
                NSString *str = [NSString stringWithFormat:@"%@%@",LMLocalizedString(@"Chat Someone note me", nil),self.content];

                NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:str];

                [attrStr addAttribute:NSFontAttributeName
                                value:[UIFont systemFontOfSize:FONT_SIZE(27)]
                                range:NSMakeRange(0, str.length)];
                NSInteger len = LMLocalizedString(@"Chat Someone note me", nil).length;

                [attrStr addAttribute:NSForegroundColorAttributeName
                                value:GJCFQuickHexColor(@"F14C60")
                                range:NSMakeRange(0, len)];
                [attrStr addAttribute:NSForegroundColorAttributeName
                                value:LMBasicDarkGray
                                range:NSMakeRange(len, str.length - len)];
                _contentAttrStr = attrStr;
            } else{
                NSString *str = [NSString stringWithFormat:@"%@%@",LMLocalizedString(@"Chat Draft", nil),self.draft];

                NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:str];

                [attrStr addAttribute:NSFontAttributeName
                                value:[UIFont systemFontOfSize:FONT_SIZE(27)]
                                range:NSMakeRange(0, str.length)];
                NSInteger len = LMLocalizedString(@"Chat Draft", nil).length;

                [attrStr addAttribute:NSForegroundColorAttributeName
                                value:GJCFQuickHexColor(@"F14C60")
                                range:NSMakeRange(0, len)];
                [attrStr addAttribute:NSForegroundColorAttributeName
                                value:LMBasicDarkGray
                                range:NSMakeRange(len, str.length - len)];
                _contentAttrStr = attrStr;
            }
        }
    }
    return _contentAttrStr;
}

@end

//
//  GroupMembersListViewController.h
//  Connect
//
//  Created by MoHuilin on 16/7/19.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseViewController.h"
#import "GJGCChatFriendTalkModel.h"

typedef NS_ENUM(NSUInteger, FromSourceType) {
    FromSourceTypeCommon = 1 << 0,
    FromSourceTypeGroupManager = 1 << 1

};

@interface GroupMembersListViewController : BaseViewController

@property(weak, nonatomic) GJGCChatFriendTalkModel *talkInfo;
@property(assign, nonatomic) BOOL isGroupMaster;

- (instancetype)initWithMembers:(NSArray *)members currentIsGroupAdmin:(BOOL)isGroupAdmin;


- (instancetype)initWithMemberInfos:(NSArray *)members groupIdentifer:(NSString *)groupid groupEchhKey:(NSString *)groupEcdhKey;

@property(assign, nonatomic) NSUInteger fromSource;

@property(nonatomic, copy) void (^SuccessAttornAdminCallback)(NSString *address);


@end

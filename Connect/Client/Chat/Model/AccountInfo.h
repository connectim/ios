//
//  AccountInfo.h
//  Connect
//
//  Created by MoHuilin on 16/5/19.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseInfo.h"

typedef NS_ENUM(NSInteger,UserSourceType) {
    UserSourceTypeDefault = 0,
    UserSourceTypeContact,
    UserSourceTypeQrcode,
    UserSourceTypeTransaction,
    UserSourceTypeGroup,
    UserSourceTypeSearch,
    UserSourceTypeRecommend,
};

typedef NS_ENUM(NSInteger,RequestFriendStatus) {
    RequestFriendStatusVerfing = 0,
    RequestFriendStatusAccept,
    RequestFriendStatusAdded,
    RequestFriendStatusAdd
};

typedef void(^AccountOperation)();
typedef void(^AccountOperationWithUserInfo)(id userInfo);

@interface AccountInfo : BaseInfo

@property (nonatomic ,copy) NSString *address;
@property (nonatomic ,copy) NSString *avatar;
@property (nonatomic ,copy) NSString *avatar400; //big avatar
@property (nonatomic ,copy) NSString *encryption_pri;
@property (nonatomic ,copy) NSString *password_hint;
@property (nonatomic ,copy) NSString *pub_key;
@property (nonatomic ,copy) NSString *username;
@property (nonatomic ,copy) NSString *remarks;
@property (nonatomic ,copy) NSString *bondingPhone; //User bound phone number, if binding, the need to survive in Keychain
@property (nonatomic ,assign) BOOL bonding;

@property (nonatomic ,copy) NSString *groupNickName;
@property (nonatomic ,copy) NSString *prikey;
@property (copy, nonatomic) NSString* contentId;

@property (nonatomic ,copy) NSString *groupShowName;
@property (nonatomic ,copy) NSString *normalShowName;

@property (nonatomic ,copy) NSString *phoneContactName; //The name of the registered phone number in the local address book
@property (nonatomic ,assign) NSTimeInterval lastLoginTime;

@property (nonatomic ,strong) NSArray *tags;
@property (nonatomic ,assign) BOOL requestRead;

@property (nonatomic ,copy) NSString *message;
@property (nonatomic ,strong) NSNumber *times;
@property (nonatomic ,assign) int32_t source;
@property (nonatomic ,assign) RequestFriendStatus status;
@property (nonatomic ,copy) AccountOperation customOperation;
@property (nonatomic ,copy) AccountOperationWithUserInfo customOperationWithInfo;
@property (nonatomic ,assign) BOOL isSelected;
@property (nonatomic ,assign) BOOL isGroupAdmin;
@property (nonatomic ,assign) BOOL isThisGroupMember;
@property (nonatomic ,assign) BOOL stranger;
@property (nonatomic ,assign) int  roleInGroup;
@property (nonatomic ,assign) BOOL groupMute;
@property (nonatomic ,assign) BOOL isBlackMan;
@property (nonatomic ,assign) BOOL isOffenContact;
@property (nonatomic ,assign) BOOL isUnRegisterAddress;
@property (nonatomic ,assign) int recommandStatus; //2:sent 1:unsend
@property (nonatomic ,assign) BOOL recommend;

@end

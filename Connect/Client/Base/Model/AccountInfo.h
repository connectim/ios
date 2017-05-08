//
//  AccountInfo.h
//  Connect
//
//  Created by MoHuilin on 16/5/19.
//  Copyright © 2016年 bitmain. All rights reserved.
//

#import "BaseInfo.h"

typedef NS_ENUM(NSInteger,UserSourceType) {
    UserSourceTypeDefault = 0, //UserSourceTypeDefault
    UserSourceTypeContact, //联系人
    UserSourceTypeQrcode, //二维码
    UserSourceTypeTransaction, //交易
    UserSourceTypeGroup, //群组
    UserSourceTypeSearch, //搜索
    UserSourceTypeRecommend, //推荐(可能认识的人)
};

typedef void(^AccountOperation)();
typedef void(^AccountOperationWithUserInfo)(id userInfo);

@interface AccountInfo : BaseInfo

@property (nonatomic ,copy) NSString *address;
@property (nonatomic ,copy) NSString *avatar;
@property (nonatomic ,copy) NSString *localAvatarIcon;

@property (nonatomic ,copy) NSString *avatar400; //大图

@property (nonatomic ,copy) NSString *encryption_pri;
@property (nonatomic ,copy) NSString *password_hint;
@property (nonatomic ,copy) NSString *pub_key;
@property (nonatomic ,copy) NSString *username; //用户名
@property (nonatomic ,copy) NSString *bondingPhone; // 用户绑定的手机号码，如果绑定，需要存续到keychain中
@property (nonatomic ,assign) BOOL bonding;

@property (nonatomic ,copy) NSString *groupNickName; //群组昵称

@property (nonatomic ,copy) NSString *identifier;
@property (nonatomic ,copy) NSString *prikey;
@property (copy, nonatomic) NSString* contentId; //用户的ID

//界面展示的名称
@property (nonatomic ,copy) NSString *groupShowName; //群组信息展示的名称
@property (nonatomic ,copy) NSString *normalShowName; //非群下面展示的名称

@property (nonatomic ,copy) NSString *remarks;//别名

@property (nonatomic ,copy) NSString *phoneContactName; //注册手机号在本地通讯录中的名字
@property (nonatomic ,assign) NSTimeInterval lastLoginTime; //最后活跃时间，用来排序

@property (nonatomic ,strong) NSArray *tags;

@property (nonatomic ,assign) BOOL isCommonGroup; //是否是群组联系人
@property (nonatomic ,strong) NSArray *groupMembers; // 群组成员

///新的朋友
@property (nonatomic ,copy) NSString *message;
@property (nonatomic ,strong) NSNumber *times;
@property (nonatomic ,assign) UserSourceType source; //用户来源
@property (nonatomic ,assign) int role; //添加好友的角色  1 ：邀请者  2 ：接受邀请者
@property (nonatomic ,assign) int status; //状态  role == 1 , 0 等待验证 1 通过验证 2:添加 ///// role == 2 ,0 ：未接受  1 已接受

@property (nonatomic ,copy) AccountOperation customOperation; //用户操作的block
@property (nonatomic ,copy) AccountOperationWithUserInfo customOperationWithInfo; //带参数的block

@property (nonatomic ,assign) BOOL isSelected;

//群组
@property (nonatomic ,assign) BOOL isGroupAdmin;
@property (nonatomic ,assign) BOOL isThisGroupMember;
@property (nonatomic ,assign) BOOL isMyFriend;
@property (nonatomic ,assign) int  roleInGroup; //群组中的角色
@property (nonatomic ,assign) BOOL groupMute; //群组免扰

//黑名单
@property (nonatomic ,assign) BOOL isBlackMan;
//常用联系人
@property (nonatomic ,assign) BOOL isOffenContact;

@property (nonatomic ,assign) BOOL isUnRegisterAddress; //是否是未注册的地址

//这下边的只在特殊的情况使用，其他情况不使用  payattion
@property (nonatomic ,assign) int isSend; //是否点击发送了 发送为2 未发送的为1
@property (nonatomic ,assign) BOOL recommend; //是否是推荐来的




@end

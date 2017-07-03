//
//  Define.h
//  Xtalk
//
//  Created by MoHuilin on 16/2/14.
//  Copyright © 2016年 MoHuilin. All rights reserved.
//
#define RegisterNotify(_name, _selector)                    \
[[NSNotificationCenter defaultCenter] addObserver:self  \
selector:_selector name:_name object:nil];

#define RemoveNofify            \
[[NSNotificationCenter defaultCenter] removeObserver:self];

#define SendNotify(_name, _object)  \
[[NSNotificationCenter defaultCenter] postNotificationName:_name object:_object];

// Last transfer amount
#define MIN_TRANSFER_AMOUNT (0.000100000)
#define MAX_TRANSFER_AMOUNT (100.0)
#define MAX_REDBAG_AMOUNT (0.2)
#define MAX_REDMIN_AMOUNT (0.0001)
#define MIN_RED_PER (0.00005)
#define MINNER_FEE @"10000"
#define MAX_MINNER_FEE @"10000"


#define XTALK_USRID_LEN		36
#define XTALK_PRIVKEY_LEN	32

// over time code
#define OVER_TIME_CODE -110

#define MAX_PASS_LEN (4)

// Start screen time
#define LANUCH_DURATION (1.5)

#define InnerAadStringDefine @"ConnectEncrypted"

#define kSystemIdendifier @"connect"

#define hmacSHA512Key @"49f41477fa1bfc3b4792d5233b6a659f4b"


// Judge the system version of the macro
#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)


// Do not participate in the type of message after the call
#define IgnoreSnapchatMessageTypes @[@(GJGCChatFriendContentTypePayReceipt),\
@(GJGCChatFriendContentTypeTransfer),\
@(GJGCChatFriendContentTypeRedEnvelope),\
@(GJGCChatFriendContentTypeNameCard),\
@(GJGCChatFriendContentTypeStatusTip),\
@(GJGCChatFriendContentTypeNoRelationShipTip),\
@(GJGCChatFriendContentTypeSecureTip),\
@(GJGCChatInviteNewMemberTip),\
@(GJGCChatFriendContentTypeMapLocation),\
@(GJGCChatInviteToGroup),\
@(GJGCChatWalletLink)]


#pragma mark - IOS system version

#define IOSBaseVersion9     9.0
#define IOSBaseVersion8     8.0
#define IOSBaseVersion7     7.0

#pragma mark - File cache path

#define RootPath            @"/Library/.Connect"
#define CacheImagePath      @"CacheImages"
#define CacheVideoPath      @"CacheVideos"
#define CacheVoicePath      @"CacheVoices"
#define ChatMessageDBFile      @"ChatMessage.db"

#define MainConfigDBFile    @"MainConfig.db"

#pragma mark - size

#define VIEW_WIDTH self.view.frame.size.width
#define VIEW_HEIGHT self.view.frame.size.height
#define DEVICE_SIZE [UIScreen mainScreen].bounds.size
#define NEWIPHONE6P (DEVICE_SIZE.width > 390 && DEVICE_SIZE.width < 440)

#pragma mark - color

#define XCColor(r, g, b)         [UIColor colorWithRed:(r) / 255.f green:(g) / 255.f blue:(b) / 255.f alpha:1.f]
#define XCColorAlpha(r, g, b, a)         [UIColor colorWithRed:(r) / 255.f green:(g) / 255.f blue:(b) / 255.f alpha:(a)*1.f]

#define XCWhiteColor XCColor(255,255,255)
#define XCBlackColor XCColor(0,0,0)

#define NetWorkCaches @"Library/Caches/NetWorkToolCaches"

#define CREATE_SHARED_MANAGER(CLASS_NAME) \
+ (instancetype)sharedManager { \
static CLASS_NAME *_instance; \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instance = [[CLASS_NAME alloc] init]; \
}); \
\
return _instance; \
}

#define CREATE_SHARED_INSTANCE(CLASS_NAME) \
+ (instancetype)sharedInstance { \
static CLASS_NAME *_instance; \
static dispatch_once_t onceToken; \
dispatch_once(&onceToken, ^{ \
_instance = [[CLASS_NAME alloc] init]; \
}); \
\
return _instance; \
}

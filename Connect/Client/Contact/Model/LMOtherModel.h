//
//  LMOtherModel.h
//  Connect
//
//  Created by bitmain on 2016/12/28.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,InviteSourceType) {
    InviteSourceTypeQrcode = 0,
    InviteSourceTypeGroupInfoCard,
    InviteSourceTypeToken,
};

@interface LMOtherModel : NSObject

@property(copy,nonatomic) NSString* userName;

@property(copy,nonatomic) NSString* contentName;

@property(copy,nonatomic) NSString* headImageViewUrl;

@property (nonatomic ,copy) NSString *verificationCode;

@property (nonatomic ,copy) NSString *publickey;

@property (nonatomic ,copy) NSString *groupIdentifier;
// weather is handled
@property (nonatomic ,assign) BOOL handled;
// weather is refused
@property (nonatomic ,assign) BOOL refused;

@property (nonatomic ,assign) BOOL userIsinGroup;
@property (nonatomic ,assign) InviteSourceType sourceType;

@end

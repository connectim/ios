//
//  CaptureAvatarPage.h
//  Connect
//
//  Created by MoHuilin on 16/5/10.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseViewController.h"

typedef NS_ENUM(NSUInteger, SourceType) {
    SourceTypeLogin = 1 << 0,
    SourceTypeSet = 1 << 1
};

typedef void(^myImageBlock)(UIImage *image);

typedef void(^RegistImageBlock)(UIImage *clipImage, UIImage *originImage);

@interface CaptureAvatarPage : BaseViewController

@property(strong, nonatomic) myImageBlock imageBlock;
@property(strong, nonatomic) RegistImageBlock registImageBlock;
@property(assign, nonatomic) SourceType sourceType;

- (instancetype)initWithMobile:(NSString *)mobile token:(NSString *)token;

- (instancetype)initWithPrivkey:(NSString *)prikey;

@end

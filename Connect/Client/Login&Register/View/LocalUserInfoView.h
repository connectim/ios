//
//  LocalUserInfoView.h
//  Connect
//
//  Created by MoHuilin on 2016/12/6.
//  Copyright © 2016年 Connect - P2P Encrypted Instant Message. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef NS_ENUM(NSUInteger,SourceInfoType) {
    SourceInfoViewTypeCommon    = 1,
    SourceInfoViewTypeEncryPri  = 2
    
};

@interface LocalUserInfoView : UIControl

@property(nonatomic, strong) UILabel *userNameLabel;

@property(nonatomic, strong) UIImageView *avatarImageView;


+ (instancetype)viewWithAccountInfo:(AccountInfo *)user;

- (void)reloadWithUser:(AccountInfo *)user;

// hide sow
@property(nonatomic, assign) BOOL hidenArrowView;

@property(nonatomic, assign) SourceInfoType soureInfoType;


@end

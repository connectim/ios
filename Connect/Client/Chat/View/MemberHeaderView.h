//
//  MemberHeaderView.h
//  Connect
//
//  Created by MoHuilin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AccountInfo.h"

typedef void(^TapMemberHeaderViewBlock)(AccountInfo *info);

@interface MemberHeaderView : UIControl

- (instancetype)initWithImage:(NSString *)avatar name:(NSString *)name;

- (instancetype)initWithImage:(NSString *)avatar name:(NSString *)name tapBlock:(TapMemberHeaderViewBlock)tapBlock;

- (instancetype)initWithAccountInfo:(AccountInfo *)info tapBlock:(TapMemberHeaderViewBlock)tapBlock;

@property(nonatomic, copy) TapMemberHeaderViewBlock tapBlock;

@end

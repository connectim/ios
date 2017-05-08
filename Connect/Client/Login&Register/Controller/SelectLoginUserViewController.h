//
//  SelectLoginUserViewController.h
//  Connect
//
//  Created by MoHuilin on 2016/12/7.
//  Copyright © 2016年 Connect - P2P Encrypted Instant Message. All rights reserved.
//

#import "BaseViewController.h"

@interface SelectLoginUserViewController : BaseViewController

- (instancetype)initWithCallBackBlock:(void (^)(AccountInfo *user))block
                            chainUser:(NSArray *)chainUser
                         selectedUser:(AccountInfo *)selectedUser;

@end

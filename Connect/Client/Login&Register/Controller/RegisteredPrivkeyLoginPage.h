//
//  RegisteredPrivkeyLoginPage.h
//  Connect
//
//  Created by MoHuilin on 2016/12/7.
//  Copyright © 2016年 Connect - P2P Encrypted Instant Message. All rights reserved.
//

#import "BaseViewController.h"
#import "Protofile.pbobjc.h"

@interface RegisteredPrivkeyLoginPage : BaseViewController

- (instancetype)initWithUserToken:(UserExistedToken *)userToken privkey:(NSString *)privkey;


@end

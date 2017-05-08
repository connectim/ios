//
//  LMGroupZChouTransViewController.h
//  Connect
//
//  Created by Edwin on 16/8/24.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMBaseViewController.h"
#import "Protofile.pbobjc.h"
#import "Protofile.pbobjc.h"


@interface LMGroupZChouTransViewController : LMBaseViewController

@property(nonatomic, copy) void (^PaySuccessCallBack)(Crowdfunding *payedCrowding);

- (instancetype)initWithCrowdfundingInfo:(Crowdfunding *)crowdfunding;


@end

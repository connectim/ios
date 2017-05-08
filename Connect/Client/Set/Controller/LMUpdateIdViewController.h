//
//  LMUpdateIdViewController.h
//  Connect
//
//  Created by bitmain on 2017/1/19.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "BaseSetViewController.h"

typedef void (^UpdateIdBlock)(NSString *);

@interface LMUpdateIdViewController : BaseSetViewController
@property(strong, nonatomic) UpdateIdBlock updateIdBlock;
@end

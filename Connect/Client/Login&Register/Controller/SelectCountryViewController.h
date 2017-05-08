//
//  SelectCountryViewController.h
//  Connect
//
//  Created by MoHuilin on 2016/12/6.
//  Copyright © 2016年 Connect - P2P Encrypted Instant Message. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

@interface SelectCountryViewController : BaseViewController

- (instancetype)initWithCallBackBlock:(void (^)(id countryInfo))block;

@property(assign, nonatomic) BOOL isSetSelectCountry;
@end

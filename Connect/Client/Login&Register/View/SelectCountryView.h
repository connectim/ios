//
//  SelectCountryView.h
//  Connect
//
//  Created by MoHuilin on 2016/12/6.
//  Copyright © 2016年 Connect - P2P Encrypted Instant Message. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SelectCountryView : UIControl

@property(strong, nonatomic) UILabel *countryInfoLabel;

+ (instancetype)viewWithCountryName:(NSString *)countryName countryCode:(int)code;

- (void)updateCountryInfoWithCountryName:(NSString *)countryName countryCode:(int)code;

@end

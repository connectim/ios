//
//  PhoneContactInfo.h
//  Connect
//
//  Created by MoHuilin on 16/5/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseInfo.h"

@interface Phone : NSObject

@property (nonatomic ,copy) NSString *phoneNum;

@end

@interface PhoneContactInfo : BaseInfo

@property (nonatomic ,copy) NSString *firstName;
@property (nonatomic ,copy) NSString *lastName;
@property (nonatomic ,copy) NSString *nickName;

@property (nonatomic ,strong) NSArray *phones;

@property (nonatomic ,assign) BOOL isSelected;

@end

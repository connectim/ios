//
//  PhoneContactInfo.m
//  Connect
//
//  Created by MoHuilin on 16/5/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "PhoneContactInfo.h"

@implementation PhoneContactInfo

+ (NSDictionary *)mj_objectClassInArray{
    return @{@"phones":@"Phone"};
}

@end

@implementation Phone

+ (NSDictionary *)mj_replacedKeyFromPropertyName{
    return @{@"phoneNum":@"value"};
}

@end

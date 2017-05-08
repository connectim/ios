//
//  LMRootModel.m
//  Connect
//
//  Created by Qingxu Kuang on 16/7/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMRootModel.h"

@implementation LMRootModel
- (void)assignValueWithDictionary:(NSDictionary *)dict {
    if (!dict) return;
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    for (int i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        const char *propertyChar = property_getName(property);
        NSString *propertyString = [NSString stringWithUTF8String:propertyChar];
        if ([dict[propertyString] isKindOfClass:[NSNull class]]) {
            [self setValue:@"NULL" forKey:propertyString];
        } else {
            [self setValue:dict[propertyString] forKey:propertyString];
        }

    }
    free(properties);
}
@end

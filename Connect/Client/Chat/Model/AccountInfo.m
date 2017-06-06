//
//  AccountInfo.m
//  Connect
//
//  Created by MoHuilin on 16/5/19.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "AccountInfo.h"

@implementation AccountInfo

//- (NSString *)avatar{
//    if (!_address) {
//        return nil;
//    }
//    return [NSString stringWithFormat:@"%@%@",AVATAR_BASE_URL,_address];
//}

+ (NSArray *)mj_ignoredPropertyNames{
    return @[@"customOperation",@"customOperationWithInfo"];
}

- (NSString *)groupShowName{
    NSString *showName = self.username;
    if (!GJCFStringIsNull(self.remarks)) {
        showName = self.remarks;
    }
    if (!GJCFStringIsNull(self.groupNickName)) {
        showName = self.groupNickName;
    }
    if (showName.length > 0) {
        showName = [showName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    return showName;
}

- (NSString *)normalShowName{
    NSString *showName = self.username;
    if (!GJCFStringIsNull(self.remarks)) {
        showName = self.remarks;
    }
    if (showName.length > 0) {
        showName = [showName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    return showName;
}

- (NSString *)remarks{
    if (GJCFStringIsNull(_remarks)) {
        return @"";
    }
    return _remarks;
}

- (NSString *)password_hint{
    if (GJCFStringIsNull(_password_hint)) {
        return @"";
    }
    
    return _password_hint;
}

- (NSString *)avatar100{ //132
    return _avatar;
}

- (NSString *)avatar400{
    return [NSString stringWithFormat:@"%@?size=400",_avatar];
}

- (NSString *)bondingPhone{
    if ([_bondingPhone containsString:@"null"]) {
        return nil;
    }
    return _bondingPhone;
}

- (BOOL)isEqual:(id)object{
    if (object == self) {
        return YES;
    }
    if (![object isKindOfClass:[AccountInfo class]]) {
        return NO;
    }
    AccountInfo *entity = (AccountInfo *)object;
    if ([entity.address isEqualToString:self.address]) {
        return YES;
    }
    else {
        return NO;
    }
}


- (NSString *)groupNickName{
    if (_groupNickName == nil) {
        _groupNickName = @"";
    }
    return _groupNickName;
}
- (id)mutableCopyWithZone:(nullable NSZone *)zone
{
    
    id copy = [[[self class] allocWithZone:zone] init];
    unsigned int count = 0;
    Ivar *listArray = class_copyIvarList([self class], &count);
    for (int index = 0; index < count; index++) {
        Ivar ivar = listArray[index];
        NSString *name_ = [NSString stringWithUTF8String:ivar_getName(ivar)];
        NSString *name = nil;
        if (name_.length > 1) {
          name = [name_ substringFromIndex:1];
          id value = [self valueForKey:name];
          [copy setValue:value forKey:name];
        }else {
          continue;
        }
    }
    free(listArray);
    return copy;
}
@end

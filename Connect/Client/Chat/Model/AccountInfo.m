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
    
    AccountInfo * accountInfo = [[self class] allocWithZone:zone];
    
    accountInfo.address = self.address;
    accountInfo.avatar = self.avatar;
    accountInfo.avatar400 = self.avatar400;
    accountInfo.encryption_pri = self.encryption_pri;
    accountInfo.password_hint = self.password_hint;
    accountInfo.pub_key = self.pub_key;
    accountInfo.username = self.username;
    accountInfo.remarks = self.remarks;
    accountInfo.bonding = self.bonding;
    accountInfo.bondingPhone = self.bondingPhone;
    accountInfo.groupNickName = self.groupNickName;
    accountInfo.prikey = self.prikey;
    accountInfo.contentId = self.contentId;
    accountInfo.groupShowName = self.groupShowName;
    accountInfo.normalShowName = self.normalShowName;
    accountInfo.phoneContactName = self.phoneContactName;
    accountInfo.phoneContactName = self.phoneContactName;
    accountInfo.lastLoginTime = self.lastLoginTime;
    accountInfo.tags = self.tags;
    accountInfo.requestRead = self.requestRead;
    accountInfo.message = self.message;
    accountInfo.times = self.times;
    accountInfo.source = self.source;
    accountInfo.status = self.status;
    accountInfo.customOperation = self.customOperation;
    accountInfo.customOperationWithInfo = self.customOperationWithInfo;
    accountInfo.isSelected = self.isSelected;
    accountInfo.isGroupAdmin = self.isGroupAdmin;
    accountInfo.isThisGroupMember = self.isThisGroupMember;
    accountInfo.stranger = self.stranger;
    accountInfo.roleInGroup = self.roleInGroup;
    accountInfo.groupMute = self.groupMute;
    accountInfo.isBlackMan = self.isBlackMan;
    accountInfo.isOffenContact = self.isOffenContact;
    accountInfo.isUnRegisterAddress = self.isUnRegisterAddress;
    accountInfo.recommandStatus = self.recommandStatus;
    accountInfo.recommend = self.recommend;
    
    return accountInfo;

}
@end

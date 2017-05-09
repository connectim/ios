//
//  LMUUID.m
//  Connect
//
//  Created by MoHuilin on 2017/5/9.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMUUID.h"
#import <UIKit/UIKit.h>
#import "FXKeychain.h"

static NSString *kUDIDValue = nil;
static NSString *const kKeychainUDIDItemIdentifier  = @"UDID";   /* Replace with your own UDID identifier */

@implementation LMUUID

+ (NSString *)uuid {
    if (kUDIDValue == nil) {
        @synchronized ([self class]) {
            [[FXKeychain defaultKeychain] removeObjectForKey:kKeychainUDIDItemIdentifier];
            NSString *uuid = [[FXKeychain defaultKeychain] objectForKey:kKeychainUDIDItemIdentifier];;
            if (uuid) {
                kUDIDValue = uuid;
            } else {
                kUDIDValue = [self getIDFVString];
                [[FXKeychain defaultKeychain] setObject:kUDIDValue forKey:kKeychainUDIDItemIdentifier];
            }
        }
    }
    return kUDIDValue;
}

#pragma mark - Private Method
/**
 *  get identifierForVendor String
 */
+ (NSString *)getIDFVString {
    return [KeyHandle creatNewPrivkey].sha256String;
}

@end

//
//  AddressBookCallBack.m
//  Connect
//
//  Created by MoHuilin on 16/8/26.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "AddressBookCallBack.h"

@implementation AddressBookCallBack

void addressBookExternalChangeCallback(ABAddressBookRef addressBookRef, CFDictionaryRef info, void *context)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"addressBookExternalChangeCallback");
        NSLog(@"Re-sync");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AddressBookDidChangeExternallyNotification" object:(__bridge id)context];
    });
}

void registerExternalChangeCallbackForAddressBook(ABAddressBookRef addressBookRef)
{
    static BOOL registered = false;
    if (!registered) {
        ABAddressBookRegisterExternalChangeCallback(addressBookRef, addressBookExternalChangeCallback, nil);
        registered = true;
    }
}

@end

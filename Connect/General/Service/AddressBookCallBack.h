//
//  AddressBookCallBack.h
//  Connect
//
//  Created by MoHuilin on 16/8/26.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/ABAddressBook.h>

@interface AddressBookCallBack : NSObject

void registerExternalChangeCallbackForAddressBook(ABAddressBookRef addressBookRef);

@end

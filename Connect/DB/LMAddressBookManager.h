//
//  LMAddressBookManager.h
//  Connect
//
//  Created by Connect on 2017/4/13.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "BaseDB.h"
#import "AddressBookInfo.h"


#define AddressBookTable @"t_addressbook"

@interface LMAddressBookManager : BaseDB
+ (LMAddressBookManager *)sharedManager;

+ (void)tearDown;

/**
 * save address
 * @param address
 */
- (void)saveAddress:(NSString *)address;

/**
 * batch save address book
 * @param addressBooks
 */
- (void)saveBitchAddressBook:(NSArray *)addressBooks;

/**
 * get all address book
 * @return
 */
- (NSArray *)getAllAddressBooks;

/**
 * update address book tips
 * @param tag
 * @param address
 */
- (void)updateAddressTag:(NSString *)tag address:(NSString *)address;

/**
 * remove address
 * @param address
 */
- (void)deleteAddressBookWithAddress:(NSString *)address;
/**
 * remove all
 *
 */
- (void)clearAllAddress;
@end

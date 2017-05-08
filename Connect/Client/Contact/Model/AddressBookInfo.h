//
//  AddressBookInfo.h
//  Connect
//
//  Created by MoHuilin on 16/9/28.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AddressBookInfo : NSObject

@property (nonatomic ,copy) NSString *address;

@property (nonatomic ,copy) NSString *tag;

@property (nonatomic ,strong) AccountInfo *user;

@end

//
//  KTSContactsManager.h
//  kontacts-objc
//
//  Created by Kekiiwaa on 19/04/15.
//  Copyright (c) 2015 Kekiiwaa. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSUInteger, KTSContactsManagerField){
    KTSContactsManagerFieldPersonID              = 1 << 0,
    KTSContactsManagerFieldFirstName             = 1 << 1,
    KTSContactsManagerFieldLastName              = 1 << 2,
    KTSContactsManagerFieldMiddleName            = 1 << 3,
    KTSContactsManagerFieldPrefix                = 1 << 4,
    KTSContactsManagerFieldSuffix                = 1 << 5,
    KTSContactsManagerFieldFirstNamePhonetic     = 1 << 6,
    KTSContactsManagerFieldLastNamePhonetic      = 1 << 7,
    KTSContactsManagerFieldNickName              = 1 << 8,
    KTSContactsManagerFieldCompany               = 1 << 9,
    KTSContactsManagerFieldJobTitle              = 1 << 10,
    KTSContactsManagerFieldDepartment            = 1 << 11,
    KTSContactsManagerFieldNote                  = 1 << 12,
    KTSContactsManagerFieldCreatedAt             = 1 << 13,
    KTSContactsManagerFieldUpdatedAt             = 1 << 14,
    KTSContactsManagerFieldBirthday              = 1 << 15,
    KTSContactsManagerFieldPhones                = 1 << 16,
    KTSContactsManagerFieldEmails                = 1 << 17,
    KTSContactsManagerFieldImage                 = 1 << 18,
    KTSContactsManagerFieldAll                   = KTSContactsManagerFieldBirthday          |
                                                   KTSContactsManagerFieldCompany           |
                                                   KTSContactsManagerFieldCreatedAt         |
                                                   KTSContactsManagerFieldCreatedAt         |
                                                   KTSContactsManagerFieldDepartment        |
                                                   KTSContactsManagerFieldEmails            |
                                                   KTSContactsManagerFieldFirstName         |
                                                   KTSContactsManagerFieldFirstNamePhonetic |
                                                   KTSContactsManagerFieldImage             |
                                                   KTSContactsManagerFieldJobTitle          |
                                                   KTSContactsManagerFieldLastName          |
                                                   KTSContactsManagerFieldLastNamePhonetic  |
                                                   KTSContactsManagerFieldMiddleName        |
                                                   KTSContactsManagerFieldNickName          |
                                                   KTSContactsManagerFieldNote              |
                                                   KTSContactsManagerFieldPersonID          |
                                                   KTSContactsManagerFieldPhones            |
                                                   KTSContactsManagerFieldPrefix            |
                                                   KTSContactsManagerFieldSuffix            |
                                                   KTSContactsManagerFieldUpdatedAt
};

@protocol KTSContactsManagerDelegate <NSObject>

-(void)addressBookDidChange;
-(BOOL)filterToContact:(NSDictionary *)contact;

@end

@interface KTSContactsManager : NSObject

@property (strong, nonatomic) id<KTSContactsManagerDelegate> delegate;
@property (strong, nonatomic) NSArray *sortDescriptors;

+ (instancetype)sharedManager;

- (void)importContacts:(void (^)(NSArray *contacts,BOOL reject))contactsHandler;
//- (void)importContactsWithFields:(KTSContactsManagerField)fields contactsHandler:(void (^)(NSArray *))contactsHandler;
- (void)addContactName:(NSString *)firstName lastName:(NSString *)lastName phones:(NSArray *)phonesList emails:(NSArray *)emailsList birthday:(NSDate *)birthday image:(UIImage *)image completion:(void (^)(BOOL wasAdded))added;
//- (void)addContactName:(NSString *)firstName lastName:(NSString *)lastName phones:(NSArray *)phonesList emails:(NSArray *)emailsList birthday:(NSDate *)birthday completion:(void (^)(BOOL wasAdded))added __attribute__((deprecated));
- (void)removeContactById:(NSInteger)contactID completion:(void (^)(BOOL wasRemoved))removed;

@end

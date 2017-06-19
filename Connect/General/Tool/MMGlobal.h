//
//  MMGlobal.h
//  XChat
//
//  Created by MoHuilin on 16/2/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MMGlobal : NSObject

+(MMGlobal *)global;

// system version
+ (BOOL)isSystemLowIOS9;
+ (BOOL)isSystemLowIOS8;
+ (BOOL)isSystemLowIOS7;
+ (NSString *)clientVersion;

// Cache path
+ (NSString *)getRootPath;

+ (NSString *)getCacheImage:(NSString *)fileName;


+ (NSString *)getDBFile:(NSString *)dbPath;
+ (NSString *)getMainDBFile;
+ (BOOL)setNotBackUp:(NSString *)filePath;

// system hint
+ (void)alertMessage:(NSString *)message;
+ (void)alertMessageEx:(NSString *)message
                 title:(NSString *)title
              okTtitle:(NSString *)okTitle
           cancelTitle:(NSString *)cancelTitle
              delegate:(id)delegate;

// get currrent version
+( NSString*)currentVersion;
// Get the device model (eg iphone7)
+ (NSString *)getCurrentDeviceModel;
// get indexs array
+ (NSMutableArray *)getIndexArray:(NSMutableArray *)groupArray;
// get accordingTheChineseAndEnglishNameToGenerateAlphabet array
+ (NSArray *)accordingTheChineseAndEnglishNameToGenerateAlphabet:(NSMutableArray *)contactArray;
// preIsInAtoZ
+ (BOOL)preIsInAtoZ:(NSString *)str;
// nameIsAlphabeticalAscending
+ (NSMutableArray *)nameIsAlphabeticalAscending:(NSMutableArray *)contactArray withAlphaArr:(NSMutableArray *)alphaArray;
// getGroupsArray
+ (NSMutableArray *)getGroupsArray:(NSMutableArray *)indexs withContactArray:(NSMutableArray *)contactArray;
//getIndexsWith
+ (NSMutableArray *)getIndexsWith:(NSMutableArray *)contactArray;

@end

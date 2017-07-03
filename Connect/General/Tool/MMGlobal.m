//
//  MMGlobal.m
//  XChat
//
//  Created by MoHuilin on 16/2/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "MMGlobal.h"
#import "CellGroup.h"
#import "FxFileUtility.h"
#import "NSString+Pinyin.h"
#include <sys/types.h>
#include <sys/sysctl.h>
@implementation MMGlobal

+ (MMGlobal *)global
{
    static MMGlobal *s_global = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_global = [[MMGlobal alloc] init];
    });
    
    return s_global;
}

- (id)init
{
    self = [super init];
    if (self) {
    }
    
    return self;
}


#pragma mark - system version
+ (BOOL)isSystemLowIOS9
{
    UIDevice *device = [UIDevice currentDevice];
    CGFloat systemVer = [[device systemVersion] floatValue];
    if (systemVer - IOSBaseVersion9 < -0.001) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)isSystemLowIOS8
{
    UIDevice *device = [UIDevice currentDevice];
    CGFloat systemVer = [[device systemVersion] floatValue];
    if (systemVer - IOSBaseVersion8 < -0.001) {
        return YES;
    }
    
    return NO;
}

+ (BOOL)isSystemLowIOS7
{
    UIDevice *device = [UIDevice currentDevice];
    CGFloat systemVer = [[device systemVersion] floatValue];
    if (systemVer - IOSBaseVersion7 < -0.001) {
        return YES;
    }
    
    return NO;
}


+ (NSString *)clientVersion
{
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    return [infoDict objectForKey:@"CFBundleShortVersionString"];
}


#pragma mark - cache path

+ (NSString *)getRootPath
{
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:RootPath];
    [FxFileUtility createPath:path];
    
    return path;
}



+ (NSString *)getMainDBFile
{
    NSString *path = [MMGlobal getRootPath];
    return [path stringByAppendingPathComponent:MainConfigDBFile];
}

+ (NSString *)getDBFile:(NSString *)dbPath
{
    NSString *path = [MMGlobal getRootPath];
    
    return [path stringByAppendingPathComponent:dbPath];
}

/**
 Set a directory without backing up
 */

+ (BOOL)setNotBackUp:(NSString *)filePath
{
    NSError *error = nil;
    NSURL *fileURL = [NSURL fileURLWithPath:filePath];
    NSNumber *attrValue = [NSNumber numberWithBool:YES];
    
    [fileURL setResourceValue:attrValue
                       forKey:NSURLIsExcludedFromBackupKey
                        error:&error];
    if (error!=nil) {
        DDLogError([error localizedDescription]);
        return NO;
    }
    return YES;
}
// Get the current version
+( NSString*)currentVersion;
{
    NSDictionary* infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString* versionNum = [infoDict objectForKey:@"CFBundleShortVersionString"];
    return versionNum;
}
// Get the equipment model
+ (NSString *)getCurrentDeviceModel
{
    int mib[2];
    size_t len;
    char *machine;
    
    mib[0] = CTL_HW;
    mib[1] = HW_MACHINE;
    sysctl(mib, 2, NULL, &len, NULL, 0);
    machine = malloc(len);
    sysctl(mib, 2, machine, &len, NULL, 0);
    
    NSString *platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
    free(machine);
    // iPhone
    if ([platform isEqualToString:@"iPhone1,1"]) return @"iPhone2G";
    if ([platform isEqualToString:@"iPhone1,2"]) return @"iPhone3G";
    if ([platform isEqualToString:@"iPhone2,1"]) return @"iPhone3GS";
    if ([platform isEqualToString:@"iPhone3,1"]) return @"iPhone4";
    if ([platform isEqualToString:@"iPhone3,2"]) return @"iPhone4";
    if ([platform isEqualToString:@"iPhone3,3"]) return @"iPhone4";
    if ([platform isEqualToString:@"iPhone4,1"]) return @"iPhone4S";
    if ([platform isEqualToString:@"iPhone5,1"]) return @"iPhone5";
    if ([platform isEqualToString:@"iPhone5,2"]) return @"iPhone5";
    if ([platform isEqualToString:@"iPhone5,3"]) return @"iPhone5c";
    if ([platform isEqualToString:@"iPhone5,4"]) return @"iPhone5c";
    if ([platform isEqualToString:@"iPhone6,1"]) return @"iPhone5s";
    if ([platform isEqualToString:@"iPhone6,2"]) return @"iPhone5s";
    if ([platform isEqualToString:@"iPhone7,2"]) return @"iPhone6";
    if ([platform isEqualToString:@"iPhone7,1"]) return @"iPhone6Plus";
    if ([platform isEqualToString:@"iPhone8,1"]) return @"iPhone6s";
    if ([platform isEqualToString:@"iPhone8,2"]) return @"iPhone6sPlus";
    if ([platform isEqualToString:@"iPhone8,3"]) return @"iPhoneSE";
    if ([platform isEqualToString:@"iPhone8,4"]) return @"iPhoneSE";
    if ([platform isEqualToString:@"iPhone9,1"]) return @"iPhone7";
    if ([platform isEqualToString:@"iPhone9,2"]) return @"iPhone7Plus";
    
    //iPod Touch
    if ([platform isEqualToString:@"iPod1,1"])   return @"iPodTouch";
    if ([platform isEqualToString:@"iPod2,1"])   return @"iPodTouch2G";
    if ([platform isEqualToString:@"iPod3,1"])   return @"iPodTouch3G";
    if ([platform isEqualToString:@"iPod4,1"])   return @"iPodTouch4G";
    if ([platform isEqualToString:@"iPod5,1"])   return @"iPodTouch5G";
    if ([platform isEqualToString:@"iPod7,1"])   return @"iPodTouch6G";
    
    //iPad
    if ([platform isEqualToString:@"iPad1,1"])   return @"iPad";
    if ([platform isEqualToString:@"iPad2,1"])   return @"iPad2";
    if ([platform isEqualToString:@"iPad2,2"])   return @"iPad2";
    if ([platform isEqualToString:@"iPad2,3"])   return @"iPad2";
    if ([platform isEqualToString:@"iPad2,4"])   return @"iPad2";
    if ([platform isEqualToString:@"iPad3,1"])   return @"iPad3";
    if ([platform isEqualToString:@"iPad3,2"])   return @"iPad3";
    if ([platform isEqualToString:@"iPad3,3"])   return @"iPad3";
    if ([platform isEqualToString:@"iPad3,4"])   return @"iPad4";
    if ([platform isEqualToString:@"iPad3,5"])   return @"iPad4";
    if ([platform isEqualToString:@"iPad3,6"])   return @"iPad4";
    
    //iPad Air
    if ([platform isEqualToString:@"iPad4,1"])   return @"iPadAir";
    if ([platform isEqualToString:@"iPad4,2"])   return @"iPadAir";
    if ([platform isEqualToString:@"iPad4,3"])   return @"iPadAir";
    if ([platform isEqualToString:@"iPad5,3"])   return @"iPadAir2";
    if ([platform isEqualToString:@"iPad5,4"])   return @"iPadAir2";
    
    //iPad mini
    if ([platform isEqualToString:@"iPad2,5"])   return @"iPadmini1G";
    if ([platform isEqualToString:@"iPad2,6"])   return @"iPadmini1G";
    if ([platform isEqualToString:@"iPad2,7"])   return @"iPadmini1G";
    if ([platform isEqualToString:@"iPad4,4"])   return @"iPadmini2";
    if ([platform isEqualToString:@"iPad4,5"])   return @"iPadmini2";
    if ([platform isEqualToString:@"iPad4,6"])   return @"iPadmini2";
    if ([platform isEqualToString:@"iPad4,7"])   return @"iPadmini3";
    if ([platform isEqualToString:@"iPad4,8"])   return @"iPadmini3";
    if ([platform isEqualToString:@"iPad4,9"])   return @"iPadmini3";
    if ([platform isEqualToString:@"iPad5,1"])   return @"iPadmini4";
    if ([platform isEqualToString:@"iPad5,2"])   return @"iPadmini4";
    
    if ([platform isEqualToString:@"i386"])      return @"iPhoneSimulator";
    if ([platform isEqualToString:@"x86_64"])    return @"iPhoneSimulator";
    return platform;
}
+ (NSMutableArray *)getIndexArray:(NSMutableArray *)groupArray {
    if (groupArray.count <= 0) {
        return nil;
    }
    NSMutableArray *temArray = [NSMutableArray array];
    for (NSMutableDictionary* dic in groupArray) {
        if ([RegexKit isNotChinsesWithUrl:dic[@"title"]]) {
            [temArray addObject:dic[@"title"]];
        }
    }
    return temArray;
}
+ (NSArray *)accordingTheChineseAndEnglishNameToGenerateAlphabet:(NSMutableArray *)contactArray {
    NSMutableArray *alphatArr = [[NSMutableArray alloc] init];
    for (AccountInfo *info in contactArray) {
        NSString *pinyin = [info.normalShowName transformToPinyin];
        NSString *pinyinFirst = [[pinyin substringToIndex:1] uppercaseString];
        if ([MMGlobal preIsInAtoZ:pinyinFirst]) {
            if (![alphatArr containsObject:pinyinFirst]) {
                [alphatArr objectAddObject:pinyinFirst];
            }
        } else {
            if (![alphatArr containsObject:@"#"]) {
                [alphatArr objectAddObject:@"#"];
            }
        }
    }
    // sort array
    NSArray *arr = [alphatArr sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        NSComparisonResult result = [obj1 compare:obj2];
        return result;
    }];
    return arr;
}
+ (NSMutableArray *)nameIsAlphabeticalAscending:(NSMutableArray *)contactArray withAlphaArr:(NSMutableArray *)alphaArray {
    
    NSMutableArray *secArray = [NSMutableArray array];
    for (NSString *alphat in alphaArray) {
        NSMutableArray *sectionArr = [[NSMutableArray alloc] init];
        for (int i = 0; i < contactArray.count; i++) {
            AccountInfo *info = contactArray[i];
            NSString *pinyin = [info.normalShowName transformToPinyin];
            NSString *pinyinFirst = [[pinyin substringToIndex:1] uppercaseString];
            // First determine pinyinFirst is not the letter set to #
            if (pinyinFirst.length > 0) {
                NSString *regex = @"[a-zA-Z]";
                NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
                if (![pred evaluateWithObject:pinyinFirst]) {
                    pinyinFirst = @"#";
                }
                
            }
            if ([pinyinFirst isEqualToString:alphat]) {
                [sectionArr objectAddObject:info];
            }
        }
        [secArray objectAddObject:sectionArr];
    }
    return secArray;
}
+ (NSMutableArray *)getGroupsArray:(NSMutableArray *)indexs withContactArray:(NSMutableArray *)contactArray {
    NSMutableArray *items = nil;
    NSMutableArray *temArray = [NSMutableArray array];
    for (NSString *prex in indexs) {
        CellGroup *group = [[CellGroup alloc] init];
        group.headTitle = prex;
        items = [NSMutableArray array];
        for (AccountInfo *contact in contactArray) {
            NSString *name = @"";
            if (contact.remarks && contact.remarks.length > 0) {
                name = contact.remarks;
            } else {
                name = contact.username;
            }
            NSString *namePiny = [[name transformToPinyin] uppercaseString];
            if (namePiny.length <= 0) {
                continue;
            }
            NSString *pinYPrex = [namePiny substringToIndex:1];
            if (![MMGlobal preIsInAtoZ:pinYPrex]) {
                namePiny = [namePiny stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@"#"];
            }
            if ([namePiny hasPrefix:prex]) {
                [items objectAddObject:contact];
            }
        }
        group.items = [NSArray arrayWithArray:items];
        [temArray objectAddObject:group];
    }
    return temArray;
}
+ (NSMutableArray *)getIndexsWith:(NSMutableArray *)contactArray {
    NSMutableArray *temArray = [NSMutableArray array];
    for (AccountInfo *contact in contactArray) {
        NSString *prex = @"";
        NSString *name = contact.username;
        if (name.length <= 0) {
            continue;
        }
        prex = [[name transformToPinyin] substringToIndex:1];
        if ([MMGlobal preIsInAtoZ:prex]) {
            [temArray objectAddObject:[prex uppercaseString]];
        } else {
            [temArray addObject:@"#"];
        }
        NSMutableSet *set = [NSMutableSet set];
        for (NSObject *obj in temArray) {
            [set addObject:obj];
        }
        [temArray removeAllObjects];
        for (NSObject *obj in set) {
            [temArray objectAddObject:obj];
        }
        [temArray sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
            NSString *str1 = obj1;
            NSString *str2 = obj2;
            return [str1 compare:str2];
        }];
    }
    return temArray;
}
+ (BOOL)preIsInAtoZ:(NSString *)str {
    return [@"QWERTYUIOPLKJHGFDSAZXCVBNM" containsString:str] || [[@"QWERTYUIOPLKJHGFDSAZXCVBNM" lowercaseString] containsString:str];
}
@end

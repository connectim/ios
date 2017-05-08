//
//  BadgeNumberStore.m
//  Connect
//
//  Created by MoHuilin on 16/9/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BadgeNumberStore.h"
#import "RecentChatDBManager.h"
@interface BadgeNumberStore()

@property(nonatomic,copy) NSString *plistPath;

@property(nonatomic,strong) NSMutableDictionary * RootDic;

@end

@implementation BadgeNumberStore

+ (instancetype)shareManager
{
    static dispatch_once_t onceToken;
    static BadgeNumberStore *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[BadgeNumberStore alloc]init];
    });
    
    return  instance;
}


//-----------------------------------------
#pragma mark --Get the path to the plist table--
//-----------------------------------------
- (NSString *)plistPath
{
    NSArray * path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docPath = [path objectAtIndexCheck:0];
    NSString * folderPath = [docPath stringByAppendingPathComponent:[[LKUserCenter shareCenter] currentLoginUser].address];
    if (![[NSFileManager defaultManager] fileExistsAtPath:folderPath]) {
        // Create a directory
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    _plistPath = [folderPath stringByAppendingPathComponent:BadgeNumberPlistName];
    
    DDLogInfo(@"plistPath===%@",_plistPath);
    return _plistPath;
}

//-----------------------------------------
#pragma mark -- Get rootDiC -
//-----------------------------------------
- (NSMutableDictionary *)RootDic
{
    // Determine whether the file exists under the path
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.plistPath] == NO) {
        
        // Create a file
        NSFileManager * fm = [NSFileManager defaultManager];
        [fm createFileAtPath:self.plistPath contents:nil attributes:nil];
        _RootDic = [[NSMutableDictionary alloc]init];
        [_RootDic writeToFile:self.plistPath atomically:YES];
    }else
    {
        _RootDic = [[NSMutableDictionary alloc]initWithContentsOfFile:self.plistPath];
    }
    
    return _RootDic;
}




//-----------------------------------------
#pragma mark -- 讲 rootDic 写入 plist--
//-----------------------------------------
-(void)writeRootDicToPlistFile
{
    if (_RootDic) {
        [_RootDic writeToFile:self.plistPath atomically:YES];
    }else
    {
        DDLogError(@"_RootDic not exiset");
    }
}
//-----------------------------------------
#pragma mark -- Exposure to external methods--
//-----------------------------------------
/**
   * Get a single Badge from RootDic
   *
   * @param type BadgeNumber type
   *
   * @return BadgeNumber object
 */
- (BadgeNumber *)getBadgeNumber:(NSUInteger) type
{
    NSString *key = [NSString stringWithFormat:@"%lu",type];
    NSDictionary *objDic = [self.RootDic objectForKey:key];
    if (objDic) {
        BadgeNumber * badge = [[BadgeNumber alloc]init];
        [badge setValuesForKeysWithDictionary:objDic];
        return badge;
    }
    
    return nil;
}

/**
 *  Returns the total number of badge numbers displayed in the specified area by returning
 *  @param typeMin Specifies the minimum value of the interval
 *  @param typeMax Specifies the maximum value of the interval
 *
 *  @return
 */
- (NSUInteger)getBadgeNumberCountWithMin:(NSUInteger)typeMin max:(NSUInteger)typeMax
{
    NSUInteger count = 0;
    NSArray *allValues = [self.RootDic allValues];
    for (NSDictionary * objDic in allValues) {
        BadgeNumber * badge = [BadgeNumber mj_objectWithKeyValues:objDic];
        if (badge.type >= typeMin && badge.type <= typeMax) {
            count += badge.count;
        }
    }
    return count;
}


/**
   * BadgeNumber is stored
   *
   * @param badgeNumber
 */
- (BOOL)setBadgeNumber:(BadgeNumber *)badgeNumber
{
    if (badgeNumber) {
        NSString * key = [NSString stringWithFormat:@"%lu",badgeNumber.type];
        NSDictionary *objDic = [badgeNumber mj_JSONObject];
        [self.RootDic setObject:objDic forKey:key];
        [self writeRootDicToPlistFile];
        return YES;
    }else
    {
        DDLogInfo(@"badgeNumber  == nil");
        return NO;
    }
}

/**
   * Clear BadgeNumber
   *
   * @param type
 */
- (void)clearBadgeNumber:(NSUInteger) type
{
    NSString *key = [NSString stringWithFormat:@"%lu",type];
    [self.RootDic removeObjectForKey:key];
    [self writeRootDicToPlistFile];
}


- (BadgeNumber *)getBadgeNumberWithChatIdentifier:(NSString *)identifier{
    
    
    return nil;
}

- (NSUInteger)getMessageBadgeNumber{
    return 0;
}

@end

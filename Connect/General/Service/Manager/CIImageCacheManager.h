//
//  CIImageCacheManager.h
//  Connect
//
//  Created by MoHuilin on 16/9/10.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CIImageCacheManager : NSObject

+ (instancetype)sharedInstance;

/**
   * Group avatar
   *
   * @param identifier group ID
   *
   * @return
 */
- (void)groupAvatarByGroupIdentifier:(NSString *)identifier groupMembers:(NSArray *)groupMembsers complete:(void(^)(UIImage *image))complete;

/**
   * Update group user avatar
   *
   * @param image
 */
- (void)updataOrSaveGroupAvatarWithImage:(UIImage *)image;

- (void)removeGroupAvatarCacheWithGroupIdentifier:(NSString *)identifier;

- (void)removeContactAvatarCacheWithUrl:(NSString *)avatarUrl;

/**
   * Personal avatar
   *
   * @param avatarUrl personal avatar connection
   *
   * @return
 */
- (void)contactAvatarWithUrl:(NSString *)avatarUrl complete:(void(^)(UIImage *image))complete;

/**
   * Update or save personal avatar
   *
   * @param image
 */
- (void)updataOrSaveContactAvatarWithImage:(UIImage *)image;

- (void)uploadGroupAvatarWithGroupIdentifier:(NSString *)identifier groupMembers:(NSArray *)groupMembers;

@end

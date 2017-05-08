//
//  UIImageView+LMSetImageUrl.h
//  Connect
//
//  Created by MoHuilin on 2016/12/21.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImageView (LMSetImageUrl)

/**
 Set the avatar, the default avatar on the request process
 */
- (void)setPlaceholderImageWithAvatarUrl:(NSString *)url imageByRoundCornerRadius:(int)radius;

/**
 Set the avatar, the default avatar on the request process
 */
- (void)setPlaceholderImageWithAvatarUrl:(NSString *)url;

/**
    Set the avatar, the default avatar is placed after the request
 */
- (void)setImageWithAvatarUrl:(NSString *)url;


- (void)setPlaceholder:(NSString *)placeholder imageWithAvatarUrl:(NSString *)url;

- (void)setLinkUrlIconImageWithUrl:(NSString *)url placeholder:(NSString *)placeholder;
    
- (void)setOriginImageWithAvatarUrl:(NSString *)url placeholder:(NSString *)placeholder;

@end

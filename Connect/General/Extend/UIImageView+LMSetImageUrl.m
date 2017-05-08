//
//  UIImageView+LMSetImageUrl.m
//  Connect
//
//  Created by MoHuilin on 2016/12/21.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "UIImageView+LMSetImageUrl.h"
#import "UIImageView+YYWebImage.h"
#import "UIImage+YYAdd.h"

@implementation UIImageView (LMSetImageUrl)

- (void)setPlaceholderImageWithAvatarUrl:(NSString *)url imageByRoundCornerRadius:(int)radius{
    // Cache fillet
    UIImage *avatarImage = [[YYImageCache sharedCache] getImageForKey:url];
    if (avatarImage) {
        [self setImage:avatarImage];
    } else{
        // Cancel the current request
        [self cancelCurrentImageRequest];
        [self setImageWithURL:[NSURL URLWithString:url]
                  placeholder:[UIImage imageNamed:@"default_user_avatar"]
                      options:YYWebImageOptionProgressiveBlur | YYWebImageOptionShowNetworkActivity | YYWebImageOptionSetImageWithFadeAnimation
                     progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                     }
                    transform:^UIImage *(UIImage *image, NSURL *url) {
                        if (radius > 0) {
                            image = [image imageByResizeToSize:CGSizeMake(AUTO_WIDTH(100), AUTO_WIDTH(100))];
                            image = [image imageByRoundCornerRadius:radius];
                        }
                        return image;
                    }
                   completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
                   }];
    }

}

- (void)setPlaceholder:(NSString *)placeholder imageWithAvatarUrl:(NSString *)url{
    // Cache fillet
    UIImage *avatarImage = [[YYImageCache sharedCache] getImageForKey:url];
    if (avatarImage) {
        avatarImage = [avatarImage imageByRoundCornerRadius:6];
        [self setImage:avatarImage];
    } else{
        // Cancel the current request
        [self cancelCurrentImageRequest];
        [self setImageWithURL:[NSURL URLWithString:url]
                  placeholder:[UIImage imageNamed:placeholder]
                      options:YYWebImageOptionProgressiveBlur | YYWebImageOptionShowNetworkActivity | YYWebImageOptionSetImageWithFadeAnimation
                     progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                     }
                    transform:^UIImage *(UIImage *image, NSURL *url) {
                        image = [image imageByResizeToSize:CGSizeMake(AUTO_WIDTH(100), AUTO_WIDTH(100))];
                        image = [image imageByRoundCornerRadius:6];
                        return image;
                    }
                   completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
                   }];
    }
}

- (void)setPlaceholderImageWithAvatarUrl:(NSString *)url{
    UIImage *avatarImage = [[YYImageCache sharedCache] getImageForKey:url];
    if (avatarImage) {
         avatarImage = [avatarImage imageByRoundCornerRadius:6];
        [self setImage:avatarImage];
    } else{
        [self cancelCurrentImageRequest];
        [self setImageWithURL:[NSURL URLWithString:url]
                             placeholder:[UIImage imageNamed:@"default_user_avatar"]
                                 options:YYWebImageOptionProgressiveBlur | YYWebImageOptionShowNetworkActivity | YYWebImageOptionSetImageWithFadeAnimation
                                progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                                }
                               transform:^UIImage *(UIImage *image, NSURL *url) {
                                   image = [image imageByResizeToSize:CGSizeMake(AUTO_WIDTH(100), AUTO_WIDTH(100))];
                                   image = [image imageByRoundCornerRadius:6];
                                   return image;
                               }
                              completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
                                  
                                  DDLogInfo(@"%@",error);
                                  
                              }];
    }
}


- (void)setImageWithAvatarUrl:(NSString *)url{
    UIImage *avatarImage = [[YYImageCache sharedCache] getImageForKey:url];
    if (avatarImage) {
        [self setImage:avatarImage];
    } else{
         __weak __typeof(&*self)weakSelf = self;
        [self cancelCurrentImageRequest];
        [self setImageWithURL:[NSURL URLWithString:url]
                  placeholder:[UIImage imageNamed:@"default_user_avatar"]
                      options:YYWebImageOptionProgressiveBlur | YYWebImageOptionShowNetworkActivity | YYWebImageOptionSetImageWithFadeAnimation
                     progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                     }
                    transform:^UIImage *(UIImage *image, NSURL *url) {
                        image = [image imageByResizeToSize:CGSizeMake(AUTO_WIDTH(100), AUTO_WIDTH(100))];
                        image = [image imageByRoundCornerRadius:6];
                        return image;
                    }
                   completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
                       if (!image) {
                           weakSelf.image = [UIImage imageNamed:@"default_user_avatar"];
                       }
                   }];
    }
}
    
    
- (void)setOriginImageWithAvatarUrl:(NSString *)url placeholder:(NSString *)placeholder{
        UIImage *avatarImage = [[YYImageCache sharedCache] getImageForKey:url];
        if (avatarImage) {
            [self setImage:avatarImage];
        } else{
            __weak __typeof(&*self)weakSelf = self;
            [self cancelCurrentImageRequest];
            [self setImageWithURL:[NSURL URLWithString:url]
                      placeholder:nil
                          options:YYWebImageOptionProgressiveBlur | YYWebImageOptionShowNetworkActivity | YYWebImageOptionSetImageWithFadeAnimation
                         progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                         }
                        transform:^UIImage *(UIImage *image, NSURL *url) {
                            return image;
                        }
                       completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
                           if (!image) {
                               weakSelf.image = [UIImage imageNamed:placeholder];
                           }
                       }];
        }
    }



- (void)setLinkUrlIconImageWithUrl:(NSString *)url placeholder:(NSString *)placeholder{
    UIImage *avatarImage = [[YYImageCache sharedCache] getImageForKey:url];
    if (avatarImage) {
        float k = avatarImage.size.width / avatarImage.size.height;
        if (k > 1.5 || k < 0.7) {
            [self setImage:[UIImage imageNamed:placeholder]];
        } else{
            [self setImage:avatarImage];
        }
    } else{
        [self cancelCurrentImageRequest];
        [self setImageWithURL:[NSURL URLWithString:url]
                  placeholder:[UIImage imageNamed:placeholder]
                      options:YYWebImageOptionProgressiveBlur | YYWebImageOptionShowNetworkActivity | YYWebImageOptionSetImageWithFadeAnimation
                     progress:^(NSInteger receivedSize, NSInteger expectedSize) {
                     }
                    transform:^UIImage *(UIImage *image, NSURL *url) {
                        float k = image.size.width / image.size.height;
                        if (k > 1.5 || k < 0.7) {
                            image = [UIImage imageNamed:placeholder];
                        } else{
                            image = [image imageByResizeToSize:CGSizeMake(AUTO_WIDTH(100), AUTO_WIDTH(100))];
                        }
                        return image;
                    }
                   completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
                   }];
    }
}


@end

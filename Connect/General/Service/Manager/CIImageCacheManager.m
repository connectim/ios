//
//  CIImageCacheManager.m
//  Connect
//
//  Created by MoHuilin on 16/9/10.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "CIImageCacheManager.h"
#import "UIImage+YYAdd.h"
#import "UIImageView+YYWebImage.h"
#import "UIView+ScreenShot.h"
#import "StitchingImage.h"
#import "NSString+Hash.h"
#import "YYImageCache.h"
#import "GroupDBManager.h"
#import "NetWorkOperationTool.h"
#import "ConnectTool.h"

@interface CIImageCacheManager ()<NSCacheDelegate>

@property (nonatomic ,strong) dispatch_queue_t readQueue;

@end

@implementation CIImageCacheManager

+ (instancetype)sharedInstance
{
    static CIImageCacheManager* instance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [CIImageCacheManager new];
    });
    
    return instance;
}

- (instancetype)init{
    if (self = [super init]) {
        self.readQueue = dispatch_queue_create("read_image", DISPATCH_QUEUE_CONCURRENT);
    }
    
    return self;
}

- (void)removeGroupAvatarCacheWithGroupIdentifier:(NSString *)identifier{
    [[YYImageCache sharedCache] removeImageForKey:identifier];
    
    NSString *avatarName = [NSString stringWithFormat:@"%@.png",identifier];
    NSString *filePath = [[GJCFCachePathManager shareManager] mainImageCacheDirectory];
    filePath = [filePath stringByAppendingPathComponent:@"GroupAvatarCache"];
    if (!GJCFFileDirectoryIsExist(filePath)) {
        GJCFFileDirectoryCreate(filePath);
    }
    NSString *avatarPath = [filePath stringByAppendingPathComponent:avatarName];
    GJCFFileDeleteFile(avatarPath);
}

- (void)groupAvatarByGroupIdentifier:(NSString *)identifier groupMembers:(NSArray *)groupMembsers complete:(void(^)(UIImage *image))complete {
    UIImage *cacheImage = [[YYImageCache sharedCache] getImageForKey:identifier];
    if (cacheImage) {
        if (complete) {
            complete(cacheImage);
        }
    }
    NSString *avatarName = [NSString stringWithFormat:@"%@.png",identifier];
    NSString *filePath = [[GJCFCachePathManager shareManager] mainImageCacheDirectory];
    filePath = [filePath stringByAppendingPathComponent:@"GroupAvatarCache"];
    if (!GJCFFileDirectoryIsExist(filePath)) {
        GJCFFileDirectoryCreate(filePath);
    }
    NSString *avatarPath = [filePath stringByAppendingPathComponent:avatarName];
    //save group headimage
    if (!GJCFFileIsExist(avatarPath)) {
        [self downAndComposeAvatar:groupMembsers groupIdentifier:identifier complete:^(UIImage *image) {
            [[YYImageCache sharedCache] setImage:image forKey:identifier];
            if (complete) {
                complete(image);
            }
        }];
    } else{
        UIImage *image = [UIImage imageWithData:GJCFFileRead(avatarPath)];
        [[YYImageCache sharedCache] setImage:image forKey:identifier];
        if (complete) {
            complete(image);
        }
    }
}

- (void)contactAvatarWithUrl:(NSString *)avatarUrl complete:(void(^)(UIImage *image))complete {
    NSString *md5 = [avatarUrl md5String];
    UIImage *cacheImage = [[YYImageCache sharedCache] getImageForKey:md5];
    if (cacheImage) {
        if (complete) {
            complete(cacheImage);
        }
    }
    NSString *avatarName = [NSString stringWithFormat:@"%@.png",md5];
    NSString *filePath = [[GJCFCachePathManager shareManager] mainImageCacheDirectory];
    filePath = [filePath stringByAppendingPathComponent:@"ContactAvatars"];
    if (!GJCFFileDirectoryIsExist(filePath)) {
        GJCFFileDirectoryCreate(filePath);
    }
    NSString *avatarPath = [filePath stringByAppendingPathComponent:avatarName];
    // save link
    if (!GJCFFileIsExist(avatarPath)) {
        UIImageView *canvasView = [[UIImageView alloc] init];
        canvasView.frame = CGRectMake(0, 0, AUTO_WIDTH(200), AUTO_HEIGHT(200));
        
        [canvasView setImageWithURL:[NSURL URLWithString:avatarUrl] placeholder:[UIImage imageNamed:@"default_user_avatar"] options:YYWebImageOptionProgressiveBlur completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
            // save contact headimage
            if (!error) {
                NSData *data = UIImageJPEGRepresentation(image, 0.2);
                [GCDQueue executeInGlobalQueue:^{
                    GJCFFileWrite(data, avatarPath);
                }];
                [[YYImageCache sharedCache] setImage:[UIImage imageWithData:data] forKey:md5];
                if (complete) {
                    complete(image);
                }
            }
        }];
    } else{
        UIImage *image = [UIImage imageWithData:GJCFFileRead(avatarPath)];
        [[YYImageCache sharedCache] setImage:image forKey:md5];
        
        if (complete) {
            complete(image);
        }
    }
}

#pragma mark - Private method
- (void)downAndComposeAvatar:(NSArray *)groupMembsers groupIdentifier:(NSString *)identifier complete:(void(^)(UIImage *image))complete{
    
    UIImageView *canvasView = [[UIImageView alloc] init];
    canvasView.frame = CGRectMake(0, 0, AUTO_WIDTH(200), AUTO_HEIGHT(200));
    canvasView.backgroundColor = [GJGCCommonFontColorStyle mainThemeColor];
    NSMutableArray __block *temA = [NSMutableArray array];
    for (NSString *avatar in groupMembsers) {
        UIImageView __block *imageView = [[UIImageView alloc] init];
        [imageView setImageWithURL:[NSURL URLWithString:avatar]  placeholder:[UIImage imageNamed:@"default_user_avatar"] options:YYWebImageOptionProgressiveBlur completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
            if (!error) {
                [temA objectAddObject:imageView];
            } else{
                [temA objectAddObject:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"default_user_avatar"]]];
            }
            if (temA.count == groupMembsers.count) {
                UIImageView *coverImage = [[StitchingImage alloc] stitchingOnImageView:canvasView withImageViews:temA marginValue:2.f];
                UIImage *image = [coverImage screenShotWithFrame:coverImage.bounds];
                // Save group avatar
                [GCDQueue executeInGlobalQueue:^{
                    NSString *avatarName = [NSString stringWithFormat:@"%@.png",identifier];
                    NSString *filePath = [[GJCFCachePathManager shareManager] mainImageCacheDirectory];
                    filePath = [filePath stringByAppendingPathComponent:@"GroupAvatarCache"];
                    if (!GJCFFileDirectoryIsExist(filePath)) {
                        GJCFFileDirectoryCreate(filePath);
                    }
                    NSString *avatarPath = [filePath stringByAppendingPathComponent:avatarName];
                    if (!GJCFFileIsExist(avatarPath)) {
                        
                        GJCFFileWrite(UIImageJPEGRepresentation(image, 1), avatarPath);
                    }
                }];
                if (complete) {
                    complete(image);
                }
            }
        }];
    }
}

- (void)removeContactAvatarCacheWithUrl:(NSString *)avatarUrl{
    NSString *md5 = [avatarUrl md5String];
    [[YYImageCache sharedCache] removeImageForKey:md5];
    NSString *avatarName = [NSString stringWithFormat:@"%@.png",md5];
    NSString *filePath = [[GJCFCachePathManager shareManager] mainImageCacheDirectory];
    filePath = [filePath stringByAppendingPathComponent:@"ContactAvatars"];
    if (!GJCFFileDirectoryIsExist(filePath)) {
        GJCFFileDirectoryCreate(filePath);
    }
    NSString *avatarPath = [filePath stringByAppendingPathComponent:avatarName];
    GJCFFileDeleteFile(avatarPath);
}

- (void)uploadGroupAvatar:(UIImage *)avatar groupIdentifier:(NSString *)identifier{
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    // Determine whether the current user is a group
    GroupAvatar *groupAvatar = [GroupAvatar new];
    groupAvatar.identifier = identifier;
    groupAvatar.file = UIImageJPEGRepresentation(avatar, 1);
    if ([[GroupDBManager sharedManager] checkLoginUserIsGroupAdminWithIdentifier:identifier]) {
        [NetWorkOperationTool POSTWithUrlString:GroupUploadGroupAvatarUrl postProtoData:groupAvatar.data complete:^(id response) {
            HttpResponse *hResponse = (HttpResponse *)response;
            if (hResponse.code == successCode) {
                NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
                GroupAvatarResponse *avatarReponse = [GroupAvatarResponse parseFromData:data error:nil];
                // Update group avatar url
                [[GroupDBManager sharedManager] updateGroupAvatarUrl:avatarReponse.URL groupId:identifier];
                if (avatarReponse.URL) {
                    [GCDQueue executeInMainQueue:^{
                        SendNotify(@"UploadGroupAvatarSuccessNotification", (@{@"identifier":identifier,
                                                                               @"groupavatar":avatarReponse.URL}));
                    }];
                }
            }
        } fail:^(NSError *error) {
            
        }];
    }
}

- (void)uploadGroupAvatarWithGroupIdentifier:(NSString *)identifier groupMembers:(NSArray *)groupMembers{
     __weak __typeof(&*self)weakSelf = self;
    return;
    if (groupMembers.count > 9 || groupMembers.count < 1) return;
    [self groupAvatarByGroupIdentifier:identifier groupMembers:groupMembers complete:^(UIImage *image) {
          [weakSelf uploadGroupAvatar:image groupIdentifier:identifier];
    }];
}

#pragma mark - NSCacheDelegate

- (void)cache:(NSCache *)cache willEvictObject:(id)obj{
    
}

@end

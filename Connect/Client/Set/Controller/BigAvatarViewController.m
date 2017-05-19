//
//  BigAvatarViewController.m
//  Connect
//
//  Created by MoHuilin on 16/7/28.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BigAvatarViewController.h"
#import "NetWorkOperationTool.h"
#import "ImageClipViewController.h"
#import "CIImageCacheManager.h"
#import "GroupDBManager.h"
#import "YYImageCache.h"
#import <ImageIO/ImageIO.h>
#import "UIImage+YYAdd.h"
#import "CameraTool.h"
#import "CaptureAvatarPage.h"

@interface BigAvatarViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, ImageClipViewControllerDelegate>

@property(nonatomic, strong) UIImageView *bigAvatarImageView;

@property(nonatomic, strong) UIImage *editImage;

@end

@implementation BigAvatarViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = XCColor(22, 26, 33);

    UIImageView *bigAvatarImageView = [[UIImageView alloc] init];
    self.bigAvatarImageView = bigAvatarImageView;

    [self.view addSubview:bigAvatarImageView];

    bigAvatarImageView.width = DEVICE_SIZE.width;
    bigAvatarImageView.height = DEVICE_SIZE.width;
    bigAvatarImageView.center = self.view.center;

    [self setNavigationRight:@"menu_white"];

    self.title = LMLocalizedString(@"Chat Photo", nil);

    [self setAvatar];

}

- (void)setAvatar {
    [self.bigAvatarImageView setPlaceholderImageWithAvatarUrl:[[LKUserCenter shareCenter] currentLoginUser].avatar400 imageByRoundCornerRadius:0];
}

- (void)doRight:(id)sender {

    UIAlertController *actionController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *photoAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Login Take Photo", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        DDLogInfo(@"Photograph");
        [self talkPhoto];

    }];
    UIAlertAction *choosePhotoAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Login Select form album", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        DDLogInfo(@"Select from the phone album");
        [self choosePhoto];

    }];
    UIAlertAction *saveImageAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Set Save Photo", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        DDLogInfo(@"Save to album");
        [self tapSaveImageToIphone];

    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];

    [actionController addAction:photoAction];
    [actionController addAction:choosePhotoAction];
    [actionController addAction:saveImageAction];
    [actionController addAction:cancelAction];
    [self presentViewController:actionController animated:YES completion:nil];


}


- (void)tapSaveImageToIphone {

    /**
     *  将图片保存到iPhone本地相册
     *  UIImage *image            图片对象
     *  id completionTarget       响应方法对象
     *  SEL completionSelector    方法
     *  void *contextInfo
     */

    UIImageWriteToSavedPhotosAlbum(self.bigAvatarImageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);

}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    __weak typeof(self) weakSelf = self;
    if (error == nil) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Save successful", nil) withType:ToastTypeSuccess showInView:weakSelf.view complete:nil];
        }];
    } else {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Set Save Failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
    }

}


- (void)choosePhoto {
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];

    controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    controller.delegate = self;
    [self presentViewController:controller animated:YES completion:nil];
}

- (void)talkPhoto {
    __weak typeof(self) weakSelf = self;
    CaptureAvatarPage *page = [[CaptureAvatarPage alloc] init];
    __weak typeof(page) capVc = page;
    page.sourceType = SourceTypeSet;
    page.imageBlock = ^(UIImage *image) {
        if (image) {
            [weakSelf imageCropperFinish:image];
        }
        [capVc dismissViewControllerAnimated:YES completion:nil];
    };
    [self presentViewController:page animated:YES completion:nil];

}

#pragma mark - UINavigationControllerDelegate, UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info {

    [picker dismissViewControllerAnimated:NO completion:nil];
    if ([[info valueForKey:UIImagePickerControllerMediaType] hasSuffix:@"image"]) {
        UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
        ImageClipViewController *clipPage = [[ImageClipViewController alloc] initWithImage:image cropFrame:CGRectMake(0, 100, DEVICE_SIZE.width, DEVICE_SIZE.width) limitScaleRatio:3];
        clipPage.delegate = self;
        [self presentViewController:clipPage animated:NO completion:nil];
    }
}

#pragma mark - ImageClipViewControllerDelegate

- (void)imageCropperDidCancel:(ImageClipViewController *)cropperViewController {
    [cropperViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)imageCropper:(ImageClipViewController *)cropperViewController didFinished:(UIImage *)editedImage {

    self.editImage = editedImage;

    [cropperViewController dismissViewControllerAnimated:YES completion:nil];
    NSData *imageData = UIImageJPEGRepresentation(editedImage, 1);
    //remove exif
    imageData = [self dataByRemovingExif:imageData];
    //compress
    UIImage *avatarImage = [UIImage imageWithData:imageData];
    //limit in 2048kb
    imageData = [CameraTool imageSizeLessthan2M:imageData withOriginImage:avatarImage];

    [MBProgressHUD showMessage:LMLocalizedString(@"Common Loading", nil) toView:self.view];
    [self uploadAvatar:imageData];


}

- (void)imageCropperFinish:(UIImage *)editedImage {
    self.editImage = editedImage;
    NSData *imageData = UIImageJPEGRepresentation(editedImage, 1);
    imageData = [self dataByRemovingExif:imageData];
    UIImage *avatarImage = [UIImage imageWithData:imageData];
    imageData = [CameraTool imageSizeLessthan2M:imageData withOriginImage:avatarImage];

    [MBProgressHUD showMessage:LMLocalizedString(@"Common Loading", nil) toView:self.view];
    [self uploadAvatar:imageData];

}

- (NSData *)dataByRemovingExif:(NSData *)data {
    CGImageSourceRef source = CGImageSourceCreateWithData((CFDataRef) data, NULL);
    NSMutableData *mutableData = nil;

    if (source) {
        CFStringRef type = CGImageSourceGetType(source);
        size_t count = CGImageSourceGetCount(source);
        mutableData = [NSMutableData data];

        CGImageDestinationRef destination = CGImageDestinationCreateWithData((CFMutableDataRef) mutableData, type, count, NULL);

        NSDictionary *removeExifProperties = @{(id) kCGImagePropertyExifDictionary: (id) kCFNull,
                (id) kCGImagePropertyGPSDictionary: (id) kCFNull};

        if (destination) {
            for (size_t index = 0; index < count; index++) {
                CGImageDestinationAddImageFromSource(destination, source, index, (__bridge CFDictionaryRef) removeExifProperties);
            }

            if (!CGImageDestinationFinalize(destination)) {
                NSLog(@"CGImageDestinationFinalize failed");
            }

            CFRelease(destination);
        }

        CFRelease(source);
    }

    return mutableData;
}


- (void)uploadAvatar:(NSData *)imageData {
    __weak __typeof(&*self) weakSelf = self;

    Avatar *imageAvatar = [[Avatar alloc] init];
    imageAvatar.file = imageData;

    [NetWorkOperationTool POSTWithUrlString:ContactSetAvatar postProtoData:imageAvatar.data complete:^(id response) {

        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view];
        }];

        HttpResponse *hResponse = (HttpResponse *) response;
        if (hResponse.code != successCode) {
            DDLogError(@"The user information __ server update error");
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Updated failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
            return;
        }
        NSData *data = [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            AvatarInfo *userHead = [AvatarInfo parseFromData:data error:&error];

            // refresh cache
            [[YYImageCache sharedCache] removeImageForKey:[[LKUserCenter shareCenter] currentLoginUser].avatar];
            [[YYImageCache sharedCache] removeImageForKey:[[LKUserCenter shareCenter] currentLoginUser].avatar400];
            UIImage *corImage = [[UIImage imageWithData:imageData] imageByRoundCornerRadius:6];
            [[YYImageCache sharedCache] setImage:[UIImage imageWithData:imageData] forKey:[NSString stringWithFormat:@"%@?size=600", userHead.URL]]; // big photo
            [[YYImageCache sharedCache] setImage:corImage forKey:userHead.URL];
            [GCDQueue executeInMainQueue:^{
                [[LKUserCenter shareCenter] currentLoginUser].avatar = userHead.URL;
                [[LKUserCenter shareCenter] updateUserInfo:[[LKUserCenter shareCenter] currentLoginUser]];
                // update group head
                weakSelf.bigAvatarImageView.image = weakSelf.editImage;
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Update successful", nil) withType:ToastTypeSuccess showInView:weakSelf.view complete:nil];
                }];
            }];
        }
    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view];
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Updated failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
    }];
}

@end

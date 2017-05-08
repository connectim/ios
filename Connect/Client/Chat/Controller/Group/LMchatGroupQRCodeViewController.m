//
//  LMchatGroupQRCodeViewController.m
//  Connect
//
//  Created by bitmain on 2016/12/27.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "LMchatGroupQRCodeViewController.h"
#import "BarCodeTool.h"
#import "GroupDBManager.h"
#import "NetWorkOperationTool.h"
#import "UIView+ScreenShot.h"
#import "YYImageCache.h"

@interface LMchatGroupQRCodeViewController ()

@property(weak, nonatomic) IBOutlet UIImageView *QRImageView;
@property(weak, nonatomic) IBOutlet UILabel *groupNameLable;
@property(weak, nonatomic) IBOutlet UIImageView *groupHeaderImageView;
@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property(weak, nonatomic) IBOutlet UILabel *errorLable;
@property(assign, nonatomic) BOOL isAdmin;


@end

@implementation LMchatGroupQRCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.titleName) {
        self.title = self.titleName;
    }
    self.view.backgroundColor = LMBasicBlack;

    [self setUp];
    
    [self setQRNet:YES];
}

- (void)setUp {

    self.isAdmin = [[GroupDBManager sharedManager] checkLoginUserIsGroupAdminWithIdentifier:self.talkModel.chatIdendifier];
    [self.groupHeaderImageView setPlaceholderImageWithAvatarUrl:self.talkModel.chatGroupInfo.avatarUrl];
    self.groupNameLable.text = self.talkModel.chatGroupInfo.groupName;
    self.groupNameLable.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
}

- (void)creatRightButton {
    [self setNavigationRight:@"menu_white"];
}


- (void)doRight:(id)sender {

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    if (self.isAdmin) {
        UIAlertAction *refreshQR = [UIAlertAction actionWithTitle:LMLocalizedString(@"Link Refresh QR Code", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            [self showAlertView];
        }];
        [alertController addAction:refreshQR];
    }
    UIAlertAction *shareToFriend = [UIAlertAction actionWithTitle:LMLocalizedString(@"Link Share", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [self shareGroupQR];
    }];
    UIAlertAction *saveImage = [UIAlertAction actionWithTitle:LMLocalizedString(@"Wallet Save to Photos", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [self saveImageToIphone];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {

    }];
    [alertController addAction:shareToFriend];
    [alertController addAction:saveImage];
    [alertController addAction:cancel];
    [self presentViewController:alertController animated:YES completion:nil];

}

- (void)showAlertView {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:LMLocalizedString(@"Link Refresh QR tip", nil) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *sureAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [self setQRNet:NO];
    }];
    [alertController addAction:sureAction];
    [alertController addAction:cancelAction];
    [self presentViewController:alertController animated:YES completion:nil];
}


- (void)saveImageToIphone {
    UIImageWriteToSavedPhotosAlbum([self formartExportImage], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);

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

#pragma mark - formart export image

- (UIImage *)formartExportImage {
    UIView *exportFortView = [[UIView alloc] init];
    exportFortView.frame = [UIScreen mainScreen].bounds;

    UIImageView *groupImageView = [[UIImageView alloc] init];
    groupImageView.image = self.groupHeaderImageView.image;
    [exportFortView addSubview:groupImageView];
    groupImageView.frame = AUTO_RECT(100, 150, 120, 120);

    UILabel *groupName = [[UILabel alloc] init];
    [exportFortView addSubview:groupName];
    groupName.text = self.groupNameLable.text;
    groupName.top = groupImageView.top;
    groupName.right = groupImageView.right + 10;
    groupName.width = exportFortView.width - (groupImageView.right + 10);
    groupName.height = groupImageView.height;
    groupName.textAlignment = NSTextAlignmentLeft;
    groupName.textColor = LMBasicBlack;
    groupName.font = [UIFont systemFontOfSize:FONT_SIZE(24)];


    UIImageView *QRImageView = [[UIImageView alloc] initWithImage:self.QRImageView.image];
    QRImageView.frame = AUTO_RECT(100, 300, DEVICE_SIZE.width - 200, DEVICE_SIZE.width - 200);
    [exportFortView addSubview:QRImageView];

    UIImage *image = [exportFortView screenShot];

    return image;
}

/**
  share
 */
- (void)shareGroupQR {
    __weak typeof(self) weakSelf = self;
    GroupId *groupId = [[GroupId alloc] init];
    groupId.identifier = self.talkModel.chatIdendifier;
    [NetWorkOperationTool POSTWithUrlString:GroupShareUrl postProtoData:groupId.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *) response;
        if (hResponse.code != successCode) { //非公开，不可以分享
            [[GroupDBManager sharedManager] setGroupNeedNotPublic:weakSelf.talkModel.chatIdendifier];
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Link The group is not public Not Share", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                return;
            }];
        } else {                               //公开，可以分享
            NSData *data = [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                [[GroupDBManager sharedManager] setGroupNeedPublic:weakSelf.talkModel.chatIdendifier];
                GroupUrl *qrUrl = [GroupUrl parseFromData:data error:nil];
                if (qrUrl.URL.length <= 0) {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Share failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                        return;
                    }];
                }
                [self shareAction:qrUrl.URL];
            }
        }
    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Share failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            return;
        }];
    }];
}

- (void)shareAction:(NSString *)url {
    NSString *title = [NSString stringWithFormat:
                       LMLocalizedString(@"Link invite you to start encrypted chat with Connect", nil), [[LKUserCenter shareCenter] currentLoginUser].username];
    NSURL* urls = [NSURL URLWithString:url];
    UIImage *image = self.groupHeaderImageView.image;
    if (!image) {
        image = [UIImage imageNamed:@"default_user_avatar"];
    }
    UIActivityViewController *activeViewController = [[UIActivityViewController alloc] initWithActivityItems:@[title, urls, image] applicationActivities:nil];
    
    activeViewController.excludedActivityTypes = @[UIActivityTypeAirDrop, UIActivityTypeCopyToPasteboard, UIActivityTypeAddToReadingList];
    [self presentViewController:activeViewController animated:YES completion:nil];
    
    UIActivityViewControllerCompletionWithItemsHandler myblock = ^(NSString *__nullable activityType, BOOL completed, NSArray *__nullable returnedItems, NSError *__nullable activityError) {
        NSLog(@"%d %@", completed, activityType);
    };
    activeViewController.completionWithItemsHandler = myblock;
}

- (void)setQRNet:(BOOL)flag {
    [self creatActivityView];
    __weak typeof(self) weakSelf = self;
    GroupId *groupId = [[GroupId alloc] init];
    groupId.identifier = self.talkModel.chatGroupInfo.groupIdentifer;
    NSString *url = GroupCreatQRUrl;
    if (flag == NO) {
        url = RefreshGroupCreatQRUrl;
    }

    [NetWorkOperationTool POSTWithUrlString:url postProtoData:groupId.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *) response;
        if (hResponse.code != successCode) {
            [GCDQueue executeInMainQueue:^{
                if (flag) {
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Link The group is not public", nil) withType:ToastTypeFail showInView:weakSelf.view complete:^{
                        
                        [weakSelf isNotPublic];
                    }];
                    return;
                } else {
                    [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Refresh QR code failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:^{
                        self.errorLable.hidden = NO;
                        self.errorLable.text = LMLocalizedString(@"Refresh QR code failed", nil);
                        [weakSelf.activityView stopAnimating];
                    }];
                    return;
                }
            }];
        } else {
            
            NSData *data = [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                GroupHash *hashGroup = [GroupHash parseFromData:data error:nil];
                if (hashGroup.hash_p.length > 0) {
                    self.errorLable.hidden = YES;
                    
                    [weakSelf reloadViewWithHash:hashGroup];
                } else {
                    
                    [weakSelf isNotPublic];

                }
            }
            [weakSelf.activityView stopAnimating];
        }
    }                                  fail:^(NSError *error) {
        
        [weakSelf.activityView stopAnimating];
        self.errorLable.hidden = NO;
        self.errorLable.text = LMLocalizedString(@"Server Error", nil);
    }];
}

- (void)isNotPublic {
    [self.activityView stopAnimating];
    self.errorLable.hidden = NO;
    self.errorLable.text = LMLocalizedString(@"Link The group is not public", nil);
}

- (void)creatActivityView {
    [self.activityView startAnimating];
    [self.activityView setHidesWhenStopped:YES];
}


- (void)showServerError {
    self.errorLable.hidden = NO;
    self.errorLable.text = nil;

}

- (void)reloadViewWithHash:(GroupHash *)hashGroup {
    [self creatQR:hashGroup.hash_p];
    [self creatRightButton];

}

- (void)creatQR:(NSString *)string {
    self.QRImageView.image = [BarCodeTool barCodeImageWithString:string withSize:(DEVICE_SIZE.width - 130)];
}

- (void)dealloc {
    [self.activityView removeFromSuperview];
    self.activityView = nil;
}
@end

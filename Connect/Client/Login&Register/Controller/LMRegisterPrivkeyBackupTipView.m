//
//  LMRegisterPrivkeyBackupTipView.m
//  Connect
//
//  Created by MoHuilin on 2016/12/20.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "LMRegisterPrivkeyBackupTipView.h"
#import "BarCodeTool.h"
#import <MessageUI/MessageUI.h>
#import "UIView+ScreenShot.h"
#import "ConnectButton.h"
#import "UIImage+Color.h"

@interface LMRegisterPrivkeyBackupTipView () <MFMailComposeViewControllerDelegate>

@property(weak, nonatomic) IBOutlet UIImageView *privkeyQrImageView;
@property(weak, nonatomic) IBOutlet ConnectButton *startChatButton;
@property(weak, nonatomic) IBOutlet UIButton *backPrivateButton;
@property(weak, nonatomic) IBOutlet UILabel *subTitleLabel;
@property(weak, nonatomic) IBOutlet UILabel *detailLabel;
@property(weak, nonatomic) IBOutlet UILabel *titleLabel;
// Conventional constraints
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *privkeyQrImageHeightConstaton;

@end

@implementation LMRegisterPrivkeyBackupTipView

- (IBAction)startChatAction:(id)sender {
    [LKUserCenter shareCenter].isFristLogin = NO;
    self.alpha = 0;
    self.controller = nil;
    [self removeFromSuperview];
}

- (void)awakeFromNib {
    [super awakeFromNib];
    if (GJCFSystemiPhone5 || GJCFSystemiPhone6) {
        self.privkeyQrImageHeightConstaton.constant = DEVICE_SIZE.width - 140;
    } else if ([UIScreen mainScreen].bounds.size.width > 390 && [UIScreen mainScreen].bounds.size.width < 444) //6p
    {
        self.privkeyQrImageHeightConstaton.constant = DEVICE_SIZE.width - 140;
    } else   //ipad
    {
        self.privkeyQrImageHeightConstaton.constant = 100;
    }

    self.privkeyQrImageView.image = [BarCodeTool barCodeImageWithString:[[LKUserCenter shareCenter] currentLoginUser].prikey withSize:200];
    self.subTitleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(34)];
    self.subTitleLabel.text = LMLocalizedString(@"Login Decrypted private key", nil);

    self.detailLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.detailLabel.text = LMLocalizedString(@"Login export prikey explain", nil);
    self.titleLabel.text = LMLocalizedString(@"Set Backup Private Key", nil);
    [self.startChatButton setTitle:LMLocalizedString(@"Set Start encrypted messaging", nil) forState:UIControlStateNormal];
    [self.backPrivateButton setTitle:LMLocalizedString(@"Set Backup Private Key", nil) forState:UIControlStateNormal];
    self.backPrivateButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];

    [self.startChatButton setBackgroundImage:[UIImage imageWithColor:LMBasicBlue] forState:UIControlStateNormal];
    self.startChatButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
    self.startChatButton.layer.cornerRadius = 4;
    self.startChatButton.layer.masksToBounds = YES;

}

- (IBAction)backupPrivateAction:(id)sender {
    UIViewController *currentVc = [[UIViewController alloc] init];
    currentVc.view.backgroundColor = [UIColor clearColor];
    currentVc.view.frame = self.bounds;
    [self addSubview:currentVc.view];
    __weak __typeof(&*self) weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *savePhoneImage = [UIAlertAction actionWithTitle:LMLocalizedString(@"Wallet Save to Photos", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [weakSelf tapSaveImageToIphone];
        [currentVc.view removeFromSuperview];
        currentVc.view = nil;

    }];
    UIAlertAction *sendToMail = [UIAlertAction actionWithTitle:LMLocalizedString(@"Set Send it to mailbox", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [weakSelf sendToEmail];
        [currentVc.view removeFromSuperview];
        currentVc.view = nil;
    }];
    UIAlertAction *cancleAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action) {
        [currentVc.view removeFromSuperview];
        currentVc.view = nil;
    }];
    [alertController addAction:savePhoneImage];
    [alertController addAction:sendToMail];
    [alertController addAction:cancleAction];
    [currentVc presentViewController:alertController animated:YES completion:nil];
}

- (void)sendToEmail {

    // Determine whether the device can send mail
    if (![MFMailComposeViewController canSendMail]) {
        [MBProgressHUD showToastwithText:LMLocalizedString(@"Set Call failed please check system mail application", nil) withType:ToastTypeFail showInView:self complete:nil];
        return;
    }

    MFMailComposeViewController *controller = [[MFMailComposeViewController alloc] init];
    if (!controller) {
        return;
    }
    controller.mailComposeDelegate = self;
    [controller setSubject:LMLocalizedString(@"Set Export Private Key", nil)];
    [controller setMessageBody:LMLocalizedString(@"Set your private key should be properly kep", nil) isHTML:NO];
    UIImage *image = [self formartExportImage];

    [controller addAttachmentData:UIImagePNGRepresentation(image) mimeType:@"image/" fileName:@"qrcode"];

    [self.controller presentViewController:controller animated:YES completion:^{

    }];
}

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error; {
    if (result == MFMailComposeResultSent) {
        DDLogInfo(@"It's away!");
    }
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)tapSaveImageToIphone {
    UIImageWriteToSavedPhotosAlbum([self formartExportImage], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);

}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {

    if (error == nil) {
        [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Save successful", nil) withType:ToastTypeSuccess showInView:self complete:^{

        }];
    } else {
        [MBProgressHUD showToastwithText:LMLocalizedString(@"Set Save Failed", nil) withType:ToastTypeFail showInView:self complete:^{

        }];
    }

}


#pragma mark - Format the exported image

- (UIImage *)formartExportImage {
    UIView *exportFortView = [[UIView alloc] init];
    exportFortView.frame = [UIScreen mainScreen].bounds;

    UIImageView *topLogoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_black_middle"]];
    [exportFortView addSubview:topLogoImageView];
    topLogoImageView.frame = AUTO_RECT(268, 51, 214, 52);
    topLogoImageView.centerX = exportFortView.centerX;


    UIImageView *imageView = [[UIImageView alloc] initWithImage:self.privkeyQrImageView.image];
    imageView.frame = self.privkeyQrImageView.frame;
    [exportFortView addSubview:imageView];

    UILabel *tipLabel = [[UILabel alloc] init];
    [exportFortView addSubview:tipLabel];
    tipLabel.text = LMLocalizedString(@"Set Private key backup", nil);
    tipLabel.top = imageView.bottom + AUTO_HEIGHT(20);
    tipLabel.width = exportFortView.width;
    tipLabel.height = 30;
    tipLabel.textAlignment = NSTextAlignmentCenter;
    tipLabel.textColor = [UIColor colorWithWhite:0.800 alpha:1.000];


    NSString *nameTip = [NSString stringWithFormat:@"Name:\n%@", [[LKUserCenter shareCenter] currentLoginUser].username];
    NSMutableAttributedString *nameAttrString = [[NSMutableAttributedString alloc] initWithString:nameTip];
    [nameAttrString addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:FONT_SIZE(30)]
                           range:NSMakeRange(0, @"Name:".length)];
    [nameAttrString addAttribute:NSForegroundColorAttributeName
                           value:[UIColor colorWithWhite:0.800 alpha:1.000]
                           range:NSMakeRange(0, @"Name:".length)];
    [nameAttrString addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:FONT_SIZE(40)]
                           range:NSMakeRange(@"Name:".length + 1, [[LKUserCenter shareCenter] currentLoginUser].username.length)];

    GJCFCoreTextContentView *nameTextView = [[GJCFCoreTextContentView alloc] init];
    nameTextView.frame = AUTO_RECT(50, 900, 600, 200);
    nameTextView.contentBaseSize = nameTextView.size;
    [exportFortView addSubview:nameTextView];
    nameTextView.contentAttributedString = nameAttrString;
    nameTextView.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:nameAttrString forBaseContentSize:nameTextView.contentBaseSize];

    NSString *addressTip = [NSString stringWithFormat:@"ID & Bitcoin Address:\n%@", [[LKUserCenter shareCenter] currentLoginUser].address];
    NSMutableAttributedString *addressAttrString = [[NSMutableAttributedString alloc] initWithString:addressTip];
    [addressAttrString addAttribute:NSFontAttributeName
                              value:[UIFont systemFontOfSize:FONT_SIZE(30)]
                              range:NSMakeRange(0, @"ID & Bitcoin Address:".length)];
    [addressAttrString addAttribute:NSForegroundColorAttributeName
                              value:[UIColor colorWithWhite:0.800 alpha:1.000]
                              range:NSMakeRange(0, @"ID & Bitcoin Address:".length)];
    [addressAttrString addAttribute:NSFontAttributeName
                              value:[UIFont systemFontOfSize:FONT_SIZE(28)]
                              range:NSMakeRange(@"ID & Bitcoin Address:".length + 1, [[LKUserCenter shareCenter] currentLoginUser].address.length)];

    GJCFCoreTextContentView *addressTextView = [[GJCFCoreTextContentView alloc] init];
    addressTextView.frame = AUTO_RECT(50, 1010, 600, 200);
    addressTextView.contentBaseSize = addressTextView.size;
    [exportFortView addSubview:addressTextView];
    addressTextView.contentAttributedString = addressAttrString;
    addressTextView.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:addressAttrString forBaseContentSize:addressTextView.contentBaseSize];


    NSString *connect = LMLocalizedString(@"app name im", nil);


    NSMutableAttributedString *connectAttrString = [[NSMutableAttributedString alloc] initWithString:connect];
    [connectAttrString addAttribute:NSFontAttributeName
                              value:[UIFont systemFontOfSize:FONT_SIZE(30)]
                              range:NSMakeRange(0, connect.length)];

    [connectAttrString addAttribute:NSForegroundColorAttributeName
                              value:[UIColor colorWithWhite:0.800 alpha:1.000]
                              range:NSMakeRange(0, connect.length)];

    GJCFCoreTextContentView *connectTextView = [[GJCFCoreTextContentView alloc] init];
    connectTextView.frame = AUTO_RECT(0, 1200, 280, 38);
    connectTextView.right = exportFortView.right - AUTO_WIDTH(20);
    connectTextView.contentBaseSize = connectTextView.size;
    [exportFortView addSubview:connectTextView];
    connectTextView.contentAttributedString = connectAttrString;
    connectTextView.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:connectAttrString forBaseContentSize:connectTextView.contentBaseSize];


    UIImage *image = [exportFortView screenShot];

    return image;
}


@end

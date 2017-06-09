//
//  ExportEncodePrivkeyPage.m
//  Connect
//
//  Created by MoHuilin on 16/7/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ExportEncodePrivkeyPage.h"
#import "BarCodeTool.h"
#import <MessageUI/MessageUI.h>
#import "UIView+ScreenShot.h"
#import "MainTabController.h"
#import "ConnectButton.h"
#import "UIImage+Color.h"
#import "NSData+Base64.h"

@interface ExportEncodePrivkeyPage () <MFMailComposeViewControllerDelegate>

@property(nonatomic, strong) UIImageView *encodePrivkeyImageView;

@property(nonatomic, strong) UILabel *backupTiplabel; // tips

@property(nonatomic, strong) GJCFCoreTextContentView *passTipTextView;

@property(nonatomic, strong) GJCFCoreTextContentView *tipTextView;

@property(strong, nonatomic) UIButton *changeExportWayButton;

@end

@implementation ExportEncodePrivkeyPage


- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNavigationRight:@"menu_white"];
    self.view.backgroundColor = LMBasicBackgroudGray;
    self.title = LMLocalizedString(@"Set Export Private Key", nil);
    
}

- (void)doRight:(UIButton *)sender {
    __weak __typeof(&*self) weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *Encrypted = [UIAlertAction actionWithTitle:LMLocalizedString(@"Login Encrypted private key", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        weakSelf.changeExportWayButton.selected = NO;
        [weakSelf buttonSelectedChoiced];
        [weakSelf.view layoutIfNeeded];// refresh

    }];
    UIAlertAction *Unencrypted = [UIAlertAction actionWithTitle:LMLocalizedString(@"Login Decrypted private key", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        weakSelf.changeExportWayButton.selected = YES;
        [weakSelf buttonNormalAction];
        [weakSelf.view layoutIfNeeded];// refresh

    }];
    UIAlertAction *cancleAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];

    [alertController addAction:Encrypted];
    [alertController addAction:Unencrypted];
    [alertController addAction:cancleAction];
    [weakSelf presentViewController:alertController animated:YES completion:nil];


}

- (void)sendToEmail {

    // Determine whether the device can send mail
    if (![MFMailComposeViewController canSendMail]) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Set Call failed please check system mail application", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            }];
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
    [self presentViewController:controller animated:YES completion:nil];

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

    [GCDQueue executeInMainQueue:^{
        [MBProgressHUD showMessage:LMLocalizedString(@"Common Loading", nil) toView:self.view];
    }];
    UIImageWriteToSavedPhotosAlbum([self formartExportImage], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);

}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    if (error == nil) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Save successful", nil) withType:ToastTypeSuccess showInView:self.view complete:nil];
        }];

    } else {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Set Save Failed", nil) withType:ToastTypeFail showInView:self.view complete:nil];
        }];
    }
}

- (void)setup {

    AccountInfo *loginUser = [[LKUserCenter shareCenter] currentLoginUser];

    //imagview
    UIImageView *encodePrivkeyImageView = [[UIImageView alloc] init];
    self.encodePrivkeyImageView = encodePrivkeyImageView;

    [self.view addSubview:encodePrivkeyImageView];
    encodePrivkeyImageView.backgroundColor = [UIColor whiteColor];
    encodePrivkeyImageView.frame = AUTO_RECT(0, 247, 500, 500);
    encodePrivkeyImageView.centerX = self.view.centerX;
    NSString *exportContent = loginUser.prikey;
    encodePrivkeyImageView.image = [BarCodeTool barCodeImageWithString:exportContent withSize:encodePrivkeyImageView.width];


    //imageview 下的lable
    self.backupTiplabel = [[UILabel alloc] init];
    [self.view addSubview:self.backupTiplabel];
    _backupTiplabel.text = LMLocalizedString(@"Chat Unencrypted", nil);
    _backupTiplabel.textAlignment = NSTextAlignmentCenter;
    _backupTiplabel.frame = AUTO_RECT(0, 0, 750, 50);
    _backupTiplabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
    _backupTiplabel.textColor = LMBasicDarkGray;
    _backupTiplabel.top = encodePrivkeyImageView.bottom + AUTO_HEIGHT(10);

    //button
    ConnectButton *changeExportWayButton = [[ConnectButton alloc] initWithNormalTitle:LMLocalizedString(@"Set Backup encrypted private key", nil) disableTitle:nil];
    [changeExportWayButton setTitleColor:[UIColor colorWithRed:0.000 green:0.502 blue:1.000 alpha:1.000] forState:UIControlStateNormal];
    [changeExportWayButton setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor]] forState:UIControlStateNormal];
    [changeExportWayButton setBackgroundImage:[UIImage imageWithColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
    [changeExportWayButton setTitle:LMLocalizedString(@"Set Backup Private Key", nil) forState:UIControlStateSelected];
    [changeExportWayButton addTarget:self action:@selector(changeExportImage:) forControlEvents:UIControlEventTouchUpInside];
    changeExportWayButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    [self.view addSubview:changeExportWayButton];
    self.changeExportWayButton = changeExportWayButton;
    changeExportWayButton.frame = CGRectMake(AUTO_WIDTH(30), _backupTiplabel.bottom + AUTO_HEIGHT(100), DEVICE_SIZE.width - AUTO_WIDTH(30) * 2, AUTO_HEIGHT(100));

    NSString *tipString = LMLocalizedString(@"Login export prikey explain", nil);
    NSMutableAttributedString *tipAttrString = [[NSMutableAttributedString alloc] initWithString:tipString];
    [tipAttrString addAttribute:NSFontAttributeName
                          value:[UIFont systemFontOfSize:FONT_SIZE(28)]
                          range:NSMakeRange(0, tipString.length)];
    GJCFCoreTextContentView *tipTextView = [[GJCFCoreTextContentView alloc] init];
    self.tipTextView = tipTextView;
    tipTextView.frame = AUTO_RECT(50, 810, 700, 200);
    tipTextView.top = self.changeExportWayButton.bottom + AUTO_HEIGHT(30);
    tipTextView.contentBaseSize = tipTextView.size;
    [self.view addSubview:tipTextView];
    tipTextView.contentAttributedString = tipAttrString;
    tipTextView.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:tipAttrString forBaseContentSize:tipTextView.contentBaseSize];
    [self buttonSelectedChoiced];

}

#pragma mark - button exchange

- (void)changeExportImage:(UIButton *)sender {
    __weak __typeof(&*self) weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *savePhoneImage = [UIAlertAction actionWithTitle:LMLocalizedString(@"Wallet Save to Photos", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [weakSelf tapSaveImageToIphone];
    }];
    UIAlertAction *sendToMail = [UIAlertAction actionWithTitle:LMLocalizedString(@"Set Send it to mailbox", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [weakSelf sendToEmail];
    }];
    UIAlertAction *cancleAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];

    [alertController addAction:savePhoneImage];
    [alertController addAction:sendToMail];
    [alertController addAction:cancleAction];
    [weakSelf presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - button click button action

// join chat page
- (void)skipAction {
    [self.view removeFromSuperview];
    [GCDQueue executeInMainQueue:^{
        [UIApplication sharedApplication].keyWindow.rootViewController = [[MainTabController alloc] init];
    }];
}

- (void)buttonSelectedChoiced {

    self.backupTiplabel.text = LMLocalizedString(@"Chat Encrypted", nil);
    NSString *tipString = LMLocalizedString(@"Login export encrypted prikey explain", nil);
    NSMutableAttributedString *tipAttrString = [[NSMutableAttributedString alloc] initWithString:tipString];
    [tipAttrString addAttribute:NSFontAttributeName
                          value:[UIFont systemFontOfSize:FONT_SIZE(28)]
                          range:NSMakeRange(0, tipString.length)];
    self.tipTextView.contentAttributedString = tipAttrString;
    self.tipTextView.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:tipAttrString forBaseContentSize:self.tipTextView.contentBaseSize];

    AccountInfo *loginUser = [[LKUserCenter shareCenter] currentLoginUser];
    NSString *connectid = loginUser.contentId;
    if ([connectid isEqualToString:loginUser.address]) {
        connectid = @"";
    }


    ExoprtPrivkeyQrcode *exportQrcode = [ExoprtPrivkeyQrcode new];
    exportQrcode.username = loginUser.username;
    exportQrcode.version = 2;
    exportQrcode.encriptionPri = loginUser.encryption_pri;
    exportQrcode.passwordHint = loginUser.password_hint;
    NSString *phone = loginUser.bondingPhone;
    if ([phone containsString:@"-"]) {
        NSString *code = [[phone componentsSeparatedByString:@"-"] firstObject];
        NSString *lastPhone = [[phone componentsSeparatedByString:@"-"] lastObject];
        if (lastPhone.length > 1) {
            lastPhone = [lastPhone substringFromIndex:lastPhone.length/2.0 - 1];
            phone = [NSString stringWithFormat:@"%@**%@", code, lastPhone];
            exportQrcode.phone = phone;
        }
    } else {
        phone = loginUser.bondingPhone;
    }
    NSString *avatar = loginUser.avatar;
    if ([avatar hasPrefix:@"http"]) {
        NSString *token = [avatar lastPathComponent];
        token = [token stringByReplacingOccurrencesOfString:@".jpg" withString:@""];
        exportQrcode.avatar = token;
    }
    exportQrcode.phone = phone;
    exportQrcode.connectId = loginUser.contentId;
    NSString *exportContent = [exportQrcode.data base64EncodedString];
    self.encodePrivkeyImageView.image = [BarCodeTool barCodeImageWithString:[NSString stringWithFormat:@"connect://%@", exportContent] withSize:self.encodePrivkeyImageView.width];
}

#pragma mark - button normal action

- (void)buttonNormalAction {
    self.backupTiplabel.text = LMLocalizedString(@"Chat Unencrypted", nil);
    NSString *tipString = LMLocalizedString(@"Login export prikey explain", nil);
    NSMutableAttributedString *tipAttrString = [[NSMutableAttributedString alloc] initWithString:tipString];
    [tipAttrString addAttribute:NSFontAttributeName
                          value:[UIFont systemFontOfSize:FONT_SIZE(28)]
                          range:NSMakeRange(0, tipString.length)];
    self.tipTextView.contentAttributedString = tipAttrString;
    self.tipTextView.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:tipAttrString forBaseContentSize:self.tipTextView.contentBaseSize];
    self.encodePrivkeyImageView.image = [BarCodeTool barCodeImageWithString:[[LKUserCenter shareCenter] currentLoginUser].prikey withSize:self.encodePrivkeyImageView.width];
}

#pragma mark - Format the exported image

- (UIImage *)formartExportImage {
    UIView *exportFortView = [[UIView alloc] init];
    exportFortView.frame = [UIScreen mainScreen].bounds;

    UIImageView *topLogoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_black_middle"]];
    [exportFortView addSubview:topLogoImageView];
    topLogoImageView.frame = AUTO_RECT(268, 51, 214, 52);
    topLogoImageView.centerX = exportFortView.centerX;


    UIImageView *imageView = [[UIImageView alloc] initWithImage:self.encodePrivkeyImageView.image];
    imageView.frame = self.encodePrivkeyImageView.frame;
    [exportFortView addSubview:imageView];

    UILabel *tipLabel = [[UILabel alloc] init];
    [exportFortView addSubview:tipLabel];
    tipLabel.text = LMLocalizedString(@"Private Key Backup", nil);
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

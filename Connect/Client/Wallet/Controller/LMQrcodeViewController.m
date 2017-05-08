//
//  LMQrcodeViewController.m
//  Connect
//
//  Created by Edwin on 16/7/17.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMQrcodeViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "NetWorkOperationTool.h"
#import "UserDBManager.h"
#import "LMSetMoneyResultViewController.h"
#import "LMUnSetMoneyResultViewController.h"
#import "LMBitAddressViewController.h"
#import "NSURL+Param.h"
#import "HandleUrlManager.h"

#define scanViewWH (DEVICE_SIZE.width - 100)

#define animationDuration 0.2

typedef NS_ENUM(NSInteger, ScanMoneyType) {
    // pay friends
            ScanMoneyTypeSet = 0,
    // Beneficiary
            ScanMoneyTypeUnSet = 1,
};

@interface LMQrcodeViewController () <AVCaptureMetadataOutputObjectsDelegate, UIGestureRecognizerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property(nonatomic, strong) UIView *scanView;

@property(nonatomic, strong) AVCaptureSession *session;

@property(nonatomic, copy) NSString *resultContent;
@property(nonatomic, strong) NSDecimalNumber *money;
@property(nonatomic, assign) BOOL isFirstBecome;

@end

@implementation LMQrcodeViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!_isFirstBecome) {
        [self creatQRView];
        [_session startRunning];
        [self.view layoutIfNeeded];
    }

}

- (void)viewDidLoad {
    [super viewDidLoad];
    _isFirstBecome = YES;
    self.view.backgroundColor = XCColor(22, 26, 33);
    [self creatQRView];
    [self beginScanning];
    [self setNavigationRightWithTitle:LMLocalizedString(@"Chat Album", nil)];

}

- (void)doRight:(id)sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:imagePicker animated:YES completion:nil];
}


#pragma mark-> imagePickerController delegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    //1.Get the selected image
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    //2.Initialize a monitor
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyHigh}];

    [picker dismissViewControllerAnimated:YES completion:^{
        // The array of results is monitored
        NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];
        if (features.count >= 1) {
            CIQRCodeFeature *feature = [features objectAtIndexCheck:0];
            [self handleScanResult:feature.messageString];
        } else {
            [UIAlertController showAlertInViewController:self withTitle:LMLocalizedString(@"Set tip title", nil) message:LMLocalizedString(@"Wallet No qr code in the picture", nil) cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Common OK", nil)] tapBlock:^(UIAlertController *_Nonnull controller, UIAlertAction *_Nonnull action, NSInteger buttonIndex) {

            }];
        }
    }];
}


- (void)creatQRView {
    [self.view addSubview:self.scanView];
    _scanView.layer.cornerRadius = 15;
    _scanView.layer.masksToBounds = YES;
    _scanView.size = CGSizeMake(scanViewWH, scanViewWH);
    _scanView.centerX = self.view.centerX;
    _scanView.top = self.view.top + AUTO_HEIGHT(180);
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects.count > 0) {
        [_session stopRunning];
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndexCheck:0];
        [self handleScanResult:metadataObject.stringValue];
    }
}

- (void)handleScanResult:(NSString *)resultStr {
    if ([resultStr hasPrefix:@"http"]) {
        NSDictionary *parameters = [[NSURL URLWithString:resultStr] parameters];
        NSString *token = [parameters valueForKey:@"token"];
        if (!GJCFStringIsNull(token)) {
            if ([resultStr containsString:@"transfer"]) {
                NSString *urlString = [NSString stringWithFormat:@"connectim://transfer?token=%@", token];
                [HandleUrlManager handleOpenURL:[NSURL URLWithString:urlString]];
            } else if ([resultStr containsString:@"luckypacket"]) {
                NSString *urlString = [NSString stringWithFormat:@"connectim://packet?token=%@", token];
                [HandleUrlManager handleOpenURL:[NSURL URLWithString:urlString]];
            }
        } else {
            if (self.didGetScanResult) {
                self.didGetScanResult(nil, [NSError errorWithDomain:@"Parameter error" code:404 userInfo:nil]);
            }
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        if (self.isScanAddressBook) {
            if (self.didGetScanResult) {
                self.didGetScanResult(resultStr, nil);
            }
            [self.navigationController popViewControllerAnimated:YES];
        } else {
            [MBProgressHUD showLoadingMessageToView:self.view];
            if ([resultStr containsString:@"bitcoin:"] && [resultStr containsString:@"?amount"]) {
                NSString *parm = [resultStr substringFromIndex:[resultStr rangeOfString:@"?"].location + 1];
                NSString *key = [parm componentsSeparatedByString:@"="].firstObject;
                NSString *amount = [parm substringFromIndex:(key.length + 1)];
                NSString *address = [resultStr substringWithRange:NSMakeRange([resultStr rangeOfString:@":"].location + 1, [resultStr rangeOfString:@"?"].location - [resultStr rangeOfString:@":"].location - 1)];
                self.resultContent = address;
                self.money = [NSDecimalNumber decimalNumberWithString:amount];
            } else {
                self.resultContent = resultStr;
            }
            if (self.money.doubleValue > 0) {
                [self GetMoneyUserInfo];
            } else {
                [self GetUserInfo];
            }
        }
    }
}

- (void)GetUserInfo {
    __weak typeof(self) weakSelf = self;
    self.resultContent = [self.resultContent stringByReplacingOccurrencesOfString:@"bitcoin:" withString:@""];
    if (![KeyHandle checkAddress:self.resultContent]) {
        [MBProgressHUD hideHUDForView:self.view];
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Result is not a bitcoin address", nil) withType:ToastTypeFail showInView:weakSelf.view complete:^{
                [weakSelf.navigationController popViewControllerAnimated:YES];
            }];
        }];
        return;
    }
    AccountInfo *info = [[UserDBManager sharedManager] getUserByAddress:self.resultContent];
    if (info) {
        [MBProgressHUD hideHUDForView:self.view];
        LMUnSetMoneyResultViewController *unsetVc = [[LMUnSetMoneyResultViewController alloc] init];
        unsetVc.info = info;
        [self.navigationController pushViewController:unsetVc animated:YES];
        _isFirstBecome = NO;
    } else {
        [self baseQRcodeResultAddressSearchUserInformation:self.resultContent ScanMoneyType:ScanMoneyTypeUnSet];
        _isFirstBecome = NO;
    }
}

- (void)GetMoneyUserInfo {
    __weak typeof(self) weakSelf = self;
    if (![KeyHandle checkAddress:self.resultContent]) {
        [MBProgressHUD hideHUDForView:self.view];
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Result is not a bitcoin address", nil) withType:ToastTypeFail showInView:weakSelf.view complete:^{
                [weakSelf.navigationController popViewControllerAnimated:YES];
            }];
        }];
        return;
    }

    AccountInfo *info = [[UserDBManager sharedManager] getUserByAddress:self.resultContent];
    if (info) {
        [MBProgressHUD hideHUDForView:self.view];
        LMSetMoneyResultViewController *unsetVc = [[LMSetMoneyResultViewController alloc] init];
        unsetVc.info = info;
        unsetVc.trasferAmount = self.money;
        [self.navigationController pushViewController:unsetVc animated:YES];
        _isFirstBecome = NO;
    } else {
        [self baseQRcodeResultAddressSearchUserInformation:self.resultContent ScanMoneyType:ScanMoneyTypeSet];
        _isFirstBecome = NO;
    }
}

#pragma mark -- According to the scanned address to query the user information

- (void)baseQRcodeResultAddressSearchUserInformation:(NSString *)address ScanMoneyType:(ScanMoneyType)type {
    [GCDQueue executeInGlobalQueue:^{
        __weak __typeof(&*self) weakSelf = self;
        SearchUser *usrAddInfo = [[SearchUser alloc] init];
        usrAddInfo.criteria = address;
        [NetWorkOperationTool POSTWithUrlString:ContactUserSearchUrl postProtoData:usrAddInfo.data complete:^(id response) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD hideHUDForView:weakSelf.view];
            }];
            NSError *error;
            HttpResponse *respon = (HttpResponse *) response;

            if (respon.code == 2404) {

                LMBitAddressViewController *page = [[LMBitAddressViewController alloc] init];
                page.address = address;
                page.hidesBottomBarWhenPushed = YES;
                [weakSelf.navigationController pushViewController:page animated:YES];
                return;
            }

            if (respon.code != successCode) {
                return;
            }

            NSData *data = [ConnectTool decodeHttpResponse:respon];
            if (data) {
                // User Info
                UserInfo *info = [[UserInfo alloc] initWithData:data error:&error];
                AccountInfo *accoutInfo = [[AccountInfo alloc] init];
                accoutInfo.username = info.username;
                accoutInfo.avatar = info.avatar;
                accoutInfo.pub_key = info.pubKey;
                accoutInfo.address = info.address;
                if (type == ScanMoneyTypeSet) {
                    // Jump to the setting amount page
                    LMSetMoneyResultViewController *unsetVc = [[LMSetMoneyResultViewController alloc] init];
                    unsetVc.info = accoutInfo;
                    if ([self.money doubleValue] > 0) {
                        unsetVc.trasferAmount = self.money;
                    }
                    [self.navigationController pushViewController:unsetVc animated:YES];
                    _isFirstBecome = NO;
                } else {
                    // Jump to the setting amount page
                    LMUnSetMoneyResultViewController *unsetVc = [[LMUnSetMoneyResultViewController alloc] init];
                    unsetVc.info = accoutInfo;
                    [self.navigationController pushViewController:unsetVc animated:YES];
                    _isFirstBecome = NO;
                }

                if (error) {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"ErrorCode Error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                    }];

                }
            }
        }                                  fail:^(NSError *error) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD hideHUDForView:weakSelf.view];
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Server Error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
        }];
    }];
}

/**
 *  set beginScan
 */
- (void)beginScanning {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    if (!input) return;
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    output.rectOfInterest = _scanView.bounds;
    _session = [[AVCaptureSession alloc] init];
    [_session setSessionPreset:AVCaptureSessionPresetHigh];

    [_session addInput:input];
    [_session addOutput:output];
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];

    AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.frame = self.scanView.layer.bounds;
    [self.scanView.layer insertSublayer:layer atIndex:0];
    [_session startRunning];
}

#pragma mark - getter setter

- (UIView *)scanView {
    if (!_scanView) {
        _scanView = [UIView new];
    }
    return _scanView;
}

@end

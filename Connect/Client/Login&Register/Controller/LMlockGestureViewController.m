//
//  LMlockGestureViewController.m
//  Connect
//
//  Created by Connect on 2017/5/11.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMlockGestureViewController.h"
#import "GestureLockView.h"
#import "GestureThumbView.h"

#define MAX_TRYTIME  (int)4
#define MAX_SPACE_TIME (int)30

@interface LMlockGestureViewController ()<GestureLockViewDelegate>

@property(nonatomic, strong) UIImageView *lockViewShotView;

@property(nonatomic, strong) GestureThumbView *thumbView;

@property(nonatomic, strong) UILabel *tipLabel;

@property(nonatomic, strong) GestureLockView *gestureLockView;

@property(nonatomic, copy) NSString *firstLockPath;

@property(nonatomic, weak) UITextField *passTextField;

@property(nonatomic, strong) UIButton *loginPassButton;

@property(nonatomic, assign) int tryTimes;

@property(nonatomic, copy) void (^ComleteBlock )(BOOL result);

@end

@implementation LMlockGestureViewController
#pragma mark - system methods
- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = XCColor(241, 241, 241);
    
    NSTimeInterval erroTime = [[MMAppSetting sharedSetting] getLastErroGestureTime];
    if (erroTime > 0) {
        NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
        if (currentTime - erroTime > MAX_SPACE_TIME) { // More than 30 seconds can try again
            [[MMAppSetting sharedSetting] removeLastErroGestureTime];
        } else {
            __weak __typeof(&*self) weakSelf = self;
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:[NSString stringWithFormat:LMLocalizedString(@"Set Please try again after seconds", nil), (int) (MAX_SPACE_TIME - (currentTime - erroTime))] withType:ToastTypeFail showInView:weakSelf.view complete:^{
                    [weakSelf.navigationController popViewControllerAnimated:YES];
                }];
            }];
            
        }
    }
}
- (void)dealloc {
    self.gestureLockView.delegate = nil;
    [self.gestureLockView removeFromSuperview];
    self.gestureLockView = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self.view endEditing:YES];
    
}
- (instancetype)initWithAction:(void (^)(BOOL))complete {
    if (self = [super init]) {
        self.ComleteBlock = complete;
    }
    
    return self;
}
#pragma mark - lazy
- (UIButton *)loginPassButton {
    if (!_loginPassButton) {
        _loginPassButton = [[UIButton alloc] init];
        [_loginPassButton setTitle:LMLocalizedString(@"Set Use Login Password", nil) forState:UIControlStateNormal];
        [_loginPassButton setTitleColor:[UIColor colorWithRed:0.200 green:0.576 blue:0.965 alpha:1.000] forState:UIControlStateNormal];
        _loginPassButton.bottom = DEVICE_SIZE.height - 45;
        _loginPassButton.width = DEVICE_SIZE.width;
        _loginPassButton.height = AUTO_HEIGHT(45);
        _loginPassButton.left = 0;
        _loginPassButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
        [_loginPassButton addTarget:self action:@selector(loginPassAction) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _loginPassButton;
}

#pragma mark - common methods
- (void)loginPassAction{
    
    __weak __typeof(&*self) weakSelf = self;
    AccountInfo *loginUser = [[LKUserCenter shareCenter] currentLoginUser];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Set Enter Login Password", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.secureTextEntry = YES;
        weakSelf.passTextField = textField;
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        
        [GCDQueue executeInGlobalQueue:^{
            
            weakSelf.navigationController.view.userInteractionEnabled = NO;
            NSDictionary *decodeDict = [KeyHandle decodePrikeyGetDict:loginUser.encryption_pri withPassword:weakSelf.passTextField.text];
            weakSelf.navigationController.view.userInteractionEnabled = YES;
            
            if (decodeDict) {
                
                [GCDQueue executeInMainQueue:^{
                    weakSelf.tipLabel.textColor = [UIColor colorWithRed:0.400 green:1.000 blue:0.400 alpha:1.000];
                    weakSelf.tipLabel.hidden = YES;
                    weakSelf.tipLabel.text = LMLocalizedString(@"Set Verify Success", nil);
                    [MBProgressHUD showToastwithText:weakSelf.tipLabel.text withType:ToastTypeSuccess showInView:weakSelf.view complete:nil];
                }];
                
                if (self.ComleteBlock) {
                    self.ComleteBlock(YES);
                }

            } else {
                [GCDQueue executeInMainQueue:^{
                    weakSelf.tipLabel.textColor = [UIColor redColor];
                    weakSelf.tipLabel.text = LMLocalizedString(@"Login Password incorrect", nil);
                    weakSelf.tipLabel.hidden = YES;
                    [MBProgressHUD showToastwithText:weakSelf.tipLabel.text withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                }];
                if (self.ComleteBlock) {
                    self.ComleteBlock(NO);
                }
            }
        }];
        
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    [self presentViewController:alertController animated:YES completion:nil];
    
}
- (void)setup {
    
    
    UIImageView *lockViewShotView = [[UIImageView alloc] init];
    lockViewShotView.image = [UIImage imageNamed:@"setting_gesture_default"];
    lockViewShotView.frame = AUTO_RECT(323, 250, 104, 104);
    self.lockViewShotView = lockViewShotView;
    
    GestureThumbView *thumbView = [[GestureThumbView alloc] initWithFrame:AUTO_RECT(323, 250, 104, 104)];
    self.thumbView = thumbView;
    [self.view addSubview:thumbView];
    
    UILabel *tipLabel = [[UILabel alloc] init];
    tipLabel.textAlignment = NSTextAlignmentCenter;
    tipLabel.top = lockViewShotView.bottom + 10;
    tipLabel.width = DEVICE_SIZE.width;
    tipLabel.height = AUTO_HEIGHT(40);
    tipLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.tipLabel.hidden = NO;
    [self.view addSubview:tipLabel];
    self.tipLabel = tipLabel;
    
    GestureLockView *lockView = [[GestureLockView alloc] initWithFrame:CGRectMake(0, tipLabel.bottom + AUTO_HEIGHT(96), AUTO_WIDTH(538), AUTO_HEIGHT(538))];
    lockView.centerX = self.view.centerX;
    lockView.backgroundColor = XCColor(241, 241, 241);
    lockView.delegate = self;
    [self.view addSubview:lockView];
    self.gestureLockView = lockView;
    
    [self reload];
}
/* refresh*/
- (void)reload {
   
        self.title = LMLocalizedString(@"Set Draw Pattern", nil);
        self.lockViewShotView.hidden = YES;
        self.tipLabel.text = LMLocalizedString(@"Set Draw your pattern", nil);
        self.tipLabel.textColor = [UIColor blackColor];
        self.tipLabel.hidden = NO;
        [self.view addSubview:self.loginPassButton];
    
}
- (void)lockView:(GestureLockView *)lockView didFinishPath:(NSString *)path {
    
    __weak typeof(self) weakSelf = self;
    if (path.length < 4) {
        self.tipLabel.textColor = [UIColor redColor];
        self.tipLabel.text = LMLocalizedString(@"Set Please connect at least 4 points", nil);
        self.tipLabel.hidden = YES;
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:weakSelf.tipLabel.text withType:ToastTypeCommon showInView:weakSelf.view complete:nil];
            
        }];
        return;
    }

    [self.thumbView reset];
    self.thumbView.password = path;
    
    if ([[MMAppSetting sharedSetting] vertifyGesturePass:path]) {
        self.tipLabel.textColor = [UIColor colorWithRed:0.400 green:1.000 blue:0.400 alpha:1.000];
        self.tipLabel.text = LMLocalizedString(@"Set Verify Success", nil);
        self.tipLabel.hidden = YES;
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:weakSelf.tipLabel.text withType:ToastTypeSuccess showInView:weakSelf.view complete:nil];
            
        }];
        if (self.ComleteBlock) {
            self.ComleteBlock(YES);
        }
    } else {
        self.tipLabel.textColor = [UIColor blackColor];
        self.tipLabel.text = LMLocalizedString(@"Set Draw your pattern", nil);
        self.tipLabel.hidden = NO;
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:[NSString stringWithFormat:LMLocalizedString(@"Set Password incorrect you have chance", nil), MAX_TRYTIME - self.tryTimes] withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            
        }];
        if (self.tryTimes >= MAX_TRYTIME) {
            self.tipLabel.text = LMLocalizedString(@"Login Password incorrect", nil);
            self.tipLabel.hidden = YES;
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:weakSelf.tipLabel.text withType:ToastTypeFail showInView:weakSelf.view complete:^{
                    [self.navigationController popViewControllerAnimated:YES];
                }];
                
            }];
            [[MMAppSetting sharedSetting] setLastErroGestureTime:[[NSDate date] timeIntervalSince1970]];
        }
        if (self.ComleteBlock) {
            self.ComleteBlock(NO);
        }
        self.tryTimes++;
    }

}
@end

//
//  GestureSetPage.m
//  Connect
//
//  Created by MoHuilin on 16/7/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "GestureSetPage.h"
#import "GestureLockView.h"
#import "GestureThumbView.h"

#define MAX_TRYTIME  (int)4
#define MAX_SPACE_TIME (int)30

@interface GestureSetPage () <GestureLockViewDelegate>

@property(nonatomic, strong) UIImageView *lockViewShotView;

@property(nonatomic, strong) GestureThumbView *thumbView;

@property(nonatomic, strong) UILabel *tipLabel;

@property(nonatomic, strong) GestureLockView *gestureLockView;

@property(nonatomic, copy) NSString *firstLockPath; // first pass

@property(nonatomic, assign) GestureActionType actionType;

@property(nonatomic, strong) UIButton *loginPassButton; // other vertification

@property(nonatomic, weak) UITextField *passTextField; // pass

@property(nonatomic, assign) int tryTimes; // times

@property(nonatomic, copy) void (^ComleteBlock )(BOOL result);

@end

@implementation GestureSetPage

- (instancetype)initWithAction:(GestureActionType)actionType {
    if (self = [super init]) {
        self.actionType = actionType;
    }

    return self;
}

- (instancetype)initWithAction:(GestureActionType)actionType complete:(void (^)(BOOL))complete {
    if (self = [super init]) {
        self.actionType = actionType;
        self.ComleteBlock = complete;
    }

    return self;

}

- (instancetype)init {
    if (self = [super init]) {
        self.actionType = GestureActionTypeSet;
    }

    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.view endEditing:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = LMBasicLightGray;

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

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (void)doRight:(id)sender {
    self.firstLockPath = nil;
    [self.thumbView reset];
    [self setNavigationRightWithTitle:@""];
    self.lockViewShotView.image = [UIImage imageNamed:@"setting_gesture_default"];
    self.tipLabel.text = LMLocalizedString(@"Set Draw your pattern", nil);
    self.tipLabel.hidden = NO;
    self.tipLabel.textColor = [UIColor blackColor];
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

- (void)dealloc {
    self.gestureLockView.delegate = nil;
    [self.gestureLockView removeFromSuperview];
    self.gestureLockView = nil;
}


- (void)reload {
    switch (self.actionType) {
        case GestureActionTypeSet:{
            self.title = LMLocalizedString(@"Set Draw Pattern", nil);
            self.lockViewShotView.hidden = NO;
            self.tipLabel.textColor = [UIColor blackColor];
            self.tipLabel.text = LMLocalizedString(@"Set Draw your pattern", nil);
            self.tipLabel.hidden = NO;
        }
            break;
        case GestureActionTypeChange:
        case GestureActionTypeCancel:{
            self.title = LMLocalizedString(@"Set Draw Pattern", nil);
            self.lockViewShotView.hidden = YES;
            self.tipLabel.text = LMLocalizedString(@"Set Draw your pattern", nil);
            self.tipLabel.textColor = [UIColor blackColor];
            self.tipLabel.hidden = NO;
            
            [self.view addSubview:self.loginPassButton];
            self.loginPassButton.bottom = DEVICE_SIZE.height - 45;
            self.loginPassButton.width = DEVICE_SIZE.width;
            self.loginPassButton.height = AUTO_HEIGHT(45);
        }
            break;
        default:
            break;
    }
}

- (UIButton *)loginPassButton {
    if (!_loginPassButton) {
        _loginPassButton = [[UIButton alloc] init];
        [_loginPassButton setTitle:LMLocalizedString(@"Set Use Login Password", nil) forState:UIControlStateNormal];
        [_loginPassButton setTitleColor:[UIColor colorWithRed:0.200 green:0.576 blue:0.965 alpha:1.000] forState:UIControlStateNormal];
        _loginPassButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
        [_loginPassButton addTarget:self action:@selector(loginPassAction) forControlEvents:UIControlEventTouchUpInside];
    }

    return _loginPassButton;
}

- (void)loginPassAction {

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

                switch (weakSelf.actionType) {
                    case GestureActionTypeCancel: {
                        [GCDQueue executeInMainQueue:^{
                            weakSelf.tipLabel.textColor = [UIColor colorWithRed:0.400 green:1.000 blue:0.400 alpha:1.000];
                            weakSelf.tipLabel.hidden = YES;
                            weakSelf.tipLabel.text = LMLocalizedString(@"Set Remove Success", nil);
                            [MBProgressHUD showToastwithText:weakSelf.tipLabel.text withType:ToastTypeSuccess showInView:weakSelf.view complete:nil];
                            [[MMAppSetting sharedSetting] cancelGestursPass];
                        }];

                        [GCDQueue executeInMainQueue:^{
                            [weakSelf.navigationController popViewControllerAnimated:YES];
                        }             afterDelaySecs:0.5];

                    }
                        break;
                    case GestureActionTypeChange: {
                        [GCDQueue executeInMainQueue:^{
                            weakSelf.actionType = GestureActionTypeSet;
                            weakSelf.tipLabel.textColor = [UIColor blackColor];
                            [weakSelf reload];
                        }];
                    }
                        break;

                    default:
                        break;
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

    switch (self.actionType) {
        case GestureActionTypeSet: {
            self.thumbView.password = path;
            if (self.firstLockPath.length) {
                if ([path isEqualToString:self.firstLockPath]) {
                    self.tipLabel.textColor = [UIColor colorWithRed:0.400 green:1.000 blue:0.400 alpha:1.000];
                    self.tipLabel.text = LMLocalizedString(@"Set Pattern Setting Success", nil);
                    self.tipLabel.hidden = YES;
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:weakSelf.tipLabel.text withType:ToastTypeSuccess showInView:weakSelf.view complete:nil];

                    }];
                    [[MMAppSetting sharedSetting] openGesturePassWithPass:path];

                    [GCDQueue executeInMainQueue:^{
                        [self.navigationController popViewControllerAnimated:YES];
                    }             afterDelaySecs:0.5];

                } else {
                    [self.thumbView reset];
                    self.thumbView.password = self.firstLockPath;
                    self.tipLabel.textColor = [UIColor blackColor];
                    self.tipLabel.text = LMLocalizedString(@"Set Draw pattern again", nil);
                    self.tipLabel.hidden = NO;
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Set Two Patterns do not match", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];

                    }];
                }
            } else {
                self.firstLockPath = [path copy];
                self.tipLabel.textColor = [UIColor blackColor];
                self.tipLabel.text = LMLocalizedString(@"Set Draw your pattern", nil);
                self.tipLabel.hidden = NO;

                [self setNavigationRightWithTitle:LMLocalizedString(@"Set Reset", nil)];
            }
        }
            break;
        case GestureActionTypeCancel: {
            [self.thumbView reset];
            self.thumbView.password = path;
            if ([[MMAppSetting sharedSetting] vertifyGesturePass:path]) {
                self.tipLabel.textColor = [UIColor colorWithRed:0.400 green:1.000 blue:0.400 alpha:1.000];
                self.tipLabel.text = LMLocalizedString(@"Set Remove Success", nil);
                self.tipLabel.hidden = YES;
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:weakSelf.tipLabel.text withType:ToastTypeSuccess showInView:weakSelf.view complete:nil];

                }];
                [[MMAppSetting sharedSetting] cancelGestursPass];
                [GCDQueue executeInMainQueue:^{
                    [self.navigationController popViewControllerAnimated:YES];
                }             afterDelaySecs:0.5];
            } else {
                self.tipLabel.textColor = [UIColor blackColor];
                self.tipLabel.text = LMLocalizedString(@"Set Draw your pattern", nil);
                self.tipLabel.hidden = NO;
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:[NSString stringWithFormat:LMLocalizedString(@"Set Password incorrect you have chance", nil), MAX_TRYTIME - self.tryTimes + 1] withType:ToastTypeFail showInView:weakSelf.view complete:nil];

                }];
                if (self.tryTimes >= MAX_TRYTIME) {
                    self.tipLabel.text = LMLocalizedString(@"Login Password incorrect", nil);
                    self.tipLabel.hidden = YES;
                    [[MMAppSetting sharedSetting] setLastErroGestureTime:[[NSDate date] timeIntervalSince1970]];
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:weakSelf.tipLabel.text withType:ToastTypeFail showInView:weakSelf.view complete:^{
                            [self.navigationController popViewControllerAnimated:YES];
                        }];
                    }];
                    [GCDQueue executeInMainQueue:^{

                    }             afterDelaySecs:0.5];
                }
                self.tryTimes++;
            }
        }
            break;
        case GestureActionTypeChange: {
            if ([[MMAppSetting sharedSetting] vertifyGesturePass:path]) {
                if (self.isChangeGesture) {
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Set Enter correct please enter a new gesture", nil) withType:ToastTypeSuccess showInView:weakSelf.view complete:nil];

                    }];
                }
                self.actionType = GestureActionTypeSet;
                self.tipLabel.textColor = [UIColor blackColor];
                self.tipLabel.hidden = NO;
                [self reload];

            } else {
                self.tipLabel.textColor = [UIColor blackColor];
                self.tipLabel.text = LMLocalizedString(@"Set Draw your pattern", nil);
                self.tipLabel.hidden = NO;
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD showToastwithText:[NSString stringWithFormat:LMLocalizedString(@"Set Password incorrect you have chance", nil), MAX_TRYTIME - self.tryTimes + 1] withType:ToastTypeFail showInView:weakSelf.view complete:nil];

                }];
                if (self.tryTimes >= MAX_TRYTIME) {
                    self.tipLabel.text = LMLocalizedString(@"Login Password incorrect", nil);
                    self.tipLabel.hidden = YES;
                    [[MMAppSetting sharedSetting] setLastErroGestureTime:[[NSDate date] timeIntervalSince1970]];
                    [GCDQueue executeInMainQueue:^{
                        [MBProgressHUD showToastwithText:weakSelf.tipLabel.text withType:ToastTypeFail showInView:weakSelf.view complete:^{
                            [self.navigationController popViewControllerAnimated:YES];
                        }];
                    }             afterDelaySecs:0.5];
                }

                self.tryTimes++;
            }
        }
            break;
        default:
            break;
    }

}

@end

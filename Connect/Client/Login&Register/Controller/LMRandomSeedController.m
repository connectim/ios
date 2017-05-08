//
//  LMRandomSeedController.m
//  Connect
//
//  Created by bitmain on 2017/3/14.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "LMRandomSeedController.h"
#import "SetUserInfoPage.h"
#import "LMDisplayProgressView.h"
#import "StringTool.h"

#define DisplayTime (5.0*60)
#define FaliCount 3
#define CheckNum  -70

@interface LMRandomSeedController ()
// xib attribute
@property(weak, nonatomic) IBOutlet UILabel *displayLable;
@property(weak, nonatomic) IBOutlet UIImageView *displayImageView;
@property(strong, nonatomic) LMDisplayProgressView *progressView;
@property(weak, nonatomic) IBOutlet UIButton *skipButton;

// other attrbute
@property(strong, nonatomic) CADisplayLink *link;
@property(assign, nonatomic) NSInteger count;
@property(assign, nonatomic) NSInteger faileCount;
@property(strong, nonatomic) AVAudioRecorder *recoder;
@property(copy, nonatomic) NSString *recoderPath;
// constraint attribute
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *imageTop;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint *lableTop;
// mobile attribute
@property(nonatomic, copy) NSString *mobile;
@property(nonatomic, copy) NSString *token;
// error
@property(assign, nonatomic) BOOL isLoaded;
@property(assign, nonatomic) BOOL bCanRecord;
// array
@property(strong, nonatomic) NSMutableArray *storageArray;
@property(assign, nonatomic) NSInteger sameCount;
@property(assign, nonatomic) CGFloat recodNum;
@property(strong, nonatomic) NSMutableArray *storageCountArray;


@end

@implementation LMRandomSeedController
- (instancetype)initWithMobile:(NSString *)mobile token:(NSString *)token {
    if (self = [super init]) {
        self.mobile = mobile;
        self.token = token;
    }
    return self;
}

#pragma mark - lazy

- (NSMutableArray *)storageArray {
    if (_storageArray == nil) {
        self.storageArray = [NSMutableArray array];
    }
    return _storageArray;
}

- (NSMutableArray *)storageCountArray {
    if (_storageCountArray == nil) {
        self.storageCountArray = [NSMutableArray array];
    }
    return _storageCountArray;
}

- (AVAudioRecorder *)recoder {
    if (_recoder == nil) {
        NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey, [NSNumber numberWithFloat:44100], AVSampleRateKey, [NSNumber numberWithInt:2], AVNumberOfChannelsKey, [NSNumber numberWithInt:16], AVLinearPCMBitDepthKey, [NSNumber numberWithInt:AVAudioQualityHigh], AVEncoderAudioQualityKey, [NSNumber numberWithBool:NO], AVLinearPCMIsBigEndianKey, [NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey, nil];
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *randStr = [NSString stringWithFormat:@"%d", arc4random_uniform(1000)];
        NSString *recoderPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%@recoder.caf", randStr]];
        self.recoder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:recoderPath] settings:settings error:nil];
        self.recoderPath = recoderPath;
        [self.recoder prepareToRecord];
        self.recoder.meteringEnabled = YES;
    }
    return _recoder;
}

#pragma mark - system method

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Login creat account", nil);
    self.displayLable.text = nil;
    [self setup];
    [self canRecord];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    [self.navigationController.navigationBar lt_setBackgroundColor:[UIColor clearColor]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.progressView == nil) {
        // set up progress
        LMDisplayProgressView *progressView = [[LMDisplayProgressView alloc] initWithFrame:self.displayImageView.frame];
        progressView.userInteractionEnabled = YES;
        progressView.backgroundColor = [UIColor clearColor];
        progressView.currentColor = LMBasicGreen;
        progressView.progressWidth = 1.5;
        progressView.radius = 35.5;
        progressView.circleRadius = progressView.radius + progressView.progressWidth;
        progressView.circleWidth = 0.5;
        progressView.circleColor = GJCFQuickHexColor(@"CECECE");
        progressView.isCircle = YES;
        [self.view addSubview:progressView];
        self.progressView = progressView;
        // set lable
        self.displayLable.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
        self.displayLable.textColor = GJCFQuickHexColor(@"767A82");
        // begin link
        [self startLink];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar lt_reset];
}

/**
 *  power
 */
- (BOOL)canRecord {
    __block BOOL bCanRecord = NO;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
            [audioSession performSelector:@selector(requestRecordPermission:) withObject:^(BOOL granted) {
                if (granted) {
                    bCanRecord = YES;
                    self.bCanRecord = bCanRecord;
                } else {
                    bCanRecord = NO;
                    self.bCanRecord = bCanRecord;
                    [GCDQueue executeInMainQueue:^{
                        [self creatSetLable];
                        [self stopLink];
                        [self.navigationController popViewControllerAnimated:YES];
                    }];

                }
            }];
        }
    }
    return bCanRecord;
}

#pragma mark - action

- (void)doLeft:(id)sender {
    [self stopLink];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)setup {
    self.bCanRecord = NO;
    [self startRecode];
    self.imageTop.constant = AUTO_HEIGHT(300);
    self.lableTop.constant = AUTO_HEIGHT(20);


    [self.skipButton setTitle:LMLocalizedString(@"Login created by random number generator", nil) forState:UIControlStateNormal];
    [self.skipButton setTitleColor:LMBasicGreen forState:UIControlStateNormal];

}

/**
 * skip action
 */
- (IBAction)skipAction:(id)sender {
    SetUserInfoPage *page = nil;
    page = [[SetUserInfoPage alloc] initWithStr:[StringTool getSystemUrl]];
    [self.navigationController pushViewController:page animated:YES];
}

/**
 *  tip view
 */
- (void)creatSetLable {
    [self showMsgWithTitle:LMLocalizedString(@"Set tip title", nil) andContent:LMLocalizedString(@"Login recording authority in the settings", nil)];
}

- (void)showMsgWithTitle:(NSString *)title andContent:(NSString *)content {
    [UIAlertController showAlertInViewController:self withTitle:title message:content cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@[LMLocalizedString(@"Common OK", nil)] tapBlock:^(UIAlertController *_Nonnull controller, UIAlertAction *_Nonnull action, NSInteger buttonIndex) {

    }];
}

#pragma mark - start/stop record

/**
 *  begin record
 */
- (void)startRecode {
    [self.recoder record];
}

/**
 *  stop record
 */
- (void)stopRecode {
    [self.recoder stop];
    self.recoder = nil;
}

- (void)startLink {
    if (self.link) {
        [self.link invalidate];
        self.link = nil;
    }
    CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(changeProgressViewValue)];
    [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    self.link = link;
}

- (void)stopLink {
    self.isLoaded = NO;
    if (self.link) {
        [self.link invalidate];
        self.link = nil;
        [self stopRecode];
    }
}

#pragma 定时器方法响应

- (void)changeProgressViewValue {
    [self.recoder updateMeters];
    if (self.bCanRecord == NO) return;
    // failure 3 detail
    if (self.faileCount >= FaliCount) {
        [self faileure3Action];
    }
    // count
    self.count += 1;
    if (self.count >= DisplayTime) {
        self.count = DisplayTime;
    }
    // display progress
    self.progressView.progress = self.count / DisplayTime;
    if (self.progressView.progress <= 0.5) {
        // expect array
        [self exceptAction];
        self.displayLable.text = LMLocalizedString(@"Login Collecting Sounds as Random Seed", nil);
    } else if (self.progressView.progress > 0.5 && self.progressView.progress <= 0.75) {
        if (self.isLoaded == NO) {
            // Recording failed
            if ([self isCheckExcept] == NO) {
                [self stopRecode];
                [self isFailure];
                return;
            }
        }
        self.isLoaded = YES;
        self.displayLable.text = LMLocalizedString(@"Login Generating Private and Public Key", nil);
    } else {
        self.displayLable.text = LMLocalizedString(@"Login Generating Bitcoin address", nil);
    }
    // action
    if (self.progressView.progress == 1.0) {
        [self stopLink];
        [self delayAction];
    }
}

/**
 *  Whether the expectation is qualified
 */
- (BOOL)isCheckExcept {
    NSInteger count = 0;
    CGFloat resultValue = 0.0;
    for (NSInteger index = 0; index < self.storageCountArray.count; index++) {
        NSInteger numberCount = [self.storageCountArray[index] integerValue];
        count += numberCount;
    }
    for (NSInteger index = 0; index < self.storageCountArray.count; index++) {
        NSInteger numberCount = [self.storageCountArray[index] integerValue];
        CGFloat indexValue = [self.storageArray[index] floatValue];
        CGFloat newValue = indexValue * ((CGFloat) numberCount / (CGFloat) count);
        resultValue += newValue;
    }
    if (resultValue > CheckNum) {
        return YES;
    }
    return NO;
}

/**
 *  get expect array
 */
- (void)exceptAction {
    CGFloat recoderNum = [self.recoder peakPowerForChannel:1];
    if (self.recodNum != recoderNum) {
        if (self.recodNum != 0) {
            [self.storageArray objectAddObject:[NSNumber numberWithFloat:self.recodNum]];
        }
        if (self.sameCount != 0) {
            [self.storageCountArray objectAddObject:[NSNumber numberWithInteger:self.sameCount]];
        }
        self.sameCount = 1;
    } else {
        self.sameCount += 1;
    }
    self.recodNum = recoderNum;
}

#pragma mark - failure action

- (void)isFailure {
    self.isLoaded = NO;
    self.faileCount += 1;
    [self stopLink];
    [self failureAction];
}

- (void)faileure3Action {
    self.skipButton.hidden = NO;
    [self stopRecode];
    [self stopLink];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.displayLable.text = LMLocalizedString(@"Login Generated Failure", nil);
    });
}

- (void)failureAction {
    self.count = 0;
    self.displayLable.text = LMLocalizedString(@"Login Generated Failure", nil);
    UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Set tip title", nil) message:LMLocalizedString(@"Login Generated Failure", nil) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [self resetAction];
    }];
    [alertVc addAction:okAction];
    [self presentViewController:alertVc animated:YES completion:nil];
}

#pragma mark - Delay operation / and subsequent operations

- (void)resetAction {
    self.displayImageView.image = [UIImage imageNamed:@"recording_sound"];
    [self startRecode];
    [self startLink];
}

- (void)delayAction {
    self.displayImageView.image = [UIImage imageNamed:@"generated_success"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.displayLable.text = LMLocalizedString(@"Login Generated Successful", nil);
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        SetUserInfoPage *page = nil;
        NSData *data = [NSData dataWithContentsOfFile:self.recoderPath];
        // Should be checked first
        if (self.token && self.mobile) {
            page = [[SetUserInfoPage alloc] initWithStr:[StringTool stringWithData:data] mobile:self.mobile token:self.token];
            [self.navigationController pushViewController:page animated:YES];
        } else {
            page = [[SetUserInfoPage alloc] initWithStr:[StringTool stringWithData:data]];
            [self.navigationController pushViewController:page animated:YES];
        }
    });
}

- (void)dealloc {
    [self stopLink];
    [self.displayLable removeFromSuperview];
    self.displayLable = nil;
    [self.recoder stop];
    self.recoderPath = nil;
    [self.displayImageView removeFromSuperview];
    self.displayImageView = nil;
    self.count = 0;
    [self.progressView removeFromSuperview];
    self.progressView = nil;
    self.mobile = nil;
    self.token = nil;
    self.isLoaded = NO;

    [self.storageArray removeAllObjects];
    self.storageArray = nil;
    [self.storageCountArray removeAllObjects];
    self.storageCountArray = nil;

}
@end

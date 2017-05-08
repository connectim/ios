//
//  LMDBUpdataController.m
//  Connect
//
//  Created by MoHuilin on 2017/4/12.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMDBUpdataController.h"
#import "LMDataMigrationHelper.h"
#import "MMGlobal.h"
#import "LMDisplayProgressView.h"

#define DisplayTime 4

@interface LMDBUpdataController ()
//dispaly view
@property (weak, nonatomic) IBOutlet UIImageView *displayImage;
@property (weak, nonatomic) IBOutlet UILabel *displayLable;
@property (weak, nonatomic) IBOutlet UILabel *tipLable;
@property(nonatomic, assign) BOOL isDisplay;

@property(nonatomic, strong) LMDisplayProgressView *circleView;
@property(nonatomic, strong) CADisplayLink *link;

@property (nonatomic ,copy)void (^complete)(BOOL complete);

@end

@implementation LMDBUpdataController
- (instancetype)initWithUpdateComplete:(void (^)(BOOL complete))complete{
    if (self = [super init]) {
        self.complete = complete;
    }
    return self;
}
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (self.isDisplay) {
        if (self.circleView == nil) {
            LMDisplayProgressView* progressView = [[LMDisplayProgressView alloc]initWithFrame:self.displayImage.frame];
            progressView.userInteractionEnabled = YES;
            progressView.backgroundColor = [UIColor clearColor]; //00C400
            progressView.currentColor = LMBasicGreen;
            progressView.progressWidth = 5;
            progressView.radius = 35;
            progressView.circleRadius = progressView.radius;
            progressView.circleWidth = 5;
            progressView.circleColor = GJCFQuickHexColor(@"CECECE");
            progressView.isCircle = YES;
            [self.view addSubview:progressView];
            self.circleView = progressView;
            //set a timer
            [self startLink];
        }
    }
}
- (void)viewDidLoad {
    NSString *olddbPath = [MMGlobal getDBFile:[[LKUserCenter shareCenter] currentLoginUser].pub_key.sha256String];
    if (GJCFFileIsExist(olddbPath)) {
        self.isDisplay = YES;
        self.displayLable.text = LMLocalizedString(@"Chat Updating Database", nil);
        self.tipLable.text = LMLocalizedString(@"Chat Update Database", nil);
        self.displayLable.hidden = NO;
        self.displayImage.hidden = NO;
        self.tipLable.hidden = NO;
        [LMDataMigrationHelper dataMigrationWithComplete:^(CGFloat progress) {
            DDLogInfo(@"dataMigrationWithComplete progress %f",progress);
        }];
        [GCDQueue executeInMainQueue:^{
            self.complete(YES);
        } afterDelaySecs:(DisplayTime + 1)];
    } else{
        self.complete(YES);
    }
    
}
#pragma mark - response
//start timer
-(void)startLink{
    
    CADisplayLink* link = [CADisplayLink displayLinkWithTarget:self selector:@selector(progrssChange:)];
    [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    self.link = link;
}
//progress change
- (void)progrssChange:(CADisplayLink*)link{
    static int count = 0;
    count ++;
    if (count >= (CGFloat)DisplayTime/2*60) {
        count+=2.5;
    }
    self.circleView.progress = (double)count/(DisplayTime*60);
    if (self.circleView.progress >= 1.0) {
        self.circleView.progress = 1.0;
        [self stopLink];
        [self successAction];
    }
}

- (void)successAction{
    [GCDQueue executeInMainQueue:^{
        self.displayLable.text = LMLocalizedString(@"Login Update successful", nil);
        self.displayImage.image = [UIImage imageNamed:@"generated_success"];
    }];
   
}
//stop timer
-(void)stopLink{
    if (self.link) {
        [self.link setPaused:YES];
        [self.link invalidate];
        self.link = nil;
    }
}
-(void)dealloc
{
    [self.displayImage removeFromSuperview];
    self.displayImage = nil;
    [self.displayLable removeFromSuperview];
    self.displayLable = nil;
    [self.circleView removeFromSuperview];
    self.circleView = nil;
    [self stopLink];
}
@end

//
//  MMProgressWebView.m
//  Connect
//
//  Created by MoHuilin on 16/10/16.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "MMProgressWebView.h"
#import "MMGlobal.h"
#import <objc/runtime.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#define FeedBackCloseKey @"FeedBackClose"
#define ConfigUserAgent  [NSString stringWithFormat:@"CONNECT.IM(%@;%@)",[MMGlobal currentVersion],[MMGlobal getCurrentDeviceModel]]

NSString *const progressColorKey = @"progressColorKey";

@interface MMProgressWebView ()<WKScriptMessageHandler>

@property (strong, nonatomic) CALayer *progresslayer;

@property (nonatomic ,strong) UIView *progress;


@end

@implementation MMProgressWebView


- (void)initWithDefault{
    self.progressColor = [UIColor colorWithRed:22.f / 255.f green:126.f / 255.f blue:251.f / 255.f alpha:.8];;
}

- (void)initWithProgressView{
    if (!self.progress) {
        UIView *progress = [[UIView alloc]initWithFrame:CGRectMake(0, 64, CGRectGetWidth(self.frame), 3)];
        progress.backgroundColor = [UIColor clearColor];
        [self addSubview:progress];
        self.progress = progress;
        [[UIDevice currentDevice] localizedModel];
    }
    
    if (!self.progresslayer) {
        CALayer *layer = [CALayer layer];
        layer.backgroundColor = self.progressColor.CGColor;
        [self.progress.layer addSublayer:layer];
        self.progresslayer = layer;
        self.progresslayer.frame = CGRectMake(0, 0, AUTO_WIDTH(20), 3);
    }
}

- (UIColor *)progressColor{
    return objc_getAssociatedObject(self, &progressColorKey);
}

- (void)setProgressColor:(UIColor *)progressColor{
    objc_setAssociatedObject(self, &progressColorKey, progressColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.progresslayer.backgroundColor = progressColor.CGColor;
    [self.progress layoutIfNeeded];
}

- (instancetype)initWithUrl:(NSURL *)url{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        // Initialize js stuffed stuff
        WKWebViewConfiguration* configuration = [[WKWebViewConfiguration alloc] init];
        WKUserContentController* controller  = [[WKUserContentController alloc]init];
        configuration.userContentController = controller;
        WKWebView *webView = [[WKWebView alloc]initWithFrame:[UIScreen mainScreen].bounds configuration:configuration];
        self.webView = webView;
        [controller addScriptMessageHandler:self name:FeedBackCloseKey];
        webView.allowsBackForwardNavigationGestures = YES;
        // Add the observer to observe the estimatedProgress attribute of wkwebview
        [webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
        [self addSubview:webView];
        [webView loadRequest:[NSURLRequest requestWithURL:url]];
        [self initWithDefault];
        [self initWithProgressView];
        
        // config user - agent
        [webView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id result, NSError *error) {
            NSString *oldAgent = result;
            NSString *newAgent = [NSString stringWithFormat:@"%@;%@", oldAgent, ConfigUserAgent];
            // set global User-Agent
            NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:newAgent, @"UserAgent", nil];
            [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
            
        }];
    }
    return self;
}
- (UIViewController*)viewController {
    for (UIView* next = [self superview]; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController*)nextResponder;
        }
    }
    return nil;
}
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:FeedBackCloseKey]) {
        [[self viewController].navigationController popViewControllerAnimated:YES];
    }
}
- (void)dealloc{
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [self.webView removeObserver:self forKeyPath:FeedBackCloseKey];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        self.progresslayer.opacity = 1;
        // Do not let the progress bar go backwards ... sometimes goback will happen
        if ([change[@"new"] floatValue] < [change[@"old"] floatValue]) {
            return;
        }
        self.progresslayer.frame = CGRectMake(0, 0, self.bounds.size.width * [change[@"new"] floatValue], 3);
        if ([change[@"new"] floatValue] == 1) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.progresslayer.opacity = 0;
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.progresslayer.frame = CGRectMake(0, 0, 0, 3);
            });
        }
    }else{
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

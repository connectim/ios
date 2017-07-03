//
//  CommonClausePage.m
//  HashNest
//
//  Created by MoHuilin on 16/5/5.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "CommonClausePage.h"
#import <WebKit/WebKit.h>
#import "MMProgressWebView.h"
#import "UIAlertController+Blocks.h"
#import "ReconmandChatListPage.h"
#import "MMMessage.h"
#import "TFHpple.h"

@interface CommonClausePage () <WKNavigationDelegate>

@property(nonatomic, strong) MMProgressWebView *progressWebView;

@property(copy, nonatomic) NSString *contentHTML;
@property(copy, nonatomic) NSString *url;

@property(nonatomic, strong) UIBarButtonItem *closeItem;

@property(nonatomic, assign) BOOL loadFinish;

@end

@implementation CommonClausePage
#pragma mark - system methods
- (instancetype)initWithUrl:(NSString *)url {
    if (self = [super init]) {
        self.url = url;
        [self configUrl];
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    NSMutableArray *leftItems = [NSMutableArray array];
    
    
    UIBarButtonItem *offset = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    offset.width = -10;
    [leftItems objectAddObject:offset]; //offset
    [leftItems objectAddObject:[self blackBackItem]];
    [leftItems objectAddObject:[self closeItem]];
    self.navigationItem.leftBarButtonItems = leftItems;
    //init js code
    MMProgressWebView *progressWebView = [[MMProgressWebView alloc] initWithUrl:[NSURL URLWithString:self.url]];
    self.progressWebView = progressWebView;
    progressWebView.webView.navigationDelegate = self;
    progressWebView.progressColor = LMBasicGreen;
    [self.view addSubview:progressWebView];
    self.closeItem.customView.hidden = YES;
    if (self.sourceType == SourceTypeOutNetWork) {
        [self setNavigationRight:@"menu_white"];
    } else if (self.sourceType == SourceTypeHelp) {
        [self setNavigationRight:LMLocalizedString(@"Set FeedBack", nil) titleColor:LMBasicGreen];
    }
}
#pragma other methods
- (void)configUrl {
    // weather contain ?
    NSString* parameter = @"?";
    if ([self.url containsString:@"?"]) {
        parameter = @"&";
    }
    self.url = [NSString stringWithFormat:@"%@%@locale=%@",self.url,parameter,GJCFUDFGetValue(@"userCurrentLanguage")];
}
- (void)doLeft:(id)sender {
    if (self.progressWebView.webView.canGoBack) {
        [self.progressWebView.webView goBack];
    } else {
        [super doLeft:sender];
    }
}

- (void)doRight:(id)sender {
    __weak __typeof(&*self) weakSelf = self;
    if (self.sourceType == SourceTypeHelp) {
        CommonClausePage *page = [[CommonClausePage alloc] initWithUrl:FeedBackUrl];
        page.sourceType = SourceTypeFeedBack;
        [self.navigationController pushViewController:page animated:YES];
    } else {
        NSArray *titles = @[LMLocalizedString(@"Link Share to Friend", nil), LMLocalizedString(@"Link Open in Safari", nil)];
        if (!self.loadFinish) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Set load tip", nil) withType:ToastTypeCommon showInView:weakSelf.view complete:nil];
            }];
            return;
        }
        [UIAlertController showActionSheetInViewController:self withTitle:nil message:nil cancelButtonTitle:LMLocalizedString(@"Common Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:titles popoverPresentationControllerBlock:nil tapBlock:^(UIAlertController *_Nonnull controller, UIAlertAction *_Nonnull action, NSInteger buttonIndex) {
            [weakSelf shareUrlWithIndex:buttonIndex];
        }];
    }
}
- (void)shareUrlWithIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 2: //to chat
        {
            __weak __typeof(&*self) weakSelf = self;
            NSString *html = @"document.documentElement.innerHTML";
            [self.progressWebView.webView evaluateJavaScript:html
                                           completionHandler:^(id _Nullable htmlStr, NSError *_Nullable error) {
                                               if (!error) {
                                                   TFHpple *Hpple = [[TFHpple alloc] initWithHTMLData:[htmlStr dataUsingEncoding:NSUTF8StringEncoding]];
                                                   TFHppleElement *descElement = [Hpple peekAtSearchWithXPathQuery:@"//meta[@name='description'][1]"];
                                                   NSArray *array = [Hpple searchWithXPathQuery:@"//img[@src]"];
                                                   TFHppleElement *element = [array firstObject];
                                                   NSString *linkImageUrl = [element.attributes valueForKey:@"src"];
                                                   NSString *shareUrl = weakSelf.progressWebView.webView.URL.absoluteString;
                                                   if (!shareUrl) {
                                                       shareUrl = weakSelf.url;
                                                   }

                                                   LMRerweetModel *retweetModel = [[LMRerweetModel alloc] init];
                                                   MMMessage *message = [[MMMessage alloc] init];
                                                   message.type = GJGCChatWalletLink;
                                                   message.content = shareUrl;
                                                   NSString *title = LMLocalizedString(@"Share the web page", nil);
                                                   NSString *subTitle = [descElement.attributes valueForKey:@"content"];
                                                   if (!subTitle) {
                                                       subTitle = shareUrl;
                                                   }
                                                   if (weakSelf.progressWebView.webView.title) {
                                                       title = weakSelf.progressWebView.webView.title;
                                                   }

                                                   NSMutableDictionary *ext1 = [NSMutableDictionary dictionary];
                                                   [ext1 setObject:title forKey:@"linkTitle"];
                                                   [ext1 setObject:subTitle forKey:@"linkSubtitle"];
                                                   if (linkImageUrl) {
                                                       [ext1 setObject:linkImageUrl forKey:@"linkImageUrl"];
                                                   }
                                                   message.ext1 = ext1;
                                                   retweetModel.retweetMessage = message;
                                                   ReconmandChatListPage *page = [[ReconmandChatListPage alloc] initWithRetweetModel:retweetModel];
                                                   page.title = LMLocalizedString(@"Chat Retweet", nil);
                                                   UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:page];
                                                   [weakSelf presentViewController:nav animated:YES completion:nil];
                                               }
                                           }];
        }
            break;

        case 3: //safari
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.url]];
        }
            break;
        default:
            break;
    }
}


- (void)popViewAction:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
- (UIBarButtonItem *)blackBackItem {
    UIButton *btn = nil;
    if (GJCFSystemiPhone6 || GJCFSystemiPhone5) {
        btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    } else {
        btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    }
    [btn setImage:[UIImage imageNamed:@"back_white"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(doLeft:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:btn];

    return item;
}

- (UIBarButtonItem *)closeItem {
    if (!_closeItem) {
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        [btn setImage:[UIImage imageNamed:@"close_white"] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(popViewAction:) forControlEvents:UIControlEventTouchUpInside];
        _closeItem = [[UIBarButtonItem alloc] initWithCustomView:btn];
    }
    return _closeItem;
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (webView.backForwardList.backList.count > 0) {
        self.closeItem.customView.hidden = NO;
    } else {
        self.closeItem.customView.hidden = YES;
    }
    self.title = webView.title;
    if (self.sourceType == SourceTypeHelp) {
        self.title = LMLocalizedString(@"Set Help and feedback", nil);
    }
    self.loadFinish = YES;
}
@end

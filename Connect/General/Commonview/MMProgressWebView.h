//
//  MMProgressWebView.h
//  Connect
//
//  Created by MoHuilin on 16/10/16.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>


@interface MMProgressWebView : UIView

/**
 *  progress view
 */
@property (strong, nonatomic) UIColor *progressColor;

@property (nonatomic ,strong) WKWebView *webView;

- (instancetype)initWithUrl:(NSURL *)url;


@end

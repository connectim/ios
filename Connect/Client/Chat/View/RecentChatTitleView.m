//
//  RecentChatTitleView.m
//  Connect
//
//  Created by MoHuilin on 16/6/25.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "RecentChatTitleView.h"

@implementation RecentChatTitleView

- (instancetype)init {
    if (self = [super init]) {

        self.titleLabel = [[UILabel alloc] init];
        /**
         *  [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
         [UIColor colorWithHex:0x161a21], NSForegroundColorAttributeName, [UIFont fontWithName:@"Helvetica-Bold" size:18], NSFontAttributeName, nil]];
         */
        self.titleLabel.font = [GJGCCommonFontColorStyle navigationBarTitleViewFont];
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        self.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
        [self addSubview:self.titleLabel];

        self.indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        self.indicatorView.color = [UIColor colorWithWhite:0.8 alpha:0.8];
        [self addSubview:self.indicatorView];
        self.gjcf_size = CGSizeMake(DEVICE_SIZE.width - AUTO_WIDTH(150), 44);
        self.indicatorView.gjcf_centerY = self.titleLabel.gjcf_centerY;
    }
    return self;
}

- (NSDictionary *)statusLabelDict {
    return @{

            @(RecentChatConnectStateConnecting): LMLocalizedString(@"Chat Connecting", nil),

            @(RecentChatConnectStateFaild): LMLocalizedString(@"Chat Not connected", nil),

            @(RecentChatConnectStateSuccess): LMLocalizedString(@"Chat Chats", nil),

            @(RecentChatConnectStateAuthing): LMLocalizedString(@"Chat Refreshing Secret Key", nil),

            @(RecentChatConnectStateGetOffline): LMLocalizedString(@"Chat Loading", nil),

    };
}

- (void)setConnectState:(RecentChatConnectState)connectState {
    _connectState = connectState;
    NSString *title = [self statusLabelDict][@(connectState)];
    if (connectState == RecentChatConnectStateSuccess) {
        title = LMLocalizedString(@"Chat Secret Key Refreshed", nil);
        [GCDQueue executeInMainQueue:^{
            self.titleLabel.text = [self statusLabelDict][@(RecentChatConnectStateSuccess)];
        } afterDelaySecs:0.8f];
    }
    self.titleLabel.text = title;
    [self.titleLabel sizeToFit];
    self.indicatorView.gjcf_size = (CGSize) {self.titleLabel.gjcf_height, self.titleLabel.gjcf_height};
    if (connectState == RecentChatConnectStateConnecting || connectState == RecentChatConnectStateGetOffline || connectState == RecentChatConnectStateAuthing) {
        self.indicatorView.right = self.titleLabel.left - AUTO_WIDTH(15);
        self.indicatorView.gjcf_centerY = self.titleLabel.gjcf_centerY;
        self.indicatorView.hidden = NO;
        [self.indicatorView startAnimating];
    } else {
        self.indicatorView.hidden = YES;
        [self.indicatorView stopAnimating];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    if (self.indicatorView.hidden) {
        self.titleLabel.gjcf_centerX = self.gjcf_width / 2;
        self.titleLabel.gjcf_centerY = self.gjcf_height / 2;
    } else {
        self.titleLabel.gjcf_centerX = self.gjcf_width / 2 + self.indicatorView.width / 2 + AUTO_WIDTH(10);
        self.titleLabel.gjcf_centerY = self.gjcf_height / 2;
        self.indicatorView.gjcf_centerY = self.titleLabel.gjcf_centerY;
        self.indicatorView.right = self.titleLabel.left - AUTO_WIDTH(10);
    }
}


@end

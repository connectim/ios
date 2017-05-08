//
//  ChatPageTitleView.m
//  Connect
//
//  Created by MoHuilin on 16/10/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "ChatPageTitleView.h"

@interface ChatPageTitleView ()


@end

@implementation ChatPageTitleView

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

        self.snapChatImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"snaptitle_privacy_white"]];
        [self addSubview:self.snapChatImageView];

        self.gjcf_size = CGSizeMake(DEVICE_SIZE.width - AUTO_WIDTH(300), 44);
    }
    return self;
}

- (void)setTitle:(NSString *)title {
    _title = title;
    [self setChatStyle:self.chatStyle];
}


- (void)setChatStyle:(ChatPageTitleViewStyle)chatStyle {
    _chatStyle = chatStyle;

    switch (chatStyle) {
        case ChatPageTitleViewStyleNomarl:
            self.titleLabel.text = self.title;
            self.snapChatImageView.hidden = YES;
            [self.titleLabel sizeToFit];
            self.snapChatImageView.gjcf_size = CGSizeZero;
            if (self.titleLabel.width > (DEVICE_SIZE.width - 100)) {
                self.titleLabel.width = DEVICE_SIZE.width - 100;
            }
            self.width = self.titleLabel.width;
            break;
        case ChatPageTitleViewStyleSnapChat: {
            if (self.title.length > 1) {
                NSMutableString *title = [NSMutableString stringWithString:[self.title substringToIndex:1]];
                [title appendString:@"***"];
                [title appendString:[self.title substringFromIndex:self.title.length - 1]];
                self.titleLabel.text = title;
            } else {
                self.titleLabel.text = [NSString stringWithFormat:@"%@***%@", self.title, self.title];
            }
            self.snapChatImageView.hidden = NO;
            [self.titleLabel sizeToFit];
            self.snapChatImageView.width = self.titleLabel.gjcf_height * 1.1;
            CGSize imageSize = self.snapChatImageView.image.size;
            self.snapChatImageView.height = self.snapChatImageView.width * imageSize.height / imageSize.width;
            self.width = self.titleLabel.width + self.snapChatImageView.width + AUTO_WIDTH(15);
        }
            break;
        default:
            break;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.chatStyle == ChatPageTitleViewStyleNomarl) {
        self.titleLabel.gjcf_centerX = self.gjcf_width / 2;
    } else {
        self.titleLabel.gjcf_centerX = self.gjcf_width / 2 + self.snapChatImageView.width / 2;
    }
    self.titleLabel.gjcf_centerY = self.gjcf_height / 2;
    self.snapChatImageView.right = self.titleLabel.left - AUTO_WIDTH(15);
    self.snapChatImageView.gjcf_centerY = self.titleLabel.gjcf_centerY;
}


@end

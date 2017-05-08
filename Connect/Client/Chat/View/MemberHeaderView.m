//
//  MemberHeaderView.m
//  Connect
//
//  Created by MoHuilin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "MemberHeaderView.h"

@interface MemberHeaderView ()

@property(nonatomic, strong) UIImageView *avatarView;
@property(nonatomic, strong) UILabel *nameLabel;

@property(nonatomic, copy) NSString *avatarUrl;
@property(nonatomic, copy) NSString *name;

@property(nonatomic, strong) AccountInfo *info;

@end

@implementation MemberHeaderView


- (void)setup {

    [self addTarget:self action:@selector(tapSelf) forControlEvents:UIControlEventTouchUpInside];

    self.width = 50;

    self.avatarView = [[UIImageView alloc] init];
    self.avatarView.layer.cornerRadius = 5;
    self.avatarView.layer.masksToBounds = YES;

    self.avatarView.size = CGSizeMake(50, 50);
    self.left = 0;
    self.top = 0;

    NSString *avatar = self.avatarUrl;
    [self.avatarView setPlaceholderImageWithAvatarUrl:avatar];
    [self addSubview:self.avatarView];


    UIImageView *adminImageView = [[UIImageView alloc] init];
    adminImageView.top = 0;
    adminImageView.width = 19;
    adminImageView.height = 27;
    adminImageView.left = 40;
    adminImageView.image = [UIImage imageNamed:@"message_groupchat_admin"];
    [self addSubview:adminImageView];

    adminImageView.hidden = !self.info.isGroupAdmin;

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont systemFontOfSize:14];
    self.nameLabel.textColor = [UIColor blackColor];
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:self.nameLabel];

    self.nameLabel.top = self.avatarView.bottom;
    self.nameLabel.width = 50;
    self.nameLabel.height = 20;
    self.nameLabel.text = self.name;
    self.height = self.nameLabel.bottom;

}

- (instancetype)initWithImage:(NSString *)avatar name:(NSString *)name {
    if (self = [super init]) {
        self.avatarUrl = avatar;
        self.name = name;

        [self setup];
    }

    return self;
}

- (instancetype)initWithAccountInfo:(AccountInfo *)info tapBlock:(TapMemberHeaderViewBlock)tapBlock {
    if (self = [super init]) {
        self.info = info;
        self.avatarUrl = info.avatar;
        self.name = info.groupShowName;
        self.tapBlock = tapBlock;
        [self setup];
    }

    return self;

}

- (instancetype)initWithImage:(NSString *)avatar name:(NSString *)name tapBlock:(TapMemberHeaderViewBlock)tapBlock {
    if (self = [super init]) {
        self.avatarUrl = avatar;
        self.name = name;
        self.tapBlock = tapBlock;
        [self setup];
    }

    return self;

}

#pragma mark -event

- (void)tapSelf {
    if (self.tapBlock) {
        self.tapBlock(self.info);
    }
}

@end

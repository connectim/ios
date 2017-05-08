//
//  GroupMembersCell.m
//  Connect
//
//  Created by MoHuilin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "GroupMembersCell.h"
#import "MemberHeaderView.h"

@interface GroupMembersCell () {
    CGFloat margin;
}

@property(nonatomic, strong) UIControl *membersView;

@property(nonatomic, strong) UIButton *addNewPersionButton;

@property(nonatomic, strong) UIImageView *rightArrowImageView;

@end

@implementation GroupMembersCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        margin = 15;

        self.membersView = [[UIControl alloc] init];
        self.membersView.size = CGSizeMake(DEVICE_SIZE.width - 50, 70);
        self.membersView.top = margin;
        self.membersView.left = 0;

        UIImageView *rightArrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ShareArrow"]];
        self.rightArrowImageView = rightArrowImageView;
        rightArrowImageView.size = CGSizeMake(9, 14);
        rightArrowImageView.right = DEVICE_SIZE.width - 15;
        [self.contentView addSubview:rightArrowImageView];

        [self.contentView addSubview:self.membersView];

        self.height = self.membersView.bottom + margin;

        rightArrowImageView.top = 40 - 6;


    }
    return self;
}

- (void)setData:(id)data {
    [super setData:data];

    for (UIView *subV in self.membersView.subviews) {
        [subV removeFromSuperview];
    }

    NSArray *members = (NSArray *) data;
    if (members.count == 0) {
        return;
    }
    self.rightArrowImageView.hidden = (members.count == 1);

    __weak __typeof(&*self) weakSelf = self;

    NSInteger max = members.count;
    if (max > 3) {
        max = 3;
    }

    margin = (self.membersView.width - (50 * 4)) / 8;

    AccountInfo *info = [members objectAtIndexCheck:0];

    MemberHeaderView *headerView0 = [[MemberHeaderView alloc] initWithAccountInfo:info tapBlock:^(AccountInfo *info) {
        if (weakSelf.tapMemberHeaderBlock) {
            weakSelf.tapMemberHeaderBlock(info);
        }
    }];
    headerView0.frame = CGRectMake(15, 0, 50, 70);
    [self.membersView addSubview:headerView0];

    UIView *lastView = headerView0;
    for (int i = 1; i < max; i++) {
        AccountInfo *info = [members objectAtIndexCheck:i];

        MemberHeaderView *headerView = [[MemberHeaderView alloc] initWithAccountInfo:info tapBlock:^(AccountInfo *info) {
            if (weakSelf.tapMemberHeaderBlock) {
                weakSelf.tapMemberHeaderBlock(info);
            }
        }];
        headerView.frame = CGRectMake(headerView0.right + (margin * 2) * i + (i - 1) * 50, 0, 50, 70);
        [self.membersView addSubview:headerView];

        lastView = headerView;
    }

    [self.membersView addSubview:self.addNewPersionButton];
    self.addNewPersionButton.frame = CGRectMake(lastView.right + margin * 2, 0, 50, 50);
}

- (UIButton *)addNewPersionButton {
    if (!_addNewPersionButton) {
        _addNewPersionButton = [[UIButton alloc] init];
        [_addNewPersionButton setImage:[UIImage imageNamed:@"chat_friend_set_addmember"] forState:UIControlStateNormal];
        [_addNewPersionButton addTarget:self action:@selector(addGroupMenberButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }

    return _addNewPersionButton;
}

- (void)addGroupMenberButtonClick {
    if (self.tapAddMemberBlock) {
        self.tapAddMemberBlock();
    }
}

@end

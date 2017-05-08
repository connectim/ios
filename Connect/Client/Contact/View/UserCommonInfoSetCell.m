//
//  UserCommonInfoSetCell.m
//  Connect
//
//  Created by MoHuilin on 16/7/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "UserCommonInfoSetCell.h"
#import "TagsView.h"
#import "UserDBManager.h"

@interface UserCommonInfoSetCell () <TagsViewDelegate, UITextFieldDelegate>

@property(nonatomic, strong) TagsView *tagsView;

@property(nonatomic, strong) UITextField *alisTextField;

@property(nonatomic, strong) AccountInfo *user;

@end

@implementation UserCommonInfoSetCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        TagsView *tagsView = [[TagsView alloc] init];
        self.tagsView = tagsView;
        tagsView.frame = AUTO_RECT(0, 20, 750, 360);
        tagsView.delegate = self;
        tagsView.type = TagsViewTypeEdit;
        [self.contentView addSubview:tagsView];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (self.TextValueChangeBlock) {
        self.TextValueChangeBlock(self.alisTextField.text);
    }
    return YES;
}


- (void)setData:(id)data {

    [super setData:data];
    CellItem *item = (CellItem *) self.data;
    AccountInfo *info = item.userInfo;

    self.alisTextField.text = info.remarks;

    self.user = info;
    _tagsView.tags = [NSMutableArray arrayWithArray:self.user.tags];
    if (_tagsView.tags.count <= 0) {
        _tagsView.tags = [[UserDBManager sharedManager] getUserTags:self.user.address].mutableCopy;
    }
    [_tagsView reloadData];
}

- (void)tagsViewSaveNewTag:(NSString *)newTag {

    CellItem *item = (CellItem *) self.data;

    if (item) {
        if (item.operationWithInfo) {
            item.operationWithInfo(newTag);
        }
    }

}

// all exist tag
- (void)removeBottomTag:(NSString *)tag {
    if (GJCFStringIsNull(tag) || GJCFStringIsNull(self.user.address)) {
        return;
    }
    [SetGlobalHandler removeUserHaveAddress:self.user.address formTag:tag];
}

// only user tag
- (void)removeTag:(NSString *)tag {
    if (GJCFStringIsNull(tag) || GJCFStringIsNull(self.user.address)) {
        return;
    }
    UIMenuController *shareMenuViewController = [UIMenuController sharedMenuController];
    if (shareMenuViewController.isMenuVisible) {
        [shareMenuViewController setMenuVisible:NO animated:YES];
    }
    [SetGlobalHandler removeUserAddress:self.user.address formTag:tag];
}

// only user tag
- (void)addTag:(NSString *)tag {
    if (GJCFStringIsNull(tag) || GJCFStringIsNull(self.user.address)) {
        return;
    }
    UIMenuController *shareMenuViewController = [UIMenuController sharedMenuController];
    if (shareMenuViewController.isMenuVisible) {
        [shareMenuViewController setMenuVisible:NO animated:YES];
    }
    [SetGlobalHandler setUserAddress:self.user.address ToTag:tag];
}

- (void)dealloc {
    self.alisTextField.delegate = nil;
    self.tagsView.delegate = nil;
}


@end

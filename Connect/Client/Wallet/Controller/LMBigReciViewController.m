//
//  LMBigReciViewController.m
//  Connect
//
//  Created by Edwin on 16/7/14.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMBigReciViewController.h"
#import "LMRecipFriendsViewController.h"
#import "LMReManFriendViewController.h"
#import "UserDBManager.h"
#import "ChineseToPinyin.h"

#import "LMSelectTableViewCell.h"

@interface LMBigReciViewController () <UITableViewDelegate, UITableViewDataSource>
@property(nonatomic, strong) NSMutableArray *selectedList;

@property(nonatomic, strong) NSMutableArray *dataArr;

@property(nonatomic, strong) NSMutableArray *sectionArr;
@property(nonatomic, strong) NSMutableArray *alphaArr;

@property(nonatomic, strong) UITableView *tableView;

@property(nonatomic, strong) TransferButton *transferBtn;
@end

static NSString *friends = @"friends";

@implementation LMBigReciViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = LMLocalizedString(@"Wallet Select friends", nil);

    [MBProgressHUD showLoadingMessageToView:self.view];

    [[UserDBManager sharedManager] getAllUsersNoConnectWithComplete:^(NSArray *contacts) {
        [MBProgressHUD hideHUDForView:self.view];
        self.dataArr = contacts.mutableCopy;
        self.alphaArr = [[self accordingTheChineseAndEnglishNameToGenerateAlphabet] mutableCopy];
        [self nameIsAlphabeticalAscending];
        [self.tableView reloadData];
    }];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, VSIZE.width, VSIZE.height - 64 - AUTO_HEIGHT(100)) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.view addSubview:self.tableView];
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    self.tableView.sectionIndexColor = [UIColor lightGrayColor];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    [self.tableView registerNib:[UINib nibWithNibName:@"LMSelectTableViewCell" bundle:nil] forCellReuseIdentifier:friends];
    self.transferBtn = [[TransferButton alloc] initWithNormalTitle:[NSString stringWithFormat:LMLocalizedString(@"Wallet Transfer Count", nil), (int) self.selectedList.count] disableTitle:LMLocalizedString(@"Chat Choose Members", nil)];
    self.transferBtn.frame = CGRectMake(0, self.view.frame.size.height - AUTO_HEIGHT(100), VSIZE.width, AUTO_HEIGHT(100));
    [self.transferBtn addTarget:self action:@selector(transferBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.transferBtn];

}

#pragma mark --获取好友

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.alphaArr.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *array = self.sectionArr[section];
    return [array count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return AUTO_HEIGHT(40);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VSIZE.width, AUTO_HEIGHT(40))];
    bgView.backgroundColor = [UIColor colorWithRed:236 / 255.0 green:236 / 255.0 blue:236 / 255.0 alpha:1.0];
    UILabel *titleOneLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, VSIZE.width - 20, AUTO_HEIGHT(40))];
    titleOneLabel.backgroundColor = [UIColor colorWithRed:236 / 255.0 green:236 / 255.0 blue:236 / 255.0 alpha:1.0];
    titleOneLabel.text = [NSString stringWithFormat:@"%@", self.alphaArr[section]];
    titleOneLabel.font = [UIFont systemFontOfSize:FONT_SIZE(22)];
    titleOneLabel.textColor = [UIColor blackColor];
    titleOneLabel.textAlignment = NSTextAlignmentLeft;
    [bgView addSubview:titleOneLabel];
    return bgView;
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.alphaArr;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    NSIndexPath *selectIndexPath = [NSIndexPath indexPathForRow:0 inSection:index];
    [tableView scrollToRowAtIndexPath:selectIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    return index;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LMSelectTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:friends];
    if (!cell) {
        cell = [[LMSelectTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:friends];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.userInteractionEnabled = YES;
    AccountInfo *info = self.sectionArr[indexPath.section][indexPath.row];
    [cell setAccoutInfo:info];
    return cell;
}

- (void)LMSelectTableViewCell:(LMSelectTableViewCell *)cell SelectedBtnClick:(UIButton *)btn {
    btn.selected = !btn.selected;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    AccountInfo *info = self.sectionArr[indexPath.section][indexPath.row];
    if (btn.selected) {
        [self.selectedList objectAddObject:info];
    } else {
        [self.selectedList removeObject:info];
    }
    [self.transferBtn setTitle:[NSString stringWithFormat:LMLocalizedString(@"Wallet Receivables from", nil), (int) self.selectedList.count] forState:UIControlStateNormal];
    [self.tableView reloadData];
}

- (void)transferBtnClicked:(UIButton *)btn {

    __weak typeof(self) weakSelf = self;
    if (self.selectedList.count == 0) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Wallet Select friends", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];

        return;
    }
    if (self.selectedList.count == 1) { // single transfer
        LMRecipFriendsViewController *transfer = [[LMRecipFriendsViewController alloc] init];
        transfer.info = self.selectedList.lastObject;
        [self.navigationController pushViewController:transfer animated:YES];
    } else { // Many people receive money
        LMReManFriendViewController *manFriends = [[LMReManFriendViewController alloc] init];
        manFriends.selectArr = self.selectedList;
        [self.navigationController pushViewController:manFriends animated:YES];
    }

}

- (NSArray *)accordingTheChineseAndEnglishNameToGenerateAlphabet {
    NSMutableArray *objectArr = [[NSMutableArray alloc] init];
    NSMutableArray *alphatArr = [[NSMutableArray alloc] init];
    for (AccountInfo *info in self.dataArr) {
        NSString *firsrObject = [info.username substringToIndex:1];
        [objectArr objectAddObject:firsrObject];
    }
    for (NSString *str in objectArr) {
        const char *utf8 = [str UTF8String];
        if (strlen(utf8) == 3) {
            NSString *pinyin = [ChineseToPinyin pinyinFromChiniseString:str];
            NSString *pinyinFirst = [pinyin substringToIndex:1];
            NSString *upperStr = [pinyinFirst uppercaseString];
            [alphatArr objectAddObject:upperStr];
        } else {
            NSString *upperStr = [str uppercaseString];
            [alphatArr objectAddObject:upperStr];
        }
    }

    // Remove the same elements from the array
    NSMutableArray *listAry = [[NSMutableArray alloc] init];
    for (NSString *str in alphatArr) {
        if (![listAry containsObject:str]) {
            [listAry objectAddObject:str];
        }
    }
    DDLogInfo(@"%@", listAry);

    // Use the block to sort the array
    NSArray *arr = [listAry sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        NSComparisonResult result = [obj1 compare:obj2];
        return result;
    }];
    return arr;
}

- (void)nameIsAlphabeticalAscending {

    for (NSString *alphat in self.alphaArr) {
        NSMutableArray *sectionArr = [[NSMutableArray alloc] init];
        for (int i = 0; i < self.dataArr.count; i++) {
            AccountInfo *info = self.dataArr[i];
            NSString *obj = [info.username substringToIndex:1];
            const char *utf8 = [obj UTF8String];
            if (strlen(utf8) == 3) {
                NSString *pinyin = [ChineseToPinyin pinyinFromChiniseString:obj];
                NSString *pinyinFirst = [pinyin substringToIndex:1];
                NSString *upperStr = [pinyinFirst uppercaseString];
                if ([upperStr isEqualToString:alphat]) {
                    [sectionArr objectAddObject:info];
                }
            } else {
                NSString *upperStr = [obj uppercaseString];
                if ([upperStr isEqualToString:alphat]) {
                    [sectionArr objectAddObject:info];
                }
            }
        }
        [self.sectionArr objectAddObject:sectionArr];
    }

}

#pragma mark --lazy

- (NSMutableArray *)selectedList {
    if (_selectedList == nil) {
        _selectedList = [NSMutableArray array];
    }
    return _selectedList;
}

- (NSMutableArray *)dataArr {
    if (_dataArr == nil) {
        _dataArr = [NSMutableArray array];
    }
    return _dataArr;
}

- (NSMutableArray *)sectionArr {
    if (_sectionArr == nil) {
        _sectionArr = [NSMutableArray array];
    }
    return _sectionArr;
}

- (NSMutableArray *)alphaArr {
    if (_alphaArr == nil) {
        _alphaArr = [NSMutableArray array];
    }
    return _alphaArr;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}
@end

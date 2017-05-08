//
//  LMGroupFriendsViewController.m
//  Connect
//
//  Created by Edwin on 16/8/24.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMGroupFriendsViewController.h"
#import "LMTransFriendsViewController.h"
#import "LMSelectTableViewCell.h"
#import "UIImage+Color.h"
#import "NSString+Size.h"

@interface LMGroupFriendsViewController () <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSMutableArray *selectedList;

@property(nonatomic, strong) TransferButton *transferBtn;


@end

static NSString *friends = @"friends";

@implementation LMGroupFriendsViewController

- (void)viewDidLoad {
    self.title = LMLocalizedString(@"Chat Choose Members", nil);
    for (AccountInfo *info in self.groupFriends) {
        if ([info.address isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].address]) {
            [self.groupFriends removeObject:info];
            break;
        }
    }
    [super viewDidLoad];
    self.navigationItem.leftBarButtonItems = nil;
    [self addNewCloseBarItem];
}

/**
 * get status
 */
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    for (AccountInfo *user in self.selectedList) {
        user.isSelected = NO;
    }
}

- (void)setup {
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, VSIZE.width, VSIZE.height - 64) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.rowHeight = AUTO_HEIGHT(115);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:self.tableView];
    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    self.tableView.sectionIndexColor = [UIColor lightGrayColor];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    [self.tableView registerNib:[UINib nibWithNibName:@"LMSelectTableViewCell" bundle:nil] forCellReuseIdentifier:friends];

    [self setRightBarButtonItemWithEnable:NO withDispalyString:LMLocalizedString(@"Wallet Transfer", nil) withDisplayColor:[UIColor colorWithWhite:1.0 alpha:0.5]];

}

/**
 *  create right button
 */
- (void)setRightBarButtonItemWithEnable:(BOOL)enable withDispalyString:(NSString *)titleName withDisplayColor:(UIColor *)color {
    self.navigationItem.rightBarButtonItems = nil;

    self.transferBtn = [[TransferButton alloc] initWithNormalTitle:titleName disableTitle:titleName];
    self.transferBtn.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
    self.transferBtn.width = [titleName widthWithFont:[UIFont systemFontOfSize:FONT_SIZE(28)] constrainedToHeight:MAXFLOAT];
    self.transferBtn.height = 44;
    [self.transferBtn addTarget:self action:@selector(transferBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.transferBtn];
    [self.transferBtn setBackgroundImage:[UIImage imageWithColor:[UIColor clearColor]] forState:UIControlStateDisabled];
    [self.transferBtn setBackgroundImage:[UIImage imageWithColor:[UIColor clearColor]] forState:UIControlStateNormal];
    if (enable) {
        [self.transferBtn setTitleColor:color forState:UIControlStateNormal];
    } else {
        [self.transferBtn setTitleColor:color forState:UIControlStateDisabled];
    }

    self.transferBtn.enabled = enable;
}

#pragma mark -- get friends

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.groupFriends.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return AUTO_HEIGHT(40);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    LMSelectTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

    AccountInfo *info = self.groupFriends[indexPath.row];
    info.isSelected = !info.isSelected;
    [cell.checkBox setOn:info.isSelected animated:YES];
    if (info.isSelected) {
        [self.selectedList objectAddObject:info];
    } else {
        [self.selectedList removeObject:info];
    }
    if (self.selectedList.count) {
        [self setRightBarButtonItemWithEnable:YES withDispalyString:[NSString stringWithFormat:LMLocalizedString(@"Wallet Transfer Count", nil), (int)self.selectedList.count] withDisplayColor:LMBasicGreen];
    } else {
        [self setRightBarButtonItemWithEnable:NO withDispalyString:LMLocalizedString(@"Wallet Transfer", nil) withDisplayColor:[UIColor colorWithWhite:1.0 alpha:0.5]];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, VSIZE.width, AUTO_HEIGHT(40))];
    bgView.backgroundColor = [UIColor colorWithRed:236 / 255.0 green:236 / 255.0 blue:236 / 255.0 alpha:1.0];
    UILabel *titleOneLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, VSIZE.width - 20, AUTO_HEIGHT(40))];
    titleOneLabel.backgroundColor = [UIColor colorWithRed:236 / 255.0 green:236 / 255.0 blue:236 / 255.0 alpha:1.0];
    titleOneLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Chat Group Members", nil), self.groupFriends.count];;
    titleOneLabel.font = [UIFont systemFontOfSize:FONT_SIZE(26)];
    titleOneLabel.textColor = [UIColor blackColor];
    titleOneLabel.textAlignment = NSTextAlignmentLeft;
    [bgView addSubview:titleOneLabel];
    return bgView;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LMSelectTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:friends];
    if (!cell) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"LMSelectTableViewCell" owner:nil options:nil] lastObject];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    AccountInfo *info = self.groupFriends[indexPath.row];
    [cell setAccoutInfo:info];
    return cell;
}

- (void)transferBtnClicked:(UIButton *)btn {
    __weak typeof(self) weakSelf = self;
    if (self.selectedList.count == 0) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Chat Choose Members", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
        return;
    }
    LMTransFriendsViewController *transfer = [[LMTransFriendsViewController alloc] init];
    transfer.selectArr = self.selectedList;
    [self.navigationController pushViewController:transfer animated:YES];
}

#pragma mark --lazy

- (NSMutableArray *)groupFriends {
    if (!_groupFriends) {
        _groupFriends = [NSMutableArray array];
    }
    return _groupFriends;
}

- (NSMutableArray *)selectedList {
    if (!_selectedList) {
        _selectedList = [NSMutableArray array];
    }
    return _selectedList;
}

@end

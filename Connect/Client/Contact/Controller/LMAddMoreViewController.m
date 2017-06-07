//
//  LMAddMoreViewController.m
//  Connect
//
//  Created by bitmain on 2017/1/19.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMAddMoreViewController.h"
#import "LMRecommandFriendManager.h"
#import "NewFriendCell.h"
#import "InviteUserPage.h"
#import "UserDBManager.h"
#import "LMLinkManDataManager.h"
#import "IMService.h"
@interface LMAddMoreViewController ()<MGSwipeTableCellDelegate>
@property(strong, nonatomic) NSMutableArray *allArray;
@property(nonatomic, assign) int page;

@end

@implementation LMAddMoreViewController
#pragma mark - 懒加载

- (NSArray *)allArray {
    if (_allArray == nil) {
        self.allArray = [NSMutableArray array];
    }
    return _allArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configTableView];
    self.title = LMLocalizedString(@"Link People you may know", nil);
}

- (void)viewWillAppear:(BOOL)animated {
    if (self.allArray.count > 0) {
        [self.allArray removeAllObjects];
    }
    NSMutableArray *friendArray = [[UserDBManager sharedManager] getAllNewFirendRequest].mutableCopy;
    for (AccountInfo *user in friendArray) {
        if ([[LMRecommandFriendManager sharedManager] getUserInfoWithAddress:user.address]) {
            [[LMRecommandFriendManager sharedManager] deleteRecommandFriendWithAddress:user.address];
        }
    }
    // filter contacts
    for (AccountInfo *user in [LMLinkManDataManager sharedManager].getListFriendsArr) {
        if ([[LMRecommandFriendManager sharedManager] getUserInfoWithAddress:user.address]) {
            [[LMRecommandFriendManager sharedManager] deleteRecommandFriendWithAddress:user.address];
        }
    }
    self.page = 1;
    self.allArray = [[LMRecommandFriendManager sharedManager] getRecommandFriendsWithPage:self.page withStatus:1].mutableCopy;
    [self.tableView reloadData];
   
    // pull up load more
    __weak typeof(self)weakSelf = self;
    self.tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
        weakSelf.page += 1;
        NSArray* array = [[LMRecommandFriendManager sharedManager] getRecommandFriendsWithPage:weakSelf.page withStatus:1];
        if (array.count > 0) {
            [weakSelf.tableView.mj_footer endRefreshing];
            [weakSelf.allArray addObjectsFromArray:array];
            [GCDQueue executeInMainQueue:^{
                [weakSelf.tableView reloadData];
            }];
        }else
        {
            [weakSelf.tableView.mj_footer endRefreshingWithNoMoreData];
        }
    }];
    
    
}

#pragma mark - 配置tableview

- (void)configTableView {
    [self.tableView registerNib:[UINib nibWithNibName:@"NewFriendCell" bundle:nil] forCellReuseIdentifier:@"NewFriendCellID"];
    self.tableView.sectionIndexColor = [UIColor lightGrayColor];
    self.tableView.sectionIndexBackgroundColor = [UIColor clearColor];
    self.tableView.backgroundColor = LMBasicBackgroundColor;
    self.tableView.rowHeight = AUTO_HEIGHT(111);
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
}

#pragma mark - tableview的 datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.allArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    __weak typeof(self) weakSelf = self;
    NewFriendCell *fcell = [tableView dequeueReusableCellWithIdentifier:@"NewFriendCellID" forIndexPath:indexPath];
    fcell.addButtonBlock = ^(AccountInfo *userInfo) {
        [weakSelf addActionWithUserInfo:userInfo];
    };
    fcell.delegate = self;
    fcell.data = self.allArray[indexPath.row];
    return fcell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    AccountInfo *userInfo = self.allArray[indexPath.row];
    [self addActionWithUserInfo:userInfo];
}
#pragma mark - MGSwipeTableCellDelegate

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction; {
    return YES;
}

- (NSArray *)swipeTableCell:(MGSwipeTableCell *)cell swipeButtonsForDirection:(MGSwipeDirection)direction
              swipeSettings:(MGSwipeSettings *)swipeSettings expansionSettings:(MGSwipeExpansionSettings *)expansionSettings {
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    __weak __typeof(&*self) weakSelf = self;
    CGFloat padding = AUTO_WIDTH(50);
    if (direction == MGSwipeDirectionRightToLeft) {
        MGSwipeButton *trashButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"message_trash"] backgroundColor:[UIColor whiteColor] padding:padding callback:^BOOL(MGSwipeTableCell *sender) {
            AccountInfo *userInfo = weakSelf.allArray[indexPath.row];
            [weakSelf NotInterestedWithAddress:userInfo.address];
            return YES;
        }];
        return @[trashButton];
    }
    return nil;
}
- (void)swipeTableCell:(MGSwipeTableCell *)cell didChangeSwipeState:(MGSwipeState)state gestureIsActive:(BOOL)gestureIsActive {
    if (state == MGSwipeStateNone) {
        self.tableView.scrollEnabled = YES;
    } else {
        self.tableView.scrollEnabled = NO;
    }
}

#pragma mark -  add methods
- (void)NotInterestedWithAddress:(NSString *)oldAddress {
    
    [MBProgressHUD showLoadingMessageToView:self.view];
    [[IMService instance] setRecommandUserNoInterestAdress:oldAddress comlete:^(NSError *error, id data) {
        if (error == nil) {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD hideHUDForView:self.view];
            }];
            NSString *address = (NSString *) data;
            [[LMRecommandFriendManager sharedManager] updateRecommandFriendStatus:3 withAddress:address];
            if (self.deleBlcok) {
                self.deleBlcok();
            }
            [self creatAllArray:address];
        } else {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Operation failed", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            }];
        }
    }];
}
- (void)creatAllArray:(NSString *)address {
    AccountInfo* deleteUser = nil;
    for (AccountInfo *user in self.allArray) {
        if ([user.address isEqualToString:address]) {
            deleteUser = user;
            break;
        }
    }
    if (deleteUser.address.length > 0) {
        [self.allArray removeObject:deleteUser];
        [GCDQueue executeInMainQueue:^{
            [self.tableView reloadData];
        }];
    }
}
- (void)addActionWithUserInfo:(AccountInfo *)userInfo {
    userInfo.source = UserSourceTypeRecommend;
    userInfo.stranger = YES;
    InviteUserPage *page = [[InviteUserPage alloc] initWithUser:userInfo];
    page.sourceType = UserSourceTypeRecommend;
    [self.navigationController pushViewController:page animated:YES];
}

- (void)dealloc {
    [self.tableView removeFromSuperview];
    self.tableView = nil;

}
@end

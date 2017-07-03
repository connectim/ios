//
//  SelectLoginUserViewController.m
//  Connect
//
//  Created by MoHuilin on 2016/12/7.
//  Copyright © 2016年 Connect - P2P Encrypted Instant Message. All rights reserved.
//

#import "SelectLoginUserViewController.h"
#import "NSString+Size.h"
#import "LinkmanFriendCell.h"
#import "MMGlobal.h"
#import "ConnectTableHeaderView.h"


@interface SelectLoginUserViewController () <UITableViewDelegate, UITableViewDataSource, MGSwipeTableCellDelegate> {
    void (^selectedUserBlock)(AccountInfo *user);
}

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSMutableArray *users;
@property(nonatomic, strong) AccountInfo *selectedUser;

@end


@implementation SelectLoginUserViewController


- (instancetype)initWithCallBackBlock:(void (^)(AccountInfo *user))block
                            chainUser:(NSArray *)chainUser
                         selectedUser:(AccountInfo *)selectedUser {
    if (self = [super init]) {
        selectedUserBlock = block;
        self.selectedUser = selectedUser;
        self.users = chainUser;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    UILabel *titleLabel = [UILabel new];
    titleLabel.text = LMLocalizedString(@"Login Select User", nil);
    titleLabel.size = [titleLabel.text sizeWithFont:titleLabel.font constrainedToHeight:44];
    self.navigationItem.titleView = titleLabel;
    
    [self setBlackfBackArrowItem];
    [self.view addSubview:self.tableView];
    
    for (AccountInfo *user in self.users) {
        if ([user.address isEqualToString:self.selectedUser.address]) {
            user.isSelected = YES;
        } else {
            user.isSelected = NO;
        }
    }
    [self.tableView reloadData];
}

#pragma mark - delete local user

- (void)deleteLoacalUser:(AccountInfo *)willDeleteUser {
    [GCDQueue executeInGlobalQueue:^{
        [self.users removeObject:willDeleteUser];
        // delete preferences
        NSString *plistPath = GJCFAppDoucmentPath(@"AccountSetInfo.plist");
        NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
        DDLogInfo(@"%@", data);
        NSMutableArray *accounts = [data valueForKey:@"accounts"];
        for (NSDictionary *temD in accounts) {
            if ([temD valueForKey:willDeleteUser.address]) {
                [accounts removeObject:temD];
                break;
            }
        }
        if (accounts.count > 0) {
            NSMutableDictionary *all = @{@"accounts": accounts}.mutableCopy;
            [all writeToFile:plistPath atomically:YES];
        }
        //delete keychain
        [[MMAppSetting sharedSetting] deleteKeyChainUserWithUser:willDeleteUser];
        //delete user db 
        NSString *dbPath = [MMGlobal getDBFile:willDeleteUser.pub_key];
        GJCFFileDeleteFile(dbPath);
        [[MMAppSetting sharedSetting] deleteLocalUserWithAddress:willDeleteUser.address];
        BOOL isSelectedUser = willDeleteUser.isSelected;
        [self.users removeObject:willDeleteUser];
        [GCDQueue executeInMainQueue:^{
            [self.tableView reloadData];
            if (isSelectedUser && selectedUserBlock) {
                if (self.users.count == 0) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                } else {
                    selectedUserBlock([self.users firstObject]);
                }
            }
        }];
    }];
}

#pragma mark -UITableViewDelegate


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    ConnectTableHeaderView *hearderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"ConnectTableHeaderViewID"];
    hearderView.customTitle.text = LMLocalizedString(@"Login Local User", nil);
    return hearderView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return AUTO_HEIGHT(40);
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.users.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LinkmanFriendCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LinkmanFriendCellID" forIndexPath:indexPath];
    AccountInfo *user = [self.users objectAtIndexCheck:indexPath.row];
    if (user.isSelected) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    cell.data = user;
    cell.delegate = self;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    AccountInfo *user = [self.users objectAtIndexCheck:indexPath.row];
    if (selectedUserBlock) {
        selectedUserBlock(user);
    }
    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark Swipe Delegate

- (BOOL)swipeTableCell:(MGSwipeTableCell *)cell canSwipe:(MGSwipeDirection)direction; {
    return YES;
}

- (NSArray *)swipeTableCell:(MGSwipeTableCell *)cell swipeButtonsForDirection:(MGSwipeDirection)direction
              swipeSettings:(MGSwipeSettings *)swipeSettings expansionSettings:(MGSwipeExpansionSettings *)expansionSettings {

    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    AccountInfo *user = [self.users objectAtIndexCheck:indexPath.row];
    swipeSettings.transition = MGSwipeTransitionStatic;
    if (direction == MGSwipeDirectionRightToLeft) {
        CGFloat padding = AUTO_WIDTH(30);
        __weak __typeof(&*self) weakSelf = self;
        MGSwipeButton *setButton = [MGSwipeButton buttonWithTitle:@"" icon:[UIImage imageNamed:@"message_trash"] backgroundColor:[UIColor whiteColor] padding:padding callback:^BOOL(MGSwipeTableCell *sender) {
            [weakSelf deleteLoacalUser:user];
            return YES;
        }];
        return @[setButton];
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

#pragma mark -getter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = AUTO_HEIGHT(100);
        _tableView.sectionIndexColor = [UIColor lightGrayColor];
        _tableView.sectionIndexBackgroundColor = [UIColor clearColor];
        [_tableView registerNib:[UINib nibWithNibName:@"LinkmanFriendCell" bundle:nil] forCellReuseIdentifier:@"LinkmanFriendCellID"];
        [_tableView registerClass:[ConnectTableHeaderView class] forHeaderFooterViewReuseIdentifier:@"ConnectTableHeaderViewID"];

        _tableView.tableFooterView = [UIView new];
    }
    return _tableView;
}

- (void)dealloc {
    [self.tableView removeFromSuperview];
    self.tableView = nil;
}
@end

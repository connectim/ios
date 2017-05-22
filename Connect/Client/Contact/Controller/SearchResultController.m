//
//  SearchResultController.m
//  Connect
//
//  Created by MoHuilin on 16/8/23.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "SearchResultController.h"
#import "PaddingTextField.h"
#import "GJGCChatFriendTalkModel.h"
#import "RecentChatDBManager.h"
#import "GJGCChatFriendViewController.h"
#import "NetWorkOperationTool.h"
#import "LMBitAddressViewController.h"
#import "InviteUserPage.h"
#import "UserDetailPage.h"
#import "UIScrollView+EmptyDataSet.h"

@interface SearchResultController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource>

@property(nonatomic, strong) NSMutableArray *resultSearchDatas;
// search result
@property(nonatomic, strong) UITableView *tableView;

@property(nonatomic, strong) UITextField *searchTextFiled;

@property(nonatomic, copy) NSString *searchText;

@end

@implementation SearchResultController

- (instancetype)initWithSearchKey:(NSString *)searchKey {
    if (self = [super init]) {
        self.searchText = searchKey;
        if ([self.searchText isEqualToString:[LKUserCenter shareCenter].currentLoginUser.address]) {
            self.searchText = @"";
        }
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
    self.tableView.frame = self.view.bounds;

    self.searchTextFiled.text = self.searchText;

    self.title = LMLocalizedString(@"Link Search Result", nil);

    [self searchByNet];

}

#pragma mark - UITableViewDelegate,UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.resultSearchDatas.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BaseCell *cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:@"AddFriendCellID" forIndexPath:indexPath];
    cell.data = self.resultSearchDatas[indexPath.row];
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];


    AccountInfo *user = [self.resultSearchDatas objectAtIndexCheck:indexPath.row];
    if (user.isUnRegisterAddress) {
        return;
    }
    if (!user.stranger) {
        UserDetailPage *detailPage = [[UserDetailPage alloc] initWithUser:user];
        detailPage.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:detailPage animated:YES];
    }
}


- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *title = LMLocalizedString(@"Wallet No match user", nil);
    return [[NSAttributedString alloc] initWithString:title];
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    return nil;
}

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView {
    return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self searchByNet];
    return YES;
}

- (void)searchByNet {
    // clear
    [self.resultSearchDatas removeAllObjects];
    [self.view endEditing:YES];
    __weak __typeof(&*self) weakSelf = self;
    NSString *keyWord = _searchTextFiled.text;
    keyWord = [keyWord stringByReplacingOccurrencesOfString:@"-" withString:@""];
    keyWord = [keyWord stringByReplacingOccurrencesOfString:@" " withString:@""];
    SearchUser *search = [[SearchUser alloc] init];
    search.criteria = keyWord;
    [NetWorkOperationTool POSTWithUrlString:ContactUserSearchUrl postProtoData:search.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *) response;
        if (hResponse.code != successCode) {
           [GCDQueue executeInMainQueue:^{
               [MBProgressHUD showToastwithText:[LMErrorCodeTool showToastErrorType:ToastErrorTypeContact withErrorCode:hResponse.code withUrl:ContactUserSearchUrl] withType:ToastTypeCommon showInView:weakSelf.view complete:nil];
           }];
            return;
        }

        NSData *data = [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            UserInfo *user = [UserInfo parseFromData:data error:nil];
            AccountInfo *userInfo = [[AccountInfo alloc] init];
            userInfo.username = user.username;
            userInfo.avatar = user.avatar;
            userInfo.pub_key = user.pubKey;
            userInfo.address = user.address;
            [weakSelf reloadTableViewWith:userInfo];
        }
    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:@"Network Server error" withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
    }];

}

- (void)reloadTableViewWith:(AccountInfo *)userInfo {

    userInfo.stranger = ![[UserDBManager sharedManager] isFriendByAddress:userInfo.address];
    __weak __typeof(&*userInfo) weakUser = userInfo;
    __weak __typeof(&*self) weakSelf = self;
    userInfo.customOperation = ^{
        __strong __typeof(&*weakUser) strongUser = weakUser;
        InviteUserPage *page = [[InviteUserPage alloc] initWithUser:strongUser];
        page.sourceType = UserSourceTypeSearch;
        [weakSelf.navigationController pushViewController:page animated:YES];
    };
    [self.resultSearchDatas removeAllObjects];
    [self.resultSearchDatas objectAddObject:userInfo];
    [self.tableView reloadData];
}


- (void)transferToAddress:(AccountInfo *)userInfo {
    LMBitAddressViewController *page = [[LMBitAddressViewController alloc] init];
    page.address = userInfo.address;
    [self.navigationController pushViewController:page animated:YES];
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.emptyDataSetDelegate = self;
        _tableView.emptyDataSetSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.rowHeight = AUTO_HEIGHT(110);
        [_tableView registerNib:[UINib nibWithNibName:@"SearchByNetCell" bundle:nil] forCellReuseIdentifier:@"SearchByNetCellID"];
        [_tableView registerNib:[UINib nibWithNibName:@"LinkmanFriendCell" bundle:nil] forCellReuseIdentifier:@"LinkmanFriendCellID"];
        [_tableView registerNib:[UINib nibWithNibName:@"AddFriendCell" bundle:nil] forCellReuseIdentifier:@"AddFriendCellID"];


        // head search tip 
        UIView *headerView = [[UIView alloc] init];
        headerView.size = AUTO_SIZE(750, 150);
        PaddingTextField *searchField = [PaddingTextField new];
        [searchField becomeFirstResponder];
        self.searchTextFiled = searchField;
        _searchTextFiled.text = self.searchText;
        _searchTextFiled.returnKeyType = UIReturnKeySearch;
        _searchTextFiled.delegate = self;
        _searchTextFiled.clearButtonMode = UITextFieldViewModeWhileEditing;
        searchField.borderStyle = UITextBorderStyleRoundedRect;
        searchField.placeholder = LMLocalizedString(@"Link search someThing", nil);
        [headerView addSubview:searchField];
        searchField.frame = AUTO_RECT(30, 20, 690, 80);
        searchField.backgroundColor = [UIColor whiteColor];
        _tableView.tableHeaderView = headerView;
    }

    return _tableView;
}


- (NSMutableArray *)resultSearchDatas {
    if (!_resultSearchDatas) {
        _resultSearchDatas = [NSMutableArray array];
    }
    return _resultSearchDatas;
}

@end

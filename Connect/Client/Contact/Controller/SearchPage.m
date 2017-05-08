//
//  SearchPage.m
//  Connect
//
//  Created by MoHuilin on 16/5/25.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "SearchPage.h"
#import "SearchByNetCell.h"

#import "NSString+Pinyin.h"

#import "LMSearchTextField.h"
#import "UserDBManager.h"
#import "InviteUserPage.h"
#import "UserDetailPage.h"
#import "GJGCChatFriendTalkModel.h"
#import "LMBitAddressViewController.h"
#import "ConnectTableHeaderView.h"
#import "SearchResultController.h"
#import "UIScrollView+EmptyDataSet.h"
#import "GJGCChatGroupViewController.h"
#define cancelWidth  AUTO_WIDTH(150)

@interface SearchPage () <UITableViewDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource, UITableViewDataSource, UITextFieldDelegate>

@property(nonatomic, strong) LMSearchTextField *searchTextFiled;

@property(nonatomic, strong) UITableView *tableView;

@property(nonatomic, strong) NSArray *users;
@property(nonatomic, strong) NSArray *groups;


@property(nonatomic, strong) NSMutableArray *resultSearchDatas;

@property(nonatomic, copy) NSString *searchText;

// new search ui
@property(nonatomic, strong) UIView *TitleView;
@property(nonatomic, strong) UIButton *leftButton;
@property(nonatomic, strong) UIButton *cancelButton;
@property(nonatomic, strong) UIView *maskView;


@end

@implementation SearchPage


- (instancetype)initWithUsers:(NSArray *)users groups:(NSArray *)groups {
    if (self = [super init]) {
        self.users = users;
        self.groups = groups;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.view endEditing:YES];
    
}
- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItems = nil;


    [self.view addSubview:self.tableView];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.right.left.bottom.equalTo(self.view);
    }];
    [self.tableView reloadData];
    [self setUpSearch];
}
// new search
-(void)setUpSearch
{
    // creat title
    if (self.TitleView == nil) {
        // total view
        UIView* titleView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_SIZE.width, 44)];
        titleView.backgroundColor = [UIColor clearColor];
        
        // search textfield
        LMSearchTextField *searchField = [LMSearchTextField new];
        [searchField becomeFirstResponder];
        self.searchTextFiled = searchField;
        [_searchTextFiled addTarget:self action:@selector(textDidChange) forControlEvents:UIControlEventEditingChanged];
        _searchTextFiled.text = self.searchText;
        _searchTextFiled.clearButtonMode = UITextFieldViewModeWhileEditing;
        searchField.backgroundColor = GJCFQuickRGBColorAlpha(255,255,255,0.1);
        searchField.borderStyle = UITextBorderStyleRoundedRect;
        [searchField disPLayPlaceHolder:LMLocalizedString(@"Link Search", nil)];
        searchField.frame = CGRectMake(0, 8, DEVICE_SIZE.width - cancelWidth, 28);
        searchField.textColor = [UIColor whiteColor];
        searchField.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
        [titleView addSubview:searchField];
        //textfield 的leftview
        UIImageView* leftImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 13, 13)];
        leftImageView.image = [UIImage imageNamed:@"icon-search-small"];
        searchField.leftView = leftImageView;
        searchField.leftViewMode = UITextFieldViewModeAlways;
        // creat cacel button
        UIButton* cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [cancelButton addTarget:self action:@selector(cancelButtonAction) forControlEvents:UIControlEventTouchUpInside];
        cancelButton.frame = CGRectMake(DEVICE_SIZE.width - cancelWidth, 0, cancelWidth, 44);
        [cancelButton setTitle:LMLocalizedString(@"Common Cancel", nil) forState:UIControlStateNormal];
        cancelButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
        cancelButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
        self.cancelButton = cancelButton;
        [titleView addSubview:cancelButton];
        self.TitleView = titleView;
        // creat view
        if (self.maskView == nil) {
            UIView* maskView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, DEVICE_SIZE.width, DEVICE_SIZE.height)];
            maskView.backgroundColor = GJCFQuickRGBColorAlpha(122,122,122,0.4);
            [self.view addSubview:maskView];
            self.maskView = maskView;
        }
        
    }
    self.navigationItem.leftBarButtonItems = nil;
    self.navigationItem.rightBarButtonItems = nil;
    self.navigationItem.titleView = self.TitleView;
    
}
// cacel button action
-(void)cancelButtonAction
{
    [self dismissViewControllerAnimated:NO completion:nil];
}
- (void)doRight:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (void)textDidChange {

    [self.resultSearchDatas removeAllObjects];
    NSString *conditionText = [_searchTextFiled.text uppercaseString];
    if (GJCFStringIsNull(conditionText)) {
        [self.tableView reloadData];
        return;
    }

    [GCDQueue executeInGlobalQueue:^{

        CellGroup *searchGroup = [[CellGroup alloc] init];
        searchGroup.items = @[@""];
        [self.resultSearchDatas objectAddObject:searchGroup];

        NSMutableArray *groups = @[].mutableCopy;
        for (LMGroupInfo *info in self.groups) {
            NSString *name = info.groupName;
            name = [name uppercaseString];
            if ([name containsString:conditionText]) { //username contact
                if (![groups containsObject:info]) {
                    [groups objectAddObject:info];
                }
            } else {
                NSString *namePiny = [name pinyin];
                if ([namePiny containsString:conditionText]) {
                    if (![groups containsObject:info]) {
                        [groups addObject:info];
                    }
                }
            }
        }

        if (groups.count > 0) {
            CellGroup *group = [[CellGroup alloc] init];
            group.headTitle = LMLocalizedString(@"Group contacts", nil);
            group.items = groups;
            [self.resultSearchDatas objectAddObject:group];
        }


        NSMutableArray *contacts = @[].mutableCopy;
        for (AccountInfo *info in self.users) {
            NSString *name = info.normalShowName;
            name = [name uppercaseString];
            if ([name containsString:conditionText]) {
                if (![contacts containsObject:info]) {
                    [contacts objectAddObject:info];
                }
            } else {
                NSString *namePiny = [name pinyin];
                if ([namePiny containsString:conditionText]) {
                    if (![contacts containsObject:info]) {
                        [contacts objectAddObject:info];
                    }
                }
            }
        }
        if (contacts.count) {
            CellGroup *contactGroup = [[CellGroup alloc] init];
            contactGroup.headTitle = LMLocalizedString(@"Link Contacts", nil);
            contactGroup.items = contacts;
            [self.resultSearchDatas objectAddObject:contactGroup];
        }
        [GCDQueue executeInMainQueue:^{
            if (self.maskView != nil) {
                [self.maskView removeFromSuperview];
                self.maskView = nil;
            }
            [self.tableView reloadData];
        }];
    }];
}


- (void)transferToAddress:(AccountInfo *)userInfo {
    LMBitAddressViewController *page = [[LMBitAddressViewController alloc] init];
    page.address = userInfo.address;
    [self.navigationController pushViewController:page animated:YES];
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

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    return YES;
}

#pragma mark - UITableViewDelegate,UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    CellGroup *group = self.resultSearchDatas[section];
    return group.items.count;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.resultSearchDatas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BaseCell *cell = nil;
    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"SearchByNetCellID" forIndexPath:indexPath];
        cell.data = _searchTextFiled.text;
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"LinkmanFriendCellID" forIndexPath:indexPath];
        CellGroup *group = self.resultSearchDatas[indexPath.section];
        id data = [group.items objectAtIndexCheck:indexPath.row];
        cell.data = data;
    }

    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return nil;
    }
    CellGroup *group = self.resultSearchDatas[section];
    ConnectTableHeaderView *hearderView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"ConnectTableHeaderViewID"];
    hearderView.customTitle.text = group.headTitle;
    return hearderView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 20;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        SearchResultController *page = [[SearchResultController alloc] initWithSearchKey:self.searchTextFiled.text];
        [self.navigationController pushViewController:page animated:YES];
        return;
    }

    CellGroup *group = self.resultSearchDatas[indexPath.section];
    id data = [group.items objectAtIndexCheck:indexPath.row];
    if ([data isKindOfClass:[AccountInfo class]]) {
        AccountInfo *user = (AccountInfo*)data;
        if (user.isUnRegisterAddress) {
            return;
        }
        if (!user.stranger) {
            UserDetailPage *detailPage = [[UserDetailPage alloc] initWithUser:user];
            detailPage.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:detailPage animated:YES];
        }
    }else if([data isKindOfClass:[LMGroupInfo class]])
    {
        LMGroupInfo* group = (LMGroupInfo*)data;
        GJGCChatFriendTalkModel *talk = [[GJGCChatFriendTalkModel alloc] init];
        talk.talkType = GJGCChatFriendTalkTypeGroup;
        talk.chatIdendifier = group.groupIdentifer;
        talk.group_ecdhKey = group.groupEcdhKey;
        talk.chatGroupInfo = group;
        //save session
        [SessionManager sharedManager].chatSession = talk.chatIdendifier;
        [SessionManager sharedManager].chatObject = group;
        talk.name = GJCFStringIsNull(group.groupName) ? [NSString stringWithFormat:LMLocalizedString(@"Link Group", nil), (unsigned long) talk.chatGroupInfo.groupMembers.count] : [NSString stringWithFormat:@"%@(%lu)", group.groupName, (unsigned long) talk.chatGroupInfo.groupMembers.count];
        GJGCChatGroupViewController *groupChat = [[GJGCChatGroupViewController alloc] initWithTalkInfo:talk];
        groupChat.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:groupChat animated:YES];
    }else
    {
        return;
    }
    
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.view endEditing:YES];
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


#pragma mark - getter setter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.emptyDataSetSource = self;
        _tableView.emptyDataSetDelegate = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.rowHeight = AUTO_HEIGHT(110);
        [_tableView registerNib:[UINib nibWithNibName:@"SearchByNetCell" bundle:nil] forCellReuseIdentifier:@"SearchByNetCellID"];
        [_tableView registerNib:[UINib nibWithNibName:@"LinkmanFriendCell" bundle:nil] forCellReuseIdentifier:@"LinkmanFriendCellID"];
        [_tableView registerNib:[UINib nibWithNibName:@"AddFriendCell" bundle:nil] forCellReuseIdentifier:@"AddFriendCellID"];
        [_tableView registerClass:[ConnectTableHeaderView class] forHeaderFooterViewReuseIdentifier:@"ConnectTableHeaderViewID"];
    }

    return _tableView;
}

- (NSMutableArray *)resultSearchDatas {
    if (!_resultSearchDatas) {
        _resultSearchDatas = [NSMutableArray array];
    }
    return _resultSearchDatas;
}
-(void)dealloc
{
   [self.TitleView removeFromSuperview];
    self.TitleView = nil;
    [self.leftButton removeFromSuperview];
    self.leftButton = nil;
    [self.cancelButton removeFromSuperview];
    self.cancelButton = nil;
    [self.maskView removeFromSuperview];
    self.maskView = nil;
}

@end

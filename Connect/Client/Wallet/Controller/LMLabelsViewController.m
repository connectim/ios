//
//  LMLabelsViewController.m
//  Connect
//
//  Created by Edwin on 16/8/30.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "LMLabelsViewController.h"
#import "LMLabelsTableViewCell.h"
#import "UserDBManager.h"

@interface LMLabelsViewController () <UITableViewDelegate, UITableViewDataSource, LMLabelsTableViewCellDelegate>

@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSMutableArray *dataArr;
@property(nonatomic, strong) NSMutableArray *labelsArr;
@property(nonatomic, strong) NSMutableArray *selectedList;


@end

static NSString *labels = @"labels";

@implementation LMLabelsViewController

- (NSMutableArray *)dataArr {
    if (!_dataArr) {
        _dataArr = [NSMutableArray array];
    }
    return _dataArr;
}

- (NSMutableArray *)labelsArr {
    if (!_labelsArr) {
        _labelsArr = [NSMutableArray array];
    }
    return _labelsArr;
}

- (NSMutableArray *)selectedList {
    if (!_selectedList) {
        _selectedList = [NSMutableArray array];
    }
    return _selectedList;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Wallet Tags", nil);
    self.labelsArr = [[[UserDBManager sharedManager] tagList] mutableCopy];
    for (NSString *label in self.labelsArr) {
        NSLog(@"label === %@", labels);
        LMLabels *labels = [[LMLabels alloc] init];
        labels.label = label;
        NSMutableArray *userInfo = [[[UserDBManager sharedManager] getTagUsers:label] mutableCopy];
        labels.info = userInfo;
        [self.dataArr objectAddObject:labels];
    }


    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 64, VSIZE.width, VSIZE.height - 64) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.view addSubview:self.tableView];

    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    [self.tableView registerNib:[UINib nibWithNibName:@"LMLabelsTableViewCell" bundle:nil] forCellReuseIdentifier:labels];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LMLabelsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:labels];
    if (!cell) {
        cell = [[LMLabelsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:labels];
    }

    cell.delegate = self;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.userInteractionEnabled = YES;
    LMLabels *labels = self.dataArr[indexPath.row];
    [cell setLabels:labels];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArr.count;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    LMLabelsTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.selectBtn.selected = !cell.selectBtn.selected;
    LMLabels *labels = self.dataArr[indexPath.row];
    if (cell.selectBtn.selected) {
        [self.selectedList objectAddObject:labels];
    } else {
        [self.selectedList removeObject:labels];
    }

    if (self.didGetLabelsArrAndRefresh) {
        self.didGetLabelsArrAndRefresh(self.selectedList, YES);
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return AUTO_HEIGHT(120);
}


- (void)LMLabelsTableViewCell:(LMLabelsTableViewCell *)cell SelectedBtnClick:(UIButton *)btn {
    btn.selected = !btn.selected;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    LMLabels *labels = self.dataArr[indexPath.row];
    if (cell.selectBtn.selected) {
        [self.selectedList objectAddObject:labels];
    } else {
        [self.selectedList removeObject:labels];
    }
    if (self.didGetLabelsArrAndRefresh) {
        self.didGetLabelsArrAndRefresh(self.selectedList, YES);
    }
}

- (UIBarButtonItem *)backItem {
    UIButton *btn = nil;
    if (GJCFSystemiPhone6 || GJCFSystemiPhone5) {
        btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 44, 44)];
    } else {
        btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 22, 22)];
    }
    [btn setImage:[UIImage imageNamed:@"back_white"] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(actionBack:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:btn];

    return item;
}

- (void)actionBack:(UIButton *)btn {

    if (self.didGetLabelsArrAndRefresh) {
        self.didGetLabelsArrAndRefresh(self.selectedList, YES);
    }
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}
@end

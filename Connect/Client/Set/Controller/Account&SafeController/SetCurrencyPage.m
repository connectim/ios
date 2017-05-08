//
//  SetCurrencyPage.m
//  Connect
//
//  Created by MoHuilin on 16/8/16.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "SetCurrencyPage.h"

@interface SetCurrencyPage ()

@property(nonatomic, strong) CellItem *selectedItem;

@end

@implementation SetCurrencyPage

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LMLocalizedString(@"Set Currency", nil);
}

- (void)configTableView {
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SystemCellID"];
}

- (void)setupCellData {
    __weak __typeof(&*self) weakSelf = self;

    [self.groups removeAllObjects];
    // zero group
    CellGroup *group = [[CellGroup alloc] init];

    CellItem *dollar = [CellItem itemWithTitle:@"$ USD" type:CellItemTypeNone operation:^{
        [[MMAppSetting sharedSetting] setcurrency:@"usd/$"];
        [GCDQueue executeInMainQueue:^{
            SendNotify(@"changeCurrencyNotification", nil);
            [weakSelf setupCellData];
            [weakSelf.tableView reloadData];
        }];
    }];
    CellItem *cny = [CellItem itemWithTitle:@"¥ CNY" type:CellItemTypeNone operation:^{
        [[MMAppSetting sharedSetting] setcurrency:@"cny/¥"];
        [GCDQueue executeInMainQueue:^{
            SendNotify(@"changeCurrencyNotification", nil);
            [weakSelf setupCellData];
            [weakSelf.tableView reloadData];
        }];

    }];

    CellItem *rub = [CellItem itemWithTitle:@"₽ RUB" type:CellItemTypeNone operation:^{
        [[MMAppSetting sharedSetting] setcurrency:@"rub/₽"];
        [GCDQueue executeInMainQueue:^{
            SendNotify(@"changeCurrencyNotification", nil);
            [weakSelf setupCellData];
            [weakSelf.tableView reloadData];
        }];
    }];

    NSString *language = [[MMAppSetting sharedSetting] getcurrency];
    if ([[language lowercaseString] containsString:@"cny"]) {
        self.selectedItem = cny;
    }

    if ([[language lowercaseString] containsString:@"usd"]) {
        self.selectedItem = dollar;
    }

    if ([[language lowercaseString] containsString:@"rub"]) {
        self.selectedItem = rub;
    }


    group.items = @[dollar, cny, rub].copy;

    [self.groups objectAddObject:group];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {


    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];
    BaseCell *cell;
    if (item.type == CellItemTypeNone) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"SystemCellID"];
        if (item == self.selectedItem) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
        cell.textLabel.text = item.title;
        cell.textLabel.font = [UIFont systemFontOfSize:FONT_SIZE(32)];
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return AUTO_HEIGHT(111);
}

@end

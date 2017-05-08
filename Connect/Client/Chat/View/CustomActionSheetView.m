//
//  CustomActionSheetView.m
//  Connect
//
//  Created by MoHuilin on 16/9/5.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "CustomActionSheetView.h"
#import "ActionSheetCell.h"

@interface CustomActionSheetView () <UITableViewDelegate, UITableViewDataSource>

@property(nonatomic, strong) UITableView *tableView;

@property(nonatomic, strong) NSMutableArray *datasArray;

@property(nonatomic, strong) NSArray *snapchatTimeArray;

@property(nonatomic, strong) CellItem *selectedItem;

@end

@implementation CustomActionSheetView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }

    return self;
}

- (void)setup {
    [self addSubview:self.tableView];
    self.tableView.frame = self.bounds;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.tableView.frame = self.bounds;
    [self setNeedsLayout];
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.backgroundColor = [UIColor clearColor];
        [_tableView registerClass:[ActionSheetCell class] forCellReuseIdentifier:@"ActionSheetCellID"];
        _tableView.rowHeight = AUTO_HEIGHT(114);
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.showsHorizontalScrollIndicator = NO;
        _tableView.scrollEnabled = NO;
    }

    return _tableView;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datasArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ActionSheetCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ActionSheetCellID" forIndexPath:indexPath];
    cell.data = [self.datasArray objectAtIndexCheck:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.row == 0) {
        return;
    }
    CellItem *item = [self.datasArray objectAtIndexCheck:indexPath.row];
    item.isSelect = YES;
    self.selectedItem = item;
    [self.datasArray replaceObjectAtIndex:indexPath.row withObject:item];
    [self.tableView reloadData];

    int snapTime = [[self.snapchatTimeArray objectAtIndexCheck:indexPath.row - 1] intValue];

    if (self.ItemClick) {
        if (self.initTime != snapTime) {
            self.ItemClick(snapTime);
        } else {
            self.ItemClick(-1); // -1 unuseful code
        }
    }
}

- (void)setInitTime:(int)initTime {
    _initTime = initTime;

    NSInteger index = NSNotFound;
    for (NSNumber *time in self.snapchatTimeArray) {
        if ([time intValue] == initTime) {
            index = [self.snapchatTimeArray indexOfObject:time];
            break;
        }
    }

    if (index != NSNotFound && index != self.snapchatTimeArray.count - 1) {
        CellItem *item = [self.datasArray objectAtIndexCheck:index + 1];
        item.isSelect = YES;
        self.selectedItem = item;
        [self.datasArray replaceObjectAtIndex:index + 1 withObject:item];
        [self.tableView reloadData];
    }

}

- (NSMutableArray *)datasArray {
    if (!_datasArray) {
        _datasArray = [NSMutableArray array];
        NSArray *temA = @[LMLocalizedString(@"Chat et self destruct timer", nil), [NSString stringWithFormat:LMLocalizedString(@"Chat Seconds", nil), 5], [NSString stringWithFormat:LMLocalizedString(@"Chat Seconds", nil), 10], [NSString stringWithFormat:LMLocalizedString(@"Chat Seconds", nil), 30], [NSString stringWithFormat:LMLocalizedString(@"Chat Minute", nil), 1], [NSString stringWithFormat:LMLocalizedString(@"Chat Minute", nil), 30], [NSString stringWithFormat:LMLocalizedString(@"Chat Hour", nil), 1], [NSString stringWithFormat:LMLocalizedString(@"Chat Hour", nil), 24], LMLocalizedString(@"Chat Disable self destruct", nil)];
        for (NSString *title in temA) {
            CellItem *item = [[CellItem alloc] init];
            item.title = title;
            if ([title isEqualToString:[temA firstObject]]) {
                item.icon = @"snapchat_actionsheet_time";
            }

            if ([title isEqualToString:[temA lastObject]]) {
                item.titleColor = [UIColor colorWithRed:0.000 green:0.502 blue:1.000 alpha:1.000];
            }
            [_datasArray objectAddObject:item];
        }
    }

    return _datasArray;
}

- (NSArray *)snapchatTimeArray {
    if (!_snapchatTimeArray) {
        _snapchatTimeArray = @[@(5 * 1000), @(10 * 1000), @(30 * 1000), @(60 * 1000), @(60 * 30 * 1000), @(60 * 60 * 1000), @(60 * 60 * 24 * 1000), @(0)];
    }
    return _snapchatTimeArray;
}


@end

//
//  CountryView.m
//  BitmainLoginLib
//
//  Created by MoHuilin on 16/3/29.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "CountryView.h"
#import "NSString+Pinyin.h"

#import "SelectCountryCell.h"


#define DEVICE_SIZE [UIScreen mainScreen].bounds.size

@interface CountryView () <UITableViewDataSource, UITableViewDelegate> {
    UIButton *closeBtn;

    void (^infoBlock)(id countryInfo);

    UIControl *maskView;
}
@property(strong, nonatomic) UITableView *tableView;

@property(strong, nonatomic) NSMutableArray *countries;

@property(strong, nonatomic) NSMutableArray *indexs;

@property(strong, nonatomic) NSMutableArray *groups;

@property(nonatomic, copy) NSString *countryCode; //


@property(nonatomic, strong) NSMutableArray *ISOCountryCodes; //

@end

@implementation CountryView


- (instancetype)initCountryViewWithBlock:(void (^)(id countryInfo))block showDissBtn:(BOOL)showDissBtn {
    if (self = [super init]) {


        NSString *path = [[NSBundle mainBundle] pathForResource:@"country" ofType:@"txt"];

        NSData *data = GJCFFileRead(path);

        self.ISOCountryCodes = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];

        NSLocale *locale = [NSLocale currentLocale];
        NSString *countryCode = [locale objectForKey:NSLocaleCountryCode];
        self.countryCode = countryCode;

        infoBlock = block;
        [self addSubview:self.tableView];
        self.tableViewStyle = CountryTableViewStytleInterleave;
        if (showDissBtn) {
            closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [self addSubview:closeBtn];
            [closeBtn setImage:[UIImage imageNamed:@"close_white"] forState:UIControlStateNormal];
            [closeBtn setTitleColor:[UIColor colorWithRed:146 / 255.0 green:201 / 255.0 blue:255 / 255.0 alpha:1] forState:UIControlStateNormal];
            [closeBtn addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];
        }
    }

    return self;
}


- (void)show {
    CGFloat width = DEVICE_SIZE.width * 4 / 5;
    CGFloat height = DEVICE_SIZE.height * 2 / 3;
    self.frame = CGRectMake(0, 0, width, height);
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    self.center = window.center;

    maskView = [UIControl new];
    [maskView addTarget:self action:@selector(hide) forControlEvents:UIControlEventTouchUpInside];

    maskView.backgroundColor = [UIColor colorWithWhite:0 alpha:.8f];
    maskView.frame = self.bounds;
    maskView.center = window.center;

    [window addSubview:maskView];
    [window addSubview:self];

    self.alpha = 0;
    [UIView animateWithDuration:.2f animations:^{
        self.alpha = 1;
        maskView.frame = window.bounds;
    }];

}

- (void)hide {
    CGAffineTransform rotation = CGAffineTransformMakeRotation(3 * M_PI);
    CGAffineTransform transform = CGAffineTransformScale(rotation, 0.1, 0.1);
    [UIView animateWithDuration:.2f animations:^{
        closeBtn.transform = transform;
    }                completion:^(BOOL finished) {
        [UIView animateWithDuration:.2f animations:^{
            self.alpha = 0;
            maskView.alpha = 0;
        }                completion:^(BOOL finished) {
            [self removeFromSuperview];
            [maskView removeFromSuperview];
        }];
    }];

}

#pragma mark -UITableViewDelegate


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *items = [self.groups[section] valueForKey:@"items"];
    return items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *items = [self.groups[indexPath.section] valueForKey:@"items"];


    SelectCountryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SelectCountryCellID" forIndexPath:indexPath];

    NSString *countryName = [items[indexPath.row] valueForKey:@"countryName"];
    NSString *phoneCode = [items[indexPath.row] valueForKey:@"phoneCode"];
    NSString *codeName = [NSString stringWithFormat:@"+%@ %@", phoneCode, countryName];
    cell.countryNameLabel.text = codeName;

    if (self.tableViewStyle == CountryTableViewStytleInterleave) {
        if (indexPath.row % 2) {
            cell.backgroundColor = [UIColor colorWithWhite:0 alpha:.6f];
        } else {
            cell.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4f];
        }
    } else {
        cell.backgroundColor = [UIColor clearColor];
    }

    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.groups.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *items = [self.groups[indexPath.section] valueForKey:@"items"];
    infoBlock ? infoBlock(items[indexPath.row]) : nil;
    [self hide];
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.indexs;
}


#pragma mark -getter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = 60;
        _tableView.sectionIndexColor = [UIColor lightGrayColor];
        _tableView.sectionIndexBackgroundColor = [UIColor clearColor];
        _tableView.backgroundColor = [UIColor colorWithWhite:1 alpha:.7f];

        [_tableView registerNib:[UINib nibWithNibName:@"SelectCountryCell" bundle:nil] forCellReuseIdentifier:@"SelectCountryCellID"];
    }
    return _tableView;
}

- (NSMutableArray *)countries {

    if (_countries) {
        return _countries;
    }
    _countries = @[].mutableCopy;
    NSString *disPlayName = @"";
    NSDictionary *current = nil;
    for (NSDictionary *countryInfo in self.ISOCountryCodes) {
        disPlayName = [[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode value:[countryInfo valueForKey:@"countryCode"]];
        [countryInfo setValue:disPlayName forKey:@"countryName"];
        if ([[countryInfo valueForKey:@"countryCode"] isEqualToString:self.countryCode]) {
            current = countryInfo;
        } else {
            [_countries objectAddObject:countryInfo];
        }
    }


    if (current) {
        [self.ISOCountryCodes removeObject:current];
        [_countries objectInsert:current atIndex:0];
    }

    [_countries addObjectsFromArray:self.ISOCountryCodes];

    return _countries;
}

- (NSMutableArray *)indexs {
    if (!_indexs) {
        _indexs = @[].mutableCopy;
        NSString *lStr = [[NSLocale currentLocale] localeIdentifier];
        for (NSDictionary *temD in self.countries) {
            NSString *name = [temD valueForKey:@"countryName"];
            NSString *prex = @"";
            if ([lStr hasPrefix:@"zh"]) {
                prex = [[name transformToPinyin] substringToIndex:1];
                prex = [self change:[prex uppercaseString]];
            } else {
                prex = [name substringToIndex:1];
            }
            [_indexs objectAddObject:[prex uppercaseString]];
            //quchong
            NSMutableSet *set = [NSMutableSet set];
            for (NSObject *obj in _indexs) {
                [set addObject:obj];
            }
            [_indexs removeAllObjects];
            for (NSObject *obj in set) {
                [_indexs objectAddObject:obj];
            }
            // sort array
            [_indexs sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
                NSString *str1 = obj1;
                NSString *str2 = obj2;
                return [str1 compare:str2];
            }];
        }
    }

    return _indexs;
}

- (NSString *)change:(NSString *)sourceStr {
    if ([sourceStr hasPrefix:@"À"]) {
        return [sourceStr stringByReplacingOccurrencesOfString:@"À" withString:@"A"];
    }
    if ([sourceStr hasPrefix:@"Ā"]) {
        return [sourceStr stringByReplacingOccurrencesOfString:@"Ā" withString:@"A"];
    }
    if ([sourceStr hasPrefix:@"È"]) {
        return [sourceStr stringByReplacingOccurrencesOfString:@"È" withString:@"E"];
    }
    if ([sourceStr hasPrefix:@"É"]) {
        return [sourceStr stringByReplacingOccurrencesOfString:@"É" withString:@"E"];
    }
    return sourceStr;
}

- (NSMutableArray *)groups {
    if (!_groups) {
        _groups = @[].mutableCopy;
        NSMutableDictionary *group = nil;
        NSMutableArray *items = nil;
        NSString *lStr = [[NSLocale currentLocale] localeIdentifier];
        for (NSString *prex in self.indexs) {
            group = [NSMutableDictionary dictionary];
            items = @[].mutableCopy;
            group[@"title"] = prex;
            for (NSDictionary *temD in self.countries) {
                NSString *name = [temD valueForKey:@"countryName"];
                if ([lStr hasPrefix:@"zh"]) {
                    NSString *pinY = [name transformToPinyin];
                    pinY = [self change:[pinY uppercaseString]];
                    if ([pinY hasPrefix:prex]) {
                        [items objectAddObject:temD];
                    }
                } else if ([name hasPrefix:prex]) {
                    [items objectAddObject:temD];
                }
            }
            group[@"items"] = items;
            [_groups objectAddObject:group];
        }
    }

    return _groups;
}


- (void)layoutSubviews {
    [super layoutSubviews];
    self.tableView.frame = self.bounds;
    closeBtn.frame = CGRectMake(self.frame.size.width - 30, 0, 30, 30);
    [closeBtn sizeToFit];
}

@end

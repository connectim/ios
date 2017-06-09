//
//  SelectCountryViewController.m
//  Connect
//
//  Created by MoHuilin on 2016/12/6.
//  Copyright © 2016年 Connect - P2P Encrypted Instant Message. All rights reserved.
//

#import "SelectCountryViewController.h"
#import "NSString+Pinyin.h"
#import "LMselectCountryCell.h"

@interface SelectCountryViewController () <UITableViewDelegate, UITableViewDataSource> {
    void (^infoBlock)(id countryInfo);
}


@property(strong, nonatomic) UITableView *tableView;
@property(strong, nonatomic) NSMutableArray *indexs;
@property(strong, nonatomic) NSMutableArray *groups;
@property(nonatomic, strong) NSMutableArray *ISOCountryCodes;

@end

@implementation SelectCountryViewController

- (instancetype)initWithCallBackBlock:(void (^)(id countryInfo))block {
    if (self = [super init]) {
        infoBlock = block;
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
    [self setBlackfBackArrowItem];
    
    UILabel *titleLabel = [UILabel new];
    titleLabel.text = LMLocalizedString(@"Login Select Country", nil);
    titleLabel.size = [self sizeWithNewFont:titleLabel.font constrainedToNewHeight:44 withString:titleLabel.text];
    titleLabel.font = [UIFont boldSystemFontOfSize:FONT_SIZE(34)];
    self.navigationItem.titleView = titleLabel;

    [MBProgressHUD showLoadingMessageToView:self.view];
    [GCDQueue executeInGlobalQueue:^{
        // Country information
        NSString *path = [[NSBundle mainBundle] pathForResource:@"country" ofType:@"txt"];
        NSData *data = GJCFFileRead(path);
        self.ISOCountryCodes = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];

        NSString *disPlayName = @"";
        for (NSDictionary *countryInfo in self.ISOCountryCodes) {
            disPlayName = [[NSLocale currentLocale] displayNameForKey:NSLocaleCountryCode value:[countryInfo valueForKey:@"countryCode"]];
            [countryInfo setValue:disPlayName forKey:@"countryName"];
        }
        DDLogInfo(@"%@", self.groups);
        [GCDQueue executeInMainQueue:^{
            [self.view addSubview:self.tableView];
            [MBProgressHUD hideHUDForView:self.view];
            [self.tableView reloadData];
        }];
    }];
    // Judgment is not from the set of pieces over
    if (self.isSetSelectCountry) {
        UIImage *imageName = [self createImageWithColor:LMBasicLightGray];
        [self.navigationController.navigationBar setBackgroundImage:imageName forBarMetrics:UIBarMetricsDefault];
    }
}

- (UIImage *)createImageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

// Set the title of the title related and so on
- (CGSize)sizeWithNewFont:(UIFont *)font constrainedToNewHeight:(CGFloat)height withString:(NSString *)titleText {
    UIFont *textFont = font ? font : [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];

    CGSize textSize;

#if __IPHONE_OS_VERSION_MIN_REQUIRED < 70000
    if ([titleText respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
        paragraph.lineBreakMode = NSLineBreakByWordWrapping;
        NSDictionary *attributes = @{NSFontAttributeName: textFont,
                NSParagraphStyleAttributeName: paragraph};
        textSize = [titleText boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, height)
                                           options:(NSStringDrawingUsesLineFragmentOrigin |
                                                   NSStringDrawingTruncatesLastVisibleLine)
                                        attributes:attributes
                                           context:nil].size;
    } else {
        textSize = [titleText sizeWithFont:textFont
                         constrainedToSize:CGSizeMake(CGFLOAT_MAX, height)
                             lineBreakMode:NSLineBreakByWordWrapping];
    }
#else
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.lineBreakMode = NSLineBreakByWordWrapping;
    NSDictionary *attributes = @{NSFontAttributeName: textFont,
            NSParagraphStyleAttributeName: paragraph};
    textSize = [titleText boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, height)
                                       options:(NSStringDrawingUsesLineFragmentOrigin |
                                               NSStringDrawingTruncatesLastVisibleLine)
                                    attributes:attributes
                                       context:nil].size;
#endif

    return CGSizeMake(ceil(textSize.width), ceil(textSize.height));
}

#pragma mark -UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *items = [self.groups[section] valueForKey:@"items"];
    return items.count;
}

#pragma mark - UITableViewDatasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *items = [self.groups[indexPath.section] valueForKey:@"items"];
    LMselectCountryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LMSelectCountryCellID" forIndexPath:indexPath];
    NSString *countryName = [items[indexPath.row] valueForKey:@"countryName"];
    NSString *phoneCode = [items[indexPath.row] valueForKey:@"phoneCode"];
    NSString *codeName = [NSString stringWithFormat:@"%@ (+%@)", countryName, phoneCode];
    cell.disPlayLable.text = codeName;
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.groups.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.groups[section] valueForKey:@"title"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray *items = [self.groups[indexPath.section] valueForKey:@"items"];
    infoBlock ? infoBlock(items[indexPath.row]) : nil;
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return self.indexs;
}


#pragma mark -getter

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _tableView.rowHeight = AUTO_HEIGHT(100);
        if (!self.isSetSelectCountry) {
            _tableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0);
        }
        [_tableView registerClass:[LMselectCountryCell class] forCellReuseIdentifier:@"LMSelectCountryCellID"];
        _tableView.tableFooterView = [UIView new];
    }
    return _tableView;
}

- (NSMutableArray *)indexs {
    if (!_indexs) {
        _indexs = @[].mutableCopy;
        NSString *lStr = [[NSLocale currentLocale] localeIdentifier];
        for (NSDictionary *temD in self.ISOCountryCodes) {
            NSString *name = [temD valueForKey:@"countryName"];
            NSString *prex = @"";
            if ([lStr hasPrefix:@"zh"]) {
                prex = [[name transformToPinyin] substringToIndex:1];
                prex = [self change:[prex uppercaseString]];
            } else {
                prex = [name substringToIndex:1];
            }
            [_indexs objectAddObject:[prex uppercaseString]];
            NSMutableSet *set = [NSMutableSet set];
            for (NSObject *obj in _indexs) {
                [set addObject:obj];
            }
            [_indexs removeAllObjects];
            for (NSObject *obj in set) {
                [_indexs addObject:obj];
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
            for (NSDictionary *temD in self.ISOCountryCodes) {
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

@end

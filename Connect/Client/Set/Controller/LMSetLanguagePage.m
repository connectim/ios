//
//  LMSetLanguagePage.m
//  Connect
//
//  Created by MoHuilin on 2017/3/31.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMSetLanguagePage.h"


@interface LanguageModel : NSObject

@property(nonatomic, copy) NSString *languageCode;
@property(nonatomic, copy) NSString *languageDisplayName;

@end

@implementation LanguageModel

@end

@interface LMSetLanguagePage ()

@property(nonatomic, strong) LanguageModel *currentLanguage;
@property(nonatomic, strong) CellItem *selectedItem;

@property(nonatomic, strong) NSMutableArray *languageArray;

@end

@implementation LMSetLanguagePage

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = LMLocalizedString(@"Set Language", nil);
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"LanguageConfig" ofType:@"plist"];
    NSMutableArray *data = [[NSMutableArray alloc] initWithContentsOfFile:plistPath];

    self.languageArray = [NSMutableArray array];

    NSString *currentLanguage = GJCFUDFGetValue(@"userCurrentLanguage");
    if (GJCFStringIsNull(currentLanguage)) {
        NSArray *languages = [NSLocale preferredLanguages];
        currentLanguage = [languages objectAtIndex:0];
    }

    NSLog(@"currentLanguage :%@", currentLanguage);

    for (NSDictionary *dict in data) {
        LanguageModel *language = [LanguageModel new];
        language.languageCode = [dict objectForKey:@"language_code"];
        language.languageDisplayName = [dict objectForKey:@"language_display_name"];
        [self.languageArray addObject:language];
        if ([currentLanguage containsString:language.languageCode]) {
            self.currentLanguage = language;
        }
    }

    [self setupCellData];
}

- (void)configTableView {
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"SystemCellID"];
}

- (void)setupCellData {
    [self.groups removeAllObjects];
    //zero group
    CellGroup *group = [[CellGroup alloc] init];

    __weak __typeof(&*self) weakSelf = self;
    NSMutableArray *array = [NSMutableArray array];
    for (LanguageModel *lang in self.languageArray) {
        CellItem *item = [CellItem itemWithTitle:lang.languageDisplayName type:CellItemTypeNone operation:^{
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showMessage:LMLocalizedString(@"Set Setting language", nil) toView:weakSelf.view];
                [GCDQueue executeInMainQueue:^{
                    [MBProgressHUD hideHUDForView:weakSelf.view];
                    [Language setLanguage:lang.languageCode];
                }             afterDelaySecs:1.3f];
            }];
        }];
        if (lang == self.currentLanguage) {
            self.selectedItem = item;
        }
        [array addObject:item];
    }
    group.items = array.copy;
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

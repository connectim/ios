//
//  AboutViewController.m
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "AboutViewController.h"
#import "CommonClausePage.h"
#import "SystemTool.h"
#import "MMGlobal.h"

@interface AboutViewController ()

@property(nonatomic, copy) NSString *trackViewUrl;

// weather is new version
@property(assign, nonatomic) BOOL isNewVersion;

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = LMLocalizedString(@"Set About", nil);

    self.view.backgroundColor = LMBasicBackgroudGray;

}

- (void)configTableView {
    self.tableView.separatorColor = self.tableView.backgroundColor;

    [self.tableView registerClass:[NCellArrow class] forCellReuseIdentifier:@"NCellArrowID"];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCellID"];
    [self.tableView registerNib:[UINib nibWithNibName:@"NCellValue1" bundle:nil] forCellReuseIdentifier:@"NCellValue1ID"];

    UIView *headerView = [[UIView alloc] init];
    headerView.frame = AUTO_RECT(0, 0, 750, 436);

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo_black_middle"]];
    imageView.contentMode = UIViewContentModeCenter;
    imageView.frame = AUTO_RECT(225, 136, 300, 73);
    [headerView addSubview:imageView];

    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    NSString *versionNum = [infoDict objectForKey:@"CFBundleShortVersionString"];
    NSString *tipString = [NSString stringWithFormat:@"Version %@", versionNum];


    NSMutableAttributedString *tipAttrString = [[NSMutableAttributedString alloc] initWithString:tipString];
    [tipAttrString addAttribute:NSFontAttributeName
                          value:[UIFont systemFontOfSize:FONT_SIZE(28)]
                          range:NSMakeRange(0, tipString.length)];
    GJCFCoreTextContentView *versionView = [[GJCFCoreTextContentView alloc] init];
    versionView.frame = AUTO_RECT(299, 272, 300, 40);
    versionView.contentBaseSize = versionView.size;
    [headerView addSubview:versionView];
    versionView.contentAttributedString = tipAttrString;
    versionView.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:tipAttrString forBaseContentSize:versionView.contentBaseSize];

    versionView.centerX = headerView.centerX;

    self.tableView.tableHeaderView = headerView;


    //foot

    UIView *footView = [[UIView alloc] init];
    footView.frame = AUTO_RECT(0, 0, 750, 435);

    NSString *subString = LMLocalizedString(@"app name im", nil);


    NSMutableAttributedString *subAttrString = [[NSMutableAttributedString alloc] initWithString:subString];
    [subAttrString addAttribute:NSFontAttributeName
                          value:[UIFont systemFontOfSize:FONT_SIZE(28)]
                          range:NSMakeRange(0, subString.length)];
    GJCFCoreTextContentView *subView = [[GJCFCoreTextContentView alloc] init];
    subView.frame = AUTO_RECT(271, 353, 300, 40);
    subView.contentBaseSize = versionView.size;
    [footView addSubview:subView];
    subView.contentAttributedString = subAttrString;
    subView.gjcf_size = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:subAttrString forBaseContentSize:versionView.contentBaseSize];

    subView.centerX = footView.centerX;

    self.tableView.tableFooterView = footView;
}

- (void)setupCellData {
    __weak __typeof(&*self) weakSelf = self;
    [self.groups removeAllObjects];

    // zero group
    CellGroup *group0 = [[CellGroup alloc] init];
    CellItem *grade = [CellItem itemWithTitle:LMLocalizedString(@"Set Rate Connect", nil) type:CellItemTypeArrow operation:^{
        [GCDQueue executeInMainQueue:^{
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:appstoreAppDownloadUrl]];
        }];
    }];

    CellItem *openSource = [CellItem itemWithTitle:LMLocalizedString(@"Set Open Source", nil) type:CellItemTypeArrow operation:^{
        CommonClausePage *page = [[CommonClausePage alloc] initWithUrl:appOpensourceUrl];
        page.title = LMLocalizedString(@"Set Open Source", nil);
        [GCDQueue executeInMainQueue:^{
            [weakSelf.navigationController pushViewController:page animated:YES];
        }];
    }];
    NSString *sunStr = [self checkVersion];
    CellItem *checkUpdata = [CellItem itemWithTitle:LMLocalizedString(@"Set Check Update", nil) subTitle:sunStr type:CellItemTypeValue1 operation:^{
        if (weakSelf.isNewVersion == NO) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:nationalAppDownloadUrl]];
        }
    }];
    if ([SystemTool isNationChannel]) {
        group0.items = @[openSource, checkUpdata];
    } else {
        group0.items = @[grade, openSource];
    }
    [self.groups objectAddObject:group0];
}

- (NSString *)checkVersion {

    NSString *verNetStr = [SessionManager sharedManager].currentNewVersionInfo.version;
    int ver = [[verNetStr stringByReplacingOccurrencesOfString:@"." withString:@""] intValue];
    int currentVer = [[[MMGlobal currentVersion] stringByReplacingOccurrencesOfString:@"." withString:@""] intValue];
    NSString *subStr = nil;
    if (currentVer < ver) {
        subStr = [NSString stringWithFormat:LMLocalizedString(@"Set new version", nil), [SessionManager sharedManager].currentNewVersionInfo.version];
    } else {
        self.isNewVersion = YES;
        subStr = LMLocalizedString(@"Set This is the newest version", nil);
    }
    return subStr;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {


    CellGroup *group = self.groups[indexPath.section];
    CellItem *item = group.items[indexPath.row];

    BaseCell *cell;
    if (item.type == CellItemTypeArrow) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellArrowID"];
        NCellArrow *arrowCell = (NCellArrow *) cell;
        arrowCell.customTitleLabel.text = item.title;
    } else if (item.type == CellItemTypeValue1) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"NCellValue1ID"];
        NCellValue1 *value1Cell = (NCellValue1 *) cell;
        value1Cell.cellSourceType = CellSourceTypeAbout;
        value1Cell.data = item;
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"UITableViewCellID"];
    }
    return cell;
}


- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    CellGroup *group = self.groups[section];

    return group.footTitle;

}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return AUTO_HEIGHT(111);
}

- (void)dealloc {
    self.isNewVersion = NO;
    self.trackViewUrl = nil;
    [self.tableView removeFromSuperview];
    self.tableView = nil;

    [self.groups removeAllObjects];
    self.groups = nil;
}
@end

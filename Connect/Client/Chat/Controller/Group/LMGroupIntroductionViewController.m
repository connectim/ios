//
//  LMGroupIntroductionViewController.m
//  Connect
//
//  Created by bitmain on 2016/12/27.
//  Copyright © 2016年 Connect. All rights reserved.
//

#import "LMGroupIntroductionViewController.h"
#import "NetWorkOperationTool.h"
#import "GroupDBManager.h"

@interface LMGroupIntroductionViewController () <UITextViewDelegate>

@property(weak, nonatomic) IBOutlet UITextView *summaryTextView;

@end

@implementation LMGroupIntroductionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (self.titleName) {
        self.title = self.titleName;
    }
    self.view.backgroundColor = [UIColor whiteColor];
    [self setNavigationRight:LMLocalizedString(@"Set Save", nil) titleColor:LMBasicGreen];
    LMGroupInfo *group = [[GroupDBManager sharedManager] getgroupByGroupIdentifier:self.talkModel.chatIdendifier];
    self.summaryTextView.text = [[GroupDBManager sharedManager] getGroupSummaryWithGroupID:group.groupIdentifer];
    if (self.summaryTextView.text == nil || [self.summaryTextView.text isEqualToString:@""]) {
        self.summaryTextView.text = self.talkModel.chatGroupInfo.groupName;
    }
    self.summaryTextView.delegate = self;

}

- (void)doRight:(id)sender {
    [self changeGroupSummary:self.summaryTextView.text];
}

- (void)changeGroupSummary:(NSString *)summary {

    __weak typeof(self) weakSelf = self;
    if (GJCFStringIsNull(summary)) {
        return;
    }

    GroupSetting *groupSet = [GroupSetting new];
    groupSet.identifier = self.talkModel.chatGroupInfo.groupIdentifer;
    groupSet.summary = summary;
    groupSet.public_p = YES;
    groupSet.reviewed = self.talkModel.chatGroupInfo.isGroupVerify;

    [NetWorkOperationTool POSTWithUrlString:GroupSettingUrl postProtoData:groupSet.data complete:^(id response) {
        HttpResponse *hReponse = (HttpResponse *) response;
        if (hReponse.code == successCode) {
            
            [[GroupDBManager sharedManager] addGroupSummary:weakSelf.summaryTextView.text withGroupId:weakSelf.talkModel.chatGroupInfo.groupIdentifer];
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Update successful", nil) withType:ToastTypeSuccess showInView:weakSelf.view complete:^{
                    [weakSelf.navigationController popViewControllerAnimated:YES];
                }];
            }];
        } else {
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Link update Failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
        }
    }                                  fail:^(NSError *error) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:[LMErrorCodeTool showToastErrorType:ToastErrorTypeContact withErrorCode:error.code withUrl:GroupSettingUrl] withType:ToastTypeFail showInView:weakSelf.view complete:nil];
        }];
    }];
}

#pragma mark - textview的delegate

- (void)textViewDidChange:(UITextView *)textView {
    if (textView.text.length > 255) {
        self.rightTitleButton.enabled = NO;
        [self.rightTitleButton setTitleColor:LMBasicMiddleGray forState:UIControlStateDisabled];
    } else {
        self.rightTitleButton.enabled = YES;
    }

}
@end

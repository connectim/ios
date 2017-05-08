//
//  LMApplyJoinToGroupViewController.m
//  Connect
//
//  Created by MoHuilin on 2017/1/1.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMApplyJoinToGroupViewController.h"
#import "NetWorkOperationTool.h"
#import "UIImage+Color.h"
#import "StringTool.h"

typedef NS_ENUM(NSInteger, GetGroupInfoType) {
    GetGroupInfoTypeQrcode = 0,
    GetGroupInfoTypeGroupInfoCard,
    GetGroupInfoTypeGroupToken,
};

@interface LMApplyJoinToGroupViewController ()
@property(weak, nonatomic) IBOutlet UIImageView *groupAvatarImageView;
@property(weak, nonatomic) IBOutlet UILabel *groupNameLabel;
@property(weak, nonatomic) IBOutlet UIButton *applyToJoinGroupBtn;
@property(weak, nonatomic) IBOutlet UILabel *countLabel;
@property(weak, nonatomic) IBOutlet UILabel *sumaryLabel;
@property(weak, nonatomic) IBOutlet UIView *bottomView;
@property(weak, nonatomic) IBOutlet UILabel *groupStatueTipLabel;

@property(nonatomic, copy) NSString *identifier;
@property(nonatomic, copy) NSString *token;

//Request parameter
@property(nonatomic, strong) GroupApply *groupApply;
@property(nonatomic, strong) GroupInvite *groupInvite;

@property(nonatomic, assign) GetGroupInfoType applyType;

@end

@implementation LMApplyJoinToGroupViewController

- (instancetype)initWithGroupIdentifier:(NSString *)identifier inviteToken:(NSString *)inviteToken inviteByAddress:(NSString *)inviteBy {
    if (self = [self initWithNibName:@"LMApplyJoinToGroupViewController" bundle:nil]) {
        GroupInvite *groupApply = [GroupInvite new];
        groupApply.identifier = identifier;
        groupApply.token = inviteToken;
        groupApply.inviteBy = inviteBy;
        self.groupInvite = groupApply;
        self.applyType = GetGroupInfoTypeGroupInfoCard;
        self.identifier = identifier;
    }
    return self;
}

- (instancetype)initWithGroupToken:(NSString *)token {
    if (self = [self initWithNibName:@"LMApplyJoinToGroupViewController" bundle:nil]) {
        GroupApply *groupApply = [GroupApply new];
        groupApply.source = GetGroupInfoTypeGroupToken;
        self.applyType = GetGroupInfoTypeGroupToken;
        self.groupApply = groupApply;
        self.token = token;
    }
    return self;
}

- (instancetype)initWithGroupIdentifier:(NSString *)identifier hashP:(NSString *)hashP {
    if (self = [self initWithNibName:@"LMApplyJoinToGroupViewController" bundle:nil]) {
        GroupApply *groupApply = [GroupApply new];
        groupApply.source = GetGroupInfoTypeQrcode;
        self.applyType = GetGroupInfoTypeQrcode;
        groupApply.identifier = identifier;
        groupApply.hash_p = hashP;
        self.groupApply = groupApply;
    }
    return self;
}

- (IBAction)applyToGroup:(id)sender {

    __weak __typeof(&*self) weakSelf = self;
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LMLocalizedString(@"Link Send", nil) message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textFieldAlert) {
        [textFieldAlert addTarget:self action:@selector(textFiedChange:) forControlEvents:UIControlEventEditingChanged];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Common Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:LMLocalizedString(@"Link Send", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        UITextField *messageTextField = alertController.textFields.firstObject;
        messageTextField.text = [StringTool filterStr:messageTextField.text];
        if (weakSelf.applyType == GetGroupInfoTypeGroupInfoCard) {
            weakSelf.groupInvite.tips = messageTextField.text;
            if (messageTextField.text.length <= 0) {
                weakSelf.groupInvite.tips = LMLocalizedString(@"Link apply to join group", nil);
            }
            [NetWorkOperationTool POSTWithUrlString:GroupInviteApplyUrl postProtoData:self.groupInvite.data complete:^(id response) {
                HttpResponse *hResponse = (HttpResponse *) response;
                switch (hResponse.code) {
                    case 2430:
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Qr code is invalid", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                        break;
                    case 2403:
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Link have joined the group", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                        break;

                    case 2000:
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Send successful", nil) withType:ToastTypeSuccess showInView:weakSelf.view complete:nil];
                        break;
                    default:
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Send failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                        break;
                }
            }                                  fail:^(NSError *error) {
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];

        } else {
            weakSelf.groupApply.tips = messageTextField.text;
            if (messageTextField.text.length <= 0) {
                weakSelf.groupApply.tips = LMLocalizedString(@"Link apply to join group", nil);
            }
            [NetWorkOperationTool POSTWithUrlString:GroupApplyToGroupUrl postProtoData:self.groupApply.data complete:^(id response) {
                HttpResponse *hResponse = (HttpResponse *) response;
                switch (hResponse.code) {
                    case 2430:
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Qr code is invalid", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                        break;
                    case 2403:
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Link have joined the group", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                        break;

                    case 2000:
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Send successful", nil) withType:ToastTypeSuccess showInView:weakSelf.view complete:nil];
                        break;
                    default:
                        [MBProgressHUD showToastwithText:LMLocalizedString(@"Login Send failed", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
                        break;
                }
            }                                  fail:^(NSError *error) {
                [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:weakSelf.view complete:nil];
            }];
        }
    }];
    [alertController addAction:cancelAction];
    [alertController addAction:okAction];
    alertController.automaticallyAdjustsScrollViewInsets = NO;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.applyToJoinGroupBtn setTitle:LMLocalizedString(@"Link Join Group", nil) forState:UIControlStateNormal];
    self.applyToJoinGroupBtn.layer.cornerRadius = 5;
    self.applyToJoinGroupBtn.layer.masksToBounds = YES;
    [self.applyToJoinGroupBtn setBackgroundImage:[UIImage imageWithColor:LMBasicGreen] forState:UIControlStateDisabled];
    [self.applyToJoinGroupBtn setBackgroundImage:[UIImage imageWithColor:LMBasicGreen] forState:UIControlStateNormal];
    [self.applyToJoinGroupBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.bottomView).offset(AUTO_HEIGHT(140));
        make.width.equalTo(self.view).multipliedBy(0.7);
        make.centerX.equalTo(self.view);
        make.height.mas_equalTo(AUTO_HEIGHT(100));
    }];

    self.groupAvatarImageView.layer.borderColor = LMBasicBackGroudDarkGray.CGColor;
    self.groupAvatarImageView.layer.borderWidth = 0.6;
    self.groupAvatarImageView.layer.cornerRadius = 6;
    self.groupAvatarImageView.layer.masksToBounds = YES;

    [self hideAllView];
    switch (self.applyType) {
        case GetGroupInfoTypeGroupToken:
            [self getGroupInfoWithToken];
            break;
        case GetGroupInfoTypeGroupInfoCard:
            [self getGroupInfoWithIdentifier];
            break;
        case GetGroupInfoTypeQrcode:
            [self getGroupBaseInfo];
            break;
        default:
            break;
    }
}


- (void)getGroupInfoWithToken {
    [MBProgressHUD showLoadingMessageToView:self.view];
    GroupToken *token = [GroupToken new];
    token.token = self.token;
    [NetWorkOperationTool POSTWithUrlString:GroupInfoTokenUrl postProtoData:token.data complete:^(id response) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:self.view];
        }];
        HttpResponse *hResponse = (HttpResponse *) response;
        if (hResponse.code != successCode) {
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Group invitation is invalid", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            return;
        }
        NSData *data = [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            GroupInfoBaseShare *groupBaseInfo = [GroupInfoBaseShare parseFromData:data error:&error];
            [GCDQueue executeInMainQueue:^{
                [self dispalyAllView];
                [self.groupAvatarImageView setImageWithAvatarUrl:groupBaseInfo.avatar];
                self.groupNameLabel.text = groupBaseInfo.name;
                self.countLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Chat Member Max", nil), groupBaseInfo.count,200];
                self.sumaryLabel.text = groupBaseInfo.summary;

                self.groupApply.identifier = groupBaseInfo.identifier;
                self.groupApply.hash_p = groupBaseInfo.hash_p;

                if (!groupBaseInfo.public_p) {
                    self.applyToJoinGroupBtn.hidden = YES;
                    self.groupStatueTipLabel.hidden = NO;
                    self.groupStatueTipLabel.text = LMLocalizedString(@"Link The group is not public", nil);
                } else {
                    self.applyToJoinGroupBtn.hidden = NO;
                    self.groupStatueTipLabel.hidden = YES;
                }
            }];
        }
    }                                  fail:^(NSError *error) {
        [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
    }];
}


- (void)getGroupInfoWithIdentifier {
    [MBProgressHUD showLoadingMessageToView:self.view];
    GroupId *groupId = [GroupId new];
    groupId.identifier = self.identifier;
    [NetWorkOperationTool POSTWithUrlString:GroupPublicInfoUrl postProtoData:groupId.data complete:^(id response) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:self.view];
        }];
        HttpResponse *hResponse = (HttpResponse *) response;
        if (hResponse.code != successCode) {
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Group invitation is invalid", nil) withType:ToastTypeFail showInView:self.view complete:nil];
            return;
        }
        NSData *data = [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            GroupInfoBase *groupBaseInfo = [GroupInfoBase parseFromData:data error:&error];
            [GCDQueue executeInMainQueue:^{
                [self dispalyAllView];
                [self.groupAvatarImageView setImageWithAvatarUrl:groupBaseInfo.avatar];
                self.groupNameLabel.text = groupBaseInfo.name;
                self.countLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Chat Member Max", nil), groupBaseInfo.count,200];
                self.sumaryLabel.text = groupBaseInfo.summary;
                self.groupApply.hash_p = groupBaseInfo.hash_p;
                if (!groupBaseInfo.public_p) {
                    self.applyToJoinGroupBtn.hidden = YES;
                    self.groupStatueTipLabel.hidden = NO;
                    self.groupStatueTipLabel.text = LMLocalizedString(@"Link The group is not public", nil);
                } else {
                    self.applyToJoinGroupBtn.hidden = NO;
                    self.groupStatueTipLabel.hidden = YES;
                }
            }];
        }
    }                                  fail:^(NSError *error) {
        [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:self.view complete:nil];
    }];
}

- (void)getGroupBaseInfo {
    [self hideAllView];
    __weak typeof(self) weakSelf = self;
    GroupScan *groupScan = [GroupScan new];
    groupScan.identifier = self.groupApply.identifier;
    groupScan.hash_p = self.groupApply.hash_p;

    [NetWorkOperationTool POSTWithUrlString:ScanQRJoinGroupUrl postProtoData:groupScan.data complete:^(id response) {
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD hideHUDForView:weakSelf.view];
        }];
        HttpResponse *hResponse = (HttpResponse *) response;
        if (hResponse.code != successCode) {
            [GCDQueue executeInMainQueue:^{

                [MBProgressHUD showToastwithText:LMLocalizedString(@"Link Qr code is invalid", nil) withType:ToastTypeFail showInView:self.view complete:^{
                    [weakSelf.navigationController popViewControllerAnimated:YES];
                }];
            }];
            return;
        }
        NSData *data = [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            [weakSelf dispalyAllView];
            NSError *error = nil;
            GroupInfoBase *groupBaseInfo = [GroupInfoBase parseFromData:data error:&error];
            [weakSelf.groupAvatarImageView setImageWithAvatarUrl:groupBaseInfo.avatar];
            weakSelf.groupNameLabel.text = groupBaseInfo.name;
            weakSelf.countLabel.text = [NSString stringWithFormat:LMLocalizedString(@"Chat Member Max", nil), groupBaseInfo.count,200];
            weakSelf.sumaryLabel.text = groupBaseInfo.summary;
        }
    }                                  fail:^(NSError *error) {
        [weakSelf hideAllView];
        [GCDQueue executeInMainQueue:^{
            [MBProgressHUD showToastwithText:LMLocalizedString(@"Network Server error", nil) withType:ToastTypeFail showInView:self.view complete:^{
                [weakSelf.navigationController popViewControllerAnimated:YES];
            }];
        }];
    }];
}

- (void)hideAllView {
    self.groupAvatarImageView.hidden = YES;
    self.groupNameLabel.hidden = YES;
    self.countLabel.hidden = YES;
    self.sumaryLabel.hidden = YES;
    self.applyToJoinGroupBtn.hidden = YES;
}

- (void)dispalyAllView {
    self.groupAvatarImageView.hidden = NO;
    self.groupNameLabel.hidden = NO;
    self.countLabel.hidden = NO;
    self.sumaryLabel.hidden = NO;
    self.applyToJoinGroupBtn.hidden = NO;
}

- (void)textFiedChange:(UITextField *)textField {
    if (textField.text.length >= 30) {
        textField.text = [textField.text substringToIndex:30];
    }
}
@end

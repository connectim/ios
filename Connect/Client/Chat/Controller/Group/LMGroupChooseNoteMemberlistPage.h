//
//  LMGroupChooseNoteMemberlistPage.h
//  Connect
//
//  Created by MoHuilin on 2017/3/10.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "BaseViewController.h"

@interface LMGroupChooseNoteMemberlistPage : BaseViewController

- (instancetype)initWithMembers:(NSArray *)members;

@property(nonatomic, copy) void (^ChooseGroupMemberCallBack)(AccountInfo *member);

@end

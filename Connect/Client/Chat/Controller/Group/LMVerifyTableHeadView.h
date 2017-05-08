//
//  LMVerifyTableHeadView.h
//  Connect
//
//  Created by bitmain on 2017/2/27.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMVerifyTableHeadView : UIView
@property(weak, nonatomic) IBOutlet UIImageView *groupHeaderImageView;
@property(weak, nonatomic) IBOutlet UILabel *groupNameLable;
@property(weak, nonatomic) IBOutlet UILabel *groupMemberLable;
@property(weak, nonatomic) IBOutlet UILabel *groupSummaryLable;
@end

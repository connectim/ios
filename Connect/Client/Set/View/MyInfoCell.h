//
//  MyInfoCell.h
//  Connect
//
//  Created by MoHuilin on 16/7/18.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseCell.h"

typedef void (^QRButtonClickActionBlock)();

@interface MyInfoCell : BaseCell
@property(weak, nonatomic) IBOutlet UILabel *userIDLabel;
// Click the two-dimensional code button for the event
@property(nonatomic, copy) QRButtonClickActionBlock qrBtnClickBlock;

@end

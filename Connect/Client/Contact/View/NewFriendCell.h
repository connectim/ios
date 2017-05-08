//
//  NewFriendCell.h
//  Connect
//
//  Created by MoHuilin on 16/5/27.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseSwipeCell.h"
#import "Protofile.pbobjc.h"
typedef void (^AddButtonBlock) (AccountInfo*);
@interface NewFriendCell : BaseSwipeCell

@property(strong, nonatomic)AddButtonBlock addButtonBlock;


@end

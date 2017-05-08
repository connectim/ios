//
//  LinkmanFriendCell.h
//  Connect
//
//  Created by MoHuilin on 16/5/23.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseSwipeCell.h"

@interface LinkmanFriendCell : BaseSwipeCell

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *subTitleLabel;

@end

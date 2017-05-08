//
//  WalletItemCell.h
//  Connect
//
//  Created by MoHuilin on 2016/11/7.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WalletItemCell : UICollectionViewCell
@property(weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property(weak, nonatomic) IBOutlet UILabel *titleLabel;

- (CGFloat)heightForCell;

@end

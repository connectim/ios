//
//  AccountWListCell.m
//  Connect
//
//  Created by MoHuilin on 16/5/12.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "AccountWListCell.h"

@interface AccountWListCell ()

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *deleteUserButton;

@end

@implementation AccountWListCell

- (IBAction)deleteUser:(id)sender {
    AccountInfo *info = self.data;
    
    if (info.customOperationWithInfo) {
        info.customOperationWithInfo(info);
    }
}

- (void)awakeFromNib{
    [super awakeFromNib];
    _avatarImageView.layer.cornerRadius = 5;
    _avatarImageView.layer.masksToBounds = YES;
    self.tintColor = [UIColor whiteColor];

    // hide delete user button
    self.deleteUserButton.hidden = YES;
    
    _nameLabel.font = [UIFont systemFontOfSize:FONT_SIZE(36)];
    _nameLabel.textColor = [UIColor whiteColor];
}


- (void)setData:(id)data{
    [super setData:data];
    
    AccountInfo *info = data;
    _nameLabel.text = info.username;
    
    [self.avatarImageView setPlaceholderImageWithAvatarUrl:info.avatar];
    
    if (self.deleteUserModel) {
        self.deleteUserButton.hidden = NO;
        self.accessoryType = UITableViewCellAccessoryNone;
        
        [self shakeHead];
        
    } else{
        self.deleteUserButton.hidden = YES;
        [self.avatarImageView.layer removeAllAnimations];
        if (info.isSelected) {
            self.accessoryType = UITableViewCellAccessoryCheckmark;
        } else{
            self.accessoryType = UITableViewCellAccessoryNone;
        }
    }
}


- (void)shakeHead{
    CABasicAnimation *shake = [CABasicAnimation animationWithKeyPath:@"transform"];
    shake.duration = 0.13;
    shake.autoreverses = YES;
    shake.repeatCount = MAXFLOAT;
    shake.removedOnCompletion = NO;
    CGFloat rotation = 0.06;
    shake.fromValue = [NSValue valueWithCATransform3D:CATransform3DRotate(self.avatarImageView.layer.transform,-rotation, 0.0 ,0.0 ,1.0)];
    shake.toValue = [NSValue valueWithCATransform3D:CATransform3DRotate(self.avatarImageView.layer.transform, rotation, 0.0 ,0.0 ,1.0)];
    [self.avatarImageView.layer addAnimation:shake forKey:@"shakeAnimation"];
}


@end

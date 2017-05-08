//
//  ChatMapCell.h
//  Connect
//
//  Created by MoHuilin on 16/7/27.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "GJGCChatFriendBaseCell.h"

@interface ChatMapCell : GJGCChatFriendBaseCell

@property(nonatomic, strong) UIImageView *contentImageView;

- (void)successDownloadWithImageData:(NSData *)imageData;

- (void)failDownloadState;

@end

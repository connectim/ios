//
//  GJGCChatFriendVideoCell.h
//  Connect
//
//  Created by MoHuilin on 16/7/4.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "GJGCChatFriendBaseCell.h"

@interface GJGCChatFriendVideoCell : GJGCChatFriendBaseCell

@property(nonatomic, strong) UIImageView *contentImageView;

@property(nonatomic, strong) UIImageView *blankImageView;

- (void)resetState;

- (void)resetStateWithPrepareSize:(CGSize)pSize;

- (void)removePrepareState;

- (void)faildCoverState;

- (void)faildVideoState;

- (void)successDownloadWithImageData:(NSData *)downData isVideo:(BOOL)isVideo;

- (void)startDownloadVideoAction;

@end

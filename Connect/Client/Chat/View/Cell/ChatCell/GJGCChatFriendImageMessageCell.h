//
//  GJGCChatFriendImageMessageCell.h
//  Connect
//
//  Created by KivenLin on 14-11-5.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import "GJGCChatFriendBaseCell.h"
#import "DACircularProgressView.h"
#import "UAProgressView.h"

@interface GJGCChatFriendImageMessageCell : GJGCChatFriendBaseCell

@property(nonatomic, strong) UIImageView *contentImageView;

@property(nonatomic, strong) UIImageView *blankImageView;

@property(nonatomic, strong) UAProgressView *cirProgressView;

- (void)resetState;

- (void)resetStateWithPrepareSize:(CGSize)pSize;

- (void)removePrepareState;

- (void)faildState;

- (void)successDownloadWithImageData:(NSData *)imageData;

@end

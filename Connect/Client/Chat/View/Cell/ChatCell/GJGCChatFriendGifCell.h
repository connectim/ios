//
//  GJGCChatFriendGifCell.h
//  Connect
//
//  Created by KivenLin on 15/6/3.
//  Copyright (c) 2015年 Connect. All rights reserved.
//

#import "GJGCChatFriendBaseCell.h"

@interface GJGCChatFriendGifCell : GJGCChatFriendBaseCell

@property(nonatomic, assign) CGFloat downloadProgress;

- (void)successDownloadGifFile:(NSData *)fileData;

- (void)faildDownloadGifFile;

@end

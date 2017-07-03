//
//  ReconmandChatListPage.h
//  Connect
//
//  Created by MoHuilin on 16/7/22.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseViewController.h"
#import "GJGCChatFriendConstans.h"


@interface LMRerweetModel : NSObject

@property(nonatomic, assign) GJGCChatFriendContentType messageType;
@property(nonatomic, strong) NSData *fileData;
@property(nonatomic, strong) NSData *thumData;


@property(nonatomic, strong) MMMessage *retweetMessage;
//member group
@property(nonatomic, strong) id toFriendModel;

@end

@interface ReconmandChatListPage : BaseViewController

- (instancetype)initWithRecommandContact:(AccountInfo *)contact;

- (instancetype)initWithRetweetModel:(LMRerweetModel *)retweetModel;

@end

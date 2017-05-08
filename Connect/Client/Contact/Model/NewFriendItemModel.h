//
//  NewFriendItemModel.h
//  Connect
//
//  Created by MoHuilin on 2016/10/19.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NewFriendItemModel : NSObject

@property (nonatomic ,copy) NSString *title;

@property (nonatomic ,copy) NSString *icon;

@property (nonatomic ,copy) NSString *FriendBadge;
// add me man
@property (nonatomic ,strong) AccountInfo *addMeUser;

@end

//
//  LMGroupInfo.h
//  Connect
//
//  Created by MoHuilin on 16/7/27.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseInfo.h"
#import "Protofile.pbobjc.h"

@interface LMGroupInfo : BaseInfo
// group name
@property (nonatomic ,copy) NSString *groupName;
// group member
@property (nonatomic ,strong) NSMutableArray *groupMembers;
//address -> memberInfo dic
@property (nonatomic ,strong) NSMutableDictionary *addressMemberDict;
// groupAdmin
@property (nonatomic ,strong) AccountInfo *admin;
// group id
@property (nonatomic ,copy) NSString *groupIdentifer;
// group ecdhkey
@property (nonatomic ,copy) NSString *groupEcdhKey;
// isCommonGroup
@property (nonatomic ,assign) BOOL isCommonGroup;
// isGroupVerify
@property (nonatomic ,assign) BOOL isGroupVerify;
@property (nonatomic ,assign) BOOL isPublic;
@property (nonatomic ,copy) NSString *avatarUrl;
// groupSummary
@property (nonatomic ,copy) NSString *summary;


@end

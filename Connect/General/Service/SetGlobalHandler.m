//
//  SetGlobalHandler.m
//  Connect
//
//  Created by MoHuilin on 16/7/26.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "Protofile.pbobjc.h"
#import "NetWorkOperationTool.h"
#import "UserDBManager.h"
#import "RecentChatDBManager.h"
#import "GroupDBManager.h"
#import "IMService.h"
#import "StringTool.h"
#import "ConnectTool.h"

@implementation SetGlobalHandler


#pragma mark - black list
/**
 *  join black
 */

+ (void)addToBlackListWithAddress:(NSString *)userAddress{
    
    
    AccountInfo *user = [[AccountInfo alloc] init];
    user.address = userAddress;
   
    // add network
    UserIdentifier *userIdentifier = [[UserIdentifier alloc] init];
    userIdentifier.address = userAddress;
    [NetWorkOperationTool POSTWithUrlString:ContactBlackListAddUrl postProtoData:userIdentifier.data complete:^(id response) {
        DDLogInfo(@"Join black list successfully");
        [[UserDBManager sharedManager] addUserToBlackListWithAddress:user.address];
        // Issue a notification update interface
        [GCDQueue executeInMainQueue:^{
            SendNotify(ConnnectContactDidChangeNotification, nil);
        }];
    } fail:^(NSError *error) {
        
    }];
    
}

/**
 *  remove black list
 */
+ (void)removeBlackListWithAddress:(NSString *)userAddress{
    
    AccountInfo *user = [[AccountInfo alloc] init];
    user.address = userAddress;
   

    UserIdentifier *userIdentifier = [[UserIdentifier alloc] init];
    userIdentifier.address = userAddress;
    [NetWorkOperationTool POSTWithUrlString:ContactBlackListRemoveUrl postProtoData:userIdentifier.data complete:^(id response) {
        DDLogInfo(@"Remove black list successfully");
         [[UserDBManager sharedManager] removeUserFromBlackList:user.address];
        //Issue a notification update interface
        [GCDQueue executeInMainQueue:^{
            SendNotify(ConnnectContactDidChangeNotification, nil);
        }];
    } fail:^(NSError *error) {

    }];

}

+ (void)blackListDownComplete:(void (^)(NSArray *blackList))complete{
    
    [NetWorkOperationTool POSTWithUrlString:ContactBlackListUrl postProtoData:nil complete:^(id response) {
        DDLogInfo(@"Download black list successfully");
        
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            DDLogInfo(@"Download blacklist server error");
            if (complete) {
                complete(nil);
            }
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSMutableArray *arrM = [NSMutableArray array];
            UsersInfo *usersInfo = [UsersInfo parseFromData:data error:nil];
            for (UserInfo *user in usersInfo.usersArray) {
                AccountInfo *userInfo = [[AccountInfo alloc] init];
                userInfo.address = user.address;
                userInfo.avatar = user.avatar;
                userInfo.username = user.username;
                userInfo.pub_key = user.pubKey;
                [[UserDBManager sharedManager] addUserToBlackListWithAddress:user.address];
                [arrM objectAddObject:userInfo];
            }
            [[MMAppSetting sharedSetting] haveSyncBlickMan];
            
            if (complete) {
                complete(arrM);
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil);
        }
    }];
}


#pragma mark - Frequent contacts
/**
 *  Add a common contact
 */

+ (void)addToCommonContactListWithAddress:(NSString *)userAddress remark:(NSString *)remark{
    [[IMService instance] setFriendInfoWithAddress:userAddress remark:remark commonContact:YES comlete:^(NSError *error, id data) {
        if (error == nil) {
            [[UserDBManager sharedManager] setUserCommonContact:YES AndSetNewRemark:remark withAddress:userAddress];
            [GCDQueue executeInMainQueue:^{
                SendNotify(ConnnectContactDidChangeNotification, [[UserDBManager sharedManager] getUserByAddress:userAddress]);
            }];
        }
    }];
}

/**
 *  Remove common contacts
 */
+ (void)removeCommonContactListWithAddress:(NSString *)userAddress remark:(NSString *)remark{

   
    
    [[IMService instance] setFriendInfoWithAddress:userAddress remark:remark commonContact:NO comlete:^(NSError *erro, id data) {
        if (erro == nil) {
            [[UserDBManager sharedManager] setUserCommonContact:NO AndSetNewRemark:remark withAddress:userAddress];
            [GCDQueue executeInMainQueue:^{
                SendNotify(ConnnectContactDidChangeNotification, [[UserDBManager sharedManager] getUserByAddress:userAddress]);
            }];
        }
    }];
}


#pragma mark - tag

/**
   * Add a new label
   *
   * @param tag
 */
+ (void)addNewTag:(NSString *)tag withAddress:(NSString*)address{
    
    
    Tag *tagProto = [[Tag alloc] init];
    tagProto.name = tag;
    // db
    [NetWorkOperationTool POSTWithUrlString:ContactAddTagUrl postProtoData:tagProto.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            return;
        }
        [[UserDBManager sharedManager] saveTag:tag];
    } fail:^(NSError *error) {
        
    }];
    [self setUserAddress:address ToTag:tag];
    
    
}

/**
   * Remove the label
   *
   * @param tag
 */
+ (void)removeTag:(NSString *)tag{
    
    Tag *tagProto = [[Tag alloc] init];
    tagProto.name = tag;
    
    [NetWorkOperationTool POSTWithUrlString:ContactTagRemoveUrl postProtoData:tagProto.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            return;
        }
        // Database operation
        [[UserDBManager sharedManager] removeTag:tag];
    } fail:^(NSError *error) {
        
    }];

}

/**
   * Download the label
   *
   * @param complete
 */
+ (void)tagListDownCompelete:(void (^)(NSArray *tags))complete{
    
    [NetWorkOperationTool POSTWithUrlString:ContactTagListUrl postProtoData:nil complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil);
            }
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            TagList *taglist = [TagList parseFromData:data error:nil];
            
            for (NSString *tag in taglist.listArray) {
                [[UserDBManager sharedManager] saveTag:tag];
            }
            
            // Set the sync flag
            [[MMAppSetting sharedSetting] haveSyncUserTags];
            
            if (complete) {
                complete(taglist.listArray);
            }
            DDLogInfo(@"%@",taglist);
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil);
        }
    }];

    
}

/**
   * Set friends to a label
   *
   * @param address
   * @param tag
 */
+ (void)setUserAddress:(NSString *)address ToTag:(NSString *)tag{
    
    
    SetingUserToTag *setToTag = [[SetingUserToTag alloc] init];
    setToTag.address = address;
    setToTag.name = tag;
    
    [NetWorkOperationTool POSTWithUrlString:ContactTagSetUserTagUrl postProtoData:setToTag.data complete:^(id response) {
        
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            return;
        }
        [[UserDBManager sharedManager] saveAddress:address toTag:tag];


    } fail:^(NSError *error) {
        DDLogInfo(@"Set user to tag error");
    }];
    
}

/**
   * Remove friends to a label
   *
   * @param address
   * @param tag
 */
+ (void)removeUserAddress:(NSString *)address formTag:(NSString *)tag{
    
    
    SetingUserToTag *setToTag = [[SetingUserToTag alloc] init];
    setToTag.address = address;
    setToTag.name = tag;
    
    [NetWorkOperationTool POSTWithUrlString:ContactTagRemoveUserTagUrl postProtoData:setToTag.data complete:^(id response) {
        
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            return;
        }
        
       
        [[UserDBManager sharedManager] removeAddress:address fromTag:tag];
        
        
    } fail:^(NSError *error) {
        DDLogInfo(@"Remove user to tag error");
    }];

}
/**
   * Remove a tag that has a friend already exists
   *
   * @param address
   * @param tag
 */
+ (void)removeUserHaveAddress:(NSString *)address formTag:(NSString *)tag
{
    Tag *setToTag = [[Tag alloc] init];
    setToTag.name = tag;
    
    [NetWorkOperationTool POSTWithUrlString:ContactTagRemoveUserHaveTagUrl postProtoData:setToTag.data complete:^(id response) {
        
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            DDLogInfo(@"Remove the user tag server error");
            return;
        }
        
        DDLogInfo(@"Remove user to tag success");
        [[UserDBManager sharedManager] removeTag:tag];
        [[UserDBManager sharedManager] removeAddress:address fromTag:tag];
        
        
    } fail:^(NSError *error) {
        DDLogInfo(@"Remove user to tag error");
    }];
}
/**
   * Tags under the user
   *
   * @param tag
   * @param complete
 */
+ (void)tag:(NSString *)tag downUsers:(void (^)(NSArray *users))complete{
    
    
    Tag *tagProto = [[Tag alloc] init];
    tagProto.name = tag;
    
    
    [NetWorkOperationTool POSTWithUrlString:ContactTagTagUsersUrl postProtoData:tagProto.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            DDLogInfo(@"Get the tag under the users server error");
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            UsersInfo *usersInfo = [UsersInfo parseFromData:data error:nil];
            
            for (UserInfo *user in usersInfo.usersArray) {
                
                [[UserDBManager sharedManager] saveAddress:user.address toTag:tag];
            }
            
            DDLogInfo(@"%@",usersInfo.usersArray);
        }
    } fail:^(NSError *error) {
        DDLogError(@"Failed to get under the users");
    }];

    
}
/**
   * User under the label
   *
   * @param tag
   * @param complete
 */
+ (void)Userstag:(NSString *)address downTags:(void(^)(NSArray* tags))complete
{
    UserIdentifier *userInder = [[UserIdentifier alloc] init];
    userInder.address = address;
    [NetWorkOperationTool POSTWithUrlString:UserTagsUrl postProtoData:userInder.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil);
            }
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            TagList* tagLists = [TagList parseFromData:data error:nil];
            NSArray* tagsArray = [tagLists.listArray copy];
            if (complete) {
                complete(tagsArray);
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil);
        }
    }];
}
#pragma mark - top chat

/**
   * Top chat
   *
   * @param chatIdentifer
 */
+ (void)topChatWithChatIdentifer:(NSString *)chatIdentifer{
    
    if (GJCFStringIsNull(chatIdentifer)) {
        return;
    }
    
    [[RecentChatDBManager sharedManager] topChat:chatIdentifer];
    
}

/**
   * Cancel the top chat
   *
   * @param chatIdentifer
 */
+ (void)CancelTopChatWithChatIdentifer:(NSString *)chatIdentifer{
    if (GJCFStringIsNull(chatIdentifer)) {
        return;
    }
    [[RecentChatDBManager sharedManager] removeTopChat:chatIdentifer];
}

/**
 * Whether it is Zhiding
 *
 */
+ (BOOL)chatIsTop:(NSString *)chatIdentifer{
    if (GJCFStringIsNull(chatIdentifer)) {
        return NO;
    }
    return [[RecentChatDBManager sharedManager] isTopChat:chatIdentifer];

}


#pragma mark - Message scrambling

/**
 * Do not disturb the state
 *
 * @param publickey
 *
 *  @return
 */
+ (BOOL)friendChatMuteStatusWithPublickey:(NSString *)publickey{

    if (GJCFStringIsNull(publickey)) {
        return NO;
    }

    return [[RecentChatDBManager sharedManager] getMuteStatusWithIdentifer:publickey];
}

/**
   * Do not disturb the state
   *
   * @param groupid group of groupid
   *
   * @return
 */
+ (BOOL)GroupChatMuteStatusWithIdentifer:(NSString *)groupid{
    return [self friendChatMuteStatusWithPublickey:groupid];
}


/**
   * Group Chat Off Turns on unwanted
   *
   * @param groupid group of groupid
 */
+ (void)GroupChatSetMuteWithIdentifer:(NSString *)groupid mute:(BOOL)mute complete:(void (^)(NSError *erro))complete{
    
    UpdateGroupMute *Mute = [[UpdateGroupMute alloc] init];
    Mute.identifier = groupid;
    Mute.mute = mute;
    [NetWorkOperationTool POSTWithUrlString:GroupSetMuteUrl postProtoData:Mute.data complete:^(id response) {
        
        HttpResponse *hResponse = (HttpResponse *)response;
        
        if (hResponse.code != successCode) {
            
            if (complete) {
                complete([[NSError alloc] init]);
            }
            return;
        }
        
        if (complete) {
            complete(nil);
        }
        
    } fail:^(NSError *error) {
        if (complete) {
            complete(error);
        }
        
    }];

}

/**
   * Group personal nickname
   *
   * @param groupid group of groupid
 */
+ (void)updateGroupMynameWithIdentifer:(NSString *)groupid myName:(NSString *)myName complete:(void (^)(NSError *erro))complete{
    
    UpdateGroupMemberInfo *upDataUserNick = [[UpdateGroupMemberInfo alloc] init];
    upDataUserNick.nick = myName;
    upDataUserNick.identifier = groupid;
    //update nickname
    [[GroupDBManager sharedManager] updateMyGroupNickName:myName groupId:groupid];
    
    [NetWorkOperationTool POSTWithUrlString:GroupMemberUpdateUrl postProtoData:upDataUserNick.data complete:^(id response) {
        
        HttpResponse *hResponse = (HttpResponse *)response;
        
        if (hResponse.code != successCode) {
            
            if (complete) {
                complete([[NSError alloc] init]);
            }
            return;
        }
        
        if (complete) {
            complete(nil);
        }
        
    } fail:^(NSError *error) {
        if (complete) {
            complete(error);
        }
        
    }];
    
}


#pragma mark - group

+ (void)removeMembers:(NSArray *)addresses groupIdentifer:(NSString *)groupid complete:(void (^)(NSError *erro))complete{
    
    if (addresses.count <= 0) {
        return;
    }
    
    if (GJCFStringIsNull(groupid)) {
        return;
    }
    
    NSMutableArray *deleteUsers = @[].mutableCopy;
    
    for (NSString *address in addresses) {
        AddGroupUserInfo *deleteUser = [[AddGroupUserInfo alloc] init];
        deleteUser.address = address;
        [deleteUsers objectAddObject:deleteUser];
    }
    
    AddUserToGroup *addOrRemove = [[AddUserToGroup alloc] init];
    addOrRemove.identifier = groupid;
    addOrRemove.usersArray = deleteUsers;

    [NetWorkOperationTool POSTWithUrlString:GroupGroupDeleteUserUrl postProtoData:addOrRemove.data complete:^(id response) {
        
        HttpResponse *hResponse = (HttpResponse *)response;
        
        if (hResponse.code != successCode) {
            
            if (complete) {
                complete([[NSError alloc] init]);
            }
            return;
        }
        
        if (complete) {
            complete(nil);
        }
        
    } fail:^(NSError *error) {
        if (complete) {
            complete(error);
        }
        
    }];

}

+ (void)quitGroupWithIdentifer:(NSString *)groupid complete:(void (^)(NSError *erro))complete{
    if (GJCFStringIsNull(groupid)) {
        return;
    }
    GroupId *groupIdProto = [[GroupId alloc] init];
    groupIdProto.identifier = groupid;
    [NetWorkOperationTool POSTWithUrlString:GroupQuitGroupUrl postProtoData:groupIdProto.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete([[NSError alloc] initWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
            return;
        }
        if (complete) {
            complete(nil);
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error);
        }
    }];
}

/**
   * Save your address book
   *
   * @param groupid
 */
+ (void)setCommonContactGroupWithIdentifer:(NSString *)groupid complete:(void (^)(NSError *error))complete{
    
    if (GJCFStringIsNull(groupid)) {
        return;
    }

    //save db
    GroupId *groupIdProto = [[GroupId alloc] init];
    groupIdProto.identifier = groupid;
    
    [NetWorkOperationTool POSTWithUrlString:GroupSetCommonUrl postProtoData:groupIdProto.data complete:^(id response) {
        
        HttpResponse *hResponse = (HttpResponse *)response;
        
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:@"Server internal error" code:hResponse.code userInfo:nil]);
            }
            return;
        }
        
        if (complete) {
            complete(nil);
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error);
        }
    }];
}

/**
   * Remove contacts
   *
   * @param groupid
 */
+ (void)removeCommonContactGroupWithIdentifer:(NSString *)groupid complete:(void (^)(NSError *error))complete{
    
    if (GJCFStringIsNull(groupid)) {
        return;
    }
    
    // save db
    GroupId *groupIdProto = [[GroupId alloc] init];
    groupIdProto.identifier = groupid;

    
    [NetWorkOperationTool POSTWithUrlString:GroupRemoveCommonUrl postProtoData:groupIdProto.data complete:^(id response) {
        
        HttpResponse *hResponse = (HttpResponse *)response;
        
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:@"Server internal error" code:hResponse.code userInfo:nil]);
            }
            return;
        }
        
        if (complete) {
            complete(nil);
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error);
        }
    }];
    
}

+ (void)downGroupInfoWithGroupIdentifer:(NSString *)identifer withGroupEcdhKey:(NSString *)groupEcdh
{
    if (GJCFStringIsNull(groupEcdh) || GJCFStringIsNull(identifer)) {
        return;
    }
    GroupId *groupId = [[GroupId alloc] init];
    groupId.identifier = identifer;

    
    [NetWorkOperationTool POSTWithUrlString:GroupGetGroupInfoUrl postProtoData:groupId.data complete:^(id response) {
        
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            //Save to the database
            LMGroupInfo *group = [[LMGroupInfo alloc] init];
            GroupInfo *groupInfo = [GroupInfo parseFromData:data error:nil];
            group.groupEcdhKey = groupEcdh;
            group.isPublic = groupInfo.group.public_p;
            group.summary = groupInfo.group.summary;
            group.groupName = groupInfo.group.name;
            group.isGroupVerify = groupInfo.group.reviewed;
            //To convert
            NSMutableArray* AccoutInfoArray = [NSMutableArray array];
            for (GroupMember* member in groupInfo.membersArray) {
                AccountInfo* accountInfo = [[AccountInfo alloc] init];
                accountInfo.username = member.username;
                accountInfo.avatar = member.avatar;
                accountInfo.address = member.address;
                accountInfo.roleInGroup = member.role;
                accountInfo.groupNickName = member.nick;
                accountInfo.pub_key = member.pubKey;
                [AccoutInfoArray objectAddObject:accountInfo];
            }
            group.groupMembers = AccoutInfoArray;
            group.groupIdentifer = groupInfo.group.identifier;
            group.avatarUrl = groupInfo.group.avatar;
            [[GroupDBManager sharedManager] savegroup:group];
            
            DDLogInfo(@"%@",groupInfo);
        }
    } fail:^(NSError *error) {
        
    }];
    
}



+ (void)downGroupInfoWithGroupIdentifer:(NSString *)identifer complete:(void (^)(NSError *error))complete
{
    if (GJCFStringIsNull(identifer)) {
        return;
    }
    GroupId *groupId = [[GroupId alloc] init];
    groupId.identifier = identifer;

    [NetWorkOperationTool POSTWithUrlString:GroupGetGroupInfoUrl postProtoData:groupId.data complete:^(id response) {
        
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            //Save to the database
            LMGroupInfo *group = [[GroupDBManager sharedManager] getgroupByGroupIdentifier:identifer];
            if (GJCFStringIsNull(group.groupEcdhKey)) {
                [self downGroupEcdhKeyWithGroupIdentifier:identifer complete:^(NSString *groupKey, NSError *error) {
                    GroupInfo *groupInfo = [GroupInfo parseFromData:data error:nil];
                    //group.groupInfo = groupInfo;
                    group.groupEcdhKey = groupKey;
                    group.isPublic = groupInfo.group.public_p;
                    group.summary = groupInfo.group.summary;
                    group.groupName = groupInfo.group.name;
                    NSMutableArray* AccoutInfoArray = [NSMutableArray array];
                    for (GroupMember* member in groupInfo.membersArray) {
                        AccountInfo* accountInfo = [[AccountInfo alloc] init];
                        accountInfo.username = member.username;
                        accountInfo.avatar = member.avatar;
                        accountInfo.address = member.address;
                        accountInfo.roleInGroup = member.role;
                        accountInfo.groupNickName = member.nick;
                        accountInfo.pub_key = member.pubKey;
                        [AccoutInfoArray objectAddObject:accountInfo];
                    }
                    group.groupMembers = AccoutInfoArray;
                    group.groupIdentifer = groupInfo.group.identifier;
                    group.isGroupVerify = groupInfo.group.reviewed;
                    
                    [[GroupDBManager sharedManager] updateGroup:group];
                    
                    if (complete) {
                        complete(nil);
                    }
                    
                }];
            } else{
                GroupInfo *groupInfo = [GroupInfo parseFromData:data error:nil];
               // group.groupInfo = groupInfo;
                
                group.isPublic = groupInfo.group.public_p;
                group.summary = groupInfo.group.summary;
                group.groupName = groupInfo.group.name;
                NSMutableArray* AccoutInfoArray = [NSMutableArray array];
                for (GroupMember* member in groupInfo.membersArray) {
                    AccountInfo* accountInfo = [[AccountInfo alloc] init];
                    accountInfo.username = member.username;
                    accountInfo.avatar = member.avatar;
                    accountInfo.address = member.address;
                    accountInfo.roleInGroup = member.role;
                    accountInfo.groupNickName = member.nick;
                    accountInfo.pub_key = member.pubKey;
                    [AccoutInfoArray objectAddObject:accountInfo];
                }
                group.groupMembers = AccoutInfoArray;
                group.groupIdentifer = groupInfo.group.identifier;
                group.isGroupVerify = groupInfo.group.reviewed;
                
                [[GroupDBManager sharedManager] updateGroup:group];
                if (complete) {
                    complete(nil);
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error);
        }
    }];
    
}


+ (void)uploadGroupEcdhKey:(NSString *)groupEcdhKey groupIdentifier:(NSString *)groupid{
    
    if (GJCFStringIsNull(groupid) || GJCFStringIsNull(groupEcdhKey)) {
        return;
    }

    NSString *randomPublickey = [KeyHandle createPubkeyByPrikey:[KeyHandle creatNewPrivkey]];
    NSData *ecdhKey = [KeyHandle getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey publicKey:randomPublickey];
    GcmData *ecdhKeyGcmData = [ConnectTool createGcmWithData:groupEcdhKey ecdhKey:ecdhKey needEmptySalt:YES];
    
    GroupCollaborative *groupColl = [[GroupCollaborative alloc] init];
    groupColl.identifier = groupid;
    groupColl.collaborative = [NSString stringWithFormat:@"%@/%@",randomPublickey,[StringTool hexStringFromData:ecdhKeyGcmData.data]];

    [NetWorkOperationTool POSTWithUrlString:GroupUploadGroupKeyUrl postProtoData:groupColl.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;

        if (hResponse.code != successCode) {
            DDLogError(@"Upload group key failed");
            return;
        }
        DDLogInfo(@"Upload group key is successful");

    } fail:^(NSError *error) {
        
    }];
    
}

+ (void)downGroupEcdhKeyWithGroupIdentifier:(NSString *)groupid  complete:(void (^)(NSString *groupKey,NSError *error))complete{
        
    if (GJCFStringIsNull(groupid)) {
        return;
    }
    GroupId *groupIDProto = [[GroupId alloc] init];
    groupIDProto.identifier =  groupid;
     __weak __typeof(&*self)weakSelf = self;
    [NetWorkOperationTool POSTWithUrlString:GroupDownloadGroupKeyUrl postProtoData:groupIDProto.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        
        if (hResponse.code != successCode) {
            DDLogError(@"Download group key failed");
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            GroupCollaborative *groupColl = [GroupCollaborative parseFromData:data error:&error];
            if (!error) {
                DDLogInfo(@"下Download group key success");
                
                NSArray *array = [groupColl.collaborative componentsSeparatedByString:@"/"];
                if (array.count == 2) {
                    NSString *randomPublickey = [array objectAtIndexCheck:0];
                    NSData *ecdhKey = [KeyHandle getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey publicKey:randomPublickey];
                    ecdhKey = [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhKey salt:[ConnectTool get64ZeroData]];
                    GcmData *ecdhKeyGcmData = [GcmData parseFromData:[StringTool hexStringToData:[array objectAtIndexCheck:1]] error:nil];
                    NSData *ecdh = [ConnectTool decodeGcmDataWithEcdhKey:ecdhKey GcmData:ecdhKeyGcmData haveStructData:NO];
                    NSString *ecdhKeyString = [[NSString alloc] initWithData:ecdh encoding:NSUTF8StringEncoding];
                    if (GJCFStringIsNull(ecdhKeyString)) {
                        [weakSelf downBackupInfoWithGroupIdentifier:groupid complete:^(NSString *ecdhKey,NSError *error) {
                            if (complete) {
                                if (error) {
                                    complete(nil,error);
                                } else{
                                    complete(ecdhKey,nil);
                                }
                            }
                        }];
                    } else{
                        if (complete) {
                            complete(ecdhKeyString,nil);
                        }
                    }
                } else{
                    [weakSelf downBackupInfoWithGroupIdentifier:groupid complete:^(NSString *ecdhKey,NSError *error) {
                        if (complete) {
                            if (error) {
                                complete(nil,error);
                            } else{
                                complete(ecdhKey,nil);
                            }
                        }
                    }];
                }
            } else{
                DDLogError(@"Download group key failed");
                [weakSelf downBackupInfoWithGroupIdentifier:groupid complete:^(NSString *ecdhKey,NSError *error) {
                    if (complete) {
                        if (error) {
                            complete(nil,error);
                        } else{
                            complete(ecdhKey,nil);
                        }
                    }
                }];
            }
        }
    } fail:^(NSError *error) {
        [weakSelf downBackupInfoWithGroupIdentifier:groupid complete:^(NSString *ecdhKey,NSError *error) {
            if (complete) {
                if (error) {
                    complete(nil,error);
                } else{
                    complete(ecdhKey,nil);
                }
            }
        }];
    }];
}


+ (void)downBackupInfoWithGroupIdentifier:(NSString *)groupid  complete:(void (^)(NSString *groupKey,NSError *error))complete{
    
    if (GJCFStringIsNull(groupid)) {
        return;
    }
    GroupId *groupId = [[GroupId alloc] init];
    groupId.identifier =  groupid;
     __weak __typeof(&*self)weakSelf = self;
    [NetWorkOperationTool POSTWithUrlString:BackupDownCreateGroupInfoUrl postProtoData:groupId.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        
        if (hResponse.code != successCode) {
            DDLogError(@"Download group key failed");
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            DownloadBackUpResp *downLoad = [DownloadBackUpResp parseFromData:data error:&error];
            
            if (!error) {
                
                NSString *downBackup = downLoad.backup;
                DDLogInfo(@"Download group key failed");
                
                NSArray *temA = [downBackup componentsSeparatedByString:@"/"];
                if (temA.count == 2) {
                    NSString *pub = [temA objectAtIndexCheck:0];
                    NSString *hex = [temA objectAtIndexCheck:1];
                    
                    NSData *data = [StringTool hexStringToData:hex];
                    GcmData *gcmData = [GcmData parseFromData:data error:&error];
                    if (!error) {
                        NSData *data = [ConnectTool decodeGcmDataWithGcmData:gcmData publickey:pub needEmptySalt:YES];
                        CreateGroupMessage *groupInfo = [CreateGroupMessage parseFromData:data error:&error];
                        if (!error) {
                            /**
                             *  Upload the collaboration key for the group
                             */
                            [SetGlobalHandler uploadGroupEcdhKey:groupInfo.secretKey groupIdentifier:groupid];
                            // Download group information
                            [weakSelf downGroupInfoWithGroupIdentifer:groupid withGroupEcdhKey:groupInfo.secretKey];
                            
                            if (complete) {
                                complete(groupInfo.secretKey,nil);
                            }
                        } else{
                            if (complete) {
                                complete(nil,error);
                            }
                        }
                    }
                }
            } else{
                
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}

#pragma mark - Synchronize user base information
+ (void)syncUserBaseInfoWithAddress:(NSString *)address complete:(void (^)(AccountInfo *user))complete{
    
    SearchUser *usrAddInfo = [[SearchUser alloc]init];
    usrAddInfo.criteria = address;
    [NetWorkOperationTool POSTWithUrlString:ContactUserSearchUrl postProtoData:usrAddInfo.data complete:^(id response) {
        
        NSError *error;
        HttpResponse *respon = (HttpResponse *)response;
        if (respon.code != successCode) {
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:respon];
        if (data) {
            // User Info
            UserInfo *info = [[UserInfo alloc]initWithData:data error:&error];
            
            if (!error) {
                AccountInfo *dbUser = [[UserDBManager sharedManager] getUserByAddress:info.address];
                if (![dbUser.username isEqualToString:info.username] || ![dbUser.avatar isEqualToString:info.avatar]) {
                    dbUser.username = info.username;
                    dbUser.avatar = info.avatar;
                    //Update database user information
                    [[UserDBManager sharedManager] updateUserNameAndAvatar:dbUser];
                    //Issue a notification update interface
                    [GCDQueue executeInMainQueue:^{
                        SendNotify(ConnnectContactDidChangeNotification, dbUser);
                    }];
                    if (complete) {
                        complete(dbUser);
                    }
                }
            }
        }
    } fail:^(NSError *error) {
    }];
}

#pragma mark - privacy setting

+ (void)syncPrivacyComplete:(void(^)())complete{
    
    [NetWorkOperationTool POSTWithUrlString:ContactSyncPrivacyUrl postProtoData:nil complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        
        if (hResponse.code != successCode) {
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            
            Privacy *privac = [Privacy parseFromData:data error:&error];
            if (error) {
                return;
            }
            
            if (privac.recommend) {
                [[MMAppSetting sharedSetting] setAllowRecomand];
            } else{
                [[MMAppSetting sharedSetting] setDelyRecomand];
            }
            
            if (privac.address) {
                [[MMAppSetting sharedSetting] setAllowAddress];
            } else{
                [[MMAppSetting sharedSetting] setDelyAddress];
            }
            if (privac.phoneNum) {
                [[MMAppSetting sharedSetting] setAllowPhone];
            } else{
                [[MMAppSetting sharedSetting] setDelyPhone];
            }
            
            if (privac.syncPhoneBook) {
                [[MMAppSetting sharedSetting] setAutoSysBook];
            } else{
                [[MMAppSetting sharedSetting] setNoAutoSysBook];
            }
            
            if (privac.verify) {
                [[MMAppSetting sharedSetting] setNeedVerfiy];
            } else{
                [[MMAppSetting sharedSetting] setDelyVerfiy];
            }
            
            // Set the sync flag
            [[MMAppSetting sharedSetting] haveSyncPrivacy];
            if (complete) {
                complete();
            }
        }
    } fail:^(NSError *error) {
        
    }];

}

+ (void)privacySetAllowSearchAddress:(BOOL)address AllowSearchPhone:(BOOL)phone needVerify:(BOOL)verify syncPhonebook:(BOOL)syncPhone findMe:(BOOL)findMe{
    
    if (address) {
        [[MMAppSetting sharedSetting]  setAllowAddress];
    } else{
        [[MMAppSetting sharedSetting]  setDelyAddress];
    }
    
    if (verify) {
        [[MMAppSetting sharedSetting]  setNeedVerfiy];
    } else{
        [[MMAppSetting sharedSetting]  setDelyVerfiy];
    }
    
    if (syncPhone) {
        [[MMAppSetting sharedSetting]  setAutoSysBook];
    } else{
        [[MMAppSetting sharedSetting]  setNoAutoSysBook];
    }
    
    if (phone) {
        [[MMAppSetting sharedSetting]  setAllowPhone];
    } else{
        [[MMAppSetting sharedSetting]  setDelyPhone];
    }
    if (findMe) {
        [[MMAppSetting sharedSetting]  setAllowRecomand];
    } else{
        [[MMAppSetting sharedSetting]  setDelyRecomand];
    }
    Privacy *privac = [[Privacy alloc] init];
    privac.address = address;
    privac.phoneNum = phone;
    privac.verify = verify;
    privac.syncPhoneBook = syncPhone;
    privac.recommend = findMe;
    [NetWorkOperationTool POSTWithUrlString:ContactSetPrivacyUrl postProtoData:privac.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        
        if (hResponse.code == successCode) {
            DDLogError(@"Set privacy data successfully");
            return;
        }
        DDLogInfo(@"Setting privacy data failed");

    } fail:^(NSError *error) {
        
    }];

    
}


+ (void)setpayPass:(NSString *)payPass compete:(void(^)(BOOL result))complete{
    if (payPass == nil) {
        payPass = @"";
    }
    PayPin *paySet = [[PayPin alloc] init];
    if (!GJCFStringIsNull(payPass)) {
        GcmData *gcmData = [ConnectTool createGcmWithData:payPass
                                                publickey:[[LKUserCenter shareCenter] currentLoginUser].pub_key needEmptySalt:NO];
        paySet.payPin = [StringTool hexStringFromData:gcmData.data];
    }
    [NetWorkOperationTool POSTWithUrlString:PinSetingUrl postProtoData:paySet.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(NO);
            }
        } else{
            NSData *data = [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                PayPinVersion *version = [PayPinVersion parseFromData:data error:nil];
                [[MMAppSetting sharedSetting] setpaypassVersion:version.version];
            }
            [[MMAppSetting sharedSetting]  setPayPass:payPass];
            if (complete) {
                complete(YES);
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(NO);
        }
    }];
}

+ (void)syncPaypinversionWithComplete:(void(^)(NSString *password,NSError *error))complete{
    PayPinVersion *sendVersion = [[PayPinVersion alloc] init];
    sendVersion.version = [[MMAppSetting sharedSetting] getpaypassVersion];
    [NetWorkOperationTool POSTWithUrlString:PaypinversionUrl postProtoData:sendVersion.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(nil,[NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
            }
        } else{
            NSData *data = [ConnectTool decodeHttpResponse:hResponse];
            if (data) {
                PayPinVersion *version = [PayPinVersion parseFromData:data error:nil];
                if ([version.version isEqualToString:@"0"]) {
                    [self setpayPass:[[MMAppSetting sharedSetting] getPayPass] compete:^(BOOL result) {
                        if (result) {
                            if (complete) {
                                complete([[MMAppSetting sharedSetting] getPayPass],nil);
                            }
                        } else{
                            if (complete) {
                                complete(nil,[NSError errorWithDomain:LMLocalizedString(@"Network Server error", nil) code:-1 userInfo:nil]);
                            }
                        }
                    }];
                }else if ([sendVersion.version isEqualToString:version.version]) { //Versions are consistent and do not need to be updated
                    if (complete) {
                        complete([[MMAppSetting sharedSetting] getPayPass],nil);
                    }
                } else{
                    [[MMAppSetting sharedSetting] setpaypassVersion:version.version];
                    [self getPaySetComplete:^(NSError *erro) {
                        if (!erro && complete) {
                            complete([[MMAppSetting sharedSetting] getPayPass],nil);
                        } else{
                            complete(nil,erro);
                        }
                    }];
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(nil,error);
        }
    }];
}


+ (void)setPaySetNoPass:(BOOL)nopass payPass:(NSString *)payPass fee:(long long)fee compete:(void(^)(BOOL result))complete{
    if (nopass) {
        [[MMAppSetting sharedSetting]  setNoPassPay];
    } else{
        [[MMAppSetting sharedSetting]  cacelNoPassPay];
    }
    if (payPass == nil) {
        payPass = @"";
    }
    PaymentSetting *paySet = [[PaymentSetting alloc] init];
    paySet.noSecretPay = nopass;
    paySet.fee = fee;
    if (!GJCFStringIsNull(payPass)) {
        GcmData *gcmData = [ConnectTool createGcmWithData:payPass aad:nil];
        paySet.payPin = [StringTool hexStringFromData:gcmData.data];
    }
    [NetWorkOperationTool POSTWithUrlString:SetPaySetUrl postProtoData:paySet.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete(NO);
            }
            return;
        }
        DDLogInfo(@"Upload payment settings are successful");
        //Set a password
        [[MMAppSetting sharedSetting]  setPayPass:payPass];
        [[MMAppSetting sharedSetting]  setTransferFee:[NSString stringWithFormat:@"%lld",fee]];
        if (complete) {
            complete(YES);
        }
    } fail:^(NSError *error) {
        DDLogInfo(@"Upload payment failed");
        if (complete) {
            complete(NO);
        }
    }];
}

+ (void)getPaySetComplete:(void (^)(NSError *erro))complete{
    [NetWorkOperationTool POSTWithUrlString:SetSyncPaySetUrl postProtoData:nil complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        if (hResponse.code != successCode) {
            if (complete) {
                complete([NSError errorWithDomain:hResponse.message code:-1 userInfo:nil]);
            }
            return;
        }
        NSData* data =  [ConnectTool decodeHttpResponse:hResponse];
        if (data) {
            NSError *error = nil;
            PaymentSetting *paySet = [PaymentSetting parseFromData:data error:&error];
            if (!error) {
                if (!GJCFStringIsNull(paySet.payPin)) {
                    NSDictionary *dict = [paySet.payPin mj_JSONObject];
                    if (dict &&
                        [dict isKindOfClass:[NSDictionary   class]] &&
                        [dict.allKeys containsObject:@"aad"]) {
                        NSString *aad = [dict valueForKey:@"aad"];
                        NSString *iv = [dict valueForKey:@"iv"];
                        NSString *tag = [dict valueForKey:@"tag"];
                        NSString *ciphertext = [dict valueForKey:@"ciphertext"];
                        if (GJCFStringIsNull(aad) || GJCFStringIsNull(iv)||GJCFStringIsNull(tag) ||GJCFStringIsNull(ciphertext)) {
                            return;
                        }
                        NSString *payPass = [KeyHandle xtalkDecodeAES_GCM:[[LKUserCenter shareCenter] getLocalGCDEcodePass] data:ciphertext aad:aad iv:iv tag:tag];
                        [[MMAppSetting sharedSetting]  setPayPass:payPass];
                    } else{
                        NSData *data = [StringTool hexStringToData:paySet.payPin];
                        if (data) {
                            NSString *payPass = [ConnectTool decodeGcmData:[GcmData parseFromData:data error:nil] publickey:[[LKUserCenter shareCenter] currentLoginUser].pub_key];
                            [[MMAppSetting sharedSetting]  setPayPass:payPass];
                        }
                    }
                }
                if (paySet.noSecretPay) {
                    [[MMAppSetting sharedSetting]  setNoPassPay];
                } else{
                    [[MMAppSetting sharedSetting]  cacelNoPassPay];
                }
                [[MMAppSetting sharedSetting]  setTransferFee:[NSString stringWithFormat:@"%llu",paySet.fee]];
                [[MMAppSetting sharedSetting] haveSyncPaySet];
                if (complete) {
                    complete(nil);
                }
            } else{
                if (complete) {
                    complete([NSError errorWithDomain:hResponse.message code:hResponse.code userInfo:nil]);
                }
            }
        }
    } fail:^(NSError *error) {
        if (complete) {
            complete(error);
        }
    }];
}


+ (void)defaultSet{
    
}

#pragma mark - User operation

+ (void)syncPhoneContactWithHashContact:(NSMutableArray *)contacts complete:(void (^)(NSTimeInterval time))complete{
    
    if (contacts.count <= 0) {
        if (complete) {
            complete(0);
        }
        return;
    }
    PhoneBook *phoneBook = [[PhoneBook alloc] init];
    phoneBook.mobilesArray = contacts;
    
    [NetWorkOperationTool POSTWithUrlString:SetPhonebookSync postProtoData:phoneBook.data complete:^(id response) {
        HttpResponse *hResponse = (HttpResponse *)response;
        
        if (hResponse.code != successCode) {
            if (complete) {
                complete(0);
            }
            return;
        }
        DDLogInfo(@"Synchronous address book is successful");
        if (complete) {
            complete([[NSDate date] timeIntervalSince1970]);
        }
        
        /**
         * Last sync time
         */
        [[MMAppSetting sharedSetting]  setLastSyncContactTime];
        
    } fail:^(NSError *error) {
        
    }];
}

+ (void)getGroupInfoWihtIdentifier:(NSString *)identifier complete:(void (^)(LMGroupInfo *groupInfo ,NSError *error))complete{
    if (GJCFStringIsNull(identifier)) {
        return;
    }
    LMGroupInfo *lmGroup = [[GroupDBManager sharedManager] getgroupByGroupIdentifier:identifier];
    if (lmGroup) {
        if (complete) {
            complete(lmGroup,nil);
        }
    } else{
        [self downGroupEcdhKeyWithGroupIdentifier:identifier complete:^(NSString *groupKey, NSError *error) {
            if (!error && !GJCFStringIsNull(groupKey)) {
                GroupId *groupId = [[GroupId alloc] init];
                groupId.identifier = identifier;
                [NetWorkOperationTool POSTWithUrlString:GroupGetGroupInfoUrl postProtoData:groupId.data complete:^(id response) {
                    HttpResponse *hResponse = (HttpResponse *)response;
                    if (hResponse.code != successCode) {
                        return;
                    }
                    NSData *data = [ConnectTool decodeHttpResponse:hResponse];
                    //Save to the database
                    GroupInfo *groupInfo = [GroupInfo parseFromData:data error:nil];
                    LMGroupInfo *lmGroup = [LMGroupInfo new];
                    
                    lmGroup.groupName = groupInfo.group.name;
                    lmGroup.groupEcdhKey = groupKey;
                    lmGroup.isPublic = groupInfo.group.public_p;
                    lmGroup.groupIdentifer = groupInfo.group.identifier;
                    lmGroup.summary = groupInfo.group.summary;
                    lmGroup.isGroupVerify = groupInfo.group.reviewed;
                    //To convert
                    NSMutableArray* AccoutInfoArray = [NSMutableArray array];
                    for (GroupMember* member in groupInfo.membersArray) {
                        AccountInfo* accountInfo = [[AccountInfo alloc] init];
                        accountInfo.username = member.username;
                        accountInfo.avatar = member.avatar;
                        accountInfo.address = member.address;
                        accountInfo.roleInGroup = member.role;
                        accountInfo.groupNickName = member.nick;
                        accountInfo.pub_key = member.pubKey;
                        [AccoutInfoArray objectAddObject:accountInfo];
                    }
                    lmGroup.groupMembers = AccoutInfoArray;
                    lmGroup.isGroupVerify = groupInfo.group.reviewed;
                    lmGroup.avatarUrl = groupInfo.group.avatar;
                    [[GroupDBManager sharedManager] savegroup:lmGroup];
                    
                    if(complete)
                    {
                        complete(lmGroup,nil);
                    }
                    
                } fail:^(NSError *error) {
                    complete(nil,error);
                }];
            } else{
                complete(nil,error);
            }
        }];
    }
}

@end

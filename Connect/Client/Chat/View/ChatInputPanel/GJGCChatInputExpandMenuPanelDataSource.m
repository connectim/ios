//
//  GJGCChatInputExpandMenuPanelDataSource.m
//  ZYChat
//
//  Created by KivenLin on 14-10-28.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import "GJGCChatInputExpandMenuPanelDataSource.h"

@implementation GJGCChatInputExpandMenuPanelDataSource

+ (NSArray *)menuItemDataSourceWithConfigModel:(GJGCChatInputExpandMenuPanelConfigModel *)configModel {
    switch (configModel.talkType) {
        case GJGCChatFriendTalkTypePrivate:
            return [GJGCChatInputExpandMenuPanelDataSource menuPanelDataSource];
            break;

        case GJGCChatFriendTalkTypeGroup:
            return [GJGCChatInputExpandMenuPanelDataSource groupPanelDataSource];
            break;

        case GJGCChatFriendTalkTypePostSystem:
            return [GJGCChatInputExpandMenuPanelDataSource systemPanelDataSource];
            break;
        default:
            break;
    }


    return nil;
}

+ (NSArray *)postPanelDataSource {
    NSMutableArray *dataSource = [NSMutableArray array];

    [dataSource objectAddObject:[GJGCChatInputExpandMenuPanelDataSource cameraMenuPanelItem]];

    [dataSource objectAddObject:[GJGCChatInputExpandMenuPanelDataSource photoLibraryMenuPanelItem]];


    return dataSource;
}

+ (NSArray *)systemPanelDataSource {
    NSMutableArray *dataSource = [NSMutableArray array];

    [dataSource objectAddObject:[GJGCChatInputExpandMenuPanelDataSource photoLibraryMenuPanelItem]];

    [dataSource objectAddObject:[GJGCChatInputExpandMenuPanelDataSource cameraMenuPanelItem]];

    [dataSource objectAddObject:[GJGCChatInputExpandMenuPanelDataSource locationMenuPanelItem]];

    return dataSource;
}

+ (NSArray *)groupPanelDataSource {
    NSMutableArray *dataSource = [NSMutableArray array];

    [dataSource objectAddObject:[GJGCChatInputExpandMenuPanelDataSource photoLibraryMenuPanelItem]];

    [dataSource objectAddObject:[GJGCChatInputExpandMenuPanelDataSource cameraMenuPanelItem]];

    [dataSource objectAddObject:[GJGCChatInputExpandMenuPanelDataSource transferMenuPanelItem]];

    [dataSource objectAddObject:[GJGCChatInputExpandMenuPanelDataSource redBagMenuPanelItem]];

    [dataSource objectAddObject:[GJGCChatInputExpandMenuPanelDataSource paymentMenuPanelItem]];

    [dataSource objectAddObject:[GJGCChatInputExpandMenuPanelDataSource contactCardMenuPanelItem]];

    [dataSource objectAddObject:[GJGCChatInputExpandMenuPanelDataSource locationMenuPanelItem]];


    return dataSource;
}

+ (NSArray *)menuPanelDataSource {
    NSMutableArray *dataSource = [NSMutableArray array];
    [dataSource objectAddObject:[GJGCChatInputExpandMenuPanelDataSource photoLibraryMenuPanelItem]];

    [dataSource objectAddObject:[GJGCChatInputExpandMenuPanelDataSource cameraMenuPanelItem]];

    [dataSource objectAddObject:[GJGCChatInputExpandMenuPanelDataSource transferMenuPanelItem]];

    [dataSource objectAddObject:[GJGCChatInputExpandMenuPanelDataSource redBagMenuPanelItem]];

    [dataSource objectAddObject:[GJGCChatInputExpandMenuPanelDataSource paymentMenuPanelItem]];

    [dataSource objectAddObject:[GJGCChatInputExpandMenuPanelDataSource securityMenuPanelItem]];

    [dataSource objectAddObject:[GJGCChatInputExpandMenuPanelDataSource contactCardMenuPanelItem]];

    [dataSource objectAddObject:[GJGCChatInputExpandMenuPanelDataSource locationMenuPanelItem]];

    return dataSource;
}

+ (NSDictionary *)cameraMenuPanelItem {
    return @{
            GJGCChatInputExpandMenuPanelDataSourceTitleKey: LMLocalizedString(@"Chat Sight", nil),

            GJGCChatInputExpandMenuPanelDataSourceIconNormalKey: @"chat_bar_camera",

            GJGCChatInputExpandMenuPanelDataSourceIconHighlightKey: @"chat_bar_camera",

            GJGCChatInputExpandMenuPanelDataSourceActionTypeKey: @(GJGCChatInputMenuPanelActionTypeCamera)

    };
}

+ (NSDictionary *)photoLibraryMenuPanelItem {
    return @{

            GJGCChatInputExpandMenuPanelDataSourceTitleKey: LMLocalizedString(@"Chat Photo", nil),

            GJGCChatInputExpandMenuPanelDataSourceIconNormalKey: @"chat_bar_album",

            GJGCChatInputExpandMenuPanelDataSourceIconHighlightKey: @"chat_bar_album",

            GJGCChatInputExpandMenuPanelDataSourceActionTypeKey: @(GJGCChatInputMenuPanelActionTypePhotoLibrary)

    };
}

+ (NSDictionary *)microphoneMenuPanelItem {
    return @{

            GJGCChatInputExpandMenuPanelDataSourceTitleKey: @"语音",

            GJGCChatInputExpandMenuPanelDataSourceIconNormalKey: @"chat_bar_microphone",

            GJGCChatInputExpandMenuPanelDataSourceIconHighlightKey: @"chat_bar_microphone",

            GJGCChatInputExpandMenuPanelDataSourceActionTypeKey: @(GJGCChatInputMenuPanelActionTypeMicophone)

    };
}

+ (NSDictionary *)securityMenuPanelItem {
    return @{

            GJGCChatInputExpandMenuPanelDataSourceTitleKey: LMLocalizedString(@"Chat Read Burn", nil),

            GJGCChatInputExpandMenuPanelDataSourceIconNormalKey: @"chat_bar_privacy",

            GJGCChatInputExpandMenuPanelDataSourceIconHighlightKey: @"chat_bar_privacy",

            GJGCChatInputExpandMenuPanelDataSourceActionTypeKey: @(GJGCChatInputMenuPanelActionTypeSecurty)

    };
}


+ (NSDictionary *)transferMenuPanelItem {
    return @{
            GJGCChatInputExpandMenuPanelDataSourceTitleKey: LMLocalizedString(@"Wallet Transfer", nil),

            GJGCChatInputExpandMenuPanelDataSourceIconNormalKey: @"chat_bar_trasfer",

            GJGCChatInputExpandMenuPanelDataSourceIconHighlightKey: @"chat_bar_trasfer",

            GJGCChatInputExpandMenuPanelDataSourceActionTypeKey: @(GJGCChatInputMenuPanelActionTypeTransfer)

    };
}

+ (NSDictionary *)paymentMenuPanelItem {
    return @{
             
             GJGCChatInputExpandMenuPanelDataSourceTitleKey:LMLocalizedString(@"Wallet Receipt", nil),
             
             GJGCChatInputExpandMenuPanelDataSourceIconNormalKey:@"chat_bar_payment",
             
             GJGCChatInputExpandMenuPanelDataSourceIconHighlightKey:@"chat_bar_payment",
             
             GJGCChatInputExpandMenuPanelDataSourceActionTypeKey:@(GJGCChatInputMenuPanelActionTypePayMent)
             
             };
}

+ (NSDictionary *)redBagMenuPanelItem {
    return @{

            GJGCChatInputExpandMenuPanelDataSourceTitleKey: LMLocalizedString(@"Wallet Packet", nil),

            GJGCChatInputExpandMenuPanelDataSourceIconNormalKey: @"chat_bar_redbag",

            GJGCChatInputExpandMenuPanelDataSourceIconHighlightKey: @"chat_bar_redbag",

            GJGCChatInputExpandMenuPanelDataSourceActionTypeKey: @(GJGCChatInputMenuPanelActionTypeRedBag)

    };
}

+ (NSDictionary *)contactCardMenuPanelItem {
    return @{

            GJGCChatInputExpandMenuPanelDataSourceTitleKey: LMLocalizedString(@"Chat Name Card", nil),

            GJGCChatInputExpandMenuPanelDataSourceIconNormalKey: @"chat_bar_contract",

            GJGCChatInputExpandMenuPanelDataSourceIconHighlightKey: @"chat_bar_contract",

            GJGCChatInputExpandMenuPanelDataSourceActionTypeKey: @(GJGCChatInputMenuPanelActionTypeContact)

    };
}

+ (NSDictionary *)locationMenuPanelItem {
    return @{

            GJGCChatInputExpandMenuPanelDataSourceTitleKey: LMLocalizedString(@"Chat Loc", nil),

            GJGCChatInputExpandMenuPanelDataSourceIconNormalKey: @"chat_bar_location",

            GJGCChatInputExpandMenuPanelDataSourceIconHighlightKey: @"chat_bar_location",

            GJGCChatInputExpandMenuPanelDataSourceActionTypeKey: @(GJGCChatInputMenuPanelActionTypeMapLocation)

    };
}


@end

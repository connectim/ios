//
//  GJGCChatInputExpandEmojiPanelMenuBarDataSource.m
//  ZYChat
//
//  Created by KivenLin on 15/6/4.
//  Copyright (c) 2015年 ConnectSoft. All rights reserved.
//

#import "GJGCChatInputExpandEmojiPanelMenuBarDataSource.h"

@implementation GJGCChatInputExpandEmojiPanelMenuBarDataSource

+ (NSArray *)menuBarItems {
    return @[[GJGCChatInputExpandEmojiPanelMenuBarDataSource gifEmojiItem],
            [GJGCChatInputExpandEmojiPanelMenuBarDataSource simpleEmojiItem],
            [GJGCChatInputExpandEmojiPanelMenuBarDataSource animalEmojiItem],
            [GJGCChatInputExpandEmojiPanelMenuBarDataSource gestureEmojiItem],
            [GJGCChatInputExpandEmojiPanelMenuBarDataSource natureEmojiItem],
            [GJGCChatInputExpandEmojiPanelMenuBarDataSource objectEmojiItem],
            [GJGCChatInputExpandEmojiPanelMenuBarDataSource peopleEmojiItem],
            [GJGCChatInputExpandEmojiPanelMenuBarDataSource travelEmojiItem],
            [GJGCChatInputExpandEmojiPanelMenuBarDataSource activitiesEmojiItem],
            [GJGCChatInputExpandEmojiPanelMenuBarDataSource foodEmojiItem]];
}

+ (NSArray *)commentBarItems {
    return @[[GJGCChatInputExpandEmojiPanelMenuBarDataSource animalEmojiItem]];
}

+ (GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *)simpleEmojiItem {
    GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *item = [[GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem alloc] init];

    item.emojiType = GJGCChatInputExpandEmojiTypeSimple;
    item.emojiListFilePath = GJCFMainBundlePath(@"emoji.plist");
    item.faceEmojiIconName = @"emotion_black";
    item.faceEmojiSelectName = @"emotion_white";
    item.isNeedShowSendButton = YES;
    item.isNeedShowRightSideLine = YES;

    return item;
}


+ (GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *)animalEmojiItem {
    GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *item = [[GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem alloc] init];

    item.emojiType = GJGCChatInputExpandEmojiTypeSimple;
    item.emojiListFilePath = GJCFMainBundlePath(@"animal.plist");
    item.faceEmojiIconName = @"animals_black";
    item.faceEmojiSelectName = @"animals_white";

    item.isNeedShowSendButton = YES;
    item.isNeedShowRightSideLine = YES;

    return item;
}

+ (GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *)gestureEmojiItem {
    GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *item = [[GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem alloc] init];

    item.emojiType = GJGCChatInputExpandEmojiTypeSimple;
    item.emojiListFilePath = GJCFMainBundlePath(@"gestures.plist");
    item.faceEmojiIconName = @"gestures_black";
    item.faceEmojiSelectName = @"gestures_white";

    item.isNeedShowSendButton = YES;
    item.isNeedShowRightSideLine = YES;

    return item;
}

+ (GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *)activitiesEmojiItem {
    GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *item = [[GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem alloc] init];

    item.emojiType = GJGCChatInputExpandEmojiTypeSimple;
    item.emojiListFilePath = GJCFMainBundlePath(@"activities.plist");
    item.faceEmojiIconName = @"activities_black";
    item.faceEmojiSelectName = @"activities_white";

    item.isNeedShowSendButton = YES;
    item.isNeedShowRightSideLine = YES;

    return item;
}


+ (GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *)foodEmojiItem {
    GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *item = [[GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem alloc] init];

    item.emojiType = GJGCChatInputExpandEmojiTypeSimple;
    item.emojiListFilePath = GJCFMainBundlePath(@"food.plist");
    item.faceEmojiIconName = @"foodanddrink_black";
    item.faceEmojiSelectName = @"foodanddrink_white";

    item.isNeedShowSendButton = YES;
    item.isNeedShowRightSideLine = YES;

    return item;
}


+ (GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *)natureEmojiItem {
    GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *item = [[GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem alloc] init];

    item.emojiType = GJGCChatInputExpandEmojiTypeSimple;
    item.emojiListFilePath = GJCFMainBundlePath(@"nature.plist");
    item.faceEmojiIconName = @"nature_black";
    item.faceEmojiSelectName = @"nature_white";

    item.isNeedShowSendButton = YES;
    item.isNeedShowRightSideLine = YES;

    return item;
}

+ (GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *)objectEmojiItem {
    GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *item = [[GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem alloc] init];

    item.emojiType = GJGCChatInputExpandEmojiTypeSimple;
    item.emojiListFilePath = GJCFMainBundlePath(@"object.plist");
    item.faceEmojiIconName = @"objects_black";
    item.faceEmojiSelectName = @"objects_white";

    item.isNeedShowSendButton = YES;
    item.isNeedShowRightSideLine = YES;

    return item;
}

+ (GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *)peopleEmojiItem {
    GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *item = [[GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem alloc] init];

    item.emojiType = GJGCChatInputExpandEmojiTypeSimple;
    item.emojiListFilePath = GJCFMainBundlePath(@"people.plist");
    item.faceEmojiIconName = @"people_black";
    item.faceEmojiSelectName = @"people_white";

    item.isNeedShowSendButton = YES;
    item.isNeedShowRightSideLine = YES;

    return item;
}

+ (GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *)travelEmojiItem {
    GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *item = [[GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem alloc] init];

    item.emojiType = GJGCChatInputExpandEmojiTypeSimple;
    item.emojiListFilePath = GJCFMainBundlePath(@"travel.plist");
    item.faceEmojiIconName = @"travel_black";
    item.faceEmojiSelectName = @"travel_white";

    item.isNeedShowSendButton = YES;
    item.isNeedShowRightSideLine = YES;

    return item;
}

+ (GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *)gifEmojiItem {
    GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *item = [[GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem alloc] init];

    item.emojiType = GJGCChatInputExpandEmojiTypeGIF;
    item.emojiListFilePath = GJCFMainBundlePath(@"gifEmoji.plist");
    item.faceEmojiIconName = @"emoji_bar_gifmoji";
    item.isNeedShowSendButton = NO;
    item.isNeedShowRightSideLine = YES;

    return item;
}

@end

@implementation LMEmotionModel


@end

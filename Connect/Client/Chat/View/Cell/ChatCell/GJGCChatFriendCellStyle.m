//
//  GJGCChatFirendCellStyle.m
//  Connect
//
//  Created by KivenLin on 14-11-10.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatFriendCellStyle.h"
#import "GJGCChatContentEmojiParser.h"

@implementation GJGCChatFriendCellStyle

+ (NSString *)imageTag {
    return @"imageTag";
}

+ (NSDictionary *)formateSimpleTextMessage:(NSString *)messageText {
    if (GJCFStringIsNull(messageText)) {
        return nil;
    }

    return [[GJGCChatContentEmojiParser sharedParser] parseContent:messageText];
}

+ (NSAttributedString *)formateAudioDuration:(NSString *)duration {
    if (GJCFStringIsNull(duration)) {
        return nil;
    }

    int durationInt = [duration intValue];
    NSString *durationFormate = [NSString stringWithFormat:@"%d:%02d", durationInt / 60, durationInt % 60];

    GJCFCoreTextAttributedStringStyle *stringStyle = [[GJCFCoreTextAttributedStringStyle alloc] init];
    stringStyle.foregroundColor = [GJGCCommonFontColorStyle audioTimeTextColor];
    stringStyle.font = [GJGCCommonFontColorStyle listTitleAndDetailTextFont];

    return [[NSAttributedString alloc] initWithString:durationFormate attributes:[stringStyle attributedDictionary]];
}

+ (NSAttributedString *)formateGroupChatSenderName:(NSString *)senderName {
    if (GJCFStringIsNull(senderName)) {
        return nil;
    }
    GJCFCoreTextAttributedStringStyle *stringStyle = [[GJCFCoreTextAttributedStringStyle alloc] init];
    stringStyle.foregroundColor = [GJGCCommonFontColorStyle baseAndTitleAssociateTextColor];
    stringStyle.font = [GJGCCommonFontColorStyle baseAndTitleAssociateTextFont];

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:senderName attributes:[stringStyle attributedDictionary]];

    return attributedString;
}


@end

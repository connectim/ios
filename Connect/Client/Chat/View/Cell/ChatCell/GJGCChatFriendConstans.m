//
//  GJGCChatFriendAndGroupConstans.m
//  Connect
//
//  Created by KivenLin on 14-11-5.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatFriendConstans.h"

@implementation GJGCChatFriendConstans

+ (NSDictionary *)chatCellIdentifierDict {
    return @{

            @"GJGCChatFriendTextMessageCell": @"GJGCChatFriendTextMessageCellIdentifier",

            @"GJGCChatFriendAudioMessageCell": @"GJGCChatFriendAudioMessageCellIdentifier",

            @"GJGCChatFriendImageMessageCell": @"GJGCChatFriendImageMessageCellIdentifier",

            @"GJGCChatFriendTimeCell": @"GJGCChatFriendTimeCellIdentifier",

            @"GJGCChatFriendMemberWelcomeCell": @"GJGCChatFriendMemberWelcomeCellIdentifier",

            @"GJGCChatFriendGroupCallCell": @"GJGCChatFriendGroupCallCellIdentifier",

            @"GJGCChatFriendAcceptGroupCallCell": @"GJGCChatFriendAcceptGroupCallCellIdentifier",

            @"GJGCChatFriendGifCell": @"GJGCChatFriendGifCellIdentifier",

            @"GJGCChatFriendVideoCell": @"GJGCChatFriendVideoCellIdentifier",

            @"ChatPayReceiptCell": @"ChatPayReceiptCellIdentifier",

            @"ChatTransferCell": @"ChatTransferCellIdentifier",


            @"ChatMapCell": @"ChatMapCellIdentifier",

            @"ChatRedEnvelopeCell": @"ChatRedEnvelopeCellIdentifier",

            @"ChatNameCardCell": @"ChatNameCardCellIdentifier",

            @"ChatStatusTipCell": @"ChatStatusTipCellIdentifier",

            @"NoRelationShipTipCell": @"NoRelationShipTipCellIdentifier",

            @"NewSecureChatTipCell": @"NewSecureChatTipCellIdentifier",

            @"InviteToGroupCell": @"InviteToGroupCellIdentifier",

            @"ApplyJoinToGroupCell": @"ApplyJoinToGroupCellIdentifier",

            @"LMWalletLinkCell": @"LMWalletLinkCellIdentifier",
    };

}

+ (NSDictionary *)chatCellContentTypeDict {
    return @{

            @(GJGCChatFriendContentTypeText): @"GJGCChatFriendTextMessageCell",

            @(GJGCChatFriendContentTypeAudio): @"GJGCChatFriendAudioMessageCell",

            @(GJGCChatFriendContentTypeImage): @"GJGCChatFriendImageMessageCell",

            @(GJGCChatFriendContentTypeTime): @"GJGCChatFriendTimeCell",

            @(GJGCChatFriendContentTypeSnapChat): @"GJGCChatFriendSnapChatTipCell",

            @(GJGCChatFriendContentTypeGif): @"GJGCChatFriendGifCell",

            @(GJGCChatFriendContentTypeVideo): @"GJGCChatFriendVideoCell",

            @(GJGCChatFriendContentTypePayReceipt): @"ChatPayReceiptCell",

            @(GJGCChatFriendContentTypeTransfer): @"ChatTransferCell",

            @(GJGCChatFriendContentTypeMapLocation): @"ChatMapCell",

            @(GJGCChatFriendContentTypeRedEnvelope): @"ChatRedEnvelopeCell",

            @(GJGCChatFriendContentTypeNameCard): @"ChatNameCardCell",

            @(GJGCChatFriendContentTypeStatusTip): @"ChatStatusTipCell",

            @(GJGCChatFriendContentTypeNoRelationShipTip): @"NoRelationShipTipCell",

            @(GJGCChatFriendContentTypeSecureTip): @"NewSecureChatTipCell",

            @(GJGCChatInviteToGroup): @"InviteToGroupCell",

            @(GJGCChatApplyToJoinGroup): @"ApplyJoinToGroupCell",

            @(GJGCChatWalletLink): @"LMWalletLinkCell",
    };
}

+ (NSString *)identifierForCellClass:(NSString *)className {
    return [[GJGCChatFriendConstans chatCellIdentifierDict] objectForKey:className];
}

+ (Class)classForContentType:(GJGCChatFriendContentType)contentType {
    NSString *className = [[GJGCChatFriendConstans chatCellContentTypeDict] objectForKey:@(contentType)];

    return NSClassFromString(className);
}

+ (NSString *)identifierForContentType:(GJGCChatFriendContentType)contentType {
    NSString *className = [[GJGCChatFriendConstans chatCellContentTypeDict] objectForKey:@(contentType)];

    return [GJGCChatFriendConstans identifierForCellClass:className];
}

+ (NSString *)lastContentMessageWithType:(GJGCChatFriendContentType)type textMessage:(NSString *)textMessage senderUserName:(NSString *)senderUserName {
    if ([senderUserName isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].normalShowName]) {
        return [self lastContentMessageWithType:type textMessage:textMessage];
    }
    NSString *resultString = nil;
    switch (type) {

        case GJGCChatFriendContentTypeText: {
            resultString = [NSString stringWithFormat:@"%@:%@", senderUserName, textMessage];
        }
            break;

        case GJGCChatFriendContentTypeAudio: {
            resultString = [NSString stringWithFormat:@"%@:%@", senderUserName, LMLocalizedString(@"Chat Audio", nil)];
        }
            break;

        case GJGCChatFriendContentTypeImage: {
            resultString = [NSString stringWithFormat:@"%@:%@", senderUserName, LMLocalizedString(@"Chat Picture", nil)];
        }
            break;

        case GJGCChatFriendContentTypeVideo: {
            resultString = [NSString stringWithFormat:@"%@:%@", senderUserName, LMLocalizedString(@"Chat Video", nil)];
        }
            break;

        case GJGCChatFriendContentTypeSnapChat: {
            resultString = LMLocalizedString(@"Chat Snapchat", nil);
        }
            break;

        case GJGCChatFriendContentTypeGif: {
            resultString = [NSString stringWithFormat:@"%@:%@", senderUserName, LMLocalizedString(@"Chat Expression", nil)];
        }
            break;

        case GJGCChatFriendContentTypePayReceipt: {
            resultString = [NSString stringWithFormat:@"%@:%@", senderUserName, LMLocalizedString(@"Chat Funding", nil)];
        }
            break;
        case GJGCChatFriendContentTypeNameCard: {
            resultString = [NSString stringWithFormat:@"%@:%@", senderUserName, LMLocalizedString(@"Chat Visting card", nil)];
        }
            break;
        case GJGCChatFriendContentTypeTransfer: {
            resultString = [NSString stringWithFormat:@"%@:%@", senderUserName, LMLocalizedString(@"Chat Transfer", nil)];
        }
            break;
        case GJGCChatFriendContentTypeRedEnvelope: {
            resultString = [NSString stringWithFormat:@"%@:%@", senderUserName, LMLocalizedString(@"Chat Red packet", nil)];
        }
            break;
        case GJGCChatFriendContentTypeMapLocation: {
            resultString = [NSString stringWithFormat:@"%@:%@", senderUserName, LMLocalizedString(@"Chat Location", nil)];
        }
            break;
        case GJGCChatInviteNewMemberTip: {
            resultString = LMLocalizedString(@"Chat Group Namecard", nil);
        }
            break;
        case GJGCChatFriendContentTypeStatusTip: {
            resultString = LMLocalizedString(@"Chat Tips", nil);
        }
            break;

        case GJGCChatInviteToGroup: {
            resultString = LMLocalizedString(@"Chat Group Namecard", nil);
        }
            break;

        case GJGCChatApplyToJoinGroup: {
            resultString = LMLocalizedString(@"Chat Group certification", nil);
        }
            break;
        case GJGCChatWalletLink: {
            resultString = [NSString stringWithFormat:@"%@:%@", senderUserName, LMLocalizedString(@"Link Web page", nil)];
        }
            break;
        case 102: {
            resultString = LMLocalizedString(@"Chat Announcement", nil);
        }
            break;
        default:
            resultString = LMLocalizedString(@"Chat Unkonw message", nil);
            break;
    }
    return resultString;
}

+ (NSString *)lastContentMessageWithType:(GJGCChatFriendContentType)type
                             textMessage:(NSString *)textMessage {
    NSString *resultString = nil;

    switch (type) {

        case GJGCChatFriendContentTypeText: {
            resultString = textMessage;
        }
            break;

        case GJGCChatFriendContentTypeAudio: {
            resultString = LMLocalizedString(@"Chat Audio", nil);
        }
            break;

        case GJGCChatFriendContentTypeImage: {
            resultString = LMLocalizedString(@"Chat Picture", nil);
        }
            break;

        case GJGCChatFriendContentTypeVideo: {
            resultString = LMLocalizedString(@"Chat Video", nil);
        }
            break;

        case GJGCChatFriendContentTypeSnapChat: {
            resultString = LMLocalizedString(@"Chat Snapchat", nil);
        }
            break;

        case GJGCChatFriendContentTypeGif: {
            resultString = LMLocalizedString(@"Chat Expression", nil);
        }
            break;

        case GJGCChatFriendContentTypePayReceipt: {
            resultString = LMLocalizedString(@"Chat Funding", nil);
        }
            break;
        case GJGCChatFriendContentTypeNameCard: {
            resultString = LMLocalizedString(@"Chat Visting card", nil);
        }
            break;
        case GJGCChatFriendContentTypeTransfer: {
            resultString = LMLocalizedString(@"Chat Transfer", nil);
        }
            break;
        case GJGCChatFriendContentTypeRedEnvelope: {
            resultString = LMLocalizedString(@"Chat Red packet", nil);
        }
            break;
        case GJGCChatFriendContentTypeMapLocation: {
            resultString = LMLocalizedString(@"Chat Location", nil);
        }
            break;
        case GJGCChatInviteNewMemberTip: {
            resultString = LMLocalizedString(@"Chat Group Namecard", nil);
        }
            break;
        case GJGCChatFriendContentTypeStatusTip: {
            resultString = LMLocalizedString(@"Chat Tips", nil);
        }
            break;

        case GJGCChatInviteToGroup: {
            resultString = LMLocalizedString(@"Chat Group Namecard", nil);
        }
            break;

        case GJGCChatApplyToJoinGroup: {
            resultString = LMLocalizedString(@"Chat Group certification", nil);
        }
            break;
        case GJGCChatWalletLink: {
            resultString = LMLocalizedString(@"Link Web page", nil);
        }
            break;
        case 102: {
            resultString = LMLocalizedString(@"Chat Announcement", nil);
        }
            break;
        default:
            resultString = LMLocalizedString(@"Chat Unkonw message", nil);
            break;
    }
    return resultString;
}

+ (BOOL)shouldNoticeWithType:(NSInteger)type {
    switch (type) {
        case GJGCChatFriendContentTypeText:
        case GJGCChatFriendContentTypeAudio:
        case GJGCChatFriendContentTypeImage:
        case GJGCChatFriendContentTypeVideo:
        case GJGCChatFriendContentTypeGif:
        case GJGCChatFriendContentTypePayReceipt:
        case GJGCChatFriendContentTypeTransfer:
        case GJGCChatFriendContentTypeRedEnvelope:
        case GJGCChatFriendContentTypeMapLocation:
        case GJGCChatFriendContentTypeNameCard:
        case GJGCChatInviteToGroup:
        case GJGCChatApplyToJoinGroup:
            return YES;
            break;
        default:
            return NO;
            break;
    }
}


@end

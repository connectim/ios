//
//  GJGCChatSystemNotiCellStyle.m
//  Connect
//
//  Created by KivenLin on 14-11-6.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatSystemNotiCellStyle.h"


@implementation GJGCChatSystemNotiCellStyle


/* 时间转文案 */
+ (NSString *)timeAgoStringByLastMsgTime:(long long)lastDateTime lastMsgTime:(long long)lastTimeStamp {

    //保证秒级
    lastDateTime = lastDateTime > pow(10, 11) ? lastDateTime / 1000 : lastDateTime;
    lastTimeStamp = lastTimeStamp > pow(10, 11) ? lastTimeStamp / 1000 : lastTimeStamp;

    NSDate *date = GJCFDateFromTimeInterval(lastDateTime);

    if (GJCFCheckObjectNull(date)) {
        return nil;
    }

    long long timeNow = lastDateTime;
    NSCalendar *calendar = [GJCFDateUitil sharedCalendar];
    NSInteger unitFlags = NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekOfMonth | NSCalendarUnitWeekday;
    NSDateComponents *component = [calendar components:unitFlags fromDate:date];

    NSInteger year = [component year];
    NSInteger month = [component month];
    NSInteger day = [component day];

    NSDate *today = [NSDate date];
    component = [calendar components:unitFlags fromDate:today];

    NSInteger t_year = [component year];
    NSInteger t_month = [component month];
    NSInteger t_day = [component day];

    NSString *string = nil;

    long long now = [today timeIntervalSince1970];

    long long distance = now - timeNow;
    long long lastMsgDistance = lastDateTime - lastTimeStamp;

    if (lastMsgDistance < 60 * 3) {
        return nil;
    }

    if (distance <= 60 * 60 * 24 && day == t_day && t_month == month && t_year == year) {

        string = [NSString stringWithFormat:LMLocalizedString(@"Chat Today", nil), GJCFDateToStringByFormat(date, @"HH:mm")];

    } else if (day == t_day - 1 && t_month == month && t_year == year) {

        string = [NSString stringWithFormat:LMLocalizedString(@"Chat Yesterday s", nil), GJCFDateToStringByFormat(date, @"HH:mm")];

    } else if (day == t_day - 2 && t_month == month && t_year == year) {

        string = [NSString stringWithFormat:LMLocalizedString(@"Chat the day before yesterday time", nil), GJCFDateToStringByFormat(date, @"HH:mm")];

    } else if (year == t_year) {

        NSString *detailTime = GJCFDateToStringByFormat(date, @"HH:mm");
        string = [NSString stringWithFormat:@"%ld/%ld  %@", (long) month, (long) day, detailTime];

    } else {

        NSString *detailTime = GJCFDateToStringByFormat(date, @"HH:mm");

        string = [NSString stringWithFormat:@"%ld/%ld/%ld  %@", (long) month, (long) day, (long) year, detailTime];
    }

    return string;
}

+ (NSString *)formartDurationTime:(int)time {
    if (time < 60) {
        return [NSString stringWithFormat:@"00:00:%02d", time];
    }

    if (60 <= time && time < 60 * 60) {
        int min = time / 60;
        int second = time % 60;
        return [NSString stringWithFormat:@"00:%02d:%02d", min, second];
    }

    if (time > 60 * 60) {
        int hour = time / (60 * 60);
        int min = (time % (60 * 60)) / 60;
        int second = (time % (60 * 60)) % 60;
        return [NSString stringWithFormat:@"%02d:%02d:%02d", hour, min, second];
    }
    return nil;
}

+ (NSAttributedString *)formateSystemNotiTime:(long long)time {
    NSDate *date = GJCFDateFromTimeInterval(time);

    if (GJCFCheckObjectNull(date)) {
        return nil;
    }

    long long timeNow = [[NSDate date] timeIntervalSince1970];
    NSCalendar *calendar = [GJCFDateUitil sharedCalendar];
    NSInteger unitFlags = NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitYear | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekOfMonth | NSCalendarUnitWeekday;
    NSDateComponents *component = [calendar components:unitFlags fromDate:date];

    NSInteger year = [component year];
    NSInteger month = [component month];
    NSInteger day = [component day];

    NSDate *today = [NSDate date];
    component = [calendar components:unitFlags fromDate:today];

    NSInteger t_year = [component year];
    NSInteger t_month = [component month];
    NSInteger t_day = [component day];

    NSString *string = nil;

    long long now = [today timeIntervalSince1970];

    long long distance = now - timeNow;

    if (distance <= 60 * 60 * 24 && day == t_day && t_month == month && t_year == year) {
        string = [NSString stringWithFormat:LMLocalizedString(@"Chat Today", nil), GJCFDateToStringByFormat(date, @"HH:mm")];

    } else if (day == t_day - 1 && t_month == month && t_year == year) {

        string = [NSString stringWithFormat:LMLocalizedString(@"Chat Yesterday s", nil), GJCFDateToStringByFormat(date, @"HH:mm")];

    } else if (day == t_day - 2 && t_month == month && t_year == year) {

        string = [NSString stringWithFormat:LMLocalizedString(@"The day before yesterday  %@", nil), GJCFDateToStringByFormat(date, @"HH:mm")];

    } else if (year == t_year) {

        NSString *detailTime = GJCFDateToStringByFormat(date, @"HH:mm");
        string = [NSString stringWithFormat:@"%ld/%ld  %@", (long) month, (long) day, detailTime];

    } else {

        NSString *detailTime = GJCFDateToStringByFormat(date, @"HH:mm");

        string = [NSString stringWithFormat:@"%ld/%ld/%ld  %@", (long) month, (long) day, (long) year, detailTime];
    }

    return [GJGCChatSystemNotiCellStyle formateTime:string];
}

/* 时间标签 */
+ (NSAttributedString *)formateTime:(NSString *)timeString {
    if (GJCFStringIsNull(timeString)) {
        return nil;
    }
    NSDictionary *attributedDict = [[GJGCChatSystemNotiCellStyle timeLabelStyle] attributedDictionary];
    return [[NSAttributedString alloc] initWithString:timeString attributes:attributedDict];
}

/* 名字标签风格 */
+ (NSAttributedString *)formateNameString:(NSString *)name {
    if (GJCFStringIsNull(name)) {
        return nil;
    }
    NSDictionary *stringAttributedDict = [[GJGCChatSystemNotiCellStyle nameLabelStyle] attributedDictionary];
    NSDictionary *paragraphDict = [[GJGCChatSystemNotiCellStyle nameLabelParagraphStyle] paragraphAttributedDictionary];

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:name attributes:stringAttributedDict];
    [attributedString addAttributes:paragraphDict range:NSMakeRange(0, name.length)];

    return attributedString;
}

+ (NSAttributedString *)formateActiveDescription:(NSString *)description {
    if (GJCFStringIsNull(description)) {
        return nil;
    }

    GJCFCoreTextAttributedStringStyle *stringStyle = [[GJCFCoreTextAttributedStringStyle alloc] init];
    stringStyle.foregroundColor = [GJGCCommonFontColorStyle baseAndTitleAssociateTextColor];
    stringStyle.font = [GJGCCommonFontColorStyle listTitleAndDetailTextFont];

    GJCFCoreTextParagraphStyle *paragraphStyle = [[GJCFCoreTextParagraphStyle alloc] init];
    paragraphStyle.maxLineSpace = 5.f;
    paragraphStyle.minLineSpace = 5.f;

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:description attributes:[stringStyle attributedDictionary]];
    [attributedString addAttributes:[paragraphStyle paragraphAttributedDictionary] range:NSMakeRange(0, description.length)];

    return attributedString;
}


////////////////////////////////////////////////////////////////////////////////


/* 时间标签 */
+ (GJCFCoreTextAttributedStringStyle *)timeLabelStyle {
    GJCFCoreTextAttributedStringStyle *stringStyle = [[GJCFCoreTextAttributedStringStyle alloc] init];
    stringStyle.foregroundColor = [GJGCCommonFontColorStyle baseAndTitleAssociateTextColor];
    stringStyle.font = [GJGCCommonFontColorStyle baseAndTitleAssociateTextFont];

    return stringStyle;
}

/* 名字标签风格 */
+ (GJCFCoreTextAttributedStringStyle *)nameLabelStyle {
    GJCFCoreTextAttributedStringStyle *stringStyle = [[GJCFCoreTextAttributedStringStyle alloc] init];
    stringStyle.font = [GJGCCommonFontColorStyle detailBigTitleFont];
    stringStyle.foregroundColor = [GJGCCommonFontColorStyle detailBigTitleColor];


    return stringStyle;
}

/* 名字标签换行属性 */
+ (GJCFCoreTextParagraphStyle *)nameLabelParagraphStyle {
    GJCFCoreTextParagraphStyle *paragraphStyle = [[GJCFCoreTextParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = kCTLineBreakByTruncatingTail;

    return paragraphStyle;
}

/* 申请理由标签 */
+ (GJCFCoreTextAttributedStringStyle *)applyReasonLabelStyle {
    GJCFCoreTextAttributedStringStyle *stringStyle = [[GJCFCoreTextAttributedStringStyle alloc] init];
    stringStyle.font = [GJGCCommonFontColorStyle listTitleAndDetailTextFont];
    stringStyle.foregroundColor = [GJGCCommonFontColorStyle baseAndTitleAssociateTextColor];

    return stringStyle;
}

/* 按钮 */
+ (GJCFCoreTextAttributedStringStyle *)applyButtonStyle {
    GJCFCoreTextAttributedStringStyle *stringStyle = [[GJCFCoreTextAttributedStringStyle alloc] init];
    stringStyle.foregroundColor = [GJGCCommonFontColorStyle mainThemeColor];
    stringStyle.font = [GJGCCommonFontColorStyle listTitleAndDetailTextFont];

    return stringStyle;
}

+ (NSAttributedString *)formateOpensnapChatWithTime:(int)snapChatTime isSendToMe:(BOOL)isSendToMe chatUserName:(NSString *)userName {
    NSString *text = nil;
    if (snapChatTime > 0) {
        if (isSendToMe) {
            text = [NSString stringWithFormat:LMLocalizedString(@"Chat set the self destruct timer to", nil), userName, [self formartSnaptime:snapChatTime]];
        } else {
            text = [NSString stringWithFormat:LMLocalizedString(@"Chat set the self destruct timer to", nil), LMLocalizedString(@"Chat You", nil), [self formartSnaptime:snapChatTime]];
        }
    } else {
        if (isSendToMe) {
            text = [NSString stringWithFormat:LMLocalizedString(@"Chat disable the self descruct", nil), userName];
        } else {
            text = [NSString stringWithFormat:LMLocalizedString(@"Chat disable the self descruct", nil), LMLocalizedString(@"Chat You", nil)];
        }
    }
    NSMutableAttributedString *descText = [[NSMutableAttributedString alloc] initWithString:text];
    [descText addAttribute:NSFontAttributeName
                     value:[UIFont systemFontOfSize:FONT_SIZE(23)]
                     range:NSMakeRange(0, text.length)];

    [descText addAttribute:NSForegroundColorAttributeName
                     value:LMAssociateTextColor
                     range:NSMakeRange(0, text.length)];

    return descText;
}

+ (NSString *)formartSnaptime:(int)time {

    NSString *timeStr = @"";

    time = time / 1000;

    if (time / 60) {
        if (time / (60 * 60)) {
            timeStr = [NSString stringWithFormat:LMLocalizedString(@"Chat Hour", nil), time / (60 * 60)];
        } else {
            timeStr = [NSString stringWithFormat:LMLocalizedString(@"Chat Minute", nil), time / 60];
        }
    } else {
        timeStr = [NSString stringWithFormat:LMLocalizedString(@"Chat Seconds", nil), time];
    }

    return timeStr;
}

+ (NSAttributedString *)formateTransferWithAmount:(long long int)amount isSendToMe:(BOOL)isSendToMe isOuterTransfer:(BOOL)isOuterTransfer {
    NSString *payMessage = [NSString stringWithFormat:LMLocalizedString(@"Chat Transfer to other BTC", nil), [PayTool getBtcStringWithAmount:amount]];
    if (isSendToMe) {
        payMessage = [NSString stringWithFormat:LMLocalizedString(@"Chat Transfer to you BTC", nil), [PayTool getBtcStringWithAmount:amount]];
    }
    if (isOuterTransfer) {
        payMessage = [NSString stringWithFormat:LMLocalizedString(@"Chat You receive a transfer BTC", nil), [PayTool getBtcStringWithAmount:amount]];
    }
    NSMutableAttributedString *descText = [[NSMutableAttributedString alloc] initWithString:payMessage];
    [descText addAttribute:NSFontAttributeName
                     value:[UIFont systemFontOfSize:FONT_SIZE(28)]
                     range:NSMakeRange(0, payMessage.length)];
    [descText addAttribute:NSForegroundColorAttributeName
                     value:[UIColor whiteColor]
                     range:NSMakeRange(0, payMessage.length)];

    return descText;
}

+ (NSAttributedString *)formateRecieptWithAmount:(long long int)amount isSendToMe:(BOOL)isSendToMe isCrowdfundRceipt:(BOOL)isCrowdfundRceipt withNote:(NSString *)note {
    NSString *tipMessage = LMLocalizedString(@"Wallet Payment to friend", nil);
    if (isSendToMe) {
        tipMessage = LMLocalizedString(@"Wallet Receipt", nil);
    }
    if (isCrowdfundRceipt) {
        tipMessage = LMLocalizedString(@"Chat Crowd funding", nil);
    }

    NSString *payMessage = [NSString stringWithFormat:LMLocalizedString(@"Chat Enter BTC", nil), tipMessage, [PayTool getBtcStringWithAmount:amount]];
    if (isSendToMe) {
        payMessage = [NSString stringWithFormat:LMLocalizedString(@"Chat Enter BTC", nil), tipMessage, [PayTool getBtcStringWithAmount:amount]];
    }

    if (isCrowdfundRceipt) {
        payMessage = [NSString stringWithFormat:LMLocalizedString(@"Chat Per BTC", nil), tipMessage, [PayTool getBtcStringWithAmount:amount]];
    }


    NSMutableAttributedString *descText = [[NSMutableAttributedString alloc] initWithString:payMessage];
    [descText addAttribute:NSFontAttributeName
                     value:[UIFont systemFontOfSize:FONT_SIZE(28)]
                     range:NSMakeRange(0, payMessage.length)];
    [descText addAttribute:NSForegroundColorAttributeName
                     value:[UIColor whiteColor]
                     range:NSMakeRange(0, payMessage.length)];

    return descText;

}


+ (NSAttributedString *)formateNameCardSubTipsIsFromSelf:(BOOL)isFromSelf {
    NSString *statusMessage = LMLocalizedString(@"Chat Contact card", nil);
    if (isFromSelf) {
        statusMessage = LMLocalizedString(@"Chat Contact card", nil);
    }
    NSMutableAttributedString *subMessageText = [[NSMutableAttributedString alloc] initWithString:statusMessage];
    [subMessageText addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:FONT_SIZE(24)]
                           range:NSMakeRange(0, statusMessage.length)];
    [subMessageText addAttribute:NSForegroundColorAttributeName
                           value:LMAssociateTextColor
                           range:NSMakeRange(0, statusMessage.length)];
    return subMessageText;

}

+ (NSAttributedString *)formateCellLeftSubTipsWithType:(GJGCChatFriendContentType)contentType withNote:(NSString *)note isCrowding:(BOOL)isCrowd {
    NSString *statusMessage = note;
    if (GJCFStringIsNull(statusMessage)) {
        switch (contentType) {
            case GJGCChatFriendContentTypePayReceipt: {
                if (isCrowd) {
                    statusMessage = @"";
                } else {
                    statusMessage = LMLocalizedString(@"Wallet Receipt", nil);
                }
            }
                break;
            case GJGCChatFriendContentTypeTransfer: {
                statusMessage = LMLocalizedString(@"Wallet Transfer", nil);
            }
                break;
            case GJGCChatFriendContentTypeRedEnvelope:
                statusMessage = LMLocalizedString(@"Wallet Best wishes", nil);
                break;

            case GJGCChatFriendContentTypeNameCard:
                statusMessage = LMLocalizedString(@"Chat Contact card", nil);
                break;
            case GJGCChatInviteToGroup:
            case GJGCChatApplyToJoinGroup:
                statusMessage = LMLocalizedString(@"Link Group", nil);
                break;

            default:
                break;
        }
    }
    NSMutableAttributedString *subMessageText = [[NSMutableAttributedString alloc] initWithString:statusMessage];
    [subMessageText addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:FONT_SIZE(24)]
                           range:NSMakeRange(0, statusMessage.length)];
    [subMessageText addAttribute:NSForegroundColorAttributeName
                           value:LMAssociateTextColor
                           range:NSMakeRange(0, statusMessage.length)];
    return subMessageText;

}

+ (NSAttributedString *)formateCellStatusWithHandle:(BOOL)handle refused:(BOOL)refused isNoted:(BOOL)isNoted{

    NSString *statusMessage = nil;
    UIColor *textColor = LMAssociateTextColor;
    if (handle) {
        statusMessage = LMLocalizedString(@"Link Accepted", nil);
        if (refused) {
            statusMessage = LMLocalizedString(@"Link Refuse", nil);
        }
    } else {
        if (isNoted) {
            statusMessage = @"";
            textColor = LMBasicBlue;
        } else{
            statusMessage = LMLocalizedString(@"Chat New application", nil);
            textColor = LMBasicBlue;
        }
    }
    NSMutableAttributedString *subMessageText = [[NSMutableAttributedString alloc] initWithString:statusMessage];
    [subMessageText addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:FONT_SIZE(24)]
                           range:NSMakeRange(0, statusMessage.length)];
    [subMessageText addAttribute:NSForegroundColorAttributeName
                           value:textColor
                           range:NSMakeRange(0, statusMessage.length)];
    return subMessageText;

}


+ (NSAttributedString *)formateRecieptSubTipsWithTotal:(int)total payCount:(int)payCount isCrowding:(BOOL)isCrowd transStatus:(int)status {
    NSString *statusMessage = [NSString stringWithFormat:LMLocalizedString(@"Chat founded", nil), payCount, total];
    if (!isCrowd) {
        statusMessage = LMLocalizedString(@"Chat Unpaid", nil);
        if (status == 1) {
            statusMessage = LMLocalizedString(@"Wallet Unconfirmed", nil);
        } else if (status == 2) {
            statusMessage = LMLocalizedString(@"Wallet Confirmed", nil);
        }
    } else {
        if (total == payCount) {
            statusMessage = LMLocalizedString(@"Chat Founded complete", nil);
        }
    }
    NSMutableAttributedString *statusMessageText = [[NSMutableAttributedString alloc] initWithString:statusMessage];
    [statusMessageText addAttribute:NSFontAttributeName
                              value:[UIFont systemFontOfSize:FONT_SIZE(24)]
                              range:NSMakeRange(0, statusMessage.length)];
    [statusMessageText addAttribute:NSForegroundColorAttributeName
                              value:GJCFQuickHexColor(@"007AFF")//before redcolor
                              range:NSMakeRange(0, statusMessage.length)];


    return statusMessageText;
}

+ (NSAttributedString *)formateRedBagWithMessage:(NSString *)message isOuterTransfer:(BOOL)isOuterTransfer {

    NSString *redBagMessage = LMLocalizedString(@"Chat Send a Luck Packet Click to view", nil);
    if (isOuterTransfer) {
        redBagMessage = LMLocalizedString(@"Chat You receive a red envelope", nil);
    }

    NSMutableAttributedString *sendRedBayAttrS = [[NSMutableAttributedString alloc] initWithString:redBagMessage];
    [sendRedBayAttrS addAttribute:NSFontAttributeName
                            value:[UIFont systemFontOfSize:FONT_SIZE(28)]
                            range:NSMakeRange(0, redBagMessage.length)];
    [sendRedBayAttrS addAttribute:NSForegroundColorAttributeName
                            value:[UIColor whiteColor]
                            range:NSMakeRange(0, redBagMessage.length)];
    return sendRedBayAttrS;
}


+ (NSAttributedString *)formatetGroupInviteGroupName:(NSString *)groupName reciverName:(NSString *)reciverName isSystemMessage:(BOOL)isSystemMessage isSendFromMySelf:(BOOL)isSendFromMySelf {

    NSString *tipMessage = nil;
    if (isSystemMessage) {
        tipMessage = [NSString stringWithFormat:LMLocalizedString(@"Link apply to join group chat", nil), reciverName, groupName];
    } else {
        if (isSendFromMySelf) {
            tipMessage = [NSString stringWithFormat:LMLocalizedString(@"Link Invite friend to join", nil), groupName];
        } else {
            tipMessage = [NSString stringWithFormat:LMLocalizedString(@"Link Invite you to join", nil), groupName];
        }
    }
    NSMutableAttributedString *sendRedBayAttrS = [[NSMutableAttributedString alloc] initWithString:tipMessage];
    [sendRedBayAttrS addAttribute:NSFontAttributeName
                            value:[UIFont systemFontOfSize:FONT_SIZE(28)]
                            range:NSMakeRange(0, tipMessage.length)];
    [sendRedBayAttrS addAttribute:NSForegroundColorAttributeName
                            value:[UIColor whiteColor]
                            range:NSMakeRange(0, tipMessage.length)];
    return sendRedBayAttrS;
}


+ (NSAttributedString *)formateReceiptTipWithPayName:(NSString *)payName receiptName:(NSString *)receiptName isCrowding:(BOOL)isCrowd {

    if ([payName isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].normalShowName]) {
        payName = LMLocalizedString(@"Chat You", nil);
    }

    if ([receiptName isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].normalShowName]) {
        receiptName = LMLocalizedString(@"Chat You", nil);
    }

    NSString *tipMessage = [NSString stringWithFormat:LMLocalizedString(@"Chat paid the bill to", nil), payName, receiptName];
    if (isCrowd) {
        tipMessage = [NSString stringWithFormat:LMLocalizedString(@"Chat paid the crowd founding to", nil), payName, receiptName];
    }
    NSMutableAttributedString *tipMessageText = [[NSMutableAttributedString alloc] initWithString:tipMessage];
    [tipMessageText addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:FONT_SIZE(22)]
                           range:NSMakeRange(0, tipMessage.length)];
    [tipMessageText addAttribute:NSForegroundColorAttributeName
                           value:LMAssociateTextColor
                           range:NSMakeRange(0, tipMessage.length)];

    return tipMessageText;

}

+ (NSAttributedString *)formateCrowdingCompleteTipMessage {

    NSString *tipMessage = LMLocalizedString(@"Chat Founded complete", nil);

    NSMutableAttributedString *tipMessageText = [[NSMutableAttributedString alloc] initWithString:tipMessage];
    [tipMessageText addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:FONT_SIZE(22)]
                           range:NSMakeRange(0, tipMessage.length)];
    [tipMessageText addAttribute:NSForegroundColorAttributeName
                           value:LMAssociateTextColor
                           range:NSMakeRange(0, tipMessage.length)];

    return tipMessageText;

}


+ (NSAttributedString *)formateRedbagTipWithSenderName:(NSString *)sendName garbName:(NSString *)garbName {

    if ([sendName isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].normalShowName]) {
        sendName = LMLocalizedString(@"Chat You", nil);
    }
    if ([garbName isEqualToString:[[LKUserCenter shareCenter] currentLoginUser].normalShowName]) {
        garbName = LMLocalizedString(@"Chat You", nil);
    }
    NSString *tipMessage = [NSString stringWithFormat:LMLocalizedString(@"Chat opened Lucky Packet of", nil), garbName, sendName];
    NSMutableAttributedString *tipMessageText = [[NSMutableAttributedString alloc] initWithString:tipMessage];
    [tipMessageText addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:FONT_SIZE(22)]
                           range:NSMakeRange(0, tipMessage.length)];
    [tipMessageText addAttribute:NSForegroundColorAttributeName
                           value:LMAssociateTextColor
                           range:NSMakeRange(0, tipMessage.length)];

    return tipMessageText;
}

+ (NSAttributedString *)formateEcdhkeyUpdateWithSuccess:(BOOL)success{
    NSString *tipMessage = LMLocalizedString(@"Chat The private key failed to updated. Your message will be encrypted by temporary ECDH key", nil);
    if (success) {
        tipMessage = LMLocalizedString(@"Chat The private key has been updated successfullYour message will be encrypted by temporary ECDH key", nil);
    }
    NSMutableAttributedString *tipMessageText = [[NSMutableAttributedString alloc] initWithString:tipMessage];
    [tipMessageText addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:FONT_SIZE(22)]
                           range:NSMakeRange(0, tipMessage.length)];
    [tipMessageText addAttribute:NSForegroundColorAttributeName
                           value:LMAssociateTextColor
                           range:NSMakeRange(0, tipMessage.length)];
    
    return tipMessageText;
}


+ (NSAttributedString *)formateAddressNotify:(long long)amount {

    NSString *tipMessage = [NSString stringWithFormat:LMLocalizedString(@"Chat your bitcoin address received a transfer", nil), [PayTool getBtcStringWithAmount:amount]];
    NSMutableAttributedString *tipMessageText = [[NSMutableAttributedString alloc] initWithString:tipMessage];
    [tipMessageText addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:FONT_SIZE(22)]
                           range:NSMakeRange(0, tipMessage.length)];
    [tipMessageText addAttribute:NSForegroundColorAttributeName
                           value:[UIColor lightGrayColor]
                           range:NSMakeRange(0, tipMessage.length)];

    return tipMessageText;
}

+ (NSAttributedString *)formateTipStringWithTipMessage:(NSString *)tipMessage {

    NSMutableAttributedString *tipMessageText = [[NSMutableAttributedString alloc] initWithString:tipMessage];
    [tipMessageText addAttribute:NSFontAttributeName
                           value:[UIFont systemFontOfSize:FONT_SIZE(22)]
                           range:NSMakeRange(0, tipMessage.length)];
    [tipMessageText addAttribute:NSForegroundColorAttributeName
                           value:[UIColor lightGrayColor]
                           range:NSMakeRange(0, tipMessage.length)];

    return tipMessageText;
}


+ (NSAttributedString *)formatLocationMessage:(NSString *)location {
    NSMutableAttributedString *descText = [[NSMutableAttributedString alloc] initWithString:location];
    [descText addAttribute:NSFontAttributeName
                     value:[UIFont systemFontOfSize:FONT_SIZE(24)]
                     range:NSMakeRange(0, location.length)];
    [descText addAttribute:NSForegroundColorAttributeName
                     value:[UIColor whiteColor]
                     range:NSMakeRange(0, location.length)];


    return descText;
}

@end

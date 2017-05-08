//
//  RecentChatStyle.m
//  Connect
//
//  Created by MoHuilin on 16/6/25.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "RecentChatStyle.h"
#import "GJGCChatSystemNotiCellStyle.h"

@implementation RecentChatStyle

+ (NSAttributedString *)formateName:(NSString *)name {
    GJCFCoreTextAttributedStringStyle *stringStyle = [[GJCFCoreTextAttributedStringStyle alloc] init];
    stringStyle.foregroundColor = [GJGCCommonFontColorStyle listTitleAndDetailTextColor];
    stringStyle.font = [UIFont boldSystemFontOfSize:16];

    return [[NSAttributedString alloc] initWithString:name attributes:[stringStyle attributedDictionary]];
}

+ (NSAttributedString *)formateTime:(long long)time {
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

        string = [NSString stringWithFormat:@"%@", GJCFDateToStringByFormat(date, @"HH:mm")];

    } else if (day == t_day - 1 && t_month == month && t_year == year) {

        string = LMLocalizedString(@"Chat Yesterday", nil);

    } else if (day == t_day - 2 && t_month == month && t_year == year) {

        string = LMLocalizedString(@"Chat The day before yesterday", nil);

    } else if (year == t_year) {

        string = [NSString stringWithFormat:@"%ld/%ld", (long) month, (long) day];

    } else {

        string = [NSString stringWithFormat:@"%ld/%ld/%ld", (long) month, (long) day, (long) year];
    }

    return [GJGCChatSystemNotiCellStyle formateTime:string];
}

+ (NSAttributedString *)formateContent:(NSString *)content {
    GJCFCoreTextAttributedStringStyle *stringStyle = [[GJCFCoreTextAttributedStringStyle alloc] init];
    stringStyle.foregroundColor = [GJGCCommonFontColorStyle listTitleAndDetailTextColor];
    stringStyle.font = [GJGCCommonFontColorStyle baseAndTitleAssociateTextFont];

    return [[NSAttributedString alloc] initWithString:content attributes:[stringStyle attributedDictionary]];
}


@end

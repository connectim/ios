//
//  GJGCChatContentEmojiParser.m
//  Connect
//
//  Created by KivenLin on 14-11-26.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatContentEmojiParser.h"
#import "GJGCChatInputExpandEmojiPanelMenuBarDataSource.h"
#import "YYImageCache.h"
#import "YYImage.h"
#import "GJGCGIFLoadManager.h"
#import "NSURL+Param.h"
#import "StringTool.h"

static GJGCChatContentEmojiParser *manager = nil;

@interface GJGCChatContentEmojiParser ()

@property(nonatomic, strong) NSDictionary *emojiNameDict; //Legal expression

@property(nonatomic, strong) NSDictionary *emojiNameInternationalizationDict;

@property(nonatomic, strong) NSBundle *emotionBundle;

@property(nonatomic, strong) NSMutableDictionary *itemsEmojiDict;

@end

@implementation GJGCChatContentEmojiParser

+ (GJGCChatContentEmojiParser *)sharedParser {
    @synchronized (self) {
        if (manager == nil) {
            manager = [[[self class] alloc] init];
        }
    }
    return manager;
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized (self) {
        if (manager == nil) {
            manager = [super allocWithZone:zone];
            return manager;
        }
    }
    return nil;
}


- (instancetype)init {
    if (self = [super init]) {
        self.emojiNameDict = [NSDictionary dictionaryWithContentsOfFile:GJCFMainBundlePath(@"emojiName.plist")];
        self.emojiNameInternationalizationDict = [NSDictionary dictionaryWithContentsOfFile:GJCFMainBundlePath(@"emojiInternationalization.plist")];
        NSString *path = [[NSBundle mainBundle] pathForResource:@"ConnectEmoji" ofType:@"bundle"];
        self.emotionBundle = [NSBundle bundleWithPath:path];
        self.itemsEmojiDict = [NSMutableDictionary dictionary];
    }
    return self;
}

- (UIImage *)imageForEmotionPNGName:(NSString *)pngName {
    return [UIImage imageNamed:pngName inBundle:self.emotionBundle
 compatibleWithTraitCollection:nil];
}

- (void)prepareResources {

    [GCDQueue executeInGlobalQueue:^{
        NSArray *emojis = [GJGCChatInputExpandEmojiPanelMenuBarDataSource menuBarItems];
        for (GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *item in emojis) {
            NSArray *emojiArray = [NSArray arrayWithContentsOfFile:item.emojiListFilePath];
            if (item.emojiType == GJGCChatInputExpandEmojiTypeGIF) {
                for (NSString *gifName in emojis) {
                    NSString *cacheKey = [[NSString stringWithFormat:@"local_%@", gifName] sha1String];
                    NSData *gifData = [GJGCGIFLoadManager getCachedGifDataById:gifName];
                    if (gifData) {
                        YYImage *gifImage = [YYImage imageWithData:gifData];
                        //缓存
                        [[YYImageCache sharedCache] setImage:gifImage forKey:cacheKey];
                    }
                }
            }
            [self.itemsEmojiDict setObject:emojiArray forKey:[item.emojiListFilePath sha1String]];
        }
    }];
}

- (NSArray *)getEmojiArrayWithPath:(NSString *)path {
    NSArray *emojArray = [self.itemsEmojiDict objectForKey:[path sha1String]];

    if (!emojArray || emojArray.count == 0) {
        emojArray = [NSArray arrayWithContentsOfFile:path];
    }

    return emojArray;
}

- (NSArray *)getEmojiGroups {

    NSString *local = [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode];
    if ([[local uppercaseString] containsString:@"EN"]) {
        local = @"en";
    } else if ([[local uppercaseString] containsString:@"ZH"]) {
        local = @"cn";
    }
    NSArray *emojis = [GJGCChatInputExpandEmojiPanelMenuBarDataSource menuBarItems];
    for (GJGCChatInputExpandEmojiPanelMenuBarDataSourceItem *item in emojis) {
        NSArray *emojiArray = [NSArray arrayWithContentsOfFile:item.emojiListFilePath];
        NSMutableArray *modelEmojiArray = [NSMutableArray array];
        if (item.emojiType == GJGCChatInputExpandEmojiTypeGIF) {
            for (NSString *imageName in emojiArray) {
                LMEmotionModel *model = [LMEmotionModel new];
                model.imageGIF = imageName;
                model.text = imageName;

                [modelEmojiArray objectAddObject:model];
            }
        } else {
            for (NSDictionary *imageDict in emojiArray) {
                LMEmotionModel *model = [LMEmotionModel new];
                model.imagePNG = [[imageDict allValues] firstObject];
                model.text = [[imageDict allKeys] firstObject];
                NSDictionary *localNameDict = [self.emojiNameInternationalizationDict valueForKey:model.text];
                model.localText = [localNameDict valueForKey:local];
                [modelEmojiArray objectAddObject:model];
            }
        }
        item.emojiArrays = modelEmojiArray;
        [self.itemsEmojiDict setObject:emojiArray forKey:[item.emojiListFilePath sha1String]];
    }
    return emojis;
}


- (NSDictionary *)parseContent:(NSString *)string {
    if (GJCFStringIsNull(string)) {
        return nil;
    }

    //expression
    NSMutableArray *emojiArray = [NSMutableArray array];
    [self parseEmoji:[NSMutableString stringWithString:string] withEmojiTempString:nil withResultArray:emojiArray];

    //phone / url
    NSDictionary *dict = [self searchPhoneNumberAndUrlFromString:string];
    NSArray *phoneNumberArray = [dict objectForKey:@"phones"];

    NSArray *linkArray = [dict objectForKey:@"urls"];

    NSDictionary *parseContentDict = [self setupWithString:[dict valueForKey:@"formartString"] withPhoneNumbers:phoneNumberArray withLinkArray:linkArray andEmojis:emojiArray];

    [parseContentDict setValue:string forKey:@"originContentString"];
    [parseContentDict setValue:[dict valueForKey:@"originUrls"] forKey:@"originUrls"];

    GJCFNSCacheSet(string, parseContentDict);

    return parseContentDict;
}


- (NSString *)replaceNumberString:(NSInteger)numberStringLength {
    if (numberStringLength == 0) {
        return @"";
    }
    NSMutableString *resultString = [NSMutableString string];
    for (int i = 0; i < numberStringLength; i++) {
        [resultString appendString:@"x"];
    }
    return resultString;
}

/* 提取出字符串中的电话号码和url */
- (BOOL)isWalletUrlString:(NSString *)sourceString {
    if (GJCFStringIsNull(sourceString)) {
        return NO;
    }
    NSString *pattern = @"(http|https):\/\/(luckypacket|transfer|short|sandbox).connect.im.*$";
    NSRegularExpression *regexExpression = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray *regexArray = [regexExpression matchesInString:sourceString options:NSMatchingReportCompletion range:NSMakeRange(0, sourceString.length)];
    BOOL haveRightHost = regexArray.count > 0;
    
    if (!haveRightHost) {
        return NO;
    }
    NSURL *url = [NSURL URLWithString:sourceString];
    BOOL isTransferOrPacket = [[url parameters] valueForKey:@"token"] &&
            [url valueForParameter:@"token"].length == 128;

    BOOL isPayment = [[url parameters] valueForKey:@"address"] && [[url parameters] valueForKey:@"amount"] && [[[url parameters] valueForKey:@"amount"] integerValue] >= 0;

    if (haveRightHost && (isTransferOrPacket || isPayment)) {
        return YES;
    }
    return NO;
}

/* 提取出字符串中的电话号码和url */
- (NSDictionary *)searchPhoneNumberAndUrlFromString:(NSString *)sourceString {
    if (GJCFStringIsNull(sourceString)) {
        return nil;
    }
    NSString *formartString = [NSString stringWithString:sourceString];

    NSString *transfer_PackgeRegex = @"(http|https)://(cd.snowball.io:5502|short.connect.im)/share/v\\d/(transfer|packet)\?token=\\w{128}$";


    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSMutableArray *urlStringArray = [NSMutableArray array];
    NSMutableArray *orginUrlStringArray = [NSMutableArray array];
    NSMutableArray *phoneStringArray = [NSMutableArray array];

    NSString *anyUrlRegex = transfer_PackgeRegex;
    NSError *AnyError = NULL;

    anyUrlRegex = [StringTool regHttp];
    AnyError = NULL;

    NSRegularExpression *regexAnyLink = [NSRegularExpression regularExpressionWithPattern:anyUrlRegex options:NSRegularExpressionCaseInsensitive error:&AnyError];
    NSArray *regexAnyLinkArray = [regexAnyLink matchesInString:formartString options:NSMatchingReportCompletion range:NSMakeRange(0, formartString.length)];

    for (NSTextCheckingResult *result in regexAnyLinkArray) {
        NSString *resultString = [formartString substringWithRange:result.range];
        [urlStringArray objectAddObject:resultString];
        [orginUrlStringArray objectAddObject:resultString];
    }
    [dict setValue:phoneStringArray forKey:@"phones"];
    [dict setValue:urlStringArray forKey:@"urls"];
    [dict setValue:formartString forKey:@"formartString"];
    [dict setValue:orginUrlStringArray forKey:@"originUrls"];

    return dict;
}

- (NSDictionary *)setupWithString:(NSString *)string withPhoneNumbers:(NSArray *)phoneNumberArray withLinkArray:(NSArray *)linkArray andEmojis:(NSArray *)emojiArray {

    float fontSise = FONT_SIZE(28);
    NSMutableString *mString = [NSMutableString stringWithString:string];

    for (NSDictionary *emojiItem in emojiArray) {
        NSString *emoji = [emojiItem objectForKey:@"emoji"];
        [mString replaceOccurrencesOfString:emoji withString:@"\uFFFC" options:NSCaseInsensitiveSearch range:NSMakeRange(0, mString.length)];
    }

    GJCFCoreTextAttributedStringStyle *stringStyle = [[GJCFCoreTextAttributedStringStyle alloc] init];
    stringStyle.foregroundColor = [GJGCCommonFontColorStyle detailBigTitleColor];
    stringStyle.font = [UIFont systemFontOfSize:fontSise];

    GJCFCoreTextParagraphStyle *paragrpahStyle = [[GJCFCoreTextParagraphStyle alloc] init];
    paragrpahStyle.lineBreakMode = kCTLineBreakByCharWrapping;
    paragrpahStyle.maxLineSpace = 5.f;
    paragrpahStyle.minLineSpace = 5.f;

    NSMutableAttributedString *contentAttributedString = [[NSMutableAttributedString alloc] initWithString:mString attributes:[stringStyle attributedDictionary]];
    [contentAttributedString addAttributes:[paragrpahStyle paragraphAttributedDictionary] range:NSMakeRange(0, contentAttributedString.string.length)];

    NSMutableArray *imageInfos = [NSMutableArray array];
    for (NSDictionary *emojiItem in emojiArray) {

        NSString *emoji = [emojiItem objectForKey:@"emoji"];
        NSRange tempRange = [[emojiItem objectForKey:@"temp"] rangeValue];


        GJCFCoreTextImageAttributedStringStyle *imageStyle = [[GJCFCoreTextImageAttributedStringStyle alloc] init];
        imageStyle.imageTag = @"imageTag";
        NSString *emojiIcon = [self.emojiNameDict objectForKey:emoji];
        imageStyle.imageName = [NSString stringWithFormat:@"%@.png", emojiIcon];
        imageStyle.imageSourceString = emoji;
        imageStyle.endGap = 2.f;


        NSDictionary *imageInfo = @{kGJCFCoreTextImageInfoRangeKey: [NSValue valueWithRange:tempRange], kGJCFCoreTextImageInfoStringKey: emoji};
        [imageInfos objectAddObject:imageInfo];


        NSAttributedString *imageString = [imageStyle imageAttributedString];
        [contentAttributedString replaceCharactersInRange:tempRange withAttributedString:imageString];
    }


    for (NSString *phoneNumber in phoneNumberArray) {

        GJCFCoreTextKeywordAttributedStringStyle *keywordAttributedStyle = [[GJCFCoreTextKeywordAttributedStringStyle alloc] init];
        keywordAttributedStyle.keyword = phoneNumber;
        keywordAttributedStyle.preGap = 3.0;
        keywordAttributedStyle.endGap = 8.0;
        keywordAttributedStyle.font = [UIFont systemFontOfSize:fontSise];
        keywordAttributedStyle.keywordColor = LMBasicBlue;
        [contentAttributedString setKeywordEffectByStyle:keywordAttributedStyle];

    }


    for (NSString *link in linkArray) {

        GJCFCoreTextKeywordAttributedStringStyle *keywordAttributedStyle = [[GJCFCoreTextKeywordAttributedStringStyle alloc] init];
        keywordAttributedStyle.keyword = link;
        keywordAttributedStyle.preGap = 3.0;
        keywordAttributedStyle.endGap = 3.0;
        keywordAttributedStyle.font = [UIFont systemFontOfSize:fontSise];
        keywordAttributedStyle.keywordColor = LMBasicBlue;
        [contentAttributedString setKeywordEffectByStyle:keywordAttributedStyle];

    }

    BOOL needRenderCache = NO;
    if (imageInfos.count > 7) {
        needRenderCache = YES;
    }
    NSMutableDictionary *resultDict = @{@"contentString": contentAttributedString, @"imageInfo": imageInfos, @"phone": phoneNumberArray, @"url": linkArray, @"needRenderCache": @(needRenderCache)}.mutableCopy;

    return resultDict;
}

- (void)parseEmoji:(NSMutableString *)originString withEmojiTempString:(NSMutableString *)tempString withResultArray:(NSMutableArray *)resultArray {
    if (!tempString) {
        tempString = [originString mutableCopy];
    }
    NSString *regex = @"\\[[^\\[\\]]*\\]";

    NSRegularExpression *emojiRegexExp = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:nil];
    NSTextCheckingResult *originResult = [emojiRegexExp firstMatchInString:originString options:NSMatchingReportCompletion range:NSMakeRange(0, originString.length)];
    NSTextCheckingResult *tempResult = [emojiRegexExp firstMatchInString:tempString options:NSMatchingReportCompletion range:NSMakeRange(0, tempString.length)];
    if (!resultArray) {
        resultArray = [NSMutableArray array];
    }

    while (originResult) {
        NSString *emoji = [originString substringWithRange:originResult.range];

        if ([emoji hasPrefix:@"xx"]) {
            break;
        }
        NSRange emojiRange = originResult.range;

        NSRange replaceRange = NSMakeRange(tempResult.range.location, 1);

        [tempString replaceCharactersInRange:tempResult.range withString:@" "];

        NSMutableString *strM = [NSMutableString string];
        for (int i = 0; i < originResult.range.length; i++) {
            [strM appendString:@"x"];
        }
        [originString replaceCharactersInRange:originResult.range withString:strM];

        if ([self.emojiNameDict objectForKey:emoji]) {
            NSDictionary *item = @{@"emoji": emoji, @"origin": [NSValue valueWithRange:emojiRange], @"temp": [NSValue valueWithRange:replaceRange]};
            [resultArray objectAddObject:item];
        }
        [self parseEmoji:originString withEmojiTempString:tempString withResultArray:resultArray];
    }
}

@end

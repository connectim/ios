//
//  GJGCChatFriendTextMessageCell.m
//  Connect
//
//  Created by KivenLin on 14-11-5.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatFriendTextMessageCell.h"
#import "GJGCChatFriendCellStyle.h"
#import "GJGCChatContentEmojiParser.h"
#import "YYImageCache.h"

#define MinCellHeight (AUTO_HEIGHT(46))
#define MaxCellWidth (AUTO_HEIGHT(430))

@interface GJGCChatFriendTextMessageCell ()

@property(nonatomic, copy) NSString *contentCopyString;

@property(nonatomic, strong) UIImageView *textRenderCacheImageView;

@end

@implementation GJGCChatFriendTextMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.contentInnerMargin = AUTO_WIDTH(17);
        self.contentLabel = [[GJCFCoreTextContentView alloc] init];
        [self.contentLabel appendImageTag:[GJGCChatFriendCellStyle imageTag]];
        self.contentLabel.gjcf_left = self.contentInnerMargin;
        self.contentLabel.gjcf_width = MaxCellWidth;
        self.contentLabel.gjcf_height = MinCellHeight;
        self.contentLabel.gjcf_top = self.contentInnerMargin;
        self.contentLabel.backgroundColor = [UIColor clearColor];
        self.contentLabel.contentBaseWidth = self.contentLabel.gjcf_width;
        self.contentLabel.contentBaseHeight = self.contentLabel.gjcf_height;
        self.contentLabel.userInteractionEnabled = YES;
        [self.bubbleBackImageView addSubview:self.contentLabel];

        self.textRenderCacheImageView = [[UIImageView alloc] initWithFrame:self.contentLabel.frame];
        [self.bubbleBackImageView addSubview:self.textRenderCacheImageView];
        self.textRenderCacheImageView.hidden = YES;
    }
    return self;
}

- (void)setupTouchEnventWithPhoneNumberArray:(NSArray *)phoneNumberArray {
    if (!phoneNumberArray) {
        return;
    }
    if (phoneNumberArray.count > 0) {
        for (NSString *phoneNumber in phoneNumberArray) {
            __weak typeof(self) weakSelf = self;
            [self.contentLabel appenTouchObserverForKeyword:phoneNumber withHanlder:^(NSString *keyword, NSRange keywordRange) {
                [weakSelf tapOnPhoneNumber:keyword withRange:keywordRange];
            }];

        }

    }
}

- (void)tapOnPhoneNumber:(NSString *)phoneNumber withRange:(NSRange)phoneNumberRange {
    if (self.delegate && [self.delegate respondsToSelector:@selector(textMessageCellDidTapOnPhoneNumber:withPhoneNumber:)]) {
        [self.delegate textMessageCellDidTapOnPhoneNumber:self withPhoneNumber:phoneNumber];
    }
}

- (void)setupTouchEventWithUrlLinkArray:(NSArray *)linkArray originUrlArray:(NSArray *)originUrlArray {
    if (linkArray.count != originUrlArray.count) {
        return;
    }
    if (linkArray.count > 0) {

        for (NSString *link in linkArray) {
            NSString *originLink = [originUrlArray objectAtIndexCheck:[linkArray indexOfObject:link]];
            __weak typeof(self) weakSelf = self;
            [self.contentLabel appenTouchObserverForKeyword:link withHanlder:^(NSString *keyword, NSRange keywordRange) {
                [weakSelf tapOnUrl:originLink withRange:keywordRange];
            }];
        }
    }
}

- (void)tapOnUrl:(NSString *)url withRange:(NSRange)linkRange {
    if (self.delegate && [self.delegate respondsToSelector:@selector(textMessageCellDidTapOnUrl:withUrl:)]) {
        [self.delegate textMessageCellDidTapOnUrl:self withUrl:url];
    }
}

- (void)goToShowLongPressMenu:(UILongPressGestureRecognizer *)sender {
    [super goToShowLongPressMenu:sender];

    UIMenuController *popMenu = [UIMenuController sharedMenuController];
    if (popMenu.isMenuVisible) {
        return;
    }
    NSMutableArray *menuItems = @[].mutableCopy;
    if (self.contentModel.snapTime == 0) {
        UIMenuItem *item1 = [[UIMenuItem alloc] initWithTitle:LMLocalizedString(@"Set Copy", nil) action:@selector(copyContent:)];
        [menuItems objectAddObject:item1];
        UIMenuItem *item3 = [[UIMenuItem alloc] initWithTitle:LMLocalizedString(@"Chat Retweet", nil) action:@selector(retweetMessage:)];
        [menuItems objectAddObject:item3];
    }
    UIMenuItem *item2 = [[UIMenuItem alloc] initWithTitle:LMLocalizedString(@"Link Delete", nil) action:@selector(deleteMessage:)];
    [menuItems objectAddObject:item2];
    [popMenu setMenuItems:menuItems.copy];
    [popMenu setArrowDirection:UIMenuControllerArrowDown];

    [popMenu setTargetRect:self.bubbleBackImageView.frame inView:self];
    [popMenu setMenuVisible:YES animated:YES];
}

- (void)copyContent:(UIMenuItem *)item {
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setString:self.contentCopyString];
}

- (void)setContentModel:(GJGCChatContentBaseModel *)contentModel {
    if (!contentModel) {
        return;
    }

    [super setContentModel:contentModel];

    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) contentModel;
    self.isFromSelf = chatContentModel.isFromSelf;
    self.contentCopyString = chatContentModel.originTextMessage;

    NSDictionary *parseDict = GJCFNSCacheGetValue(chatContentModel.originTextMessage);
    if (!parseDict) {
        parseDict = [[GJGCChatContentEmojiParser sharedParser] parseContent:chatContentModel.originTextMessage];
    }
    GJCFCoreTextParagraphStyle *trailStyle = [[GJCFCoreTextParagraphStyle alloc] init];
    trailStyle.lineBreakMode = NSLineBreakByWordWrapping;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[parseDict objectForKey:@"contentString"]];
    [attributedString addAttributes:[trailStyle lineBreakModeSetting] range:NSMakeRange(0, attributedString.length)];

    BOOL needRenderCache = [[parseDict objectForKey:@"needRenderCache"] boolValue];
    NSString *renderCacheKey = [NSString stringWithFormat:@"%@_v2_renderCache", chatContentModel.originTextMessage];
    UIImage *renderCacheImage = [[YYImageCache sharedCache] getImageForKey:renderCacheKey];

    if (renderCacheImage) {
        self.contentLabel.hidden = YES;
        self.textRenderCacheImageView.hidden = NO;
        self.textRenderCacheImageView.image = renderCacheImage;
        self.textRenderCacheImageView.gjcf_size = renderCacheImage.size;
    } else {
        self.contentLabel.contentAttributedString = nil;
        if (contentModel.contentSize.height > 0) {
            self.contentSize = contentModel.contentSize;
            self.contentLabel.gjcf_size = contentModel.contentSize;
        } else {
            CGSize theContentSize = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:attributedString forBaseContentSize:self.contentLabel.contentBaseSize];
            self.contentSize = theContentSize;
            self.contentLabel.gjcf_size = theContentSize;
        }
        self.contentLabel.contentAttributedString = attributedString;
        NSArray *phoneArray = [parseDict objectForKey:@"phone"];
        NSArray *urlArray = [parseDict objectForKey:@"url"];

        if (phoneArray.count > 0) {
            [self setupTouchEnventWithPhoneNumberArray:phoneArray];
        }
        if (urlArray.count > 0) {
            [self setupTouchEventWithUrlLinkArray:urlArray originUrlArray:[parseDict valueForKey:@"originUrls"]];
        }
        if (phoneArray.count == 0 && urlArray.count == 0) {
            [self.contentLabel clearKeywordTouchEventHanlder];
        }
        self.contentLabel.hidden = self.contentLabel.contentAttributedString == nil ? YES : NO;
        self.textRenderCacheImageView.image = nil;
        self.textRenderCacheImageView.hidden = YES;
        if (needRenderCache && !renderCacheImage) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                [self.contentLabel setNeedsDisplay];
                UIImage *render = GJCFScreenShotFromView(self.contentLabel);
                [[YYImageCache sharedCache] setImage:render imageData:nil forKey:renderCacheKey withType:YYImageCacheTypeMemory];
            });
        }
    }
    if (renderCacheImage) {

        CGFloat renderHeight = self.textRenderCacheImageView.gjcf_height + 2 * self.contentInnerMargin;
        renderHeight = MAX(renderHeight, AUTO_HEIGHT(80));
        self.bubbleBackImageView.gjcf_height = renderHeight;

        self.bubbleBackImageView.gjcf_width = self.textRenderCacheImageView.gjcf_width + 2 * self.contentInnerMargin + BubbleLeftRight;
        self.textRenderCacheImageView.centerY = self.bubbleBackImageView.centerY;
        if (chatContentModel.isFromSelf) {
            self.textRenderCacheImageView.gjcf_right = self.bubbleBackImageView.gjcf_width - BubbleLeftRight - self.contentInnerMargin;
        } else {
            self.textRenderCacheImageView.gjcf_left = self.contentInnerMargin + BubbleLeftRight;
        }

        [self adjustContent];
        self.textRenderCacheImageView.gjcf_centerY = self.bubbleBackImageView.gjcf_height / 2;

    } else {

        CGFloat textHeight = self.contentLabel.gjcf_height + 2 * self.contentInnerMargin;
        textHeight = MAX(textHeight, AUTO_HEIGHT(80));
        self.bubbleBackImageView.gjcf_height = textHeight;
        self.bubbleBackImageView.gjcf_width = self.contentLabel.gjcf_width + 2 * self.contentInnerMargin + BubbleLeftRight;
        self.textRenderCacheImageView.centerY = self.bubbleBackImageView.centerY;
        if (chatContentModel.isFromSelf) {
            self.contentLabel.gjcf_right = self.bubbleBackImageView.gjcf_width - BubbleLeftRight - self.contentInnerMargin;
        } else {
            self.contentLabel.gjcf_left = self.contentInnerMargin + BubbleLeftRight;
        }

        [self adjustContent];
        self.contentLabel.gjcf_centerY = self.bubbleBackImageView.gjcf_height / 2;
    }
}

+ (CGFloat)cellHeightForContentModel:(GJGCChatContentBaseModel *)contentModel {

    GJGCChatFriendContentModel *chatContentModel = (GJGCChatFriendContentModel *) contentModel;

    NSDictionary *parseDict = GJCFNSCacheGetValue(chatContentModel.originTextMessage);
    if (!parseDict) {
        parseDict = [[GJGCChatContentEmojiParser sharedParser] parseContent:chatContentModel.originTextMessage];
    }

    GJCFCoreTextParagraphStyle *trailStyle = [[GJCFCoreTextParagraphStyle alloc] init];
    trailStyle.lineBreakMode = NSLineBreakByWordWrapping;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:[parseDict objectForKey:@"contentString"]];
    [attributedString addAttributes:[trailStyle lineBreakModeSetting] range:NSMakeRange(0, attributedString.length)];

    CGSize contentSize = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:attributedString forBaseContentSize:CGSizeMake(MaxCellWidth, AUTO_HEIGHT(40))];
    if (contentSize.height < MinCellHeight) {
        contentSize.height = MinCellHeight;
    }
    CGSize nameSize = CGSizeZero;
    if (chatContentModel.isGroupChat && !chatContentModel.isFromSelf) {
        NSAttributedString *name = [[NSAttributedString alloc] initWithString:chatContentModel.senderName];
        nameSize = [GJCFCoreTextContentView contentSuggestSizeWithAttributedString:name forBaseContentSize:CGSizeMake(DEVICE_SIZE.width - AUTO_WIDTH(150), 25)];
        nameSize.height += 3;
    }
    return contentSize.height + AUTO_WIDTH(28) * 2 + BOTTOM_CELL_MARGIN + nameSize.height;
}

@end

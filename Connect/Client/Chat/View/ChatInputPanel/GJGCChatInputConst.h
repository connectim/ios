//
//  GJGCChatInputConst.h
//  Connect
//
//  Created by KivenLin on 14-10-28.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, GJGCChatInputBarActionType) {
    GJGCChatInputBarActionTypeNone = 0,
    GJGCChatInputBarActionTypeRecordAudio,
    GJGCChatInputBarActionTypeInputText,
    GJGCChatInputBarActionTypeChooseEmoji,
    GJGCChatInputBarActionTypeExpandPanel,
};

typedef NS_ENUM(NSUInteger, GJGCChatInputMenuPanelActionType) {
    /**
     *  camera
     */
            GJGCChatInputMenuPanelActionTypeCamera = 0,
    /**
     *  photo libray
     */
            GJGCChatInputMenuPanelActionTypePhotoLibrary,
    /**
     *  audio
     */
            GJGCChatInputMenuPanelActionTypeMicophone,
    /**
     *  snapchat
     */
            GJGCChatInputMenuPanelActionTypeSecurty,
    /**
     *  transfer
     */
            GJGCChatInputMenuPanelActionTypeTransfer,
    /**
     *  receipt
     */
            GJGCChatInputMenuPanelActionTypePayMent,
    /**
     *  luckypackage
     */
            GJGCChatInputMenuPanelActionTypeRedBag,
    /**
     *  namecard
     */
            GJGCChatInputMenuPanelActionTypeContact,

    /**
     * location
     */
            GJGCChatInputMenuPanelActionTypeMapLocation

};

typedef NS_ENUM(NSUInteger, GJGCChatInputTextViewRecordActionType) {
    GJGCChatInputTextViewRecordActionTypeStart,
    GJGCChatInputTextViewRecordActionTypeCancel,
    GJGCChatInputTextViewRecordActionTypeFinish,
    GJGCChatInputTextViewRecordActionTypeTooShort
};

typedef NS_ENUM(NSUInteger, GJGCChatInputExpandEmojiType) {
    GJGCChatInputExpandEmojiTypeSimple = 0,
    GJGCChatInputExpandEmojiTypeGIF = 1,
};

extern NSString *const GJGCChatInputTextViewRecordSoundMeterNoti;

extern NSString *const GJGCChatInputTextViewRecordCancelNoti;

extern NSString *const GJGCChatInputTextViewRecordTooShortNoti;

extern NSString *const GJGCChatInputTextViewRecordTooLongNoti;

extern NSString *const GJGCChatInputExpandEmojiPanelChooseEmojiNoti;

extern NSString *const GJGCChatInputExpandEmojiPanelChooseGIFEmojiNoti;

extern NSString *const GJGCChatInputExpandEmojiPanelChooseDeleteNoti;

extern NSString *const GJGCChatInputExpandEmojiPanelChooseSendNoti;

extern NSString *const GJGCChatInputSetLastMessageDraftNoti;

extern NSString *const GJGCChatInputPanelBeginRecordNoti;

extern NSString *const GJGCChatInputPanelNeedAppendTextNoti;

#define GJGCChatInputTextViewDeleteNoteGroupMemberNoti @"GJGCChatInputTextViewDeleteNoteGroupMemberNoti"
#define GJGCChatInputTextViewContentChangeNoti @"GJGCChatInputTextViewContentChangeNoti"
#define GJGCChatInputTextViewContentShouldChangeNoti @"GJGCChatInputTextViewContentShouldChangeNoti"


@interface GJGCChatInputConst : NSObject

+ (NSString *)panelNoti:(NSString *)notiName formateWithIdentifier:(NSString *)identifier;

@end

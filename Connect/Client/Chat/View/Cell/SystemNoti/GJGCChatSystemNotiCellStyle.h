//
//  GJGCChatSystemNotiCellStyle.h
//  Connect
//
//  Created by KivenLin on 14-11-6.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJGCChatFriendConstans.h"

@interface GJGCChatSystemNotiCellStyle : NSObject

/**
 * message time formart
 * @param lastDateTime
 * @param lastTimeStamp
 * @return
 */
+ (NSString *)timeAgoStringByLastMsgTime:(long long)lastDateTime lastMsgTime:(long long)lastTimeStamp;

/**
 * fomart time string
 * @param timeString
 * @return
 */
+ (NSAttributedString *)formateTime:(NSString *)timeString;

/**
 * fomart system time
 * @param time
 * @return
 */
+ (NSAttributedString *)formateSystemNotiTime:(long long)time;

/**
 * formart name
 * @param name
 * @return
 */
+ (NSAttributedString *)formateNameString:(NSString *)name;

/**
 * fromart duration time
 * @param time
 * @return
 */
+ (NSString *)formartDurationTime:(int)time;

/**
 * fromart detail string
 * @param description
 * @return
 */
+ (NSAttributedString *)formateActiveDescription:(NSString *)description;

/**
 * fromart snap tip
 * @param snapChatTime
 * @param isSendToMe
 * @param userName
 * @return
 */
+ (NSAttributedString *)formateOpensnapChatWithTime:(int)snapChatTime isSendToMe:(BOOL)isSendToMe chatUserName:(NSString *)userName;

/**
 * fromart transfer
 * @param amount
 * @param isSendToMe
 * @param isOuterTransfer
 * @return
 */
+ (NSAttributedString *)formateTransferWithAmount:(long long int)amount isSendToMe:(BOOL)isSendToMe isOuterTransfer:(BOOL)isOuterTransfer;

/**
 * fromart receipt message
 * @param amount
 * @param isSendToMe
 * @param isCrowdfundRceipt
 * @param note
 * @return
 */
+ (NSAttributedString *)formateRecieptWithAmount:(long long int)amount isSendToMe:(BOOL)isSendToMe isCrowdfundRceipt:(BOOL)isCrowdfundRceipt withNote:(NSString *)note;

/**
 * fromart receipt tips
 * @param total
 * @param payCount
 * @param isCrowd
 * @param status
 * @return
 */
+ (NSAttributedString *)formateRecieptSubTipsWithTotal:(int)total payCount:(int)payCount isCrowding:(BOOL)isCrowd transStatus:(int)status;

/**
 * fromart luckypackage message
 * @param message
 * @param isOuterTransfer
 * @return
 */
+ (NSAttributedString *)formateRedBagWithMessage:(NSString *)message isOuterTransfer:(BOOL)isOuterTransfer;

/**
 * fromart cell left tips
 * @param contentType
 * @param note
 * @param isCrowd
 * @return
 */
+ (NSAttributedString *)formateCellLeftSubTipsWithType:(GJGCChatFriendContentType)contentType withNote:(NSString *)note isCrowding:(BOOL)isCrowd;

/**
 * fromart receipy pay tips
 * @param payName
 * @param receiptName
 * @param isCrowd
 * @return
 */
+ (NSAttributedString *)formateReceiptTipWithPayName:(NSString *)payName receiptName:(NSString *)receiptName isCrowding:(BOOL)isCrowd;

/**
 * fromart luckypackage tips
 * @param sendName
 * @param garbName
 * @return
 */
+ (NSAttributedString *)formateRedbagTipWithSenderName:(NSString *)sendName garbName:(NSString *)garbName;

/**
 * formart locaticon
 * @param location
 * @return
 */
+ (NSAttributedString *)formatLocationMessage:(NSString *)location;

/**
 * formart crowding compelete tips
 * @return
 */
+ (NSAttributedString *)formateCrowdingCompleteTipMessage;

/**
 * get outer address transfer
 * @param amount
 * @return
 */
+ (NSAttributedString *)formateAddressNotify:(long long)amount;

/**
 * formart group invite tips
 * @param groupName
 * @param reciverName
 * @param isSystemMessage
 * @param isSendFromMySelf
 * @return
 */
+ (NSAttributedString *)formatetGroupInviteGroupName:(NSString *)groupName reciverName:(NSString *)reciverName isSystemMessage:(BOOL)isSystemMessage isSendFromMySelf:(BOOL)isSendFromMySelf;

/**
 * formart group invite status tips
 * @param handle
 * @param refused
 * @param isNoted
 * @return
 */
+ (NSAttributedString *)formateCellStatusWithHandle:(BOOL)handle refused:(BOOL)refused isNoted:(BOOL)isNoted;

/**
 * formart tip string
 * @param tipMessage
 * @return
 */
+ (NSAttributedString *)formateTipStringWithTipMessage:(NSString *)tipMessage;

/**
 * formart name card tips
 * @param isFromSelf
 * @return
 */
+ (NSAttributedString *)formateNameCardSubTipsIsFromSelf:(BOOL)isFromSelf;

/**
 * ecdhkey update success tips
 * @param success
 * @return
 */
+ (NSAttributedString *)formateEcdhkeyUpdateWithSuccess:(BOOL)success;

@end

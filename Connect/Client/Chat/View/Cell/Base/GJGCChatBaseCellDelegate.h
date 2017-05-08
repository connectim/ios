//
//  GJGCChatSystemNotiCellDelegate.h
//  ZYChat
//
//  Created by KivenLin on 14-11-11.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GJGCChatBaseCell;

@protocol GJGCChatBaseCellDelegate <NSObject>

@optional

#pragma mark - Connect delete
/**
 *  announcement taped
 *
 *  @param tapedCell
 */
- (void)systemNotiBaseCellDidTapOnPublicMessage:(GJGCChatBaseCell *)tapedCell;

/**
 *  reviewed group
 */
- (void)chatCellDidTapOnGroupReviewed:(GJGCChatBaseCell *)tappedCell;

#pragma mark - Contact delegate


/**
 *  Video tap
 */
- (void)videoMessageCellDidTap:(GJGCChatBaseCell *)tapedCell;

/**
 *  cancel download Video
 */
- (void)videoMessageCancelDownload:(GJGCChatBaseCell *)tapedCell;


/**
 *  detail tap
 *
 *  @param tapedCell
 */
- (void)chatCellDidTapDetail:(GJGCChatBaseCell *)tapedCell;

/**
 *  audio tap
 *
 *  @param tapedCell 
 */
- (void)audioMessageCellDidTap:(GJGCChatBaseCell *)tapedCell;

/**
 *  receipt tap
 *
 *  @param tapedCell
 */
- (void)payOrReceiptCellDidTap:(GJGCChatBaseCell *)tapedCell;

/**
 *  crowding tap
 *
 *  @param tapedCell
 */
- (void)crowdfundReceiptCellDidTap:(GJGCChatBaseCell *)tapedCell;


/**
 *  transfer tap
 *
 *  @param tapedCell
 */
- (void)transforCellDidTap:(GJGCChatBaseCell *)tapedCell;


/**
 *  luckypackage tap
 *
 *  @param tapedCell
 */
- (void)redBagCellDidTap:(GJGCChatBaseCell *)tapedCell;


/**
 *  iamge message tap
 *
 *  @param tapedCell 
 */
- (void)imageMessageCellDidTap:(GJGCChatBaseCell *)tapedCell;

/**
 *  location message tap
 *
 *  @param tapedCell
 */
- (void)mapLocationMessageCellDidTap:(GJGCChatBaseCell *)tapedCell;


/**
 *  tap phone num
 *
 *  @param tapedCell
 *  @param phoneNumber
 */
- (void)textMessageCellDidTapOnPhoneNumber:(GJGCChatBaseCell *)tapedCell withPhoneNumber:(NSString *)phoneNumber;

/**
 *  tap add friend
 *
 *  @param tapedCell
 */
- (void)noRelationShipTapAddFriend:(GJGCChatBaseCell *)tapedCell;

/**
 *  tap url
 *
 *  @param tapedCell
 *  @param url       
 */
- (void)textMessageCellDidTapOnUrl:(GJGCChatBaseCell *)tapedCell withUrl:(NSString *)url;

/**
 *  tap delete message
 *
 *  @param tapedCell 
 */
- (void)chatCellDidChooseDeleteMessage:(GJGCChatBaseCell *)tapedCell;


/**
 *  tap retweet
 *
 *  @param tapedCell
 */
- (void)chatCellDidChooseRetweetMessage:(GJGCChatBaseCell *)tapedCell;

/**
 *  resent message
 *
 *  @param tapedCell 
 */
- (void)chatCellDidChooseReSendMessage:(GJGCChatBaseCell *)tapedCell;


/**
 *  tap wallet url
 *
 *  @param tapedCell
 */
- (void)chatCellDidTapWalletLinkMessage:(GJGCChatBaseCell *)tapedCell;

/**
 *  tap user head
 *
 *  @param tapedCell 
 */
- (void)chatCellDidTapOnHeadView:(GJGCChatBaseCell *)tapedCell;

/**
 *  long press user head
 *
 *  @param tapedCell 
 */
- (void)chatCellDidLongPressOnHeadView:(GJGCChatBaseCell *)tapedCell;

/**
 *  tap namecard
 */
- (void)chatCellDidTapOnNameCard:(GJGCChatBaseCell *)tappedCell;

/**
 *  tap group card
 */
- (void)chatCellDidTapOnGroupInfoCard:(GJGCChatBaseCell *)tappedCell;

@end

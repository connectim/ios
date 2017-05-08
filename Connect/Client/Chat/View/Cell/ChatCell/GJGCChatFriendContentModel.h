//
//  GJGCChatFriendContentModel.h
//  Connect
//
//  Created by KivenLin on 14-11-5.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import "GJGCChatContentBaseModel.h"
#import "GJGCChatFriendConstans.h"
#import "GJCFAudioModel.h"


@interface GJGCChatFriendContentModel : GJGCChatContentBaseModel

@property(nonatomic, assign) GJGCChatFriendContentType contentType;
@property(nonatomic, strong) NSString *senderName;
@property(nonatomic, copy) NSString *senderPublicKey;
@property(nonatomic, copy) NSString *senderAddress;
@property(nonatomic, copy) NSString *senderHeadUrl;
@property(nonatomic, strong) NSString *reciverName;
@property(nonatomic, copy) NSString *reciverPublicKey;
@property(nonatomic, copy) NSString *reciverAddress;
@property(nonatomic, copy) NSString *reciverHeadUrl;
@property(nonatomic, assign) BOOL isGroupChat;
@property(nonatomic, assign) BOOL isFromSelf;
@property(nonatomic, strong) NSString *headUrl;
@property(nonatomic, strong) NSString *downloadTaskIdentifier;
@property(nonatomic, copy) NSString *uploadTaskIdentifier;
@property(nonatomic, assign) NSInteger sex;
@property(nonatomic, copy) NSString *fromUserId;
@property(nonatomic, copy) NSString *toUserId;
@property(nonatomic, assign) BOOL isFriend;
@property(nonatomic, assign) double downloadProgress;
@property(nonatomic, assign) double uploadProgress;
@property(nonatomic, assign) BOOL uploadSuccess;
@property(nonatomic, strong) id contentModel;
@property(nonatomic, strong) NSMutableArray *noteGroupMemberAddresses;


@property(nonatomic, assign) int drawingCount; //video cover drawing count

@property(nonatomic, copy) NSString *typeString;
@property(nonatomic, strong) UIImage *messageContentImage;

@property(nonatomic, copy) NSString *encodeFileUrl;
@property(nonatomic, copy) NSString *encodeThumbFileUrl;
@property(nonatomic, copy) NSString *encodeFileTemPath;

#pragma mark -  text

@property(nonatomic, strong) NSAttributedString *simpleTextMessage;
@property(nonatomic, strong) NSString *originTextMessage;
@property(nonatomic, strong) NSArray *emojiInfoArray;
@property(nonatomic, strong) NSArray *phoneNumberArray;
@property(nonatomic, strong) NSArray *supportImageTagArray;

#pragma mark - image

@property(nonatomic, strong) NSString *imageMessageUrl;
@property(nonatomic, copy) NSString *imageOriginDataCachePath;
@property(nonatomic, copy) NSString *downEncodeImageCachePath;
@property(nonatomic, strong) NSString *thumbImageCachePath;
@property(nonatomic, copy) NSString *downThumbEncodeImageCachePath;
@property(nonatomic, assign) NSInteger originImageWidth;
@property(nonatomic, assign) NSInteger originImageHeight;
@property(nonatomic, assign) BOOL isDownloadThumbImage;
@property(nonatomic, assign) BOOL isDownloadImage;


#pragma mark - audio

@property(nonatomic, strong) GJCFAudioModel *audioModel;
@property(nonatomic, strong) NSAttributedString *audioDuration;
@property(nonatomic, assign) BOOL isPlayingAudio;
@property(nonatomic, assign) BOOL isDownloading;
@property(nonatomic, assign) BOOL isRead;

#pragma mark - receipt

@property(nonatomic, copy) NSString *tipNote;
@property(nonatomic, copy) NSString *hashID;
@property(nonatomic, assign) long long int amount;
@property(nonatomic, assign) int memberCount;
@property(nonatomic, assign) BOOL isCrowdfundRceipt;
@property(nonatomic, strong) NSAttributedString *payOrReceiptMessage;
@property(nonatomic, strong) NSAttributedString *payOrReceiptSubTipMessage;
@property(nonatomic, strong) NSAttributedString *payOrReceiptStatusMessage;


#pragma mark - transfer
@property(nonatomic, assign) BOOL isOuterTransfer;
@property(nonatomic, strong) NSAttributedString *transferMessage;
@property(nonatomic, strong) NSAttributedString *transferSubTipMessage;
@property(nonatomic, strong) NSAttributedString *transferStatusMessage;

#pragma mark - luckypackage
@property(nonatomic, strong) NSAttributedString *redBagTipMessage;
@property(nonatomic, strong) NSAttributedString *redBagSubTipMessage;


#pragma mark - location
@property(nonatomic, strong) NSAttributedString *locationMessage;
@property(nonatomic, assign) CGFloat locationLatitude;
@property(nonatomic, assign) CGFloat locationLongitude;
@property(nonatomic, copy) NSString *locationImageOriginDataCachePath;
@property(nonatomic, copy) NSString *locationImageDownPath;

#pragma mark - namecard
@property(nonatomic, copy) NSString *contactAvatar;
@property(nonatomic, copy) NSAttributedString *contactName;
@property(nonatomic, copy) NSAttributedString *contactSubTipMessage;
@property(nonatomic, copy) NSString *contactAddress;
@property(nonatomic, copy) NSString *contactPublickey;

#pragma mark - group invite
@property(nonatomic, copy) NSString *groupIdentifier;
@property(nonatomic, copy) NSString *inviteToken;

#pragma mark - video
@property(nonatomic, copy) NSString *videoOriginDataPath;
@property(nonatomic, copy) NSString *videoOriginCoverImageCachePath;
@property(nonatomic, copy) NSString *videoDownCoverEncodePath;
@property(nonatomic, copy) NSString *videoDownVideoEncodePath;
@property(nonatomic, assign) NSInteger videoDuration;
@property(nonatomic, copy) NSString *videoSize;
@property(nonatomic, assign) BOOL uploadVideoComplete;
@property(nonatomic, assign) BOOL uploadVideoCoverComplete;
@property(nonatomic, assign) BOOL videoIsDownload;
@property(nonatomic, assign) BOOL audioIsDownload;
@property(nonatomic, copy) NSString *videoEncodeUrl;
@property(nonatomic, strong) NSAttributedString *acceptSummonTitle;

#pragma mark - gif
@property(nonatomic, strong) NSString *gifLocalId;

#pragma mark - wallet link
@property(nonatomic, assign) LMWalletlinkType walletLinkType;
@property(nonatomic, copy) NSString *linkTitle;
@property(nonatomic, copy) NSString *linkSubtitle;
@property(nonatomic, copy) NSString *linkImageUrl;

+ (GJGCChatFriendContentModel *)timeSubModel;


@end

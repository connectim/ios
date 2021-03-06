
//  NetDefines.h
//  Connect
//
//  Created by MoHuilin on 16/5/16.
//  Copyright © 2016年 Connect.  All rights reserved.
//

//=========== server config ==============
#define RequestTimeout 10
#define successCode 2000

#define APIVersion @"v1"
#define SOCKET_HOST @"sandbox.connect.im"
#define baseServer  @"https://sandbox.connect.im"
#define ServerPublickey @"02c2c7398274aef3b94366369f51c6a75470f3636981c2e75e6fd7b39caede1ca9"
#define SOCKET_PORT 19090
#define DefaultHeadUrl @"https://short.connect.im/avatar/v1/b040e0a970bc6d80b675586c5a55f9e9109168ba.png"

#define nationalAppDownloadUrl @"https://connect.im/guide"
#define appstoreAppDownloadUrl @"https://itunes.apple.com/app/connect-p2p-encrypted-instant/id1181365735"
#define appOpensourceUrl       @"https://www.connect.im/mobile/developer"
#define AppCrashUrl            @"https://collector.bughd.com/kscrash?key=21bc82c6e76df952ccb0c45ca358e87a"
//=========== server config ==============
//↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓ server api config ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓

#define FeedBackUrl [NSString stringWithFormat:@"https://www.connect.im/mobile/feedback/%@",[LKUserCenter shareCenter].currentLoginUser.address]

//============= socket protocol version =============
#define socketProtocolVersion 1
//============= socket protocol version =============

#define SOCKET_TIME_OUT 20
#define SOCKET_READ_TIME_OUT 60

// fedback address
#define FeedBackUrl [NSString stringWithFormat:@"https://www.connect.im/mobile/feedback/%@",[LKUserCenter shareCenter].currentLoginUser.address]

#define txDetailBaseUrl @"http://blockchain.info/tx/"

// h5 address
#define H5ShareServerUrl @"https://me.connect.im/share/" APIVersion "/contact/"
#define H5PayServerUrl @"https://transfer.connect.im/share/" APIVersion "/pay"
#define FAQUrl @"https://www.connect.im/mobile/faqs"

//message file upload url
#define UPLOAD_FILE_SERVER_URL baseServer "/fs/" APIVersion "/up"

// Server load
#define availableServersUrl baseServer "/connect/" APIVersion "/availableServers"

// Dynamic update startup launch image
#define lanuchImagesUrl baseServer "/launch_images/" APIVersion "/%@/images"


#define updateVersionUrl baseServer "/connect/" APIVersion "/version"

// get http request salt
#define getRandomSaltUrl baseServer "/connect/" APIVersion "/users/salt"

// check http request salt
#define checkSaltExpiredUrl baseServer "/connect/" APIVersion "/users/expire/salt"

/**
  * No kb fee
 */
#define estimetfeeUrl baseServer @"/connect/" APIVersion "/estimatefee"

#pragma mark - login & regist
/**
 Log in to the interface documentation
 
 UIRL: /connect/" APIVersion "/private/user_existed
 Method: POST
 Data Format: Protobuf
 Params:
 Protobuf 文件: MobileVerify
 */
#define PrivkeySignupUrl baseServer "/connect/" APIVersion "/private/sign_in"

/**
 Log in to the interface documentation
  
   UIRL: / connect / " APIVersion " / private / user_existed
   Method: POST
   Data Format: Protobuf
   Params:
   Protobuf file: MobileVerify
 */
#define PrivkeyLoginExistedUrl baseServer "/connect/" APIVersion "/private/user_existed"


/**
 Log in to the interface documentation
  
   UIRL: / connect / " APIVersion " / sign_in
   Method: POST
   Data Format: Protobuf
   Params:
   Protobuf file: MobileVerify
 */
#define LoginSignInUrl baseServer "/connect/" APIVersion "/sign_in"

/**
 Register interface
   UIRL: / connect / " APIVersion " / sign_up
   Method: POST
   Data Format: Protobuf
   Params:
   Protobuf file: IMRequest

 */
#define LoginSignUpUrl baseServer "/connect/" APIVersion "/sign_up"

#pragma mark - SMS verification code related

/**

 send SMS
 UIRL: /connect/" APIVersion "/sms/send
 Method: POST
 Data Format: Protobuf
 Params:
 Protobuf file: SendMobileCode
 */
#define PhoneGetPhoneCode baseServer "/connect/" APIVersion "/sms/send"

#define SignInUrl baseServer "/api/sign_in"

#define UploadAvatarUrl baseServer "/api/upload_avatar"

#define signUpUrl baseServer "/api/sign_up"

/**
 Interface description
   PATH: / api / v1 / tag
   METHOD: POST
   Data Format JSON
 */
#define AddTagUrl baseServer "/api/" APIVersion "/tag"


#pragma mark - chat group

/*
 *  invitate token: /connect/" APIVersion "/group/invite/token
 */
#define GroupInviteTokenUrl baseServer "/connect/" APIVersion "/group/invite/token"


#define GroupInviteApplyUrl baseServer "/connect/" APIVersion "/group/invite"

/**
 PATH:/connect/" APIVersion "/group/info/token
 METHOD: POST
 Data Format: Protobuf
 */
#define GroupInfoTokenUrl baseServer "/connect/" APIVersion "/group/info/token"
/**
 The group generates a hash of the two-dimensional code
   Interface description
   PATH: / connect / v1 / group / hash
   METHOD: POST
   Data Format: Protobuf
   Request parameter
   Protobuf file: IMRequest
 */
#define GroupCreatQRUrl baseServer "/connect/" APIVersion "/group/hash"
/**
 Refresh the group to generate a qr code hash
   Interface description
   PATH: / connect / v1 / group / hash
   METHOD: POST
   Data Format: Protobuf
   Request parameter
   Protobuf file: IMRequest
 */
#define RefreshGroupCreatQRUrl baseServer "/connect/" APIVersion "/group/refresh/hash"
/**
 Share the group's qr code
   Interface description
   PATH: / connect / v1 / group / hash
   METHOD: POST
   Data Format: Protobuf
   Request parameter
   Protobuf file: IMRequest
 */
#define GroupShareUrl baseServer "/connect/" APIVersion "/group/share"
/**
 Upload session key interface
   Interface description
  
   PATH: / connect / v1 / group / upload_key
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 */
#define GroupUploadGroupKeyUrl baseServer "/connect/" APIVersion "/group/upload_key"

/**
 Download the session key interface
   Interface description
  
   PATH: / connect / v1 / group / download_key
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 */
#define GroupDownloadGroupKeyUrl baseServer "/connect/" APIVersion "/group/download_key"




/**
 PATH: /connect/" APIVersion "/group
 METHOD: POST
 Data Format: Protobuf

 */
#define GroupCreateGroupUrl baseServer "/connect/" APIVersion "/group"

/**
 Interface description
  
   PATH: / connect / v1 / group / setting
   METHOD: POST
   Data Format: Protobuf

 
 */
#define GroupSettingUrl baseServer "/connect/" APIVersion "/group/setting"

/**
 Group basic information synchronization
  
   Interface description
  
   PATH: / connect / v1 / group / setting_info
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 */
#define GroupSyncSettingInfoUrl baseServer "/connect/" APIVersion "/group/setting_info"


/**
 Group public information
  
   Interface description
  
   PATH: / connect / v1 / group / public_info
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 */
#define GroupPublicInfoUrl baseServer "/connect/" APIVersion "/group/public_info"
/**
 Sweep plus group
   Interface description
  
   PATH: / connect / v1 / group / scan
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 */
#define ScanQRJoinGroupUrl baseServer "/connect/" APIVersion "/group/scan"

/**
 PATH: /connect/" APIVersion "/group/info
 METHOD: POST
 Data Format: Protobuf

 */
#define GroupGetGroupInfoUrl baseServer "/connect/" APIVersion "/group/info"


/**
 PATH: /connect/" APIVersion "/group/update
 METHOD: POST
 Data Format: Protobuf
 */

#define GroupUpdateGroupInfoUrl baseServer "/connect/" APIVersion "/group/update"

/**
 Delete group members
  
   Interface description
  
   PATH: / connect / v1 / group / deluser
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest

 */
#define GroupGroupDeleteUserUrl baseServer "/connect/" APIVersion "/group/deluser"

/**
 groupAamin exchange
 
 Interface description
  
   PATH: / connect / v1 / group / attorn
   METHOD: POST
   Data Format: Protobuf
 */
#define GroupAttornUrl baseServer "/connect/" APIVersion "/group/attorn"

/**
 Group join application
  
   Interface description
  
   PATH: / connect / v1 / group / apply
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 */
#define GroupApplyToGroupUrl baseServer "/connect/" APIVersion "/group/apply"

/**
 Group review
  
   Interface description
  
   PATH: / connect / v1 / group / reviewed
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 */
#define GroupReviewewUrl baseServer "/connect/" APIVersion "/group/reviewed"

/**
 Group owners review rejected
  
   Interface description
  
   PATH: / connect / v1 / group / reject
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest

 */
#define GroupRejectUrl baseServer "/connect/" APIVersion "/group/reject"

#define GroupUploadGroupAvatarUrl baseServer "/connect/" APIVersion "/group/avatar"

/**
 Group join application
  
   Interface description
  
   PATH: / connect / " APIVersion " / group / invite
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 */
#define GroupInvateToGroupUrl baseServer "/connect/" APIVersion "/group/invite"



/**
 Leave the group
  
   Interface description
  
   PATH: / connect / v1 / group / quit
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest

 */
#define GroupQuitGroupUrl baseServer "/connect/" APIVersion "/group/quit"

/**
 Interface Description Set nickname disables
  
   PATH: / connect / v1 / group / member_update
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest

 */

#define GroupMemberUpdateUrl baseServer "/connect/" APIVersion "/group/member_update"


/**
 Interface Description Sets the group to quarantine
  
   PATH: / connect / v1 / group / mute
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 
 */

#define GroupSetMuteUrl baseServer "/connect/" APIVersion "/group/mute"


/**
 Save  common used groups
  
   Interface description
  
   PATH: / connect / v1 / group / set_common
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 
 */

#define GroupSetCommonUrl baseServer "/connect/" APIVersion "/group/set_common"

/**
 Cancel common groups
  
   Interface description
  
   PATH: / connect / v1 / group / remove_common
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest

 */
#define GroupRemoveCommonUrl baseServer "/connect/" APIVersion "/group/remove_common"

#pragma mark - External red envelopes

/**
 Get hashid and payment address
  
   Interface description
  
   PATH: / wallet / v1 / billing / external / pending
   METHOD: POST
   Data Format: Protobuf
 */
#define ExternalPendingUrl baseServer "/wallet/" APIVersion "/billing/external/pending"

/**
 Pay
   Interface description
  
   PATH: / wallet / v1 / billing / external / send
   METHOD: POST
   Data Format: Protobuf
 */
#define ExternalSendUrl baseServer "/wallet/" APIVersion "/billing/external/send"

/**
 External transfer history
   Interface description
  
   PATH: / wallet / v1 / billing / external / history
   METHOD: POST
   Data Format: Protobuf
 */
#define ExternalTransferHistoryUrl baseServer "/wallet/" APIVersion "/billing/external/history"

/**
 External red envelopes history
   Interface description
  
   PATH: / wallet / v1 / red_package / history
   METHOD: POST
   Data Format: Protobuf
 */
#define ExternalRedPackageHistoryUrl baseServer "/wallet/" APIVersion "/red_package/history"

/**
 Transfer canceled
   Interface description
  
   PATH: / wallet / v1 / billing / external / cancel
   METHOD: POST
   Data Format: Protobuf
 */
#define ExternalBillCancelUrl baseServer "/wallet/" APIVersion "/billing/external/cancel"

/**
 External transfer details
   Interface description
  
   PATH: / wallet / v1 / billing / external / info
   METHOD: POST
   Data Format: Protobuf
 */
#define ExternalBillInfoUrl baseServer "/wallet/" APIVersion "/billing/external/info"


#pragma mark - redpack

/**
 Receive system red envelopes
  
   Interface description
  
   PATH: / wallet / v1 / red_package / grabSystem
   METHOD: POST
   data
 */
#define RedBagGrabSystemUrl baseServer "/wallet/" APIVersion "/red_package/grabSystem"


/**
 Get red envelope details
  
   Interface description
  
   PATH: / wallet / v1 / red_package / system / info
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 */
#define RedBagSystemInfoUrl baseServer "/wallet/" APIVersion "/red_package/system/info"


/**
 Red envelopes
  
   Interface description
  
   PATH: / wallet / v1 / red_package / send
   METHOD: POST
   Data Format: Protobuf
 */
#define RedBagSendUrl baseServer "/wallet/" APIVersion "/red_package/send"
/**
 Get red envelopes based on information
  
   Interface description
  
   PATH: / wallet / v1 / red_package / pending
   METHOD: POST
   Data Format: Protobuf
 */
#define RedBagPendingUrl baseServer "/wallet/" APIVersion "/red_package/pending"
/**
 Get red envelope details
  
   Interface description
  
   PATH: / wallet / v1 / red_package / info
   METHOD: POST
   Data Format: Protobuf
 */
#define RedBagInfoUrl baseServer "/wallet/" APIVersion "/red_package/info"


/**
 Grab red packets red envelopes
  
   Interface description
  
   PATH: / wallet / v1 / red_package / grab
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 */
#define RedBagGrabInfoUrl baseServer "/wallet/" APIVersion "/red_package/grab"


#pragma mark - wallet

/*
 * blance
 */

#define WalletUnspentQueryV2Url(address)  [NSString stringWithFormat:@"%@/blockchain/" APIVersion "/unspent/%@/info",baseServer,(address)]


#define QueryRedpackgeWithToken(token)  [NSString stringWithFormat:@"%@/wallet/" APIVersion "/red_package/info/%@",baseServer,(token)]

/**
 Interface description
  
   PATH: / unspent /: id / order
   METHOD: POST
   Data Format: protobuf
   Request protobuf FriendRecords
 */
#define WalletUsefulUnspentQueryUrl baseServer "/blockchain/" APIVersion "/unspent/%@/order"

/**
 Interface description
  
   PATH: / connect / v1 / users / friends / records
   METHOD: POST
   Data Format: protobuf
   Request protobuf FriendRecords
 */
#define WallteFriendRecordsUrl baseServer "/connect/" APIVersion "/users/friends/records"


/**
 Interface description
 PATH: /wallet/" APIVersion "/crowdfuning/launch
 METHOD: POST
 Data Format: Protobuf
 */
#define WallteBillCrowdfuningUrl baseServer "/wallet/" APIVersion "/crowdfuning/launch"

/**
 Interface description
 
 PATH: /wallet/" APIVersion "/crowdfuning/pay
 METHOD: POST
 Data Format: Protobuf
 */
#define WalltePayCrowdfuningUrl baseServer "/wallet/" APIVersion "/crowdfuning/pay"

/**
 Interface description
 
 PATH: /wallet/" APIVersion "/crowdfuning/info
 METHOD: POST
 Data Forma: Protobuf
 */
#define WallteCrowdfuningInfoUrl baseServer "/wallet/" APIVersion "/crowdfuning/info"

/**
 Interface description
 
 PATH: /wallet/" APIVersion "/crowdfuning/records/users
 METHOD: POST
 Data Format: Protobuf
 */
#define WallteCrowdfuningUserRecordsUrl baseServer "/wallet/" APIVersion "/crowdfuning/records/users"

/**
 Transfer to multiple people interface
  
   Interface description
  
   PATH: / wallet / v1 / billing / muilt_send
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 */
#define WallteBillingMuiltSendUrl baseServer "/wallet/" APIVersion "/billing/muilt_send"

/**
 Query a deal
   Interface description
  
   PATH: / wallet / v1 / billing / info
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 */
#define WallteQueryBillInfoUrl baseServer "/wallet/" APIVersion "/billing/info"

/**
 Broadcasting
  
   Interface description
  
   PATH: / wallet / v1 / billing / publish / tx
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 */
#define WallteBillPublishUrl baseServer "/wallet/" APIVersion "/billing/publish/tx"

/**
 Transfer to the individual
   PATH: / wallet / v1 / billing / send
   METHOD: POST
   Data Format: Protobuf
 */
#define WallteBillingSendUrl baseServer "/wallet/" APIVersion "/billing/send"

/**
 Receipt to personal interface
  
   Interface description
  
   PATH: / wallet / v1 / billing / recive
   METHOD: POST
   Data format: Protobuf
 */
#define WallteBillingReciveUrl baseServer "/wallet/" APIVersion "/billing/recive"

/**
 Address transaction record
  
   Interface description
  
   PATH: / blockchain / v1 / address /: id / tx
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: QueryAddressTx
 */
#define WalletAddressTransRecodsUrl baseServer "/blockchain/" APIVersion "/address/%@/tx?page=%ld&pagesize=%ld"

/**
 address book
 
 Interface description
 
 PATH: /wallet/" APIVersion "/address_book/list
 METHOD: POST
 Data Format: Protobuf
 */
#define Walletaddress_bookListUrl baseServer "/wallet/" APIVersion "/address_book/list"

/**
 Add address
   Interface description
 
  
   PATH: / wallet / v1 / address_book / add
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 */
#define Walletaddress_bookAddUrl baseServer "/wallet/" APIVersion "/address_book/add"

/**
 Delete address
  
   Interface description
  
   PATH: / wallet / v1 / address_book / remove
   METHOD: POST
   Data Format: Protobuf
 */
#define Walletaddress_bookRemoveUrl baseServer "/wallet/" APIVersion "/address_book/remove"

/**
 Address setting tag
  
   PATH: / wallet / v1 / address_book / tag
   METHOD: POST
   Data Format: Protobuf
 */
#define Walletaddress_bookTagUrl baseServer "/wallet/" APIVersion "/address_book/tag"

#pragma mark - contacts
/**
 Interface description
  
   PATH: / connect / v1 / users / phonebook
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: RequestNotEncrypt

 */
#define ContactPhoneBookUrl baseServer "/connect/" APIVersion "/users/phonebook"

/**
 Friends search
  
   Interface description
  
   PATH: / connect / v1 / users / search
   METHOD: POST
   Data Format: JSON
   Request parameter
 
 */
#define ContactUserSearchUrl baseServer "/connect/" APIVersion "/users/search"

/**
 Add a blacklist
  
   Interface description
  
   PATH: / connect / v1 / blacklist
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest

 */

#define ContactBlackListAddUrl baseServer "/connect/" APIVersion "/blacklist"

/**
 Interface description
  
   PATH: / connect / v1 / blacklist / remove
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest

 */
#define ContactBlackListRemoveUrl baseServer "/connect/" APIVersion "/blacklist/remove"

/**
 Blacklist interface
  
   Interface description
  
   PATH: / connect / v1 / blacklist / list
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest

 */
#define ContactBlackListUrl baseServer "/connect/" APIVersion "/blacklist/list"

/**
 Set privacy
  
   Interface description
  
   PATH: / connect / v1 / setting / privacy
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 
 */

#define ContactSetPrivacyUrl baseServer "/connect/" APIVersion "/setting/privacy"
/**
 Set whether to allow me to find me from the practitioner
  
   Interface description
  
   PATH: / connect / v1 / setting / privacy
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 
 */

#define RecommendFindMe baseServer "/connect/" APIVersion "/setting/recommend"
/**

 Get set privacy
  
   Interface description
  
   PATH: / connect / v1 / setting / privacy / info
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
*/
#define ContactSyncPrivacyUrl baseServer "/connect/" APIVersion "/setting/privacy/info"


/**
 Update user avatar
  
   Interface description
  
   PATH: / connect / v1 / setting / avatar
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 */
#define ContactSetAvatar baseServer "/connect/" APIVersion "/setting/avatar"

#pragma mark -contact tag

/**
 Tag interface
  
   Interface description
  
   PATH: / connect / v1 / tag
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 
 */
#define ContactAddTagUrl baseServer "/connect/" APIVersion "/tag"


/**
 Tag interface
  
   Interface description
  
   PATH: / connect / v1 / tag / list
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 */
#define ContactTagListUrl baseServer "/connect/" APIVersion "/tag/list"


/**
 Remove the label interface
  
   Interface description
  
   PATH: / connect / v1 / tag / remove
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest

 */

#define ContactTagRemoveUrl baseServer "/connect/" APIVersion "/tag/remove"

/**
 Set friend interface
  
   Interface description
  
   PATH: / connect / v1 / tag / adduser
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
  
   Add the member Protobuf file: SetingUserToTag

 */
#define ContactTagSetUserTagUrl baseServer "/connect/" APIVersion "/tag/adduser"


/**
 Set friend interface
  
   Interface description
  
   PATH: / connect / v1 / tag / remove / user
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest

 */
#define ContactTagRemoveUserTagUrl baseServer "/connect/" APIVersion "/tag/remove/user"
/**
 Set friend interface
  
   Interface description
  
   PATH: / connect / v1 / tag / remove / user
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 
 */
#define ContactTagRemoveUserHaveTagUrl baseServer "/connect/" APIVersion "/tag/remove"

/**
 Tag friends list
  
   Interface description
  
   PATH: / connect / v1 / tag / users
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest

 */
#define ContactTagTagUsersUrl baseServer "/connect/" APIVersion "/tag/users"
/**
 Friends under the tags
  
   Interface description
  
   PATH: / connect / v1 / tag / users
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 
 */
#define UserTagsUrl baseServer "/connect/" APIVersion "/tag/friendTags"


#pragma mark - user
/**
 Interface description
  
   PATH: / avatar / v1 / up
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: RequestNotEncrypt

 */
#define UserSetOrUpdataAvatar baseServer "/avatar/" APIVersion "/up"

/**
 Interface description
  
   PATH: / connect / v1 / setting / userinfo
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 */
#define SetUpdataUserInfo baseServer "/connect/" APIVersion "/setting/userinfo"

// ===========================exchange rate=================================//
/**
 *  Conversion of RMB and Bitcoin
 */
#define RMBExchangeBitRateUrl baseServer "/apis/cny"

/**
 *  Bit currency quot; apis / bitstamp
 */
#define BitsampUrl baseServer "/apis/bitstamp"

/**
 Bitcoin and dollar conversion / apis / usd
 */
#define DollarExchangeBitRateUrl baseServer "/apis/usd"

/**
 *  Conversion of rubles and bitcoats / apis / rub
 */
#define  RubleExchangeBitRateUrl baseServer "/apis/rub"

#pragma mark - blockchain Query interface
/**
 Unused transaction
 /blockchain/api/" APIVersion "/unspent/:id
 */
//#define BlockChainUnspentUrl baseServer "/blockchain/" APIVersion "/unspent/"
#define BlockChainUnspentUrlWithAddress(address)  [NSString stringWithFormat:@"%@/blockchain/" APIVersion "/unspent/%@",baseServer,(address)]


/**
 Interface description
  
   PATH: / blockchain / v1 / tx / compose
   METHOD: post
 Data Format: Protobuf

 */

//#define BlockChaincomposeUrl @"http://192.168.4.179:3000" "/blockchain/" APIVersion "/tx/compose"
#define BlockChaincomposeUrl baseServer "/blockchain/" APIVersion "/tx/compose"


#pragma mark - set
/**
 Unbind
  
   Interface description
  
   PATH: / connect / v1 / setting / unbind / mobile
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest

 */

#define SetUnBindPhoneUrl baseServer "/connect/" APIVersion "/setting/unbind/mobile"

/**
 Bind the phone number
  
   Interface description
  
   PATH: / connect / v1 / setting / bind / mobile
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest

*/

#define SetBindPhoneUrl baseServer "/connect/" APIVersion "/setting/bind/mobile"

/**
 Change the login password
  
   Interface description
  
   PATH: / connect / v1 / setting / backup / key
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest

 */
#define SetChangeLoginPass baseServer "/connect/" APIVersion "/setting/backup/key"

/**
 Payment settings
  
   Interface description
  
   PATH: / connect / v1 / setting / pay / setting
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest

 */
#define SetPaySetUrl baseServer "/connect/" APIVersion "/setting/pay/setting"

#define PinSetingUrl baseServer "/connect/" APIVersion "/setting/pay/pin/setting"
#define PaypinversionUrl  baseServer "/connect/" APIVersion "/setting/pay/pin/version"

/**
 Payment settings
  
   Interface description
  
   PATH: / connect / v1 / setting / pay / setting / sync
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest

 */
#define SetSyncPaySetUrl baseServer "/connect/" APIVersion "/setting/pay/setting/sync"

#pragma mark - userinfo message


#pragma mark - FAQ
#define FAQWikisUrl baseServer "/faq/" APIVersion "/wikis"

#define ShareAppUrl baseServer "/share/" APIVersion "/app"


#pragma mark -Synchronous address book

/**
 Synchronous address book
  
   Interface description
  
   PATH: / connect / v1 / setting / phonebook / sync
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 */
#define SetPhonebookSync baseServer "/connect/" APIVersion "/setting/phonebook/sync"

#pragma mark - synchroize
/**
 Get backup information
   PATH: / connect / v1 / group / backup
   METHOD: POST
   Data Format: Protobuf
   Request parameter
  
   Protobuf file: IMRequest
 */
#define BackupDownCreateGroupInfoUrl baseServer "/connect/" APIVersion "/group/backup"
/**
 Modify user id
  
   UIRL: / connect / v1 / setting / connectId
   Method: POST
   Data Format: Protobuf
   Params:
   Protobuf file: SendMobileCode
 */
#define UpdateUserID baseServer "/connect/" APIVersion "/setting/connectId"
/**
 recommand man
 
 UIRL: /connect/" APIVersion "/users/recommend
 Method: POST
 Data Format: Protobuf
 Params:
 Protobuf file: SendMobileCode
 */
#define GetRecommandFriendUrl baseServer "/connect/" APIVersion "/users/recommend"

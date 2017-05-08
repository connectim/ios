/*                                                                            
  Copyright (c) 2014-2015, GoBelieve     
    All rights reserved.		    				     			
 
  This source code is licensed under the BSD-style license found in the
  LICENSE file in the root directory of this source tree. An additional grant
  of patent rights can be found in the PATENTS file in the same directory.
*/

#import <Foundation/Foundation.h>

#import "Protofile.pbobjc.h"
#import "Protofile.pbobjc.h"
#import "Protofile.pbobjc.h"
#import "Protofile.pbobjc.h"
#import "Protofile.pbobjc.h"

//========= IM Message ========
#define BM_IM_TYPE 0x05
#define BM_IM_ROBOT_EXT 0x00 //robot message
#define BM_IM_EXT 0x01
#define BM_IM_MESSAGE_ACK_EXT 0x02
#define BM_IM_SEND_GROUPINFO_EXT 0x03
#define BM_IM_GROUPMESSAGE_EXT 0x04
#define BM_IM_UNARRIVE_EXT 0x05
#define BM_IM_NO_RALATIONSHIP_EXT 0x06
#define BM_TRASACTION_NOTI_EXT 0x07 //deprecated
#define BM_REDBAG_NOTI_EXT 0x08 //deprecated
#define BM_SERVER_NOTE_EXT 0x09 //trasaction note

//========= heart beat ========
#define BM_HEARTBEAT_TYPE 0x02
#define BM_HEARTBEAT_EXT 0x00

//========= hand shake ========
#define BM_HANDSHAKE_TYPE 0x01
#define BM_HANDSHAKE_EXT 0x01
#define BM_HANDSHAKEACK_EXT 0x02

//========= Ack ========
#define BM_ACK_TYPE 0x03
#define BM_ACK_EXT 0x00
#define BM_ACK_BACK_EXT 0x01
#define BM_ACK_OFFLIE_BACK_EXT 0x02 //offline ack
#define BM_GETOFFLINECMD_ACK_EXT 0x02 //ack


//========= Command ========
#define BM_COMMAND_TYPE 0x04
#define BM_OFFLINE_CMD_EXT 0x02
#define BM_COMMON_GROUP_EXT 0x03
#define BM_GETOFFLINE_EXT 0x04 //offline message
#define BM_SYNCBADGENUMBER_EXT 0x05
#define BM_BINDDEVICETOKEN_EXT 0x06
#define BM_UNBINDDEVICETOKEN_EXT 0x07
#define BM_NEWFRIEND_EXT 0x08
#define BM_ACCEPT_NEWFRIEND_EXT 0x09
#define BM_DELETE_FRIEND_EXT 0x0a
#define BM_SET_FRIENDINFO_EXT 0x0b
#define BM_GROUPINFO_CHANGE_EXT 0x0d
#define BM_OUTER_TRANSFER_EXT 0x11
#define BM_OUTER_REDPACKET_EXT 0x12
#define BM_INVITE_TO_GROUP_EXT 0x13
#define BM_RECOMMADN_NOTINTEREST_EXT 0x15
#define BM_UPLOAD_APPINFO_EXT 0x16
#define BM_UPLOAD_CHAT_COOKIE_EXT 0x17
#define BM_FRIEND_CHAT_COOKIE_EXT 0x18
#define BM_FRIENDLIST_EXT 0x01
#define BM_CREATE_SESSION 0x0c
#define BM_SETMUTE_SESSION 0x10
#define BM_DELETE_SESSION 0x0e


//========= system ========
#define BM_CUTOFFINE_CONNECT_TYPE 0x06
#define BM_CUTOFFINE_CONNECT_EXT 0x00
#define BM_CUTOFFINE_BYSERVER_EXT 0x01


#define BM_SERVER_ERROR_TYPE 0x08
#define BM_SERVER_SIGN_ERROR_EXT 0x00
#define BM_NO_RELATIONSHIP_EXT 0x34


@interface Message : NSObject

@property(nonatomic, copy) NSString *msgIdentifer;

@property(nonatomic) unsigned char typechar;
@property(nonatomic) unsigned char extension;
@property(nonatomic, assign) int len;
@property(nonatomic) id body; //encrypt data
@property(nonatomic) id originData; //origindata
@property(nonatomic, strong) id sendOriginInfo; //send data

@property(nonatomic, assign) int seq;

- (NSMutableData *)pack;

- (BOOL)unpack:(NSData *)data;

@property(nonatomic, strong) Connection *fristConn;
@property(nonatomic, strong) IMResponse *handshakeResponse;
@property(nonatomic, strong) MessagePost *messagePost;

@end

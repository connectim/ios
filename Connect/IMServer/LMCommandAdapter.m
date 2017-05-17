//
//  LMCommandAdapter.m
//  Connect
//
//  Created by MoHuilin on 2017/5/16.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "LMCommandAdapter.h"
#import "ConnectTool.h"

@implementation LMCommandAdapter

+ (Message *)sendAdapterWithExtension:(unsigned char)extension sendData:(GPBMessage *)sendData {
    if (sendData) {
        //command
        Command *command = [[Command alloc] init];
        command.msgId = [ConnectTool generateMessageId];
        command.detail = sendData.data;

        //transferData
        IMTransferData *request = [ConnectTool createTransferWithEcdhKey:[ServerCenter shareCenter].extensionPass data:command.data aad:nil];

        Message *m = [[Message alloc] init];
        m.msgIdentifer = command.msgId;
        m.originData = command.data;
        m.sendOriginInfo = sendData;
        m.typechar = BM_COMMAND_TYPE;
        m.extension = extension;
        m.len = (int) [request data].length;
        m.body = [request data];

        return m;
    } else {
        Message *m = [[Message alloc] init];
        m.typechar = BM_COMMAND_TYPE;
        m.extension = extension;
        m.body = [NSData data];
        m.len = 0;
        return m;
    }
}

@end

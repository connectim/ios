//
//  GPBMessage+LMProtoDataValidation.m
//  Connect
//
//  Created by MoHuilin on 2017/3/6.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "GPBMessage+LMProtoDataValidation.h"
#import "Protofile.pbobjc.h"

#define CASE(str)                       if ([__s__ isEqualToString:(str)])
#define SWITCH(s)                       for (NSString *__s__ = (s); ; )
#define DEFAULT

@implementation GPBMessage (LMProtoDataValidation)

+ (nullable instancetype)parseFromValidationData:(NSData *)data error:(NSError **)errorPtr{
    GPBMessage *message = [self parseFromData:data error:errorPtr];
    NSString *modelClassName = NSStringFromClass([message class]);
    SWITCH (modelClassName) {
        CASE (@"IMTransferData") {
            IMTransferData *model = (IMTransferData *)message;
            if (!model.sign) {
                return nil;
            }
            if (![self validationGcmdata:model.cipherData]) {
                return nil;
            }
            break;
        }
        CASE (@"IMResponse") {
            IMResponse *model = (IMResponse *)message;
            if (!model.sign) {
                return nil;
            }
            if (![self validationGcmdata:model.cipherData]) {
                return nil;
            }
            break;
        }
        CASE (@"QuitMessage") {
            QuitMessage *model = (QuitMessage *)message;
            if (!model.deviceName) {
                return nil;
            }
            break;
        }
        CASE (@"MessagePost") {
            MessagePost *model = (MessagePost *)message;
            if (!model.pubKey) {
                return nil;
            }
            if (!model.sign) {
                return nil;
            }
            if (!model.msgData.receiverAddress) {
                return nil;
            }
            if (!model.msgData.msgId) {
                return nil;
            }
            if (![self validationGcmdata:model.msgData.cipherData]) {
                return nil;
            }
            break;
        }
        CASE(@"MSMessage"){
            MSMessage *model = (MSMessage *)message;
            if (!model.msgId) {
                return nil;
            }
            break;
        }
        CASE(@"NoticeMessage"){
            NoticeMessage *model = (NoticeMessage *)message;
            if (!model.msgId) {
                return nil;
            }
            break;
        }
        CASE(@"SendToUserMessage"){
            SendToUserMessage *model = (SendToUserMessage *)message;
            if (!model.hashId) {
                return nil;
            }
            if (!model.operation) {
                return nil;
            }
            break;
        }

        CASE(@"RejectMessage"){
            RejectMessage *model = (RejectMessage *)message;
            if (!model.msgId) {
                return nil;
            }
            if (!model.receiverAddress) {
                return nil;
            }
            break;
        }
        CASE(@"Command"){
            Command *model = (Command *)message;
            if (!model.msgId) {
                return nil;
            }
            break;
        }

        DEFAULT {
            break;
        }
    }
    return message;
}

+ (BOOL)validationGcmdata:(GcmData *)gcdData{
    if (!gcdData.aad) {
        return NO;
    }
    if (!gcdData.iv) {
        return NO;
    }
    if (!gcdData.ciphertext) {
        return NO;
    }
    if (!gcdData.tag) {
        return NO;
    }
    return YES;
}

@end

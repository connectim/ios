//
//  StreamParser.m
//  Connect
//
//  Created by MoHuilin on 16/8/12.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "StreamParser.h"
#import "NSData+Hash.h"

@interface StreamParser () {
#if __has_feature(objc_arc_weak)
    __weak id delegate;
#else
    __unsafe_unretained id delegate;
#endif
    dispatch_queue_t delegateQueue;
    NSMutableData *byteParsed;
    int _minDataLength;
    unsigned char _type;
    unsigned char _extension;
    unsigned char _version;
    UInt16 _check;
}

@end


#define SOCKET_HEAD_LEN 13 //1 + 1 + 4 + 1 + 4 + 2 version type len extension salt check 
#define SALT_LEN 4

@implementation StreamParser

- (id)initWithDelegate:(id)aDelegate delegateQueue:(id)aDelegateQueue {
    delegate = aDelegate;
    delegateQueue = aDelegateQueue;
    byteParsed = [[NSMutableData alloc] init];
    _minDataLength = SOCKET_HEAD_LEN;
    _type = 0xff;
    _version = 0xff;
    _extension = 0xff;
    return self;
}

- (void)checkVersion {

}

- (void)parseData:(NSData *)data {
    [byteParsed appendBytes:[data bytes] length:[data length]];

    if (byteParsed.length >= 1) {
        [self checkVersion];
    }

    NSLog(@"byteParsed len:%ld", byteParsed.length);
    while ([byteParsed length] >= SOCKET_HEAD_LEN) {
        if (_type == 0xff || _extension == 0xff) {
            [byteParsed getBytes:&_version range:NSMakeRange(0, sizeof(_version))];
            [byteParsed getBytes:&_type range:NSMakeRange(sizeof(_version), sizeof(_type))];
            [byteParsed getBytes:&_minDataLength range:NSMakeRange(sizeof(_version) + sizeof(_type), sizeof(_minDataLength))];
            [byteParsed getBytes:&_extension range:NSMakeRange(sizeof(_version) + sizeof(_type) + sizeof(_minDataLength), sizeof(_extension))];
            [byteParsed getBytes:&_check range:NSMakeRange(SALT_LEN + sizeof(_version) + sizeof(_type) + sizeof(_minDataLength) + sizeof(_extension), sizeof(_check))];

            if (![self checkBytes]) {
                //clear data
                [byteParsed setLength:0];

                //reverse
                _minDataLength = SOCKET_HEAD_LEN;
                _type = 0xff;
                _extension = 0xff;
                _version = 0xff;
                if (delegate && [delegate respondsToSelector:@selector(IllegalData)]) {
                    [delegate IllegalData];
                }
                break;
            }

            _minDataLength = NSSwapHostIntToBig(_minDataLength);
            NSLog(@"willreadlen:%d", _minDataLength);
        }

        if (_type < 0xff && _extension < 0xff) {
            if ([byteParsed length] < _minDataLength + SOCKET_HEAD_LEN) {
                break;
            }
            NSData *thisData = [byteParsed subdataWithRange:NSMakeRange(1, _minDataLength + SOCKET_HEAD_LEN - 1)];
            //to do
            if (delegate && [delegate respondsToSelector:@selector(parserDidReadStanza:thisData:)]) {
                __strong id theDelegate = delegate;

                Message *msg = [[Message alloc] init];
                [msg unpack:thisData];
                [theDelegate parserDidReadStanza:msg thisData:thisData];
            }
            if ([byteParsed length] >= SOCKET_HEAD_LEN + _minDataLength) {
                [byteParsed setData:[byteParsed subdataWithRange:NSMakeRange(SOCKET_HEAD_LEN + _minDataLength, [byteParsed length] - SOCKET_HEAD_LEN - _minDataLength)]];
            }

            _minDataLength = SOCKET_HEAD_LEN;
            _type = 0xff;
            _extension = 0xff;
            _version = 0xff;
        }
    }

}


- (void)handleData:(NSData *)data {
    [byteParsed appendBytes:[data bytes] length:[data length]];
    while ([byteParsed length] >= SOCKET_HEAD_LEN) {
        if (_type == 0xff || _extension == 0xff) {
            [byteParsed getBytes:&_version range:NSMakeRange(0, sizeof(_version))];
            [byteParsed getBytes:&_type range:NSMakeRange(sizeof(_version), sizeof(_type))];
            [byteParsed getBytes:&_minDataLength range:NSMakeRange(sizeof(_version) + sizeof(_type), sizeof(_minDataLength))];
            [byteParsed getBytes:&_extension range:NSMakeRange(sizeof(_version) + sizeof(_type) + sizeof(_minDataLength), sizeof(_extension))];
            [byteParsed getBytes:&_check range:NSMakeRange(SALT_LEN + sizeof(_version) + sizeof(_type) + sizeof(_minDataLength) + sizeof(_extension), sizeof(_check))];
            _minDataLength = NSSwapHostIntToBig(_minDataLength);

            if (![self checkBytes]) {

                [byteParsed setLength:0];

                _minDataLength = SOCKET_HEAD_LEN;
                _type = 0xff;
                _extension = 0xff;
                _version = 0xff;
                if (delegate && [delegate respondsToSelector:@selector(IllegalData)]) {
                    [delegate IllegalData];
                }
                break;
            }

            if (_type == 0xff || _extension == 0xff) {
                break;
            }
        }

        if (_type < 0xff && _extension < 0xff) {
            if ([byteParsed length] < _minDataLength + SOCKET_HEAD_LEN) {
                break;
            }
            NSData *thisData = [byteParsed subdataWithRange:NSMakeRange(1, _minDataLength + SOCKET_HEAD_LEN - 1)];
            //to do
            if (delegate && [delegate respondsToSelector:@selector(parserDidReadThisData:)]) {
                __strong id theDelegate = delegate;
                [theDelegate parserDidReadThisData:thisData];
            }

            if ([byteParsed length] >= SOCKET_HEAD_LEN + _minDataLength) {
                [byteParsed setData:[byteParsed subdataWithRange:NSMakeRange(SOCKET_HEAD_LEN + _minDataLength, [byteParsed length] - SOCKET_HEAD_LEN - _minDataLength)]];
            }

            _minDataLength = SOCKET_HEAD_LEN;
            _type = 0xff;
            _extension = 0xff;
            _version = 0xff;
        }
    }

}

- (BOOL)checkBytes {

    NSMutableData *checkData = [NSMutableData dataWithData:[byteParsed subdataWithRange:NSMakeRange(1, 10)]];

    UInt8 j = 0xc0;
    NSData *data1 = [[NSData alloc] initWithBytes:&j length:sizeof(j)];
    [checkData appendData:data1];

    UInt8 i = 0x2E;
    NSData *data2 = [[NSData alloc] initWithBytes:&i length:sizeof(i)];
    [checkData appendData:data2];

    UInt8 n = 0xC7;

    NSData *data3 = [[NSData alloc] initWithBytes:&n length:sizeof(n)];
    [checkData appendData:data3];

    NSData *checkDataMd5 = [checkData md5Data];

    NSData *checkTwoBytes = [checkDataMd5 subdataWithRange:NSMakeRange(0, 2)];

    NSData *serverCheckBytes = [NSData dataWithBytes:&_check length:sizeof(_check)];
    return [checkTwoBytes isEqualToData:serverCheckBytes];
}


- (void)revert {
    byteParsed = [[NSMutableData alloc] init];
    _type = 0xff;
    _version = 0xff;
    _extension = 0xff;
}

@end

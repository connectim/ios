//
//  MyLogFormatter.m
//  Connect
//
//  Created by MoHuilin on 16/8/12.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "MyLogFormatter.h"

@implementation MyLogFormatter

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage{
    
    NSString *logLevel = nil;
    switch (logMessage->_flag)
    {
        case DDLogFlagError:
            logLevel = @"[ERROR]> ";
            break;
        case DDLogFlagWarning:
            logLevel = @"[WARN]> ";
            break;
        case DDLogFlagInfo:
            logLevel = @"[INFO]> ";
            break;
        case DDLogFlagDebug:
            logLevel = @"[DEBUG]> ";
            break;
        case DDLogFlagVerbose:
            logLevel = @"[VBOSE]> ";
            break;
        default:
            
            break;
    }
    NSDate *date = [NSDate date];
    
    // Create a time to format the object
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"MM-dd HH-mm-ss";
    
    NSString *res = [formatter stringFromDate:date];
    NSString *formatStr = [NSString stringWithFormat:@"KivenLin:%@==%@[%@ %@][line %lu] %@",res,
                           logLevel, logMessage.fileName, logMessage->_function,
                           (unsigned long)logMessage->_line, logMessage->_message];
    return formatStr;
}

@end

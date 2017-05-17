//
//  NSString+DNS.m
//  Connect
//
//  Created by MoHuilin on 2017/5/17.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "NSString+DNS.h"
#include <netdb.h>
#include <sys/socket.h>
#include <arpa/inet.h>


@implementation NSString (DNS)


-(NSString*)IPString{
    
    const char* szname = [self UTF8String];
    struct hostent* phot ;
    @try
    {
        phot = gethostbyname(szname);
    }
    @catch (NSException * e)
    {
        return nil;
    }
    
    struct in_addr ip_addr;
    memcpy(&ip_addr,phot->h_addr_list[0],4);///h_addr_list[0]里4个字节,每个字节8位，此处为一个数组，一个域名对应多个ip地址或者本地时一个机器有多个网卡
    
    char ip[20] = {0};
    inet_ntop(AF_INET, &ip_addr, ip, sizeof(ip));
    
    NSString* strIPAddress = [NSString stringWithUTF8String:ip];
    return strIPAddress;}


@end

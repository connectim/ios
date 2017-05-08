//
//  NetServiceTool.h
//  URLCallBackDemo
//
//  Created by Edwin on 16/8/15.
//  Copyright © 2016年 EdwinXiang. All rights reserved.
//

#import <Foundation/Foundation.h>

// Network request callback block
typedef void(^ServiceResultCallback)(id obj);

@interface NetServiceTool : NSObject

+(instancetype)shareService;
- (void)aqureResultWithUrl:(NSString *)url withParams:(NSDictionary *)params withCallBack:(ServiceResultCallback)callBack;
@end

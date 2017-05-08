//
//  LMLoginTest.m
//  Connect
//
//  Created by bitmain on 2017/3/10.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "Kiwi.h"
#import "LMSoundTool.h"
#import "LKUserCenter.h"
SPEC_BEGIN(SetPageSpec)
describe(@"Math", ^{
    context(@"Login Test", ^{
        it(@"check Login Data", ^{
            //验证声音生成的字符串是否合法
            NSInteger firstObject = arc4random_uniform(1000);
            NSInteger lastObject = arc4random_uniform(1000);
            NSString* str = [LKUserCenter shareCenter].currentLoginUser.prikey;
            if(str.length <= 0) str = @"abcd";
            NSArray* cachArray = @[@(firstObject),str,@(lastObject)];
            NSString* path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString* cachePath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"%darray.data",arc4random_uniform(1000)]];
            [cachArray writeToFile:cachePath atomically:YES];
            NSData* data = [NSData dataWithContentsOfFile:cachePath];
            NSString* checkStr = [LMSoundTool stringWithData:data];
            NSInteger strLen = 128;
            [[expectFutureValue(theValue(checkStr.length)) shouldEventuallyBeforeTimingOutAfter(3)] equal:theValue(strLen)];
            
            //私钥登录url校验
           
            //注册头像url校验
            
            
            //本地用户头像url校验
            
            
            
        });
    });
});
SPEC_END

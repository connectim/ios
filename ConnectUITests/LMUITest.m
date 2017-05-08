//
//  LMUITest.m
//  Connect
//
//  Created by bitmain on 2017/3/8.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import "Kiwi.h"

SPEC_BEGIN(NetWorkOperationToolSpec)

describe(@"Math", ^{
    
    context(@"test net work", ^{
        it(@"is pretty cool", ^{//
            NSUInteger a = 16;
            NSUInteger b = 26;
            [[theValue(a + b) should] equal:theValue(42)];
        });
        
    });
});

SPEC_END

//
//  LMCommandAdapter.h
//  Connect
//
//  Created by MoHuilin on 2017/5/16.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Message.h"

@interface LMCommandAdapter : NSObject

+ (Message *)sendAdapterWithExtension:(unsigned char)extension sendData:(GPBMessage *)sendData;

@end

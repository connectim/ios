//
//  CameraTool.h
//  Connect
//
//  Created by MoHuilin on 16/5/13.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^LoadLastImageCallBack)(UIImage * lastImage) ;

@interface CameraTool : NSObject

+ (void)loadLastPhoto:(LoadLastImageCallBack) callback;

+(NSData*)imageSizeLessthan2M:(NSData*)imageData withOriginImage:(UIImage*)clipImage;

+(NSData*)imageSizeLessthan2K:(NSData*)imageData withOriginImage:(UIImage*)clipImage;


@end

//
//  CameraTool.m
//  Connect
//
//  Created by MoHuilin on 16/5/13.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "CameraTool.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation CameraTool

+ (void)loadLastPhoto:(LoadLastImageCallBack)callback{
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    
    // Enumerate just the photos and videos group by using ALAssetsGroupSavedPhotos.
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        
        // Within the group enumeration block, filter to enumerate just photos.
        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
        
        // Chooses the photo at the last index
        [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *alAsset, NSUInteger index, BOOL *innerStop) {
            
            // The end of the enumeration is signaled by asset == nil.
            if (alAsset) {
                ALAssetRepresentation *representation = [alAsset defaultRepresentation];
                UIImage *latestPhoto = [UIImage imageWithCGImage:[representation fullScreenImage]];
                
                // Stop the enumerations
                *stop = YES; *innerStop = YES;
                if (callback) {
                    callback(latestPhoto);
                }
            }
        }];
    } failureBlock: ^(NSError *error) {
        // Typically you should handle an error more gracefully than this.
        NSLog(@"No groups");
    }];
}


+(NSData*)imageSizeLessthan2M:(NSData*)imageData withOriginImage:(UIImage*)clipImage
{
    if (imageData.length > 2 * 1024 * 1024) {
        CGFloat persentValue = (double)imageData.length/(2 * 1024 * 1024);
        imageData = UIImageJPEGRepresentation(clipImage, 1.0/persentValue);
    }else
    {
        imageData = UIImageJPEGRepresentation(clipImage, 0.2);
    }
    return imageData;
}


+(NSData*)imageSizeLessthan2K:(NSData*)imageData withOriginImage:(UIImage*)clipImage
{
    if (imageData.length > 2 * 1024) {
        CGFloat persentValue = (double)imageData.length/(2 * 1024);
        imageData = UIImageJPEGRepresentation(clipImage, 1.0/persentValue);
    }else
    {
        imageData = UIImageJPEGRepresentation(clipImage, 0.2);
    }
    return imageData;
}



@end

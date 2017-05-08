//
//  PlayViewController.h
//  SBVideoCaptureDemo
//
//  Created by Pandara on 14-8-18.
//  Copyright (c) 2014年 Pandara. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlayViewController : UIViewController

- (id)initWithVideoFileURL:(NSURL *)videoFileURL;

@property (nonatomic ,copy) void (^ClosePlayCallBack)(BOOL playComplete);

@end

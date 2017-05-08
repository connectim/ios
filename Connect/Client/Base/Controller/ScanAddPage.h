//
//  ScanAddPage.h
//  Connect
//
//  Created by MoHuilin on 16/5/22.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseViewController.h"

typedef void (^ScanComplete)(NSString *scanString);

@interface ScanAddPage : BaseViewController
@property(assign, nonatomic) BOOL isFromBook;

- (instancetype)initWithScanComplete:(ScanComplete)complete;

@property(nonatomic, assign) BOOL showMyQrCode; //Whether to display their two-dimensional code

@end

//
//  ScanQRCodePage.h
//  Xtalk
//
//  Created by MoHuilin on 16/2/23.
//  Copyright © 2016年 MoHuilin. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^CallBackWithScanValue)(NSString *value);

@interface ScanQRCodePage : UIViewController

- (instancetype)initWithCallBack:(CallBackWithScanValue)callBack;

@end

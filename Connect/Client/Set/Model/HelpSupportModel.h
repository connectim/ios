//
//  HelpSupportModel.h
//  Connect
//
//  Created by MoHuilin on 16/8/11.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HelpSupportModel : NSObject

@property(nonatomic, assign) NSInteger ID;

@property(nonatomic, copy) NSString *title;

@property(nonatomic, copy) NSString *desc;
@property(nonatomic, assign) NSInteger local_id;
@property(nonatomic, copy) NSString *created_at;
@property(nonatomic, copy) NSString *updated_at;

@end

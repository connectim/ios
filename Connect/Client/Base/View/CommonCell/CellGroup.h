//
//  CellGroup.h
//  HashNest
//
//  Created by MoHuilin on 16/3/16.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CellGroup : NSObject

@property (nonatomic ,copy) NSString *headTitle;

@property (nonatomic ,copy) NSString *footTitle;

@property (nonatomic ,strong) NSArray *items;

@end

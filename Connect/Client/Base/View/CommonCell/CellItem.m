//
//  CellItem.m
//  HashNest
//
//  Created by MoHuilin on 16/3/16.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "CellItem.h"

@implementation CellItem


+ (instancetype)itemWithTitle:(NSString *)title subTitle:(NSString *)subTitle type:(CellItemType)type operation:(Operation)operation{
    CellItem *item = [[CellItem alloc] init];
    item.title = title;
    item.type = type;
    item.operation = operation;
    item.subTitle = subTitle;
    return item;
}


+ (instancetype)itemWithTitle:(NSString *)title type:(CellItemType)type operation:(Operation)operation{
    CellItem *item = [[CellItem alloc] init];
    item.title = title;
    item.type = type;
    item.operation = operation;
    return item;
}

+ (instancetype)itemWithIcon:(NSString *)icon title:(NSString *)title type:(CellItemType)type operation:(Operation)operation{
    CellItem *item = [[CellItem alloc] init];
    item.icon = icon;
    item.title = title;
    item.type = type;
    item.operation = operation;
    return item;
}

@end

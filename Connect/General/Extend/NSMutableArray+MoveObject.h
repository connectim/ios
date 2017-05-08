//
//  NSMutableArray+MoveObject.h
//  Connect
//
//  Created by MoHuilin on 2016/12/8.
//  Copyright © 2016年 Connect - P2P Encrypted Instant Message. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (MoveObject)

- (void)moveObjectFromIndex:(NSUInteger)from toIndex:(NSUInteger)to;

- (void)moveObject:(id)obj toIndex:(NSUInteger)to;

- (void)repleteObject:(id)obj1 withObj:(id)obj2;

- (void)objectInsert:(id)object atIndex:(NSInteger)index;

- (void)objectAddObject:(id)object;
@end

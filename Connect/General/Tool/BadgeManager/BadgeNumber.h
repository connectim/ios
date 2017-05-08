//
//  BadgeNumber.h
//  Connect
//
//  Created by MoHuilin on 16/9/21.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  Indicates classification information
 */
typedef enum : NSUInteger {
    ALCategory_One = 0x1,    // The first tabbarItem: message
    ALCategory_Two = 0x2,    // Second tabbarItem: contact person
    ALCategory_Three = 0x3,  // Third tabbarItem: wallet
    ALCategory_Four = 0x4,   // Third tabbarItem: set
} ALCategory;

/**
 * The index that belongs to the beginning of the second ALCategory_One message
 */
typedef enum : NSUInteger {
    ALTYPE_CategoryTwo_ChatBadgeBegin =  (ALCategory_One << 16) + 0x1,  // begin
} ALTYPE_CategoryOne;

/**
 * Belongs to the second ALCategoryTwo number type definition
 */
typedef enum : NSUInteger {
    ALTYPE_CategoryTwo_NewFriend =  (ALCategory_Two << 16) + 0x1,  // New friend
    ALTYPE_CategoryTwo_PhoneContact = (ALCategory_Two << 16) + 0x2,  //Phone contact person
} ALTYPE_CategoryTwo;

typedef enum : NSUInteger {
    ALDisplayMode_Dot = 0,      // Red dot
    ALDisplayMode_Number,   // Red dot numbers
} ALDisplayMode;

@interface BadgeNumber : NSObject

/** type */
@property (nonatomic,assign) NSUInteger  type;

/** number */
@property (nonatomic,assign) NSUInteger  count;
/** The display type defaults to red dot*/
@property (nonatomic,assign) ALDisplayMode displayMode;

@end

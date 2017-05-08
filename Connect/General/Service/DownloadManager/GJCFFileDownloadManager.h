//
//  GJCFFileDownloadManager.h
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-18.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJCFFileDownloadTask.h"

@class GJCFFileDownloadTask;

typedef void (^GJCFFileDownloadManagerCompletionBlock) (GJCFFileDownloadTask *task,NSData *originData,NSString *originFilePath,BOOL isFinishCache);

typedef void (^GJCFFileDownloadManagerProgressBlock) (GJCFFileDownloadTask *task,CGFloat progress);

typedef void (^GJCFFileDownloadManagerFaildBlock) (GJCFFileDownloadTask *task,NSError *error);

@interface GJCFFileDownloadManager : NSObject


+ (GJCFFileDownloadManager *)shareDownloadManager;

//Whether a message is being downloaded
- (NSString *)getDownloadIdentifierWithMessageId:(NSString *)messageId;

/* Add a download task */
- (void)addTask:(GJCFFileDownloadTask *)task;

/*
 * The observer uniquely identifies the generation method
 */
+ (NSString*)uniqueKeyForObserver:(NSObject*)observer;

/* 
 * Set the observer to complete the method
 */
- (void)setDownloadCompletionBlock:(GJCFFileDownloadManagerCompletionBlock)completionBlock forObserver:(NSObject*)observer;

/*
 *  Set the observer progress method
 */
- (void)setDownloadProgressBlock:(GJCFFileDownloadManagerProgressBlock)progressBlock forObserver:(NSObject*)observer;

/*
 *  Set the observer's failure method
 */
- (void)setDownloadFaildBlock:(GJCFFileDownloadManagerFaildBlock)faildBlock forObserver:(NSObject*)observer;

/*
 * The observer's block is cleared
 */
- (void)clearTaskBlockForObserver:(NSObject *)observer;

/**
 *  Exit the specified download task
 *
 *  @param taskUniqueIdentifier download task flag
 */
- (void)cancelTask:(NSString *)taskUniqueIdentifier;

/**
 *  Quit the download task group with the same flag
 *
 *  @param groupTaskUniqueIdentifier
 */
- (void)cancelGroupTask:(NSString *)groupTaskUniqueIdentifier;

@end

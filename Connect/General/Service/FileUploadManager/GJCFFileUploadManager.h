//
//  GJCFFileUploadManager.h
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-12.
//  Copyright (c) 2014年 Connect.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJCFFileUploadTask.h"
#import "Protofile.pbobjc.h"

/* File upload progress, the block will be called in the sub-thread, be sure to put the UI update code on the main line */
typedef void (^GJCFFileUploadManagerUpdateTaskProgressBlock) (GJCFFileUploadTask *updateTask,CGFloat progressValue);

/* File upload is complete, the block will be called in the sub-thread, be sure to put the UI update code on the main line */
typedef void (^GJCFFileUploadManagerTaskCompletionBlock) (GJCFFileUploadTask *task,FileData *fileData);

/* File upload failed, the block will be called in the sub-thread, be sure to put the UI update code on the main line */
typedef void (^GJCFFileUploadManagerTaskFaildBlock) (GJCFFileUploadTask *task,NSError *error);

/* File upload component */
@interface GJCFFileUploadManager : NSObject

/*
 * The default is the progress block of the upload task performed by the foreground
 */
@property (nonatomic,copy)GJCFFileUploadManagerUpdateTaskProgressBlock progressBlock;

/*
 * The default is the completion of the implementation of the upload task block
 */
@property (nonatomic,copy)GJCFFileUploadManagerTaskCompletionBlock completionBlock;

/*
 * The default is the failure of the upload task
 */
@property (nonatomic,copy)GJCFFileUploadManagerTaskFaildBlock faildBlock;

/* There is a better way to achieve this block*/
- (void)setCompletionBlock:(GJCFFileUploadManagerTaskCompletionBlock)completionBlock;

/* There is a better way to achieve this block*/
- (void)setProgressBlock:(GJCFFileUploadManagerUpdateTaskProgressBlock)progressBlock;

/* There is a better way to achieve this block*/
- (void)setFaildBlock:(GJCFFileUploadManagerTaskFaildBlock)faildBlock;

/*
 * Constructs a successful state block for an observation object
 */
- (void)setCompletionBlock:(GJCFFileUploadManagerTaskCompletionBlock)completionBlock forObserver:(NSObject*)observer;

/*
 * Create a progress view block for an observation object
 */
- (void)setProgressBlock:(GJCFFileUploadManagerUpdateTaskProgressBlock)progressBlock forObserver:(NSObject*)observer;

/*
 * Creates a failure watch state block for an observation object
 */
- (void)setFaildBlock:(GJCFFileUploadManagerTaskFaildBlock)faildBlock forObserver:(NSObject*)observer;

/*
 * Set the observer of the current front desk, the observer can achieve the observation of the three progress of the block
 */
- (void)setCurrentObserver:(NSObject*)observer;


/* share single */
+ (GJCFFileUploadManager *)shareUploadManager;

- (instancetype)initWithOwner:(id)owner;

/*
 * Set the default address of the current file upload service
 */
- (void)setDefaultHostUrl:(NSString*)url;

/*
 * Add an upload task
 */
- (void)addTask:(GJCFFileUploadTask *)aTask;

/*
 *  Just exit an upload task
 */
- (void)cancelTaskOnly:(NSString *)aTaskIdentifier;

/*
 * Exit and clear the upload task
 */
- (void)cancelTaskAndRemove:(NSString *)aTaskIdentifier;

/*
 * Quit all tasks that are being uploaded
 */
- (void)cancelAllExcutingTask;

/*
 * Clear all tasks
 */
- (void)removeAllTask;

/*
 * Clear all failed tasks
 */
- (void)removeAllFaildTask;

/*
 * Reapply upload based on task Id
 */
- (void)tryDoTaskByUniqueIdentifier:(NSString*)uniqueIdentifier;

/*
 * Try to upload all unsuccessful tasks
 */
- (void)tryDoAllUnSuccessTask;

/*
 * Clear the block view of the current view
 */
- (void)clearCurrentObserveBlocks;

/*
 * Clear the block reference of an observer
 */
- (void)clearBlockForObserver:(NSObject*)observer;

/*
 * The observer uniquely identifies the generation method 
 */
+ (NSString*)uniqueKeyForObserver:(NSObject*)observer;

@end

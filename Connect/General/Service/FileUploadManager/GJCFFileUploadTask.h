//
//  GJCFFileUploadTask.h
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-12.
//  Copyright (c) 2014年 ConnectSoft.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GJCFUploadFileModel.h"
#import "GJGCChatContentBaseModel.h"

/* Upload the status of the task*/
typedef NS_ENUM(NSUInteger, GJCFFileUploadState) {
    
    GJFileUploadStateNeverBegin = 0,

    GJFileUploadStateHadFaild = 1,

    GJFileUploadStateUploading = 2,

    GJFileUploadStateSuccess = 3,

    GJFileUploadStateCancel = 4,
};

/* File upload task */
@interface GJCFFileUploadTask : NSObject<NSCoding>


//Upload file type (group, personal, system)
@property (nonatomic ,assign) GJGCChatFriendTalkType msgType;

/* current status  */
@property (nonatomic,assign)GJCFFileUploadState uploadState;

/* Uniquely identifies */
@property (nonatomic,readonly)NSString *uniqueIdentifier;

/* Custom request for HttpHeader */
@property (nonatomic,strong)NSDictionary *customRequestHeader;

/* Customize the contents of the request */
@property (nonatomic,strong)NSDictionary *customRequestParams;

/* An array of objects that need to upload files, including GJCFUploadFileModel */
@property (nonatomic,strong)NSMutableArray *filesArray;

/* User-defined information */
@property (nonatomic,strong)NSDictionary *userInfo;

/* The user sets the task index number */
@property (nonatomic,assign)NSInteger customTaskIndex;

/* The observer of the task, used to respond to the task of the implementation of the block, support single task multi-observer */
@property (nonatomic,readonly)NSArray *taskObservers;


/*
 * Use the path of the file group to be uploaded to upload these files
 */
+ (GJCFFileUploadTask *)taskWithUploadData:(NSData *)uploadData taskObserver:(NSObject*)observer getTaskUniqueIdentifier:(NSString**)taskIdentifier;

/*
 * Use the path of the file group to be uploaded to upload these files
 */
+ (GJCFFileUploadTask *)taskWithUploadFilePaths:(NSArray *)filePaths usingCommonExtension:(BOOL)isCommmonExtentsion commonExtension:(NSString *)commonExtension withFormName:(NSString *)formName taskObserver:(NSObject*)observer getTaskUniqueIdentifier:(NSString**)taskIdentifier;

/*
 * Specify a special task for this particular case: a single file path upload task is convenient to generate
 */
+ (GJCFFileUploadTask *)taskWithFilePath:(NSString*)filePath withFileName:(NSString*)fileName withFormName:(NSString*)formName taskObserver:(NSObject*)observer getTaskUniqueIdentifier:(NSString**)taskIdentifier;

+ (GJCFFileUploadTask *)taskWithUploadImages:(NSArray *)imagesArray commonExtension:(NSString*)extention withFormName:(NSString*)formName taskObserver:(NSObject*)observer getTaskUniqueIdentifier:(NSString**)taskIdentifier;

+ (GJCFFileUploadTask *)taskWithFileData:(NSData*)fileData withFileName:(NSString*)fileName withFormName:(NSString*)formName taskObserver:(NSObject*)observer getTaskUniqueIdentifier:(NSString**)taskIdentifier;


+ (GJCFFileUploadTask *)taskWithMutilFile:(NSArray*)fileModelArray taskObserver:(NSObject*)observer getTaskUniqueIdentifier:(NSString**)taskIdentifier;


+ (GJCFFileUploadTask *)taskForFile:(GJCFUploadFileModel*)aFile taskObserver:(NSObject*)observer getTaskUniqueIdentifier:(NSString *__autoreleasing *)taskIdentifier;


+ (GJCFFileUploadTask *)taskWithUploadImages:(NSArray *)imagesArray commonExtension:(NSString*)extention withFormName:(NSString*)formName getTaskUniqueIdentifier:(NSString**)taskIdentifier;

+ (GJCFFileUploadTask *)taskWithFileData:(NSData*)fileData withFileName:(NSString*)fileName withFormName:(NSString*)formName getTaskUniqueIdentifier:(NSString**)taskIdentifier;


+ (GJCFFileUploadTask *)taskWithMutilFile:(NSArray*)fileModelArray getTaskUniqueIdentifier:(NSString**)taskIdentifier;

+ (GJCFFileUploadTask *)taskForFile:(GJCFUploadFileModel*)aFile getTaskUniqueIdentifier:(NSString *__autoreleasing *)taskIdentifier;

- (BOOL)isEqual:(GJCFFileUploadTask*)aTask;

/*
 * Single task multiple observer add
 */
- (void)addNewTaskObserver:(id)observer;

/*
 * remove observer
 */
- (void)removeTaskObserver:(id)observer;

/*
 * Remove all task watchers
 */
- (void)removeAllTaskObserver;

/*
 * Single task multiple observer add observer only sign
 */
- (void)addNewTaskObserverUniqueIdentifier:(NSString*)uniqueId;

/*
 * Single task multiple observation removal plus observer unique logo
 */
- (void)removeTaskObserverUniqueIdentifier:(NSString*)uniqueId;

/*
 * Determine whether an observer Id is present
 */
- (BOOL)taskIsObservedByUniqueIdentifier:(NSString*)uniqueId;

/* 
 * Whether the task matches the upload criteria
 */
- (BOOL)isValidateBeingForUpload;

@end

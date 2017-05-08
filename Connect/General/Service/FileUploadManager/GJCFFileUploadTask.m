//
//  GJCFFileUploadTask.m
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-12.
//  Copyright (c) 2014年 ConnectSoft.com. All rights reserved.
//

#import "GJCFFileUploadTask.h"
#import "GJCFUploadFileModel.h"
#import "GJCFFileUploadManager.h"

@interface GJCFFileUploadTask()

@property (nonatomic,strong)NSString *innerIdentifier;

@property (nonatomic,strong)NSMutableArray *innerTaskObserverArray;

@end

@implementation GJCFFileUploadTask

/*
 * Use the path of the file group to be uploaded to upload these files
 */
+ (GJCFFileUploadTask *)taskWithUploadFilePaths:(NSArray *)filePaths usingCommonExtension:(BOOL)isCommmonExtentsion commonExtension:(NSString *)commonExtension withFormName:(NSString *)formName taskObserver:(NSObject*)observer getTaskUniqueIdentifier:(NSString**)taskIdentifier
{
    if (!filePaths || filePaths.count == 0 || !formName ) {
        return nil;
    }
    
    NSMutableArray *modelArray = [NSMutableArray array];
    
    for(NSString *fileItemPath in filePaths){
        
        NSString *fileName = [fileItemPath lastPathComponent];
        NSString *fileExtention = nil;
        
        /* The file in the path has no extension */
        if ([fileName componentsSeparatedByString:@"."].count > 0) {
            fileExtention = [[fileName componentsSeparatedByString:@"."]lastObject];
        }
        
        /* If the filegroup uses a uniform extension */
        if (isCommmonExtentsion) {
            fileExtention = commonExtension;
        }
        
        /* If the extension here is empty, then certainly can not upload  */
        if (fileExtention == nil) {
            NSLog(@"FileItemPath:% @ no file extension, can not be added to the task, can not generate the task of uploading filegroups",fileItemPath);
            break;
            return nil;
        }
        
        /* Form a new file name */
        fileName = [NSString stringWithFormat:@"%@.%@",[[fileName componentsSeparatedByString:@"."]firstObject],fileExtention];
        GJCFUploadFileModel *aFile = [GJCFUploadFileModel fileModelWithFileName:fileName withFilePath:fileItemPath withFormName:formName];
        
        [modelArray objectAddObject:aFile];

    }

    return [GJCFFileUploadTask taskWithMutilFile:modelArray taskObserver:observer getTaskUniqueIdentifier:taskIdentifier];
}

/*
 * Use the path of the file group to be uploaded to upload these files
 */
+ (GJCFFileUploadTask *)taskWithUploadData:(NSData *)uploadData taskObserver:(NSObject*)observer getTaskUniqueIdentifier:(NSString**)taskIdentifier{
    if (!uploadData) {
        return nil;
    }
    
    GJCFUploadFileModel *aFileModel = [GJCFUploadFileModel fileModelWithData:uploadData];
    
    return [GJCFFileUploadTask taskForFile:aFileModel taskObserver:observer getTaskUniqueIdentifier:taskIdentifier];
}


/*
 * Specify a special task for this particular case: a single file upload task is convenient to generate
 */
+ (GJCFFileUploadTask *)taskWithFilePath:(NSString*)filePath withFileName:(NSString*)fileName withFormName:(NSString*)formName taskObserver:(NSObject*)observer getTaskUniqueIdentifier:(NSString**)taskIdentifier
{
    if (!filePath || !formName ) {
        return nil;
    }
    
    NSString *filePathFileName = [filePath lastPathComponent];
    NSString *fileExtension = nil;
    
    /* If the file path already has an extension, then read the file path extension directly, if not read from the fileName inside, if there is no extension, then return to the empty task, can not perform tasks */
    if ([filePathFileName componentsSeparatedByString:@"."].count > 0) {
        
        fileExtension = [[filePathFileName componentsSeparatedByString:@"."]lastObject];
        
    }else{
        
        if (!fileExtension) {
            
            if (fileName) {
                if ([fileName componentsSeparatedByString:@"."].count > 0) {
                    
                    NSString *fileNameExtension = [[fileName componentsSeparatedByString:@"."]lastObject];
                    
                    if (!fileExtension) {
                        
                        fileExtension = fileNameExtension;
                        filePath = [NSString stringWithFormat:@"%@.%@",filePath,fileExtension];
                        
                    }else{
                        
                        /* There is no extension can not continue the task, because can not find MIMETYPE */
                        return nil;
                    }
                }
            }
            
        }
        
    }
    
    
    return [GJCFFileUploadTask taskWithUploadFilePaths:@[filePath] usingCommonExtension:NO commonExtension:nil withFormName:formName taskObserver:observer getTaskUniqueIdentifier:taskIdentifier];
}

+ (GJCFFileUploadTask *)taskWithFileData:(NSData *)fileData withFileName:(NSString *)fileName  withFormName:(NSString*)formName taskObserver:(NSObject*)observer getTaskUniqueIdentifier:(NSString *__autoreleasing *)taskIdentifier
{
    if (!fileData || !fileName) {
        return nil;
    }
    
    GJCFUploadFileModel *aFileModel = [GJCFUploadFileModel fileModelWithFileName:fileName withFileData:fileData withFormName:formName];
    
    return [GJCFFileUploadTask taskForFile:aFileModel taskObserver:observer getTaskUniqueIdentifier:taskIdentifier];
}

+ (GJCFFileUploadTask *)taskForFile:(GJCFUploadFileModel *)aFile taskObserver:(NSObject*)observer getTaskUniqueIdentifier:(NSString *__autoreleasing *)taskIdentifier
{
    if (!aFile) {
        return nil;
    }
    
    return [GJCFFileUploadTask taskWithMutilFile:[@[aFile] mutableCopy] taskObserver:observer getTaskUniqueIdentifier:taskIdentifier];
}

+ (GJCFFileUploadTask *)taskWithMutilFile:(NSArray *)fileModelArray taskObserver:(NSObject*)observer getTaskUniqueIdentifier:(NSString *__autoreleasing *)taskIdentifier
{
    if (!fileModelArray || fileModelArray.count == 0) {
        return nil;
    }
    
    GJCFFileUploadTask *task = [[self alloc]init];
    [task.filesArray addObjectsFromArray:fileModelArray];
    *taskIdentifier = task.uniqueIdentifier;
    [task addNewTaskObserver:observer];
    
    return task;
    
}

+ (GJCFFileUploadTask *)taskWithUploadImages:(NSArray *)imagesArray commonExtension:(NSString*)extention  withFormName:(NSString*)formName taskObserver:(NSObject*)observer getTaskUniqueIdentifier:(NSString**)taskIdentifier
{
    
    NSMutableArray *modelArray = [NSMutableArray array];
    
    [imagesArray enumerateObjectsUsingBlock:^(UIImage *aImage, NSUInteger idx, BOOL *stop) {
        
        NSString *fileName = [NSString stringWithFormat:@"%@.%@",[GJCFFileUploadTask currentTimeStamp],extention];
        NSData *fileData = nil;
        if ([extention isEqualToString:@"png"] || [extention isEqualToString:@"PNG"] ) {
            
            fileData = UIImagePNGRepresentation(aImage);
        }
        if ([extention isEqualToString:@"jpg"] || [extention isEqualToString:@"jpeg"] || [extention isEqualToString:@"JPG"] || [extention isEqualToString:@"JPEG"]) {
            
            fileData = UIImageJPEGRepresentation(aImage, 0.5);
        }
        GJCFUploadFileModel *aFile = [GJCFUploadFileModel fileModelWithFileName:fileName withFileData:fileData withFormName:formName];
        [modelArray objectAddObject:aFile];
        
    }];
    
    return [GJCFFileUploadTask taskWithMutilFile:modelArray taskObserver:observer getTaskUniqueIdentifier:taskIdentifier];
}

/* Default by UploadManager specified observer case: the same attribute, no file name of the picture convenient task generation */
+ (GJCFFileUploadTask *)taskWithUploadImages:(NSArray *)imagesArray commonExtension:(NSString*)extention withFormName:(NSString*)formName getTaskUniqueIdentifier:(NSString**)taskIdentifier
{
   return [GJCFFileUploadTask taskWithUploadImages:imagesArray commonExtension:extention withFormName:formName taskObserver:nil getTaskUniqueIdentifier:taskIdentifier];
}

/* By default, UploadManager specifies the observer case: a single file upload task is easily generated */
+ (GJCFFileUploadTask *)taskWithFileData:(NSData*)fileData withFileName:(NSString*)fileName withFormName:(NSString*)formName getTaskUniqueIdentifier:(NSString**)taskIdentifier
{
    return [GJCFFileUploadTask taskWithFileData:fileData withFileName:fileName withFormName:formName taskObserver:nil getTaskUniqueIdentifier:taskIdentifier];
}

/* By default, UploadManager specifies the observer case: File group upload task */
+ (GJCFFileUploadTask *)taskWithMutilFile:(NSArray*)fileModelArray getTaskUniqueIdentifier:(NSString**)taskIdentifier
{
    return [GJCFFileUploadTask taskWithMutilFile:fileModelArray taskObserver:nil getTaskUniqueIdentifier:taskIdentifier];
}

/* By default, UploadManager specifies the observer case: a single file upload task */
+ (GJCFFileUploadTask *)taskForFile:(GJCFUploadFileModel*)aFile getTaskUniqueIdentifier:(NSString *__autoreleasing *)taskIdentifier
{
    return [GJCFFileUploadTask taskForFile:aFile taskObserver:nil getTaskUniqueIdentifier:taskIdentifier];
}

- (id)init
{
    if (self = [super init]) {
        
        self.filesArray = [[NSMutableArray alloc]init];
        self.innerTaskObserverArray = [[NSMutableArray alloc]init];
        self.uploadState = GJFileUploadStateNeverBegin;
        
    }
    return self;
}

- (NSString *)uniqueIdentifier
{
    if (self.innerIdentifier) {
        return self.innerIdentifier;
    }
    
    self.innerIdentifier = [GJCFFileUploadTask currentTimeStamp];
    return self.innerIdentifier;
}

- (NSArray*)taskObservers
{
    return self.innerTaskObserverArray;
}

+ (NSString *)currentTimeStamp
{
    NSDate *now = [NSDate date];
    NSTimeInterval timeInterval = [now timeIntervalSinceReferenceDate];
    
    NSString *timeString = [NSString stringWithFormat:@"%lf",timeInterval];
    timeString = [timeString stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    
    return timeString;
}

- (BOOL)isEqual:(GJCFFileUploadTask *)aTask
{
    if (!aTask || ![aTask isKindOfClass:[GJCFFileUploadTask class]]) {
        return NO;
    }
    return [self.uniqueIdentifier isEqualToString:aTask.uniqueIdentifier];
}

#pragma mark - NSCoding 

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        
        self.uploadState = [aDecoder decodeIntegerForKey:@"uploadState"];
        
        self.innerIdentifier  = [aDecoder decodeObjectForKey:@"innerIdentifier"];
        
        self.customRequestHeader = [aDecoder decodeObjectForKey:@"customRequestHeader"];
        
        self.customRequestParams = [aDecoder decodeObjectForKey:@"customRequestParams"];
        
        self.filesArray = [aDecoder decodeObjectForKey:@"filesArray"];
        
        
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:self.uploadState forKey:@"uploadState"];
    
    [aCoder encodeObject:self.innerIdentifier forKey:@"innerIdentifier"];
    
    [aCoder encodeObject:self.customRequestHeader forKey:@"customRequestHeader"];
    
    [aCoder encodeObject:self.customRequestParams forKey:@"customRequestParams"];
    
    [aCoder encodeObject:self.filesArray forKey:@"filesArray"];
}

#pragma mark - Observers add and remove operations
/* Single task multiple observer add */
- (void)addNewTaskObserver:(id)observer
{
    if (!observer) {
        return;
    }
    
    NSString *uniqueIdentifier = [GJCFFileUploadManager uniqueKeyForObserver:observer];
    
    if ([self.innerTaskObserverArray containsObject:uniqueIdentifier]) {
        
        return;
    }
    
    [self.innerTaskObserverArray objectAddObject:uniqueIdentifier];
}

/* Remove the task observer */
- (void)removeTaskObserver:(id)observer
{
    if (!observer) {
        return;
    }
    
    NSString *uniqueIdentifier = [GJCFFileUploadManager uniqueKeyForObserver:observer];
    
    if (![self.innerTaskObserverArray containsObject:uniqueIdentifier]) {
        
        return;
    }
    
    [self.innerTaskObserverArray removeObject:uniqueIdentifier];
}

/* Remove all task watchers */
- (void)removeAllTaskObserver
{
    if (self.innerTaskObserverArray && self.innerTaskObserverArray.count > 0) {
        
        [self.innerTaskObserverArray removeAllObjects];
    }
}

/* Task Many observers add observer unique logo */
- (void)addNewTaskObserverUniqueIdentifier:(NSString*)uniqueId
{
    if (!uniqueId) {
        return;
    }
    
    NSLog(@"addNewTaskObserverUniqueIdentifier %@ self.innerTaskObserverArray%@",uniqueId,self.innerTaskObserverArray);
    
    if ([self.innerTaskObserverArray containsObject:uniqueId]) {
        
        return;
    }
    [self.innerTaskObserverArray objectAddObject:uniqueId];
    
    NSLog(@"addNewTaskObserverUniqueIdentifier %@ self.innerTaskObserverArray%@",uniqueId,self.innerTaskObserverArray);
    
}

/* Single task multiple observation removal plus observer unique logo */
- (void)removeTaskObserverUniqueIdentifier:(NSString*)uniqueId
{
    if (!uniqueId) {
        return;
    }
    
    if (![self.innerTaskObserverArray containsObject:uniqueId]) {
        
        return;
    }
    
    [self.innerTaskObserverArray removeObject:uniqueId];
}

/* Determine whether an observer Id is present */
- (BOOL)taskIsObservedByUniqueIdentifier:(NSString*)uniqueId
{
    if (!uniqueId) {
        
        return NO;
    }
    
    return [self.innerTaskObserverArray containsObject:uniqueId];
}

/*
 * Whether the task matches the upload criteria
 */
- (BOOL)isValidateBeingForUpload
{
    __block BOOL isValidate = YES;
    [self.filesArray enumerateObjectsUsingBlock:^(GJCFUploadFileModel *aFile, NSUInteger idx, BOOL *stop) {
        
        if (![aFile isValidateForUpload]) {
            
            isValidate = NO;
            
            *stop = YES;
        }
    }];
    
    return isValidate;
}

@end

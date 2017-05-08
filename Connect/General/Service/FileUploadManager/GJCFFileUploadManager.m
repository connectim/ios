//
//  GJCFFileUploadManager.m
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-12.
//  Copyright (c) 2014年 Connect.com. All rights reserved.
//

#import "GJCFFileUploadManager.h"
#import "NetWorkTool.h"
#import "AFURLRequestSerialization.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "GJCFUitils.h"
#import "SingleAFNetworkManager.h"
#import "NSString+Hash.h"
#import "Protofile.pbobjc.h"
#import "Protofile.pbobjc.h"
#import "NSString+DictionaryValue.h"
#import "ConnectTool.h"
#import "Protofile.pbobjc.h"
#import "NetWorkOperationTool.h"
#import "MMMessage.h"
#import "MessageDBManager.h"
#import "IMService.h"
#import "RecentChatDBManager.h"
#import "NSData+Hash.h"


static NSString * GJCFFileUploadManagerQueue = @"gjcf.file_upload.queue";

static NSString * GJCFFileUploadManagerTaskPersistDir = @"GJCFFileUploadManagerTaskPersistDir";

static NSString * GJCFFileUploadManagerTaskPersistFile = @"GJCFFileUploadManagerTaskPersistFile";

static NSString * kGJCFFileUploadManagerCompletionBlockKey = @"kGJCFFileUploadManagerCompletionBlockKey";

static NSString * kGJCFFileUploadManagerProgressBlockKey = @"kGJCFFileUploadManagerProgressBlockKey";

static NSString * kGJCFFileUploadManagerFaildBlockKey = @"kGJCFFileUploadManagerFaildBlockKey";

static NSString * kGJCFFileUploadManagerObserverUniqueIdentifier = @"kGJCFFileUploadManagerObserverUniqueIdentifier";

static dispatch_queue_t _gjcfFileUploadManagerOperationQueue ;

@interface GJCFFileUploadManager ()

@property (nonatomic,strong)NSString     *defaultHostUrl;

@property (nonatomic,strong)NSMutableArray *taskArray;

@property (nonatomic,strong)NSMutableArray *taskSessionArray;

@property (nonatomic,strong)NSMutableDictionary *observerActionDict;

/* The observer currently located at the foreground is uniquely identified */
@property (nonatomic,strong)NSString *currentForegroundObserverUniqueIdenfier;

@property (nonatomic,strong) NSData *serverUserEcdhKey;

@end

@implementation GJCFFileUploadManager

+ (GJCFFileUploadManager*)shareUploadManager
{
    static GJCFFileUploadManager *_fileUploadManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _gjcfFileUploadManagerOperationQueue = dispatch_queue_create(GJCFFileUploadManagerQueue.UTF8String, DISPATCH_QUEUE_CONCURRENT);
        _fileUploadManager = [[self alloc]init];
    });
    return _fileUploadManager;
}

- (instancetype)initWithOwner:(id)owner
{
    if (self = [super init]) {
        
        self.taskArray = [[NSMutableArray alloc]init];
        self.taskSessionArray = [[NSMutableArray alloc]init];
        self.observerActionDict = [[NSMutableDictionary alloc]init];
        
        if (!_gjcfFileUploadManagerOperationQueue) {
            _gjcfFileUploadManagerOperationQueue = dispatch_queue_create(GJCFFileUploadManagerQueue.UTF8String, DISPATCH_QUEUE_CONCURRENT);
        }
        if (owner) {
            self.currentForegroundObserverUniqueIdenfier = [GJCFFileUploadManager uniqueKeyForObserver:owner];
        }
    }
    return self;
}

- (id)init
{
    if (self = [super init]) {
        
        self.taskArray = [[NSMutableArray alloc]init];

        if (!_gjcfFileUploadManagerOperationQueue) {
            _gjcfFileUploadManagerOperationQueue = dispatch_queue_create(GJCFFileUploadManagerQueue.UTF8String, DISPATCH_QUEUE_CONCURRENT);
        }
        self.observerActionDict = [[NSMutableDictionary alloc]init];
    }
    return self;
}

- (NSData *)serverUserEcdhKey{
    NSData *ecdhKey = [KeyHandle getECDHkeyWithPrivkey:[[LKUserCenter shareCenter] currentLoginUser].prikey publicKey:[[ServerCenter shareCenter] getCurrentServer].data.pub_key];
    return [KeyHandle getAes256KeyByECDHKeyAndSalt:ecdhKey salt:[ServerCenter shareCenter].httpTokenSalt];
}



#pragma mark - set message
- (void)setCurrentObserver:(NSObject *)observer
{
    if (!observer) {
        return;
    }
    
    NSString *observerIdentifier = [GJCFFileUploadManager uniqueKeyForObserver:observer];
    
    if ([self.currentForegroundObserverUniqueIdenfier isEqualToString:observerIdentifier]) {
        return;
    }
    
    /* Clear the observation of the original foreground observer */
    [self clearCurrentObserveBlocks];
    self.currentForegroundObserverUniqueIdenfier = observerIdentifier;
}

- (void)setDefaultHostUrl:(NSString *)url
{
    _defaultHostUrl = url;
    [self initClient];
}


- (void)initClient
{
    if (!self.defaultHostUrl) {
        return;
    }
}


- (void)addTask:(GJCFFileUploadTask *)aTask
{
    
    if (![aTask isValidateBeingForUpload] || !aTask) {
        NSLog(@"GJCFFileUploadManager Task ID:%@ The task to be uploaded is not legal and can not start the task",aTask.uniqueIdentifier);
        return;
    }
    
    dispatch_async(_gjcfFileUploadManagerOperationQueue, ^{
    
        if (aTask.taskObservers.count <= 0) {
            [aTask addNewTaskObserverUniqueIdentifier:self.currentForegroundObserverUniqueIdenfier];
        }
        
        for (GJCFFileUploadTask *task in self.taskArray) {
            MMMessage *willUploadMessage = [aTask.userInfo valueForKey:@"message"];
            MMMessage *uploadindMessage = [task.userInfo valueForKey:@"message"];
            if ([uploadindMessage.message_id isEqualToString:willUploadMessage.message_id]) {
                [task addNewTaskObserverUniqueIdentifier:self.currentForegroundObserverUniqueIdenfier];
                return;
            }
        }
        
        if (aTask.uploadState != GJFileUploadStateHadFaild && aTask.uploadState != GJFileUploadStateCancel) {
            [self.taskArray objectAddObject:aTask];
        }
        
        for (GJCFUploadFileModel *uplodDataModel in aTask.filesArray) {
            
            StructData *sturtData = [StructData new];
            sturtData.plainData = uplodDataModel.fileData;
            sturtData.random = [ConnectTool get16_32RandData];
            GcmData *serverGcmData = [ConnectTool createGcmDataWithEcdhkey:self.serverUserEcdhKey data:sturtData.data aad:[ServerCenter shareCenter].defineAad];
            MediaFile *mediaFile = [[MediaFile alloc] init];
            mediaFile.pubKey = [[LKUserCenter shareCenter] currentLoginUser].pub_key;
            mediaFile.cipherData = serverGcmData;

            
            NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:self.defaultHostUrl]];
            [request setHTTPBody:mediaFile.data];
            [request setHTTPMethod:@"POST"];
            __weak __typeof(&*self)weakSelf = self;
            NSURLSessionUploadTask *uploadTask = [NetWorkOperationTool POSTWithUrlString:self.defaultHostUrl postData:mediaFile.data UploadProgressBlock:^(NSProgress *uploadProgress) {
                dispatch_async(_gjcfFileUploadManagerOperationQueue, ^{
                    if (uploadProgress.fractionCompleted >= 0.9f) {
                        [weakSelf progressWithTask:aTask withPercentValue:0.9f];
                    } else{
                        [weakSelf progressWithTask:aTask withPercentValue:uploadProgress.fractionCompleted];
                    }
                });
            } complete:^(id response) {
                dispatch_async(_gjcfFileUploadManagerOperationQueue, ^{
                    [weakSelf progressWithTask:aTask withPercentValue:1.f];
                    [weakSelf completionWithTask:aTask withResultDict:response];
                    /* update status  */
                    [weakSelf updateTask:aTask.uniqueIdentifier withState:GJFileUploadStateSuccess];
                    [weakSelf.taskArray removeObject:aTask];
                });
            } fail:^(NSError *error) {
                dispatch_async(_gjcfFileUploadManagerOperationQueue, ^{
                    /* update status  */
                    [weakSelf updateTask:aTask.uniqueIdentifier withState:GJFileUploadStateHadFaild];
                    [weakSelf faildWithTask:aTask withError:error];
                });
            }];
            
            [self.taskSessionArray objectAddObject:uploadTask];
            [self updateTask:aTask.uniqueIdentifier withState:GJFileUploadStateUploading];
        }
    });
}

- (void)updateTask:(NSString*)aTaskIdentifier withState:(GJCFFileUploadState)uploadState
{
    for (int i = 0 ; i < self.taskArray.count ; i++) {
        
        GJCFFileUploadTask *task = [self.taskArray objectAtIndex:i];
        
        if ([task.uniqueIdentifier isEqual:aTaskIdentifier]) {
            
            task.uploadState = uploadState;
            
            [self.taskArray replaceObjectAtIndex:i withObject:task];
            
            break;
        }
        
    }
}

- (void)completionWithTask:(GJCFFileUploadTask *)aTask withResultDict:(id)responseObject
{
    HttpResponse *hResponse = (HttpResponse *)responseObject;
    if (hResponse.code == 2401) {
        /* update status  */
        [self updateTask:aTask.uniqueIdentifier withState:GJFileUploadStateHadFaild];
        [self faildWithTask:aTask withError:[NSError errorWithDomain:LMLocalizedString(@"", nil) code:hResponse.code userInfo:nil]];
    } else if (hResponse.code == successCode) {
        NSData *decodeData = [ConnectTool decodeHttpResponse:hResponse withEcdhKey:self.serverUserEcdhKey];
        if (decodeData) {
            NSError* error;
            FileData *fileData = [FileData parseFromData:decodeData error:&error];
            /* Find the block of the response */
            if (aTask.taskObservers.count == 0) {
                if (self.completionBlock) {
                    self.completionBlock(aTask,fileData);
                }
            }
            /* Is set to the front desk response to this object */
            if ([aTask taskIsObservedByUniqueIdentifier:self.currentForegroundObserverUniqueIdenfier]) {
                if (self.completionBlock) {
                    self.completionBlock(aTask,fileData);
                }
            }
            
            NSLog(@"aTask.taskObservers %@ self.observerActionDict%@",aTask.taskObservers,self.observerActionDict);
            
            //update success
            MMMessage *msg = [aTask.userInfo valueForKey:@"message"];
            if (msg) {
                // Not the current session is not forwarding the message
                if (![[SessionManager sharedManager].chatSession isEqualToString:msg.publicKey] && ![aTask.userInfo valueForKey:@"toFriend"]) {
                    // update message
                    NSString *fileUrl = [NSString stringWithFormat:@"%@?pub_key=%@&token=%@",fileData.URL,msg.publicKey,fileData.token];
                    switch (msg.type) {
                        case GJGCChatFriendContentTypeVideo:
                        case GJGCChatFriendContentTypeImage:
                        {
                            msg.content = [NSString stringWithFormat:@"%@/thumb?pub_key=%@&token=%@",fileData.URL,msg.publicKey,fileData.token];
                            msg.url = fileUrl;
                        }
                            break;
                        case GJGCChatFriendContentTypeMapLocation:
                        case GJGCChatFriendContentTypeAudio:
                        {
                            msg.content = fileUrl;
                        }
                            break;
                        default:
                            break;
                    }
                    // update message
                    ChatMessageInfo *messageInfo = [[MessageDBManager sharedManager] getMessageInfoByMessageid:msg.message_id messageOwer:msg.publicKey];
                    messageInfo.message = msg;
                    [[MessageDBManager sharedManager] updataMessage:messageInfo];
                    // send message
                    [self sendMessagePost:msg task:aTask];
                }
            }
            
            for (NSString *taskObserverIdentifier in aTask.taskObservers) {
                
                NSMutableDictionary *existActionDict = [self.observerActionDict objectForKey:taskObserverIdentifier];
                
                if (existActionDict) {
                    
                    GJCFFileUploadManagerTaskCompletionBlock successBlock = [existActionDict objectForKey:kGJCFFileUploadManagerCompletionBlockKey];
                    
                    if (successBlock) {
                        
                        successBlock(aTask,fileData);
                        
                    }
                }
            }
        }
    }
}


-(void)faildWithTask:(GJCFFileUploadTask *)aTask withError:(NSError *)error
{
    /* Find the block of the response */
    if (aTask.taskObservers.count == 0) {
        if (self.faildBlock) {
            self.faildBlock(aTask,error);
        }
    }
    /* Is set to the front desk response to this object */
    if ([aTask taskIsObservedByUniqueIdentifier:self.currentForegroundObserverUniqueIdenfier]) {
        if (self.faildBlock) {
            self.faildBlock(aTask,error);
        }
    }
    
    MMMessage *msg = [aTask.userInfo valueForKey:@"message"];
    if (msg) {
        // Update the sending status of the message
        [[MessageDBManager sharedManager] updateMessageSendStatus:GJGCChatFriendSendMessageStatusFaild withMessageId:msg.message_id messageOwer:msg.publicKey];
        // Not in the current session
        if (![[SessionManager sharedManager].chatSession isEqualToString:msg.publicKey]) {
            [GCDQueue executeInMainQueue:^{
                SendNotify(ConnnectUploadFileFailNotification, msg.publicKey);
            }];
        }
    }
    
    for (NSString *taskObserverIdentifier in aTask.taskObservers) {
        
        NSMutableDictionary *existActionDict = [self.observerActionDict objectForKey:taskObserverIdentifier];
        
        if (existActionDict) {
            
            GJCFFileUploadManagerTaskFaildBlock faildBlock = [existActionDict objectForKey:kGJCFFileUploadManagerFaildBlockKey];
            if (faildBlock) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    faildBlock(aTask,error);

                });
                
            }
        }
    }
}

- (void)progressWithTask:(GJCFFileUploadTask *)aTask withPercentValue:(CGFloat)percent
{
    /* Find the block of the response */
    if (aTask.taskObservers.count == 0) {
        if (self.progressBlock) {
            self.progressBlock(aTask,percent);
        }
    }
    
    /* Is set to the front desk response to this object */
    if ([aTask taskIsObservedByUniqueIdentifier: self.currentForegroundObserverUniqueIdenfier]) {
        if (self.progressBlock) {
            self.progressBlock(aTask,percent);
        }
    }
    
    for (NSString *taskObserverIdentifier in aTask.taskObservers) {
        
        NSMutableDictionary *existActionDict = [self.observerActionDict objectForKey:taskObserverIdentifier];
        
        if (existActionDict) {
            
            GJCFFileUploadManagerUpdateTaskProgressBlock progressBlock = [existActionDict objectForKey:kGJCFFileUploadManagerProgressBlockKey];
            
            if (progressBlock) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    progressBlock(aTask,percent);

                });
            }
            
        }
        
    }
}

- (void)cancelTaskOnly:(NSString *)aTaskIdentifier
{
    [self cancelTask:aTaskIdentifier shouldRemove:NO];
}

- (void)cancelTaskAndRemove:(NSString *)aTaskIdentifier
{
    [self cancelTask:aTaskIdentifier shouldRemove:YES];
}

- (void)cancelTask:(NSString *)aTaskIdentifier shouldRemove:(BOOL)remove
{
    
    dispatch_async(_gjcfFileUploadManagerOperationQueue, ^{
        
        [self.taskSessionArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            GJCFFileUploadTask *destTask = self.taskArray[idx];
            
            if ([destTask.uniqueIdentifier isEqualToString:aTaskIdentifier]) {
                HYBURLSessionTask *session = self.taskSessionArray[idx];
                [session cancel];
                
                *stop = YES;
            }
        }];
        
        
        /* Update the task status */
        [self updateTask:aTaskIdentifier withState:GJFileUploadStateCancel];
        
        if (remove) {
            
            /* remove task */
            for (GJCFFileUploadTask *task in self.taskArray) {
                
                if ([task.uniqueIdentifier isEqual:aTaskIdentifier]) {
                    
                    [self.taskArray removeObject:task];
                    
                    break;
                }
            }
            
        }
        
    });
    
}

- (void)removeTask:(GJCFFileUploadTask *)aTask
{
    [self cancelTaskAndRemove:aTask.uniqueIdentifier];
}

- (void)cancelAllExcutingTask
{
    [self.taskArray enumerateObjectsUsingBlock:^(GJCFFileUploadTask *task, NSUInteger idx, BOOL *stop) {
        
        if (task.uploadState == GJFileUploadStateUploading) {
            
            [self cancelTaskOnly:task.uniqueIdentifier];
            
            *stop = YES;
        }
    }];
}

- (void)removeAllTask
{
    [self.taskArray enumerateObjectsUsingBlock:^(GJCFFileUploadTask *task, NSUInteger idx, BOOL *stop) {
        
        [self cancelTaskAndRemove:task.uniqueIdentifier];
        
    }];
}

- (void)removeAllFaildTask
{
    [self.taskArray enumerateObjectsUsingBlock:^(GJCFFileUploadTask *task, NSUInteger idx, BOOL *stop) {
        
        if (task.uploadState == GJFileUploadStateHadFaild) {
            
            [self cancelTaskAndRemove:task.uniqueIdentifier];
            
        }
        
    }];
}

- (void)tryDoTaskByUniqueIdentifier:(NSString*)uniqueIdentifier
{
    [self.taskArray enumerateObjectsUsingBlock:^(GJCFFileUploadTask *task, NSUInteger idx, BOOL *stop) {
        
        if (task.uploadState == GJFileUploadStateHadFaild && [task.uniqueIdentifier isEqualToString:uniqueIdentifier]) {
            
            [self addTask:task];
        }
        
    }];
}

- (void)tryDoAllUnSuccessTask
{
    [self.taskArray enumerateObjectsUsingBlock:^(GJCFFileUploadTask *task, NSUInteger idx, BOOL *stop) {
        
        if (task.uploadState == GJFileUploadStateHadFaild) {
            
            [self addTask:task];
        }
    }];
}

#pragma mark - observer
+ (NSString*)uniqueKeyForObserver:(NSObject*)observer
{
    return [NSString stringWithFormat:@"%@_%lu",kGJCFFileUploadManagerObserverUniqueIdentifier,(unsigned long)[observer hash]];
}

/* Constructs a successful state block for an observation object */
- (void)setCompletionBlock:(GJCFFileUploadManagerTaskCompletionBlock)completionBlock forObserver:(NSObject*)observer
{
    if (!observer) {
        return;
    }
    NSString *observerActionInfoKey = [GJCFFileUploadManager uniqueKeyForObserver:observer];
    self.currentForegroundObserverUniqueIdenfier = observerActionInfoKey;
    
    NSLog(@"completionBlock %@",observerActionInfoKey);
    
    if (![self.observerActionDict objectForKey:observerActionInfoKey]) {
        
        NSMutableDictionary *observerInfo = [NSMutableDictionary dictionary];
        [observerInfo setObject:completionBlock forKey:kGJCFFileUploadManagerCompletionBlockKey];
        
        [self.observerActionDict setObject:observerInfo forKey:observerActionInfoKey];
        return;
    }
    
    NSMutableDictionary *existActionDict = [self.observerActionDict objectForKey:observerActionInfoKey];
    [existActionDict setObject:completionBlock forKey:kGJCFFileUploadManagerCompletionBlockKey];
    
}

/* Create a progress view block for an observation object */
- (void)setProgressBlock:(GJCFFileUploadManagerUpdateTaskProgressBlock)progressBlock forObserver:(NSObject*)observer
{
    if (!observer) {
        return;
    }
    NSString *observerActionInfoKey = [GJCFFileUploadManager uniqueKeyForObserver:observer];
    self.currentForegroundObserverUniqueIdenfier = observerActionInfoKey;
    NSLog(@"progressBlock %@",observerActionInfoKey);
    
    if (![self.observerActionDict objectForKey:observerActionInfoKey]) {
        
        NSMutableDictionary *observerInfo = [NSMutableDictionary dictionary];
        [observerInfo setObject:progressBlock forKey:kGJCFFileUploadManagerProgressBlockKey];
        
        [self.observerActionDict setObject:observerInfo forKey:observerActionInfoKey];
        return;
    }
    
    NSMutableDictionary *existActionDict = [self.observerActionDict objectForKey:observerActionInfoKey];
    [existActionDict setObject:progressBlock forKey:kGJCFFileUploadManagerProgressBlockKey];
}

/* Creates a failure watch state block for an observation object */
- (void)setFaildBlock:(GJCFFileUploadManagerTaskFaildBlock)faildBlock forObserver:(NSObject*)observer
{
    if (!observer) {
        return;
    }
    NSString *observerActionInfoKey = [GJCFFileUploadManager uniqueKeyForObserver:observer];
    self.currentForegroundObserverUniqueIdenfier = observerActionInfoKey;
    NSLog(@"faildBlock %@",observerActionInfoKey);
    
    if (![self.observerActionDict objectForKey:observerActionInfoKey]) {
        
        NSMutableDictionary *observerInfo = [NSMutableDictionary dictionary];
        [observerInfo setObject:faildBlock forKey:kGJCFFileUploadManagerFaildBlockKey];
        
        [self.observerActionDict setObject:observerInfo forKey:observerActionInfoKey];
        return;
    }
    
    NSMutableDictionary *existActionDict = [self.observerActionDict objectForKey:observerActionInfoKey];
    [existActionDict setObject:faildBlock forKey:kGJCFFileUploadManagerFaildBlockKey];
}

- (void)clearCurrentObserveBlocks
{
    /* The foreground set the block to clear */
    self.completionBlock = nil;
    self.faildBlock = nil;
    self.progressBlock = nil;
    
    if (self.currentForegroundObserverUniqueIdenfier) {
        [self.observerActionDict removeObjectForKey:self.currentForegroundObserverUniqueIdenfier];
    }
    
    self.currentForegroundObserverUniqueIdenfier = nil;
    
}

/* 清除某个观察者的block引用 */
- (void)clearBlockForObserver:(NSObject*)observer
{
    if (self.currentForegroundObserverUniqueIdenfier) {
        /* Clear the block reference of an observer */
        self.completionBlock = nil;
        self.faildBlock = nil;
        self.progressBlock = nil;
    }
    
    if (!observer) {
        return;
    }
    
    NSString *observerActionInfoKey = [GJCFFileUploadManager uniqueKeyForObserver:observer];
    if (observerActionInfoKey) {
        [self.observerActionDict removeObjectForKey:observerActionInfoKey];
    }
    
}



#pragma mark - send message
- (void)sendMessagePost:(MMMessage *)message task:(GJCFFileUploadTask *)task{
    
    if (task.msgType == GJGCChatFriendTalkTypePrivate) {
        [[IMService instance] asyncSendMessageMessage:message onQueue:nil completion:^(MMMessage *messageInfo,NSError *error) {
            
            if (!messageInfo) {
                return;
            }
            if (messageInfo.type == 12) {
                
                DDLogInfo(@"Read receipt of the message of success！！！");
                
                return;
            }
            ChatMessageInfo *chatMessage = [[MessageDBManager sharedManager] getMessageInfoByMessageid:message.message_id messageOwer:message.publicKey];
            chatMessage.message = messageInfo;
            chatMessage.sendstatus = messageInfo.sendstatus;
            
            [[MessageDBManager sharedManager] updataMessage:chatMessage];
            if (messageInfo.sendstatus == GJGCChatFriendSendMessageStatusSuccess) {
                
            }
        } onQueue:nil];
        
    } else if (task.msgType == GJGCChatFriendTalkTypeGroup){
        [[IMService instance] asyncSendGroupMessage:message withGroupEckhKey:@"" onQueue:nil completion:^(MMMessage *messageInfo, NSError *error) {
            
            if (!messageInfo) {
                return;
            }
            
            ChatMessageInfo *chatMessage = [[MessageDBManager sharedManager] getMessageInfoByMessageid:message.message_id messageOwer:message.message_id];
            chatMessage.message = messageInfo;
            chatMessage.sendstatus = messageInfo.sendstatus;
            
            [[MessageDBManager sharedManager] updataMessage:chatMessage];
            if (messageInfo.sendstatus == GJGCChatFriendSendMessageStatusSuccess) {
                
            }
        } onQueue:nil];
    } else if (task.msgType == GJGCChatFriendTalkTypePostSystem){
        [[IMService instance] asyncSendSystemMessage:message completion:^(MMMessage *messageInfo, NSError *error) {
            if (!messageInfo) {
                return;
            }
            //update db status 
            [GCDQueue executeInBackgroundPriorityGlobalQueue:^{
                
                ChatMessageInfo *chatMessage = [[MessageDBManager sharedManager] getMessageInfoByMessageid:message.message_id messageOwer:message.message_id];
                chatMessage.message = messageInfo;
                chatMessage.sendstatus = messageInfo.sendstatus;
                
                [[MessageDBManager sharedManager] updataMessage:chatMessage];
                
                if (messageInfo.sendstatus == GJGCChatFriendSendMessageStatusSuccess) {
                    
                }
            }];
        }];
    }
}

- (void)setCurrentForegroundObserverUniqueIdenfier:(NSString *)currentForegroundObserverUniqueIdenfier{
    _currentForegroundObserverUniqueIdenfier = currentForegroundObserverUniqueIdenfier;
    NSLog(@"_currentForegroundObserverUniqueIdenfier%@",_currentForegroundObserverUniqueIdenfier);
}

@end

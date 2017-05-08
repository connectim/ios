//
//  GJCFAudioModel.h
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-16.
//  Copyright (c) 2014年 Connect. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GJCFAudioModel : NSObject

@property (nonatomic ,copy) NSString *message_id;
@property (nonatomic,readonly)NSString *uniqueIdentifier;
@property (nonatomic,assign)NSTimeInterval duration;
@property (nonatomic ,copy) NSString *tempEncodeFilePath;
@property (nonatomic ,copy) NSString *localAMRStorePath;

/* The file is at the remote address of the server */
@property (nonatomic,strong)NSString *remotePath;

@property (nonatomic ,copy) NSString *localStorePath;

/* Limit the recording time */
@property (nonatomic,assign)NSTimeInterval limitRecordDuration;

/* Limit the duration of play */
@property (nonatomic,assign)NSTimeInterval limitPlayDuration;

/* The name of the form to be simulated when the file is simulated by uploading the form */
@property (nonatomic,strong)NSString *uploadFormName;

/* file name */
@property (nonatomic,strong)NSString *fileName;

/* Temporary transcoding file name */
@property (nonatomic,strong)NSString *tempWamFilePath;

@property (nonatomic ,copy) NSString *downloadEncodeCachePath;

/* Wav file size */
@property (nonatomic,readonly)CGFloat dataSize;

/* User-defined information */
@property (nonatomic,strong)NSDictionary *userInfo;

/* File extension */
@property (nonatomic,strong)NSString *extensionName;

/* Temporary transcoding file extension */
@property (nonatomic,strong)NSString *tempEncodeFileExtensionName;

/* Multimedia file type */
@property (nonatomic,strong)NSString *mimeType;

/* Specify the subcache directory under the main cache directory */
@property (nonatomic,strong)NSString *subCacheDirectory;

/* Whether to upload the local transcoding format file, the default is YES, because the server needs to be converted after the audio file */
@property (nonatomic,assign)BOOL isUploadTempEncodeFile;

/* Whether the need to store a sub-conversion to the WAV encoding format of the file, the default is YES, because now our main business needs, currently only support AMR to WAV */
@property (nonatomic,assign)BOOL isNeedConvertEncodeToSave;

/* Whether to download the end of the play*/
@property (nonatomic,assign)BOOL shouldPlayWhileFinishDownload;

/* When the transcoding cost to the iOS support format, whether to delete the temporary encoding file */
@property (nonatomic,assign)BOOL isDeleteWhileFinishConvertToLocalFormate;

/* When the temporary transcoding file is uploaded, whether the temporary encoding file is deleted */
@property (nonatomic,assign)BOOL isDeleteWhileUploadFinish;

/* Whether the audio file has been uploaded */
@property (nonatomic,assign)BOOL isBeenUploaded;

/* Delete the temporary encoding file */
- (void)deleteTempEncodeFile;

/* Delete the local wav format file */
- (void)deleteWavFile;


@end

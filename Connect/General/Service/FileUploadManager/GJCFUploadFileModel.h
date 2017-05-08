//
//  GJCFUploadFileModel.h
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-12.
//  Copyright (c) 2014年 ConnectSoft.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

/* Upload file object */
@interface GJCFUploadFileModel : NSObject<NSCoding>

/* file name */
@property (nonatomic,strong)NSString *fileName;

/* Binary data of the file */
@property (nonatomic,strong)NSData   *fileData;

/* The multimedia type of the file */
@property (nonatomic,strong)NSString *mimeType;

/* The name of the form required to simulate the form submission */
@property (nonatomic,strong)NSString *formName;

/* If the picture can be used when the preservation of the width */
@property (nonatomic,assign)CGFloat  imageWidth;

/* if the picture can be used when the preservation of height */
@property (nonatomic,assign)CGFloat  imageHeight;

/* Used to save the local path address of the file to be uploaded */
@property (nonatomic,strong)NSString *localStorePath;

/* To upload the Assets file */
@property (nonatomic,strong)ALAsset *contentAsset;

/* Whether it is uploaded Assets file */
@property (nonatomic,assign)BOOL isUploadAsset;

/* Whether to upload the original file of the Asset file, upload the original image by default */
@property (nonatomic,assign)BOOL isUploadAssetOriginImage;

/* Whether to upload a picture */
@property (nonatomic,assign)BOOL isUploadImage;

/* Whether the uploaded image is archived, the default is not archived*/
@property (nonatomic,assign)BOOL isUploadImageHasBeenArchieved;

/* Whether to upload voice */
@property (nonatomic,assign)BOOL isUploadAudio;

/* If it is time to use the voice can be used to save voice length */
@property (nonatomic,assign)NSTimeInterval audioDuration;

/*The user wants to carry the custom information */
@property (nonatomic,strong)NSDictionary *userInfo;

// ===================== It is recommended to upload files using the path to be uploaded ============= //

/* Convenient object generation */
+ (GJCFUploadFileModel*)fileModelWithFileName:(NSString*)fileName withFilePath:(NSString*)filePath withFormName:(NSString*)formName;


+ (GJCFUploadFileModel*)fileModelWithData:(NSData *)uplodata;

+ (GJCFUploadFileModel*)fileModelWithFileName:(NSString*)fileName withFilePath:(NSString*)filePath withFormName:(NSString*)formName withMimeType:(NSString*)mimeType;
+ (GJCFUploadFileModel*)fileModelWithFileName:(NSString*)fileName withFileData:(NSData*)fileData withFormName:(NSString*)formName;
+ (GJCFUploadFileModel*)fileModelWithFileName:(NSString*)fileName withFileData:(NSData*)fileData withFormName:(NSString*)formName withMimeType:(NSString*)mimeType;


+ (NSString*)mimeTypeWithFileName:(NSString*)fileName;

/* Whether it is in compliance with the upload rules */
- (BOOL)isValidateForUpload;

@end

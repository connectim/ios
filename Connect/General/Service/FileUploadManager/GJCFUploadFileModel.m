//
//  GJCFUploadFileModel.m
//  GJCommonFoundation
//
//  Created by KivenLin on 14-9-12.
//  Copyright (c) 2014年 Connect.com. All rights reserved.
//

#import "GJCFUploadFileModel.h"

@implementation GJCFUploadFileModel

- (id)init
{
    if (self = [super init]) {
        
        /* Upload the original image by default */
        self.isUploadAssetOriginImage = YES;
        
        /* The default upload pictures are not archived */
        self.isUploadImageHasBeenArchieved = NO;
    }
    return self;
}
/* Convenient object generation */
+ (GJCFUploadFileModel*)fileModelWithFileName:(NSString*)fileName withFilePath:(NSString*)filePath withFormName:(NSString*)formName
{
    return [GJCFUploadFileModel fileModelWithFileName:fileName withFilePath:filePath withFormName:formName withMimeType:nil];
}

/* Convenient object generation */
+ (GJCFUploadFileModel*)fileModelWithFileName:(NSString*)fileName withFilePath:(NSString*)filePath withFormName:(NSString*)formName withMimeType:(NSString*)mimeType
{
    GJCFUploadFileModel *fileModel = [[self alloc]init];
    fileModel.fileName = fileName;
    fileModel.localStorePath = filePath;
    fileModel.formName = formName;
    if (!mimeType) {
        fileModel.mimeType = [GJCFUploadFileModel mimeTypeWithFileName:fileName];
    }else{
        fileModel.mimeType = mimeType;
    }
    
    return fileModel;
}

+ (GJCFUploadFileModel*)fileModelWithFileName:(NSString*)fileName withFileData:(NSData*)fileData withFormName:(NSString*)formName
{
    return [GJCFUploadFileModel fileModelWithFileName:fileName withFileData:fileData withFormName:formName withMimeType:nil];
}

+ (GJCFUploadFileModel*)fileModelWithData:(NSData *)uplodata{
    GJCFUploadFileModel *fileModel = [[self alloc]init];
    fileModel.fileData = uplodata;
    return fileModel;
}

+ (GJCFUploadFileModel*)fileModelWithFileName:(NSString*)fileName withFileData:(NSData*)fileData withFormName:(NSString*)formName withMimeType:(NSString*)mimeType
{
    GJCFUploadFileModel *fileModel = [[self alloc]init];
    fileModel.fileName = fileName;
    fileModel.fileData = fileData;
    fileModel.formName = formName;
    if (!mimeType) {
        fileModel.mimeType = [GJCFUploadFileModel mimeTypeWithFileName:fileName];
    }else{
        fileModel.mimeType = mimeType;
    }
    
    return fileModel;
}

+ (NSString*)mimeTypeWithFileName:(NSString*)fileName
{
    NSString *fileExtension = [[fileName componentsSeparatedByString:@"."]lastObject];
    NSLog(@"fileExtension:%@",fileExtension);
    if (!fileExtension) {
        return nil;
    }
    
    NSDictionary *typeMapDict = @{
                                  @"png": @"image/png",
                                  
                                  @"PNG": @"image/png",
                                  
                                  @"jpg": @"image/jpeg",
                                  
                                  @"JPG": @"image/jpeg",
                                  
                                  @"jpeg": @"image/jpeg",

                                  @"JPEG": @"image/jpeg",
                                  
                                  @"GIF": @"image/jpeg",
                                  
                                  @"gif": @"image/jpeg",

                                  @"mp3": @"audio/mp3",
                                  
                                  @"MP3": @"audio/mp3",
                                  
                                  @"amr": @"audio/amr",
                                  
                                  @"AMR": @"audio/amr",
                                  
                                  };
    
    return [typeMapDict objectForKey:fileExtension];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"文件名:%@ 文件类型:%@ 表单名字:%@",self.fileName,self.mimeType,self.formName];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init]) {
        
        self.fileName = [aDecoder decodeObjectForKey:@"fileName"];
        
        self.fileData = [aDecoder decodeObjectForKey:@"fileData"];
        
        self.mimeType = [aDecoder decodeObjectForKey:@"mimeType"];
        
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.fileName forKey:@"fileName"];
    
    [aCoder encodeObject:self.fileData forKey:@"fileData"];

    [aCoder encodeObject:self.mimeType forKey:@"mimeType"];

}

/* Whether it is in compliance with the upload rules */
- (BOOL)isValidateForUpload
{
    /* Directly upload file binary data */
    if (self.fileData) {
        return YES;
    }
    
    return NO;
}

@end

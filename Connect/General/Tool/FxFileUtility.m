//
//  FxFileUtility.m
//  FxCore
//
//  Created by hejinbo on 12-2-22.
//  Copyright (c) 2012年 Hejinbo. All rights reserved.
//

#import "FxFileUtility.h"
#import <sys/stat.h>
#import <dirent.h>
 
@implementation FxFileUtility

+ (BOOL)isFileExist:(NSString *)filePath
{
    NSFileManager *fm = [NSFileManager defaultManager];
    return [fm fileExistsAtPath:filePath];
}

+ (BOOL)createPath:(NSString *)filePath
{
    if ([FxFileUtility isFileExist:filePath]) {
        return YES;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    
    [fm createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:&error];
    if (error!=nil) {
        DDLogError([error localizedDescription]);
        return NO;
    }
    
    return YES;
}

+ (BOOL)renameFile:(NSString *)filePath toFile:(NSString *)toPath
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    if ([FxFileUtility isFileExist:toPath]) {
        [fm removeItemAtPath:filePath error:&error];
        if (error!=nil) {
            DDLogError([error localizedDescription]);
        }
    }
    
    [fm moveItemAtPath:filePath toPath:toPath error:&error];
    if (error != nil) {
        DDLogError([error localizedDescription]);
        return NO;
    }
    
    return YES;
}

+ (BOOL)deleteFile:(NSString *)filePath
{
    if (![FxFileUtility isFileExist:filePath]) {
        return YES;
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    
    [fm removeItemAtPath:filePath error:&error];
    if (error!=nil) {
        DDLogError([error localizedDescription]);
        return NO;
    }
    
    return YES;
}
 
+ (BOOL)copyFromPath:(NSString *)fromPath
              toPath:(NSString *)toPath 
           isReplace:(BOOL)isReplace
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    
    if ([FxFileUtility isFileExist:toPath] && isReplace) {
        [FxFileUtility deleteFile:toPath];
    }
    
    [fm copyItemAtPath:fromPath toPath:toPath error:&error];
    if (error!=nil) {
        DDLogError([error localizedDescription]);
        return NO;
    }
    
    return YES;
}

+ (BOOL)copyContentsFromPath:(NSString *)fromPath
                      toPath:(NSString *)toPath 
                   isReplace:(BOOL)isReplace
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;

    NSArray *contents = [fm contentsOfDirectoryAtPath:fromPath error:&error];
    if (error != nil) {
        DDLogError([error localizedDescription]);
    }
    
    NSString *toFilePath = nil, *fromFilePath = nil;
    for (NSString *path in contents) {
        
        toFilePath = [toPath stringByAppendingPathComponent:path];
        fromFilePath = [fromPath stringByAppendingPathComponent:path];
        
        if ([FxFileUtility isFileExist:toFilePath] && isReplace) {
            [FxFileUtility deleteFile:toFilePath];
        }
        
        [fm copyItemAtPath:fromFilePath toPath:toFilePath error:&error];
        if (error != nil) {
            DDLogError([error localizedDescription]);
        }
    }
    
    return YES;
}

+ (BOOL)moveFromPath:(NSString *)fromPath
              toPath:(NSString *)toPath 
           isReplace:(BOOL)isReplace
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    
    if ([FxFileUtility isFileExist:toPath] && isReplace) {
        [FxFileUtility deleteFile:toPath];
    }
    
    [fm moveItemAtPath:fromPath toPath:toPath error:&error];
    if (error!=nil) {
        DDLogError([error localizedDescription]);
        return NO;
    }
    
    return YES;
}


+ (BOOL)moveContentsFromPath:(NSString *)fromPath
                      toPath:(NSString *)toPath 
                   isReplace:(BOOL)isReplace
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    
    NSArray *contents = [fm contentsOfDirectoryAtPath:fromPath error:&error];
    if (error != nil) {
        DDLogError([error localizedDescription]);
    }
    
    NSString *toFilePath = nil, *fromFilePath = nil;
    for (NSString *path in contents) {
        
        toFilePath = [toPath stringByAppendingPathComponent:path];
        fromFilePath = [fromPath stringByAppendingPathComponent:path];
        
        if ([FxFileUtility isFileExist:toFilePath] && isReplace) {
            [FxFileUtility deleteFile:toFilePath];
        }
        
        [fm moveItemAtPath:fromFilePath toPath:toFilePath error:&error];
        if (error != nil) {
            DDLogError([error localizedDescription]);
        }
    }
    
    return YES;
}

+ (double)calculteFileSzie:(NSString *)filePath
{
    double fSize = 0.0f;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:filePath error:nil];
    
    if (dirContents == nil) {
        NSDictionary* dirAttr = [fm attributesOfItemAtPath:filePath error: nil];
        fSize += [[dirAttr objectForKey:NSFileSize] floatValue];
    }
    else {
        for (NSString *dirName in dirContents) {
            fSize +=  [FxFileUtility calculteFileSzie:[filePath stringByAppendingPathComponent:dirName]] ;
        }
    }
    
    return fSize;
}

+ (double)calculteFileSizeAtPath:(const char*)folderPath
{
    double folderSize = 0;
    DIR* dir = opendir(folderPath);
    
    if (dir != NULL) { 
        struct dirent* child;
        struct stat st;
        NSInteger folderPathLength = 0;
        char childPath[1024] = {0};
        
        while ((child = readdir(dir))!=NULL) {
            // Ignore directory.
            if (child->d_type == DT_DIR && (child->d_name[0] == '.' && child->d_name[1] == 0)) { 
                continue;
            }
            
            // Ignore directory.
            if (child->d_type == DT_DIR && (child->d_name[0] == '.' && child->d_name[1] == '.' && child->d_name[2] == 0)) 
                continue;
            
            folderPathLength = strlen(folderPath);
            stpcpy(childPath, folderPath);
            
            if (folderPath[folderPathLength-1] != '/'){
                childPath[folderPathLength] = '/';
                folderPathLength++;
            }
            
            stpcpy(childPath+folderPathLength, child->d_name);
            childPath[folderPathLength + child->d_namlen] = 0;
            
            // Recursively calculate subdirectories
            if (child->d_type == DT_DIR) { 
                folderSize += [FxFileUtility calculteFileSizeAtPath:childPath]; 
                // The directory itself occupied by the space also added
                if(lstat(childPath, &st) == 0) 
                    folderSize += st.st_size;
            }
            else if (child->d_type == DT_REG || child->d_type == DT_LNK){ // file or link
                if(lstat(childPath, &st) == 0) {
                    folderSize += st.st_size;
                }
            }
        }
    
    }
         
    closedir(dir);
    return folderSize;
}

+ (double)calculteFileSzieEx:(NSString *)filePath
{
    if (![FxFileUtility isFileExist:filePath]) {
        return 0.0f;
    }
    
    return [FxFileUtility calculteFileSizeAtPath:[filePath cStringUsingEncoding:NSUTF8StringEncoding]];
}

+ (void)deleteFiles:(NSArray *)fileNames inPath:(NSString *)path
{
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *dirContents = [fm contentsOfDirectoryAtPath:path error:nil];
    
    if (dirContents == nil) {
        if ([fileNames containsObject:[path lastPathComponent]]) {
            [FxFileUtility deleteFile:path];
        }
    }
    else {
        for (NSString *dirName in dirContents) {
            if ([fileNames containsObject:dirName]) {
                [FxFileUtility deleteFile:[path stringByAppendingPathComponent:dirName]];
            }
            else {
                [FxFileUtility deleteFiles:fileNames inPath: [path stringByAppendingPathComponent:dirName]];
            }
        }
    }
}

@end

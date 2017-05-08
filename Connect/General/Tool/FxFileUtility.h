//
//  FxFileUtility.h
//  FxCore
//
//  Created by hejinbo on 12-2-22.
//  Copyright (c) 2012年 Hejinbo. All rights reserved.
//

@interface FxFileUtility : NSObject {

}

/**
   * Function: to determine whether the file or folder already exists
   * Parameters:
   FilePath: the full path of a file or folder
   *return:
   TRUE: already exists
   FALSE: does not exist
 **/
+ (BOOL)isFileExist:(NSString *)filePath;

/**
   * Function: Create directory
   * Parameters:
   FilePath: the full path of the file or folder; it is created automatically if it does not exist
   *return:
   TRUE: already exists or does not exist to create
   FALSE: Failed to create
 **/
+ (BOOL)createPath:(NSString *)filePath;

/**
   * Function: Rename the file
   TRUE: success
   FALSE: Failed to create
 **/
+ (BOOL)renameFile:(NSString *)filePath toFile:(NSString *)toPath;

/**
   * Function: Delete file or folder
   * Parameters:
   FilePath: the full path of a file or folder
   *return:
   TRUE: success
   FALSE: failed
 **/
+ (BOOL)deleteFile:(NSString *)filePath;

/**
   * Function: Copy files or folders from one directory to another
   * Parameters:
   FromPath: raw directory, such as / library / 11
   ToPath: target directory, such as / Documents / 11
   IsReplace: if it already exists, is it replaced?
   *return:
   TRUE: success
   FALSE: failed
 **/
+ (BOOL)copyFromPath:(NSString *)fromPath
              toPath:(NSString *)toPath 
           isReplace:(BOOL)isReplace;

/**
   * Function: copy the contents of the folder to another directory,
   * Parameters:
   FromPath: the original directory, such as / library / 11, which has 1.jpg
   ToPath: target directory, such as / Documents /, after the success of the implementation, / Documents / 1.jpg
   IsReplace: if it already exists, is it replaced?
   *return:
   TRUE: success
   FALSE: failed
 **/
+ (BOOL)copyContentsFromPath:(NSString *)fromPath
              toPath:(NSString *)toPath 
           isReplace:(BOOL)isReplace;


/**
   * Function: Move a file or folder from one directory to another
   * Parameters:
   FromPath: raw directory, such as / library / 11
   ToPath: target directory, such as / Documents / 11
   IsReplace: if it already exists, is it replaced?
   *return:
   TRUE: success
   FALSE: failed
 **/
+ (BOOL)moveFromPath:(NSString *)fromPath
              toPath:(NSString *)toPath 
           isReplace:(BOOL)isReplace;

/**
   * Function: Move the contents of the folder to another directory,
   * Parameters:
   FromPath: the original directory, such as / library / 11, which has 1.jpg
   ToPath: target directory, such as / Documents /, after the success of the implementation, / Documents / 1.jpg
   IsReplace: if it already exists, is it replaced?
   *return:
   TRUE: success
   FALSE: failed
 **/
+ (BOOL)moveContentsFromPath:(NSString *)fromPath
                      toPath:(NSString *)toPath 
                   isReplace:(BOOL)isReplace;

/**
   * Function: Calculate a file or folder size,
   * Parameters:
   FilePath: file or folder path
   * Returns: the number of bytes occupied by a file or folder
 **/
+ (double)calculteFileSzie:(NSString *)filePath;

/**
   * Function: Calculate the size of a folder, the method is more efficient
   * Parameters:
   FilePath: file or folder path
   * Returns: the number of bytes occupied by a file or folder
 **/
+ (double)calculteFileSzieEx:(NSString *)filePath;


/**
 * Function: Recursively delete a specified file in a directory
 **/
+ (void)deleteFiles:(NSArray *)fileNames inPath:(NSString *)path;
@end

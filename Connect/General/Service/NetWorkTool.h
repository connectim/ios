//
//  NetWorkTool.h
//  Connect
//
//  Created by MoHuilin on 16/5/17.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AFHTTPSessionManager.h"

// Project packaging on the line will not print the log, so can be assured.。
#ifdef DEBUG
#define HYBAppLog(s, ... ) NSLog( @"[%@ in line %d] ===============>%@", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define HYBAppLog(s, ... )
#endif

/*!
   * @author Huang Yi standard, 16-01-08 14:01:26
   *
   * Download progress
   *
   * @param bytesRead has been downloaded in size
   * @param totalBytesRead The total size of the file
   * @param totalBytesExpectedToRead how much need to download
 */
typedef void (^HYBDownloadProgress)(int64_t bytesRead,
                                    int64_t totalBytesRead);

typedef HYBDownloadProgress HYBGetProgress;
typedef HYBDownloadProgress HYBPostProgress;

/*!
   * @author Huang Yi standard, 16-01-08 14:01:26
   *
   * Upload progress
   *
   * @param bytesWritten already uploaded size
   * @param totalBytesWritten total upload size
 */
typedef void (^HYBUploadProgress)(int64_t bytesWritten,
                                  int64_t totalBytesWritten);

typedef NS_ENUM(NSUInteger, HYBResponseType) {
    kHYBResponseTypeJSON = 1,
    kHYBResponseTypeXML  = 2,
    // In special circumstances, a conversion server can not be identified, the default will try to convert to JSON, if you need to change their own failure
    kHYBResponseTypeData = 3
};

typedef NS_ENUM(NSUInteger, HYBRequestType) {
    kHYBRequestTypeJSON = 1,
    kHYBRequestTypePlainText  = 2
};

typedef NS_ENUM(NSInteger, HYBNetworkStatus) {
    kHYBNetworkStatusUnknown          = -1,// Unknown network
    kHYBNetworkStatusNotReachable     = 0,// The network is not connected
    kHYBNetworkStatusReachableViaWWAN = 1,// 2，3，4G network
    kHYBNetworkStatusReachableViaWiFi = 2,// WIFI network
};

@class NSURLSessionTask;

// Do not use NSURLSessionDataTask directly to reduce reliance on third parties
// The type returned by all interfaces is the base class NSURLSessionTask, to receive the return value//And processing, please convert to the corresponding sub-type
typedef NSURLSessionTask HYBURLSessionTask;
typedef void(^HYBResponseSuccess)(id response);
typedef void(^HYBResponseFail)(NSError *error);

/*!
 *  @author huangyibiao, 15-11-15 13:11:31
 *  Network layer encapsulation class based on AFNetworking.
 *
 *  @note here only provide public api
 */
@interface NetWorkTool : NSObject

/*!
   * @author Huang Yi standard, 15-11-15 13:11:45
   *
   * Used to specify the base url for the network request interface, such as:
   * Http://henishuo.com or http://101.200.209.244
   * Normally set up once in the AppDelegate. If the interface has a source
   * On multiple servers, you can call updates
   *
   * @param baseUrl The base url of the web interface
 */
+ (void)updateBaseUrl:(NSString *)baseUrl;
+ (NSString *)baseUrl;

/**
 * Set the request timeout time, the default is 60 seconds
 *
 * @param timeout timeout
 */
+ (void)setTimeout:(NSTimeInterval)timeout;

/**
 * Whether to extract data from the local when checking for network anomalies. Default is NO. Once set to YES, when setting the refresh cache,
 * If the network exception also reads data from the cache. Similarly, if the set timeout does not call back, the same will be in the network when the callback, unless
 * No data available locally!
 *
 *	@param shouldObtain	YES/NO
 */
+ (void)obtainDataFromLocalWhenNetworkUnconnected:(BOOL)shouldObtain;

/**
   * @author Huang Yi standard
   *
   * By default, only the GET request data is buffered and the POST request is not cached. If you want to cache POST data, you need to manually call the settings
   * Valid for JSON type data, for PLIST, XML is not sure!
   *
   * @param isCacheGet defaults to YES
   * @param shouldCachePost defaults to NO
 */
+ (void)cacheGetRequest:(BOOL)isCacheGet shoulCachePost:(BOOL)shouldCachePost;

/**
   * @author Huang Yi standard
   *
   * Get cache total size / bytes
   *
   * @return cache size
 */
+ (unsigned long long)totalCacheSize;

/**
   * @author Huang Yi standard
   *
   *	clear cache
 */
+ (void)clearCaches;

/*!
   * @author Huang Yi standard, 15-11-15 14:11:40
   *
   * Turn on or off the interface to print information
   *
   * @param isDebug development period, the best open, the default is NO
 */
+ (void)enableInterfaceDebug:(BOOL)isDebug;

/*!
   * @author Huang Yi standard, 15-12-25 15:12:45
   *
   * Configuration request format, the default is JSON. If you need to pass XML or PLIST, please configure the global configuration
   *
   * @param requestType request format, the default is JSON
   * @param responseType response format, the default is JSO,
   * @param shouldAutoEncode YES or NO, the default is NO, whether the automatic encode url
   * @param shouldCallbackOnCancelRequest when cancel the request, whether to callback, the default is YES
 */
+ (void)configRequestType:(HYBRequestType)requestType
             responseType:(HYBResponseType)responseType
      shouldAutoEncodeUrl:(BOOL)shouldAutoEncode
  callbackOnCancelRequest:(BOOL)shouldCallbackOnCancelRequest;

/*!
   * @author Huang Yi standard, 15-11-16 13:11:41
   *
   * Configuration of the public request header, can only be called once, usually on the application when the configuration can be activated
   *
   * @param httpHeaders only need to be fixed with the server to set the parameters can be
 */
+ (void)configCommonHttpHeaders:(NSDictionary *)httpHeaders;

/**
   * @author Huang Yi standard
   *
   * Cancel all requests
 */
+ (void)cancelAllRequest;
/**
   * @author Huang Yi standard
   *
   * Cancel a request. If you want to cancel a request, it is best to refer to the interface to return to the HYBURLSessionTask object,
   * Then call the object's cancel method. If you do not want to reference the object, here is an additional way to achieve the cancellation of a request
   *
   * @param url URL, it can be an absolute URL, it can be path (that is, does not include baseurl)
 */
+ (void)cancelRequestWithURL:(NSString *)url;

/*!
   * @author Huang Yi standard, 15-11-15 13:11:50
   *
   * GET request interface, if not designated baseurl, can pass the full url
   *
   * @param url interface path, such as / path / getArticleList
   * @param refreshCache whether to refresh the cache. Due to the success of the request may also be no data, for business failure, only through manual judgments
   * @ Param params The required splice parameters in the interface, such as @ {category category: @ (12)}
   * @param success The interface successfully requests a callback to the data
   * @param fail interface Request data failed callback
   *
   * @return The returned object has an API that can cancel the request
 */
+ (HYBURLSessionTask *)getWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                          success:(HYBResponseSuccess)success
                             fail:(HYBResponseFail)fail;
// More than one params parameter
+ (HYBURLSessionTask *)getWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                           params:(NSDictionary *)params
                          success:(HYBResponseSuccess)success
                             fail:(HYBResponseFail)fail;
// More with a progress callback
+ (HYBURLSessionTask *)getWithUrl:(NSString *)url
                     refreshCache:(BOOL)refreshCache
                           params:(NSDictionary *)params
                         progress:(HYBGetProgress)progress
                          success:(HYBResponseSuccess)success
                             fail:(HYBResponseFail)fail;

/*!
   * @author Huang Yi standard, 15-11-15 13:11:50
   *
   * POST request interface, if not designated baseurl, can pass the full url
   *
   * @param url interface path, such as / path / getArticleList
   * @param params The required parameters in the interface, such as @ {category category: @ (12)}
   * @param success The interface successfully requests a callback to the data
   * @param fail interface Request data failed callback
   *
   * @return The returned object has an API that can cancel the request
 */
+ (HYBURLSessionTask *)postWithUrl:(NSString *)url
                      refreshCache:(BOOL)refreshCache
                            params:(NSDictionary *)params
                           success:(HYBResponseSuccess)success
                              fail:(HYBResponseFail)fail;
+ (HYBURLSessionTask *)postWithUrl:(NSString *)url
                      refreshCache:(BOOL)refreshCache
                            params:(NSDictionary *)params
                          progress:(HYBPostProgress)progress
                           success:(HYBResponseSuccess)success
                              fail:(HYBResponseFail)fail;
/**
   * @ Volunteer Huang Yi standard, 16-01-31 00:01:40
   *
   * Picture upload interface, if not designated baseurl, can pass the full url
   *
   * @param image image object
   * @param url upload image interface path, such as / path / images /
   * @param filename to the picture from a name, the default for the current date and time, the format is "yyyyMMddHHmmss", suffix `jpg`
   * @param name The name associated with the specified image, which is specified by the person who writes the backend, such as imagefiles
   * @param mimeType defaults to image / jpeg
   * @param parameters
   * @param progress upload progress
   * @param success upload successful callback
   * @param fail upload failed callback
 *
 *	@return
 */
+ (HYBURLSessionTask *)uploadWithImage:(UIImage *)image
                                   url:(NSString *)url
                              filename:(NSString *)filename
                                  name:(NSString *)name
                              mimeType:(NSString *)mimeType
                            parameters:(NSDictionary *)parameters
                              progress:(HYBUploadProgress)progress
                               success:(HYBResponseSuccess)success
                                  fail:(HYBResponseFail)fail;

/**
   * @ Volunteer Huang Yi standard, 16-01-31 00:01:40
   *
   * Picture upload interface, if not designated baseurl, can pass the full url
   *
   * @param image image object
   * @param url upload image interface path, such as / path / images /
   * @param filename to the picture from a name, the default for the current date and time, the format is "yyyyMMddHHmmss", suffix `jpg`
   * @param name The name associated with the specified image, which is specified by the person who writes the backend, such as imagefiles
   * @param mimeType defaults to image / jpeg
   * @param parameters
   * @param progress upload progress
   * @param success upload successful callback
   * @param fail upload failed callback
 *
 *	@return
 */
+ (HYBURLSessionTask *)uploadWithUrl:url
           ConstructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
                          parameters:(NSDictionary *)parameters
                            progress:(HYBUploadProgress)progress
                             success:(HYBResponseSuccess)success
                                fail:(HYBResponseFail)fail;


/**
   * @author Huang Yi standard, 16-01-31 00:01:59
   *
   * Upload file operations
   *
   * @param url upload path
   * @param uploadingFile The path to upload the file
   * @param progress upload progress
   * @param success upload successful callback
   * @param fail upload failed callback
 *
 *	@return
 */
+ (HYBURLSessionTask *)uploadFileWithUrl:(NSString *)url
                           uploadingFile:(NSString *)uploadingFile
                                progress:(HYBUploadProgress)progress
                                 success:(HYBResponseSuccess)success
                                    fail:(HYBResponseFail)fail;


/*!
   * @author Huang Yi standard, 16-01-08 15:01:11
   *
   * download file
   *
   * @param url download URL
   * @param saveToPath to which path to download
   * @param progressBlock download progress
   * @param success after the success of the callback call
   * @param failure download failed after the callback
 */
+ (HYBURLSessionTask *)downloadWithUrl:(NSString *)url
                            saveToPath:(NSString *)saveToPath
                              progress:(HYBDownloadProgress)progressBlock
                               success:(HYBResponseSuccess)success
                               failure:(HYBResponseFail)failure;


@end


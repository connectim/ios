//
//  GJAssetsPickerViewController.m
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-8.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import "GJCFAssetsPickerViewController.h"
#import "GJCFAlbumsViewController.h"

#define kGJPhotoViewControllerCustomKey      @"kGJPhotoViewControllerCustomKey"
#define kGJAlbumsViewControllerCellCustomKey @"kGJAlbumsViewControllerCellCustomKey"
#define kGJAlbumsViewControllerCellCustomHeightKey @"kGJAlbumsViewControllerCellCustomHeightKey"

@interface GJCFAssetsPickerViewController ()<GJCFAlbumsViewControllerDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (nonatomic,strong)GJCFAssetsPickerStyle *customStyle;
@property (nonatomic,strong)GJCFAlbumsViewController *albumsViewController;
@property (nonatomic,strong)NSMutableDictionary *customClassDict;

@end

@implementation GJCFAssetsPickerViewController

#pragma mark - Life cycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.customClassDict = [[NSMutableDictionary alloc]init];
        
        [self initAlbums];
    }
    return self;
}
- (id)init
{
    if (self = [super init]) {
        
        self.customClassDict = [[NSMutableDictionary alloc]init];
        
        [self initAlbums];

    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Whether there is a custom UI
    if (!self.customStyle) {
        
        if (self.pickerDelegate && [self.pickerDelegate respondsToSelector:@selector(pickerViewShouldUseCustomStyle:)]) {
            self.customStyle = [self.pickerDelegate pickerViewShouldUseCustomStyle:self];
        }else{
            self.customStyle = [GJCFAssetsPickerStyle defaultStyle];
        }
        
    }
    
    self.albumsViewController.mutilSelectLimitCount = self.mutilSelectLimitCount;

    // Observe the necessary notice
    [self observeAssetsPickerNotis];
}

#pragma mark - Initialize the album
- (void)initAlbums
{
    self.albumsViewController = [[GJCFAlbumsViewController alloc]init];
    self.albumsViewController.shouldInitSelectedStateAssetArray = self.shouldInitSelectedStateAssetArray;
    self.albumsViewController.delegate = self;
    
    /* Whether there is a custom UI */
    if ([self.customClassDict objectForKey:kGJPhotoViewControllerCustomKey]) {
        [self.albumsViewController registPhotoViewControllerClass:NSClassFromString([self.customClassDict objectForKey:kGJPhotoViewControllerCustomKey])];
    }
    if ([self.customClassDict objectForKey:kGJAlbumsViewControllerCellCustomKey]) {
        NSDictionary *customCellDict = [self.customClassDict objectForKey:kGJAlbumsViewControllerCellCustomKey];
        [self.albumsViewController registAlbumsCustomCellClass:NSClassFromString([customCellDict objectForKey:kGJAlbumsViewControllerCellCustomKey]) withCellHeight:[[customCellDict objectForKey:kGJAlbumsViewControllerCellCustomHeightKey] floatValue]];
    }
    
    [self setViewControllers:@[self.albumsViewController] animated:NO];
}

#pragma mark - GJCFAssetsPickerAlbumsViewController delegate
- (GJCFAssetsPickerStyle*)albumsViewControllerShouldUseCustomStyle:(GJCFAlbumsViewController *)albumsViewController
{
    return self.customStyle;
}

#pragma mark - NSNotification

// Observe all necessary notice
- (void)observeAssetsPickerNotis
{
    /*
     * Watch the GJPhotosViewController more time to select the number of changes in the number of photos
     */
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(observePhotoControllerMutilSelectLimitCountChange:) name:kGJAssetsPickerPhotoControllerDidReachLimitCountNoti object:nil];
    
    /*
     *  Observe the error message
     */
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(observeComeAcrossAnErrorNoti:) name:kGJAssetsPickerComeAcrossAnErrorNoti object:nil];
    
    /*
     *Watch the picture preview message
     */
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(observePhotoControlleRequirePreviewButNoSelectedImages:) name:kGJAssetsPickerRequirePreviewButNoSelectPhotoTipNoti object:nil];
    
    /*
     * View the picture Select the exit message
     */
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(observePickerControllerNeedCancel:) name:kGJAssetsPickerNeedCancelNoti object:nil];
    
    /*
     * View the picture Select the message that has been completed
     */
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(observeChooseMediaDidFinishNoti:) name:kGJAssetsPickerDidFinishChooseMediaNoti object:nil];
}

/*
 * Handles a message when the image selection reaches the limit number
 */
- (void)observePhotoControllerMutilSelectLimitCountChange:(NSNotification*)noti
{
    NSNumber *limitCount = (NSNumber*)noti.object;
    
    if (self.pickerDelegate && [self.pickerDelegate respondsToSelector:@selector(pickerViewController:didReachLimitSelectedCount:)]) {
        [self.pickerDelegate pickerViewController:self didReachLimitSelectedCount:[limitCount intValue]];
    }
}

/*
 * Image wants to preview without picture
 */
- (void)observePhotoControlleRequirePreviewButNoSelectedImages:(NSNotification*)noti
{
    if (self.pickerDelegate && [self.pickerDelegate respondsToSelector:@selector(pickerViewControllerRequirePreviewButNoSelectedImage:)]) {
        [self.pickerDelegate pickerViewControllerRequirePreviewButNoSelectedImage:self];
    }
}

/*
 * Image Select the message that has been completed
 */
- (void)observeChooseMediaDidFinishNoti:(NSNotification*)noti
{
    NSArray *resultArray = (NSArray*)noti.object;
    
    if (resultArray.count > 0) {
        
        if (self.pickerDelegate && [self.pickerDelegate respondsToSelector:@selector(pickerViewController:didFinishChooseMedia:)]) {
            [self.pickerDelegate pickerViewController:self didFinishChooseMedia:resultArray];
        }
        
    }else{
        
        if (self.pickerDelegate && [self.pickerDelegate respondsToSelector:@selector(pickerViewController:didFaildWithErrorMsg:withErrorType:)]) {
            [self.pickerDelegate pickerViewController:self didFaildWithErrorMsg:@"至少选择一张照片" withErrorType:GJAssetsPickerErrorTypePhotoLibarayChooseZeroCountPhoto];
        }
    }

}

/*
 * There was an error message
 */
- (void)observeComeAcrossAnErrorNoti:(NSNotification*)noti
{
    NSError *error = (NSError*)noti.object;
    
    NSString *errorDomain = [error domain];
    if ([errorDomain isEqualToString:kGJAssetsPickerErrorDomain]) {
        
        GJAssetsPickerErrorType errorType = error.code;
        
        switch (errorType) {
            case GJAssetsPickerErrorTypePhotoLibarayNotAuthorize:
            {
                if (self.pickerDelegate && [self.pickerDelegate respondsToSelector:@selector(pickerViewControllerPhotoLibraryAccessDidNotAuthorized:)]) {
                    
                    [self.pickerDelegate pickerViewControllerPhotoLibraryAccessDidNotAuthorized:self];
                }
            }
                break;
                
            default:
                break;
        }
    }
}


- (void)observePickerControllerNeedCancel:(NSNotification*)noti
{
    [self dismissPickerViewController];
}



- (void)dismissPickerViewController
{
    if (self.pickerDelegate && [self.pickerDelegate respondsToSelector:@selector(pickerViewControllerWillCancel:)]) {
        [self.pickerDelegate pickerViewControllerWillCancel:self];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}



- (void)registAlbumsCustomCellClass:(Class)aAlbumsCustomCellClass
{
    if (!aAlbumsCustomCellClass) {
        return;
    }
    [self registAlbumsCustomCellClass:aAlbumsCustomCellClass withCellHeight:44.f];
}

- (void)registAlbumsCustomCellClass:(Class)aAlbumsCustomCellClass withCellHeight:(CGFloat)cellHeight
{
    NSDictionary *customCellDict = @{kGJAlbumsViewControllerCellCustomKey:NSStringFromClass(aAlbumsCustomCellClass),kGJAlbumsViewControllerCellCustomHeightKey:@(cellHeight)};
    [self.customClassDict setObject:customCellDict forKey:kGJAlbumsViewControllerCellCustomKey];
}

- (void)registPhotoViewControllerClass:(Class)aPhotoViewControllerClass
{
    if (!aPhotoViewControllerClass) {
        return;
    }
    [self.customClassDict setObject:NSStringFromClass(aPhotoViewControllerClass) forKey:kGJPhotoViewControllerCustomKey];
}

- (void)setCustomStyle:(GJCFAssetsPickerStyle *)aCustomStyle
{
    if (!aCustomStyle) {
        return;
    }
    
    if (_customStyle == aCustomStyle) {
        return;
    }
    
    _customStyle = aCustomStyle;
}

- (void)setCustomStyleByKey:(NSString *)aExistCustomStyleKey
{
    if (!aExistCustomStyleKey) {
        return;
    }
    
    NSMutableDictionary *styles = [GJCFAssetsPickerStyle persistStyleDict];
    if (!styles) {
        return;
    }
    
    self.customStyle = [styles objectForKey:aExistCustomStyleKey];
}

@end

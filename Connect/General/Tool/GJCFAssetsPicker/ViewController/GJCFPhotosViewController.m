//
//  GJPhotosViewController.m
//  GJAssetsPickerViewController
//
//  Created by ZYVincent on 14-9-8.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import "GJCFPhotosViewController.h"
#import "GJCFAssetsPickerViewController.h"
#import "GJCFAssetsPreviewController.h"
#import "GJCFUitils.h"

@interface GJCFPhotosViewController ()<GJCFAssetsPreviewControllerDelegate>

@property (nonatomic,strong)UIImageView *customBottomToolBar;
@property (nonatomic,strong)UIButton *finishDoneBtn;

@end

@implementation GJCFPhotosViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.colums = 4;
        self.mutilSelectLimitCount = 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.assetsTable = [[UITableView alloc]init];
    self.assetsTable.frame = (CGRect){0,0,self.view.frame.size.width,self.view.frame.size.height};
    [self.view addSubview:self.assetsTable];
    self.assetsTable.delegate = self;
    self.assetsTable.dataSource = self;
    [self.assetsTable setAllowsSelection:NO];
    [self.assetsTable setSeparatorStyle:UITableViewCellSeparatorStyleNone];
 
    self.assetsArray = [[NSMutableArray alloc]init];
    
    [self setupStyle];

    [self setupPhotos];
    
    [self updateFinishDoneBtnTitle];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    

    [self.assetsTable reloadData];
}

#pragma mark - set out
- (GJCFAssetsPickerStyle *)defaultStyle
{
    GJCFAssetsPickerStyle *defaultStyle = nil;
    if (self.delegate && [self.delegate respondsToSelector:@selector(photoViewControllerShouldUseCustomStyle:)]) {
        defaultStyle = [self.delegate photoViewControllerShouldUseCustomStyle:self];
    }else{
        defaultStyle = [GJCFAssetsPickerStyle defaultStyle];
    }
    return defaultStyle;
}


- (void)setupStyle{
    
    GJCFAssetsPickerStyle *defaultStyle = [self defaultStyle];
    self.colums = defaultStyle.numberOfColums;
    

    if (defaultStyle.sysPhotoNavigationBarDes.backgroundColor) {
        UIImage *colorImage = [GJCFAssetsPickerConstans imageForColor:defaultStyle.sysPhotoNavigationBarDes.backgroundColor withSize:CGSizeMake(self.view.frame.size.width,64)];
        [self.navigationController.navigationBar setBackgroundImage:colorImage forBarMetrics:UIBarMetricsDefault];
    }
    if (defaultStyle.sysPhotoNavigationBarDes.backgroundImage) {
        [self.navigationController.navigationBar setBackgroundImage:defaultStyle.sysPhotoNavigationBarDes.backgroundImage forBarMetrics:UIBarMetricsDefault];
    }
    
   
    UILabel *titleLabel = [[UILabel alloc]init];
    [titleLabel setCommonStyleDescription:defaultStyle.sysPhotoNavigationBarDes];
    if (!self.title) {
        self.title = defaultStyle.sysPhotoNavigationBarDes.title;
    }
    self.navigationItem.titleView = titleLabel;
    self.title = titleLabel.text;
    titleLabel = nil;
    

    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [backBtn setCommonStyleDescription:defaultStyle.sysBackBtnDes];
    NSArray *viewControllers = self.navigationController.viewControllers;
    UIViewController *backToViewController = [viewControllers objectAtIndex:(viewControllers.count-2)];\
    [backBtn setTitle:backToViewController.title forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];

 
    UIBarButtonItem *backBarItem = [[UIBarButtonItem alloc]initWithCustomView:backBtn];
    self.navigationItem.leftBarButtonItem = backBarItem;
    backBarItem = nil;
    
   
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [cancelBtn setCommonStyleDescription:defaultStyle.sysCancelBtnDes];
 
    [cancelBtn addTarget:self action:@selector(dismissPickerViewController) forControlEvents:UIControlEventTouchUpInside];
  
    UIBarButtonItem *rightBarItem = [[UIBarButtonItem alloc]initWithCustomView:cancelBtn];
    self.navigationItem.rightBarButtonItem = rightBarItem;
    rightBarItem = nil;
    

    self.customBottomToolBar = [[UIImageView alloc]init];
    self.customBottomToolBar.userInteractionEnabled = YES;
    if ([self.navigationController.navigationBar backgroundImageForBarMetrics:UIBarMetricsDefault]) {
        self.customBottomToolBar.frame = CGRectOffset(self.view.frame,0,self.view.frame.size.height - defaultStyle.sysPreviewBottomToolBarDes.frameSize.height-64);
        
        CGFloat delta = [GJCFAssetsPickerConstans isIOS7]? 64:44;
        self.assetsTable.frame = (CGRect){0,0,self.view.frame.size.width,self.view.frame.size.height-defaultStyle.sysPhotoBottomToolBarDes.frameSize.height-delta};
    }else{
        self.customBottomToolBar.frame = CGRectOffset(self.view.frame,0,self.view.frame.size.height - defaultStyle.sysPreviewBottomToolBarDes.frameSize.height);
    }
    self.customBottomToolBar.backgroundColor = defaultStyle.sysPhotoBottomToolBarDes.backgroundColor;
    self.customBottomToolBar.image = defaultStyle.sysPhotoBottomToolBarDes.backgroundImage;
    [self.view addSubview:self.customBottomToolBar];
    
    
  
    UIButton *previewBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [previewBtn setCommonStyleDescription:defaultStyle.sysPreviewBtnDes];
    [self.customBottomToolBar addSubview:previewBtn];
    [previewBtn addTarget:self action:@selector(previewSelectedPhotos) forControlEvents:UIControlEventTouchUpInside];
   
    self.finishDoneBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.finishDoneBtn setCommonStyleDescription:defaultStyle.sysFinishDoneBtDes];
    [self.customBottomToolBar addSubview:self.finishDoneBtn];
    [self.finishDoneBtn addTarget:self action:@selector(finishSelectImage) forControlEvents:UIControlEventTouchUpInside];
}

- (void)back
{
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)dismissPickerViewController
{
    [GJCFAssetsPickerConstans postNoti:kGJAssetsPickerNeedCancelNoti];
}

- (void)previewSelectedPhotos
{
    if ([self totalSelectedAssets].count <= 0) {
        [GJCFAssetsPickerConstans postNoti:kGJAssetsPickerRequirePreviewButNoSelectPhotoTipNoti];
        return;
    }
    
    GJCFAssetsPreviewController *previewController = [[GJCFAssetsPreviewController alloc]initWithAssets:[self totalSelectedAssets]];
    previewController.previewDelegate = self;
    previewController.pageIndex = 0;
    previewController.mutilSelectLimitCount = self.mutilSelectLimitCount;
    [self.navigationController pushViewController:previewController animated:YES];
}

- (void)finishSelectImage
{
    [GJCFAssetsPickerConstans postNoti:kGJAssetsPickerDidFinishChooseMediaNoti withObject:[self totalSelectedAssets]];
}

#pragma mark - 帮助图片分组方法

- (void)seprateAssetsGroup:(NSMutableArray *)aGroupArray withStartIndex:(NSInteger)sIndex withLength:(NSInteger)length
{
    
    if (length == 0 || sIndex < 0 || !aGroupArray || aGroupArray.count == 0) {
        return;
    }
    
 
    if (aGroupArray.count-1 < sIndex+length) {
        
        length = aGroupArray.count-sIndex > length? length:aGroupArray.count-sIndex;
        
        NSArray * subArray = [aGroupArray subarrayWithRange:NSMakeRange(sIndex,length)];
        

        [self.assetsArray objectAddObject:[NSMutableArray arrayWithArray:subArray]];
        
        return;
    }
    
    NSArray *subArray = [aGroupArray subarrayWithRange:NSMakeRange(sIndex, length)];
    
    [self.assetsArray objectAddObject:[NSMutableArray arrayWithArray:subArray]];
    
    
    sIndex = sIndex+length;
    
   
    if (aGroupArray.count-1>= sIndex+length) {
        
        [self seprateAssetsGroup:aGroupArray withStartIndex:sIndex withLength:length];

    }else{
        
        NSArray *subArray = [aGroupArray subarrayWithRange:NSMakeRange(sIndex, aGroupArray.count-sIndex)];
        
        [self.assetsArray objectAddObject:[NSMutableArray arrayWithArray:subArray]];
    }
}

- (void)setupPhotos
{
 
    if (self.albums.assetsArray && self.albums.assetsArray.count > 0) {
        
        [self.assetsArray addObjectsFromArray:self.albums.assetsArray];
        
        [self.assetsTable reloadData];
        
        return;
    }
    
    if (self.albums.assetsGroup && self.assetsTable) {
        
        NSMutableArray *tempAssetsArray = [NSMutableArray array];
        [self.albums.assetsGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {

           
            if (result) {
                
                GJCFAsset *asset = [[GJCFAsset alloc]initWithAsset:result];
                asset.selected = NO;
                                
                [tempAssetsArray objectAddObject:asset];
            
            }

        }];
        
        [self seprateAssetsGroup:tempAssetsArray withStartIndex:0 withLength:self.colums];
        
       
        if (self.delegate && [self.delegate respondsToSelector:@selector(photoViewController:didFinishEnumrateAssets:forAlbums:)]) {
            [self.delegate photoViewController:self didFinishEnumrateAssets:self.assetsArray forAlbums:self.albums];
        }
        
        [self.assetsTable reloadData];
      
        CGFloat bottomStartOffsetY = self.assetsTable.contentSize.height - self.assetsTable.frame.size.height;
        [self.assetsTable scrollRectToVisible:CGRectOffset(self.assetsTable.frame, 0, bottomStartOffsetY)  animated:NO];
    }
    
}

#pragma mark - tableView delegate and dataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.assetsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellIdentifier";
    GJCFAssetsPickerCell *cell = (GJCFAssetsPickerCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[GJCFAssetsPickerCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.delegate = self;
        
      
        GJCFAssetsPickerStyle *defaultStyle = [self defaultStyle];
        cell.overlayViewClass = defaultStyle.sysOverlayViewClass;
        cell.columSpace = defaultStyle.columSpace;
        cell.enableBigImageShowAction = defaultStyle.enableBigImageShowAction;
        cell.colums = self.colums;
    }
    
    [cell setAssets:[self.assetsArray objectAtIndex:indexPath.row]];
    
    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.assetsTable.frame.size.width/self.colums;
}

#pragma mark -
- (NSArray *)totalSelectedAssets
{
    NSMutableArray *selectedArray = [NSMutableArray array];
    [self.assetsArray enumerateObjectsUsingBlock:^(NSArray *subArray, NSUInteger idx, BOOL *stop) {
        
        [subArray enumerateObjectsUsingBlock:^(GJCFAsset *asset, NSUInteger idx, BOOL *stop) {
            
            if (asset.selected) {
                [selectedArray objectAddObject:asset];
            }
            
        }];
        
    }];
    
    return selectedArray;
}

- (void)updateFinishDoneBtnTitle
{
    GJCFAssetsPickerStyle *defaultStyle = [self defaultStyle];
    NSString *newTitle = [NSString stringWithFormat:@"%@(%lu)",defaultStyle.sysFinishDoneBtDes.normalStateTitle,(unsigned long)[self totalSelectedAssets].count];
    
    [self.finishDoneBtn setTitle:newTitle forState:UIControlStateNormal];
}

#pragma mark - GJAssetsPickerCell delegate
- (void)assetsPickerCell:(GJCFAssetsPickerCell *)assetsPickerCell didChangeStateAtIndex:(NSInteger)index withState:(BOOL)isSelected
{
   
    NSIndexPath *indexPath = [self.assetsTable indexPathForCell:assetsPickerCell];
    NSMutableArray *subArray = [self.assetsArray objectAtIndex:indexPath.row];
    GJCFAsset *asset = [subArray objectAtIndex:index];
    asset.selected = isSelected;
    
    [subArray replaceObjectAtIndex:index withObject:asset];
    [self.assetsArray replaceObjectAtIndex:indexPath.row withObject:subArray];
   
    [self updateFinishDoneBtnTitle];
}

- (BOOL)assetsPickerCell:(GJCFAssetsPickerCell *)assetsPickerCell shouldChangeToSelectedStateAtIndex:(NSInteger)index
{
   
    if (self.mutilSelectLimitCount==0) {
        return YES;
    }
    
    NSInteger totalSelectCount = [self totalSelectedAssets].count;
    
    if (totalSelectCount>=self.mutilSelectLimitCount) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [GJCFAssetsPickerConstans postNoti:kGJAssetsPickerPhotoControllerDidReachLimitCountNoti withObject:[NSNumber numberWithInteger:self.mutilSelectLimitCount]];

        });
        
        return NO;
        
    }else{
        return YES;
    }
}

/* 进入大图查看模式  */
- (void)assetsPickerCell:(GJCFAssetsPickerCell *)assetsPickerCell shouldBeginBigImageShowAtIndex:(NSInteger)index
{
    /* Group all the photos into a new group */
    NSMutableArray *allAssets = [NSMutableArray array];
    [self.assetsArray enumerateObjectsUsingBlock:^(NSArray *subArray, NSUInteger idx, BOOL *stop) {
        
        [subArray enumerateObjectsUsingBlock:^(GJCFAsset *asset, NSUInteger idx, BOOL *stop) {
            
            [allAssets objectAddObject:asset];
        }];
    }];
    

    NSIndexPath *indexPath = [self.assetsTable indexPathForCell:assetsPickerCell];
    NSInteger totalIndex = indexPath.row * self.colums + index;
    
    GJCFAssetsPreviewController *previewController = [[GJCFAssetsPreviewController alloc]initWithAssets:allAssets];
    previewController.previewDelegate = self;
    previewController.pageIndex = totalIndex;
    previewController.mutilSelectLimitCount = self.mutilSelectLimitCount;
    [self.navigationController pushViewController:previewController animated:YES];
}

#pragma mark - GJAssetsPickerPreviewControllerDelegate
- (GJCFAssetsPickerStyle *)previewControllerShouldCustomStyle:(GJCFAssetsPreviewController *)previewController
{
    return [self defaultStyle];
}

- (void)previewController:(GJCFAssetsPreviewController *)previewController didUpdateAssetSelectedState:(GJCFAsset *)asset
{
    __block NSUInteger indexPath = 0;
    __block NSUInteger subIndex = 0;
    
    [self.assetsArray enumerateObjectsUsingBlock:^(NSArray *subArray, NSUInteger rowIndex, BOOL *rowStop) {
        
        [subArray enumerateObjectsUsingBlock:^(GJCFAsset *sAsset, NSUInteger idx, BOOL *stop) {
            
            if ([sAsset isEqual:asset]) {
                
                indexPath = rowIndex;
                subIndex = idx;
                
                *rowStop = YES;
                *stop = YES;
            }
        }];
        
    }];
    

    NSMutableArray *subArray = [self.assetsArray objectAtIndex:indexPath];
    GJCFAsset *theAsset = [subArray objectAtIndex:subIndex];
    theAsset.selected = asset.selected;
    
    [subArray replaceObjectAtIndex:subIndex withObject:theAsset];
    [self.assetsArray replaceObjectAtIndex:indexPath withObject:subArray];

  
    [self updateFinishDoneBtnTitle];
    
}

@end

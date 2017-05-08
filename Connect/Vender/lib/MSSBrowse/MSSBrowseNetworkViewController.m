//
//  MSSBrowseNetworkViewController.m
//  MSSBrowse
//
//  Created by 于威 on 16/4/26.
//  Copyright © 2016年 于威. All rights reserved.
//

#import "MSSBrowseNetworkViewController.h"
#import "YYImageCache.h"
#import "UIImageView+YYWebImage.h"
#import "UIView+MSSLayout.h"
#import "UIImage+MSSScale.h"
#import "MSSBrowseDefine.h"

@implementation MSSBrowseNetworkViewController

- (void)loadBrowseImageWithBrowseItem:(MSSBrowseModel *)browseItem Cell:(MSSBrowseCollectionViewCell *)cell bigImageRect:(CGRect)bigImageRect
{
    // 停止加载
    [cell.loadingView stopAnimation];
    // 判断大图是否存在
    if([[YYImageCache sharedCache] getImageForKey:browseItem.bigImageUrl])
    {
        // 显示大图
        [self showBigImage:cell.zoomScrollView.zoomImageView browseItem:browseItem rect:bigImageRect];
    }
    // 如果大图不存在
    else
    {
        self.isFirstOpen = NO;
        // 加载大图
        [self loadBigImageWithBrowseItem:browseItem cell:cell rect:bigImageRect];
    }
}

- (void)showBigImage:(UIImageView *)imageView browseItem:(MSSBrowseModel *)browseItem rect:(CGRect)rect
{
    // 取消当前请求防止复用问题
    [imageView cancelCurrentImageRequest];
    // 如果存在直接显示图片
    imageView.image = [[YYImageCache sharedCache] getImageForKey:browseItem.bigImageUrl];
    // 当大图frame为空时，需要大图加载完成后重新计算坐标
    CGRect bigRect = [self getBigImageRectIfIsEmptyRect:rect bigImage:imageView.image];
    // 第一次打开浏览页需要加载动画
    if(self.isFirstOpen)
    {
        self.isFirstOpen = NO;
        imageView.frame = [self getFrameInWindow:browseItem.smallImageView];
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            imageView.frame = bigRect;
        }];
    }
    else
    {
        imageView.frame = bigRect;
    }
}

// 加载大图
- (void)loadBigImageWithBrowseItem:(MSSBrowseModel *)browseItem cell:(MSSBrowseCollectionViewCell *)cell rect:(CGRect)rect
{
    UIImageView *imageView = cell.zoomScrollView.zoomImageView;
    // 加载圆圈显示
    [cell.loadingView startAnimation];
    // 默认为屏幕中间
    [imageView mss_setFrameInSuperViewCenterWithSize:CGSizeMake(browseItem.smallImageView.mssWidth, browseItem.smallImageView.mssHeight)];
    [imageView setImageWithURL:[NSURL URLWithString:browseItem.bigImageUrl] placeholder:browseItem.smallImageView.image options:YYWebImageOptionShowNetworkActivity completion:^(UIImage *image, NSURL *url, YYWebImageFromType from, YYWebImageStage stage, NSError *error) {
        // 关闭图片浏览view的时候，不需要继续执行小图加载大图动画
        if(self.collectionView.userInteractionEnabled)
        {
            // 停止加载
            [cell.loadingView stopAnimation];
            if(error)
            {
                [self showBrowseRemindViewWithText:LMLocalizedString(@"Network Image loading failed", nil)];
            }
            else
            {
                // 当大图frame为空时，需要大图加载完成后重新计算坐标
                CGRect bigRect = [self getBigImageRectIfIsEmptyRect:rect bigImage:image];
                // 图片加载成功
                [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                    imageView.frame = bigRect;
                }];
            }
        }
    }];
}

// 当大图frame为空时，需要大图加载完成后重新计算坐标
- (CGRect)getBigImageRectIfIsEmptyRect:(CGRect)rect bigImage:(UIImage *)bigImage
{
    if(CGRectIsEmpty(rect))
    {
        return [bigImage mss_getBigImageRectSizeWithScreenWidth:self.screenWidth screenHeight:self.screenHeight];
    }
    return rect;
}

@end

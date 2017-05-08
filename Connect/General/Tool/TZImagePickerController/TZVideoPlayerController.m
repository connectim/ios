//
//  TZVideoPlayerController.m
//  TZImagePickerController
//
//  Created by 谭真 on 16/1/5.
//  Copyright © 2016年 谭真. All rights reserved.
//

#import "TZVideoPlayerController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UIView+Layout.h"
#import "TZImageManager.h"
#import "TZAssetModel.h"
#import "TZImagePickerController.h"
#import "TZPhotoPreviewController.h"

@interface TZVideoPlayerController () {
    AVPlayer *_player;
    UIButton *_playButton;
    UIImage *_cover;
    
    UIView *_toolBar;
    UIButton *_okButton;
    UIProgressView *_progress;
}
@end

@implementation TZVideoPlayerController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.navigationItem.title = LMLocalizedString(@"Chat Video preview", nil);
    [self configMoviePlayer];
}

- (void)configMoviePlayer {
    [[TZImageManager manager] getPhotoWithAsset:_model.asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        _cover = photo;
    }];
    
     __weak __typeof(&*self)weakSelf = self;
    [[TZImageManager manager] getVideoWithAsset:_model.asset completion:^(AVPlayerItem *playerItem, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _player = [AVPlayer playerWithPlayerItem:playerItem];
            AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
            playerLayer.frame = weakSelf.view.bounds;
            [weakSelf.view.layer addSublayer:playerLayer];
            [weakSelf addProgressObserver];
            [weakSelf configPlayButton];
            CMTime duration = playerItem.asset.duration;
            float seconds = CMTimeGetSeconds(duration);
             [weakSelf configBottomToolBar:seconds];
            [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(pausePlayerAndShowNaviBar) name:AVPlayerItemDidPlayToEndTimeNotification object:_player.currentItem];
        });
    }];
}
/// Show progress，do it next time / 给播放器添加进度更新,下次加上
-(void)addProgressObserver{
    AVPlayerItem *playerItem = _player.currentItem;
    UIProgressView *progress = _progress;
    [_player addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float current = CMTimeGetSeconds(time);
        float total = CMTimeGetSeconds([playerItem duration]);
        if (current) {
            [progress setProgress:(current/total) animated:YES];
        }
    }];
}

- (void)configPlayButton {
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _playButton.frame = CGRectMake(0, 64, self.view.tz_width, self.view.tz_height - 64 - 44);
    [_playButton setImage:[UIImage imageNamedFromMyBundle:@"MMVideoPreviewPlay.png"] forState:UIControlStateNormal];
    [_playButton setImage:[UIImage imageNamedFromMyBundle:@"MMVideoPreviewPlayHL.png"] forState:UIControlStateHighlighted];
    [_playButton addTarget:self action:@selector(playButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_playButton];
}

- (void)configBottomToolBar:(CGFloat)numberS {
    _toolBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.tz_height - 44, self.view.tz_width, 44)];
    CGFloat rgb = 34 / 255.0;
    _toolBar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1.0];
    _toolBar.alpha = 0.7;
    
    _okButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _okButton.frame = CGRectMake(self.view.tz_width - 44 - 12, 0, 44, 44);
    _okButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_okButton addTarget:self action:@selector(okButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_okButton setTitle:LMLocalizedString(@"Link Send", nil) forState:UIControlStateNormal];
    TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
    [_okButton setTitleColor:imagePickerVc.oKButtonTitleColorNormal forState:UIControlStateNormal];
    
    [_toolBar addSubview:_okButton];
    [self.view addSubview:_toolBar];
    // 创建视频不大于10m的提醒
     UILabel* tipLable = [[UILabel alloc]initWithFrame:CGRectMake(20, 0, self.view.tz_width - 44 - 12-20, 44)];
    int limitM = 5;
    if (numberS > limitM*60) {
        _okButton.hidden = YES;
        NSMutableAttributedString* attributeStr = [[NSMutableAttributedString alloc]initWithString:[NSString stringWithFormat:LMLocalizedString(@"Chat video limit", nil),limitM]];
        NSDictionary* dic = @{ NSFontAttributeName: [UIFont systemFontOfSize:FONT_SIZE(24)],
                               NSForegroundColorAttributeName: [UIColor whiteColor]
        
        };
        NSDictionary* dic1 = @{ NSFontAttributeName: [UIFont systemFontOfSize:FONT_SIZE(18)],
                               NSForegroundColorAttributeName: LMBasicDarkGray
                               
                               };
        [attributeStr addAttributes:dic range:NSMakeRange(0, LMLocalizedString(@"Chat video tip", nil).length)];
        [attributeStr addAttributes:dic1 range:NSMakeRange(LMLocalizedString(@"Chat video tip", nil).length, [NSString stringWithFormat:LMLocalizedString(@"Chat video limit", nil),limitM].length - LMLocalizedString(@"Chat video tip", nil).length)];
        tipLable.attributedText = attributeStr;
        tipLable.numberOfLines = 0;
        [_toolBar addSubview:tipLable];
        tipLable.hidden = NO;
    }else
    {
        _okButton.hidden = NO;
        tipLable.hidden = YES;
    }
    
    
}

#pragma mark - Click Event

- (void)playButtonClick {
    CMTime currentTime = _player.currentItem.currentTime;
    CMTime durationTime = _player.currentItem.duration;
    if (_player.rate == 0.0f) {
        if (currentTime.value == durationTime.value) [_player.currentItem seekToTime:CMTimeMake(0, 1)];
        [_player play];
        [self.navigationController setNavigationBarHidden:YES];
        _toolBar.hidden = YES;
        [_playButton setImage:nil forState:UIControlStateNormal];
        if (iOS7Later) [UIApplication sharedApplication].statusBarHidden = YES;
    } else {
        [self pausePlayerAndShowNaviBar];
    }
}

- (void)okButtonClick {
    TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
    if ([imagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingVideo:sourceAssets:)]) {
        [imagePickerVc.pickerDelegate imagePickerController:imagePickerVc didFinishPickingVideo:_cover sourceAssets:_model.asset];
    }
    if (imagePickerVc.didFinishPickingVideoHandle) {
        imagePickerVc.didFinishPickingVideoHandle(_cover,_model.asset);
    }
}

#pragma mark - Notification Method

- (void)pausePlayerAndShowNaviBar {
    [_player pause];
    _toolBar.hidden = NO;
    [self.navigationController setNavigationBarHidden:NO];
    [_playButton setImage:[UIImage imageNamedFromMyBundle:@"MMVideoPreviewPlay.png"] forState:UIControlStateNormal];
    if (iOS7Later) [UIApplication sharedApplication].statusBarHidden = NO;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

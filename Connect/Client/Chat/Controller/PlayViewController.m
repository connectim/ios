//
//  PlayViewController.m
//  SBVideoCaptureDemo
//
//  Created by Pandara on 14-8-18.
//  Copyright (c) 2014年 Pandara. All rights reserved.
//

#import "PlayViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface PlayViewController ()

@property(strong, nonatomic) NSURL *videoFileURL;
@property(strong, nonatomic) AVPlayer *player;
@property(strong, nonatomic) AVPlayerLayer *playerLayer;
@property(strong, nonatomic) AVPlayerItem *playerItem;

@property(nonatomic, strong) UIView *videoPlayLayerView;

@property(nonatomic, assign) BOOL isPlaying;

@property(nonatomic, assign) BOOL sliderValueChanging;

@property(nonatomic, assign) int audioDurationSeconds;

@property(nonatomic, assign) int temDuration;

@property(nonatomic, strong) id timeObserverToken;

@property(assign, nonatomic) CADisplayLink *link;

@property(strong, nonatomic) UISlider *videoSlider;
@property(strong, nonatomic) UIButton *playOrPauseBtn;
@property(strong, nonatomic) UILabel *totalTimeLabel;
@property(strong, nonatomic) UILabel *timeLabel;
@property(nonatomic, strong) UIView *controlBar;
@property(nonatomic, strong) UITapGestureRecognizer *tap;
@property(nonatomic, assign) BOOL playComplete;


@end

@implementation PlayViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.navigationController.navigationBar.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_player pause];
    _playerItem = nil;
    self.navigationController.navigationBar.hidden = NO;
}

- (id)initWithVideoFileURL:(NSURL *)videoFileURL {
    self = [super init];
    if (self) {
        self.videoFileURL = videoFileURL;

        AVURLAsset *audioAsset = [AVURLAsset URLAssetWithURL:videoFileURL options:nil];

        CMTime audioDuration = audioAsset.duration;

        _audioDurationSeconds = CMTimeGetSeconds(audioDuration) + 0.5;
        _temDuration = _audioDurationSeconds;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:16 / 255.0f green:16 / 255.0f blue:16 / 255.0f alpha:1.0f];
    if (!_videoPlayLayerView) {
        _videoPlayLayerView = [UIView new];
        _videoPlayLayerView.frame = self.view.bounds;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapVideo)];
        [_videoPlayLayerView addGestureRecognizer:tap];
    }
    [self.view addSubview:self.videoPlayLayerView];
    [self initPlayLayer];

    [self.view addSubview:self.controlBar];

    [_controlBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view);
        make.width.equalTo(self.view);
        make.left.equalTo(self.view);
        make.height.mas_equalTo(AUTO_HEIGHT(100));
    }];

    dispatch_queue_t mainQueue = dispatch_get_main_queue();

    __weak __typeof(&*self) weakSelf = self;
    self.timeObserverToken = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:mainQueue usingBlock:^(CMTime time) {
        long long currentSecond = weakSelf.playerItem.currentTime.value / weakSelf.playerItem.currentTime.timescale;

        NSString *tempTime = calculateTimeWithTimeFormatter(currentSecond);
        if (tempTime.length > 5) {
            weakSelf.timeLabel.text = [NSString stringWithFormat:@"00:%@", tempTime];
        } else {
            weakSelf.timeLabel.text = tempTime;
        }
    }];
    [self.player play];
    _isPlaying = YES;


    CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(SliderValue)];
    [link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.link = link;
    self.link.paused = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(avPlayerItemDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

- (void)SliderValue {
    double currentSecond = (double) self.playerItem.currentTime.value / self.playerItem.currentTime.timescale;
    double curentMsecond = currentSecond * 100;
    double sliderMsecond = self.audioDurationSeconds * 100;
    if (!self.sliderValueChanging) {
        [self.videoSlider setValue:(float) curentMsecond / sliderMsecond animated:YES];
    }
}

- (void)removeBoundaryTimeObserver {
    if (self.timeObserverToken) {
        [self.player removeTimeObserver:self.timeObserverToken];
        self.timeObserverToken = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [self.playerLayer removeFromSuperlayer];
    self.playerLayer = nil;
    self.player = nil;
    self.playerItem = nil;
    if (self.link) {
        self.link.paused = YES;
        [self.link invalidate];
        self.link = nil;
    }
}

- (void)dealloc {
    if (self.timeObserverToken) {
        [self.player removeTimeObserver:self.timeObserverToken];
        self.timeObserverToken = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    [self.playerLayer removeFromSuperlayer];
    self.playerLayer = nil;
    self.player = nil;
    self.playerItem = nil;
    if (self.link) {
        self.link.paused = YES;
        [self.link invalidate];
        self.link = nil;
    }
}

NSString *calculateTimeWithTimeFormatter(long long timeSecond) {
    NSString *theLastTime = nil;
    if (timeSecond < 60) {
        theLastTime = [NSString stringWithFormat:@"00:%.2lld", timeSecond];
    } else if (timeSecond >= 60 && timeSecond < 3600) {
        theLastTime = [NSString stringWithFormat:@"%.2lld:%.2lld", timeSecond / 60, timeSecond % 60];
    } else if (timeSecond >= 3600) {
        theLastTime = [NSString stringWithFormat:@"%.2lld:%.2lld:%.2lld", timeSecond / 3600, timeSecond % 3600 / 60, timeSecond % 60];
    }
    return theLastTime;
}

- (void)initPlayLayer {
    if (!_videoFileURL) {
        return;
    }

    AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:_videoFileURL options:nil];
    self.playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
    self.player = [AVPlayer playerWithPlayerItem:_playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    _playerLayer.frame = self.videoPlayLayerView.bounds;
    [self.videoPlayLayerView.layer addSublayer:_playerLayer];

}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (UIView *)controlBar {
    if (!_controlBar) {
        _controlBar = [[UIView alloc] init];
        _controlBar.backgroundColor = [UIColor clearColor];

        self.playOrPauseBtn = [[UIButton alloc] init];
        [_controlBar addSubview:self.playOrPauseBtn];
        [_playOrPauseBtn setImage:[UIImage imageNamed:@"camera_pause"] forState:UIControlStateNormal];
        [_playOrPauseBtn setImage:[UIImage imageNamed:@"chat_videorecorder_play"] forState:UIControlStateSelected];
        [_playOrPauseBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.bottom.equalTo(_controlBar);
            make.width.equalTo(_playOrPauseBtn.mas_height);
        }];

        [_playOrPauseBtn addTarget:self action:@selector(playOrPause) forControlEvents:UIControlEventTouchUpInside];

        self.timeLabel = [[UILabel alloc] init];
        _timeLabel.text = @"00:00";
        _timeLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
        _timeLabel.textColor = [UIColor whiteColor];
        [_controlBar addSubview:self.timeLabel];
        [_timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_playOrPauseBtn.mas_right);
            make.centerY.equalTo(_controlBar.mas_centerY);
        }];

        self.totalTimeLabel = [[UILabel alloc] init];
        _totalTimeLabel.text = [NSString stringWithFormat:@"00:%02d", _audioDurationSeconds];
        _totalTimeLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
        _totalTimeLabel.textColor = [UIColor whiteColor];
        [_controlBar addSubview:self.totalTimeLabel];
        [_totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(_controlBar.mas_right).offset(-AUTO_WIDTH(20));
            make.centerY.equalTo(_controlBar.mas_centerY);
        }];

        self.videoSlider = [[UISlider alloc] init];

        [self.videoSlider addTarget:self action:@selector(sliderValueChanged) forControlEvents:UIControlEventValueChanged];
        [self.videoSlider addTarget:self action:@selector(sliderTouching) forControlEvents:UIControlEventTouchUpInside];

        [self.videoSlider setThumbImage:[UIImage imageNamed:@"video_player_traker"] forState:UIControlStateNormal];
        [self.videoSlider setMinimumTrackTintColor:[UIColor whiteColor]];
        [self.videoSlider setThumbImage:[UIImage imageNamed:@"video_player_traker"] forState:UIControlStateHighlighted];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(progressTapAct:)];
        self.tap = tap;
        tap.numberOfTapsRequired = 1;
        tap.numberOfTouchesRequired = 1;
        [self.videoSlider addGestureRecognizer:tap];
        [_controlBar addSubview:self.videoSlider];
        [_videoSlider mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_timeLabel.mas_right).offset(AUTO_WIDTH(20));
            make.right.equalTo(_totalTimeLabel.mas_left).offset(-AUTO_WIDTH(20));
            make.centerY.equalTo(_controlBar.mas_centerY);
            make.height.equalTo(_controlBar.mas_height);
        }];
    }

    return _controlBar;
}

- (void)playOrPause {

    if (!self.isPlaying) {
        [self.player play];
        self.playOrPauseBtn.selected = NO;
        _isPlaying = YES;
        self.link.paused = NO;
    } else {
        [self.player pause];
        self.playOrPauseBtn.selected = YES;
        _isPlaying = NO;
        self.link.paused = YES;
    }
}

- (void)sliderTouching {
    _sliderValueChanging = YES;
    _tap.enabled = NO;
}

- (void)sliderValueChanged {
    [self seekToTheTimeValue:self.videoSlider.value * _audioDurationSeconds];
    _tap.enabled = YES;
    self.link.paused = YES;
}


- (void)progressTapAct:(UITapGestureRecognizer *)tap {
    CGPoint location = [tap locationInView:self.videoSlider];

    float value = location.x / self.videoSlider.bounds.size.width * _audioDurationSeconds;
    [self seekToTheTimeValue:value];
}

- (void)seekToTheTimeValue:(float)value {

    CMTime changedTime = CMTimeMakeWithSeconds(value, 1);
    DDLogError(@"cmtime change time : %lld", changedTime.value);
    __weak __typeof(&*self) weakSelf = self;
    [self.player seekToTime:changedTime completionHandler:^(BOOL finished) {
        if (finished) {
            weakSelf.link.paused = NO;
            weakSelf.sliderValueChanging = NO;
        }
    }];
}


#pragma mark - PlayEndNotification

- (void)avPlayerItemDidPlayToEnd:(NSNotification *)notification {
    if ((AVPlayerItem *) notification.object != _playerItem) {
        return;
    }
    if (!self.playComplete) {
        self.playComplete = YES;
    }
    [self seekToTheTimeValue:0.0];
    [self.player pause];
    self.playOrPauseBtn.selected = YES;
    _isPlaying = NO;
}

- (void)showPlayController {
    UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootViewController presentViewController:self animated:NO completion:nil];
}

- (void)tapVideo {
    [self.player pause];
    [UIView animateWithDuration:0.1 animations:^{
        self.view.alpha = 0.1;
        if (self.ClosePlayCallBack) {
            self.ClosePlayCallBack(self.playComplete);
        }
    }                completion:^(BOOL finished) {
        [self removeBoundaryTimeObserver];
        [self dismissViewControllerAnimated:NO completion:nil];
    }];
}

@end

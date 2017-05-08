//
//  GJGCCommonHeadView.m
//  ZYChat
//
//  Created by KivenLin on 14-10-28.
//  Copyright (c) 2014年 ConnectSoft. All rights reserved.
//

@interface GJGCCommonHeadView ()
@property(nonatomic, strong) UIImageView *contentImageView;
@end

@implementation GJGCCommonHeadView

- (instancetype)init {
    if (self = [super init]) {

        [self initSubViews];
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {

        [self initSubViews];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.contentImageView.frame = self.bounds;
}

- (void)initSubViews {
    self.backgroundColor = [UIColor clearColor];
    self.contentImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.contentImageView.image = GJCFQuickImage(@"default_user_avatar");
    self.contentImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.contentImageView.clipsToBounds = YES;
    self.contentImageView.layer.cornerRadius = 5;
    [self addSubview:self.contentImageView];
}

- (void)setHeadUrl:(NSString *)url {
    if ([url hasPrefix:@"http"]) {
        NSString *avatar = url;
        [self.contentImageView setImageWithAvatarUrl:avatar];
    } else {
        self.contentImageView.image = [UIImage imageNamed:url];
    }
}


- (void)setHeadUrl:(NSString *)url headViewType:(GJGCCommonHeadViewType)headViewType {
    switch (headViewType) {
        case GJGCCommonHeadViewTypePGGroup: {
            [self.contentImageView setImage:GJCFQuickImage(@"default_user_avatar")];
            break;
        }
        case GJGCCommonHeadViewTypeContact: {
            [self.contentImageView setImage:GJCFQuickImage(@"default_user_avatar")];
            break;
        }
        default:
            break;
    }
}

- (void)setHeadImage:(UIImage *)image {
    [self.contentImageView setImage:image];
}

- (void)setHiddenImageView:(BOOL)hidden {
    self.contentImageView.hidden = hidden;
}

- (void)completionTask:(BOOL)completion withImage:(UIImage *)image {
    self.contentImageView.image = image;
}

@end

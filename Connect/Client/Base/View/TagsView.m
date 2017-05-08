//
//  TagsView.m
//  Connect
//
//  Created by MoHuilin on 16/5/31.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "TagsView.h"
#import "UIColor+Random.h"
#import "UserDBManager.h"
#import "NSObject+AddProperty.h"
#import "NSString+Size.h"
#import "StringTool.h"

#pragma mark - 内部自定义的按钮输入框什么的

@interface TagButton :UIButton
@end

@implementation TagButton

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}



- (void)setup{
    self.layer.cornerRadius = 5;
    self.layer.masksToBounds = YES;
    [self setBackgroundColor:XCColor(242, 242, 242)];
    [self setTitleColor:XCColor(102, 95, 100) forState:UIControlStateNormal];
    
    self.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];

}

-(void)setSelected:(BOOL)selected{
    [super setSelected:selected];
    if (selected) {
        [self setTitleColor:XCColor(55, 198, 92) forState:UIControlStateSelected];
    } else {
        [self setTitleColor:XCColor(102, 95, 100) forState:UIControlStateNormal];
    }
    [self setNeedsDisplay];
}
@end


@interface TagTextField : UITextField

@end
@implementation TagTextField

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    
    return self;
}

- (void)setup{
}

@end


@interface TagsView ()<UITextFieldDelegate,UIScrollViewDelegate>{
    CGFloat margin;
}

@property (nonatomic ,strong) UIScrollView *tagScrollView;

@property (nonatomic ,strong) UIScrollView *commonTagsScrollView;

@property (nonatomic ,strong) NSMutableArray *selectedTags;

@property(strong,nonatomic)UIView* line;

@property(strong,nonatomic)UILabel * addLable;
@property(strong,nonatomic)TagTextField* tagTextField;
//承载button的view
@property(strong,nonatomic)UIView* buttonView;
//右边的button
@property(strong,nonatomic)UIButton* rightButton;
//创建下边的分割线
@property(strong,nonatomic) UIView* sepLineView;
//commonButton
@property(strong,nonatomic)UIButton* commonButton;
//创建下边的commonButton
@property(strong,nonatomic)UIButton* bottomCommonButton;
//最上边的topview
@property(strong,nonatomic)UIView* topView;
//底部button的容器
@property(strong,nonatomic)UIView* bottomContainer;


@end

@implementation TagsView

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup{
    
    margin = AUTO_WIDTH(27);
    
    self.commomTags = [NSMutableArray arrayWithArray:[[UserDBManager sharedManager] tagList]];
    
    self.selectedTags = [NSMutableArray array];
    
    self.type = TagsViewTypeNone;
    
        //创建上边的view
        UIView* topView = [[UIView alloc]init];
        [self addSubview:topView];
        topView.backgroundColor = [UIColor whiteColor];
        self.topView = topView;
        [topView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.equalTo(self);
            make.height.mas_equalTo(AUTO_HEIGHT(100));
        }];
        TagTextField *textFiled = [[TagTextField alloc] init];
        textFiled.placeholder = LMLocalizedString(@"Link Input a tag", nil);
        textFiled.returnKeyType = UIReturnKeyDone;
        textFiled.delegate = self;
        [topView addSubview:textFiled];
        [textFiled addTarget:self action:@selector(textChange:) forControlEvents:
         UIControlEventEditingChanged];
        [textFiled mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(topView).offset(AUTO_HEIGHT(0));
            make.height.mas_equalTo(AUTO_HEIGHT(99));
            make.left.equalTo(topView).offset(AUTO_WIDTH(30));
            make.right.mas_equalTo(topView).offset(-AUTO_WIDTH(140));
        }];
        self.tagTextField = textFiled;
   
        //承载button的view
        self.buttonView = [[UIView alloc]init];
        [topView addSubview:self.buttonView];
        [self.buttonView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(topView.mas_right);
            make.top.equalTo(topView);
            make.width.mas_equalTo(AUTO_WIDTH(140));
            make.height.mas_equalTo(AUTO_HEIGHT(99));
        }];
        //创建中间的那个线
        UIView* middleLineView = [[UIView alloc]init];
        middleLineView.backgroundColor = LMBasicDarkGray;
        [self.buttonView addSubview:middleLineView];
        [middleLineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(self.buttonView.mas_left);
            make.height.mas_equalTo(self.buttonView.mas_height).multipliedBy(0.7);
            make.width.mas_equalTo(0.5);
            make.centerY.equalTo(self.buttonView);
            
        }];
        //创建右边的button
        UIButton* rightButton = [[UIButton alloc] init];
        [rightButton setTitle:LMLocalizedString(@"Link Add", nil) forState:UIControlStateNormal];
        [rightButton setTitleColor:LMBasicBlue forState:UIControlStateNormal];
        rightButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(28)];
        [rightButton addTarget:self action:@selector(addButtonAction) forControlEvents:UIControlEventTouchUpInside];
        [rightButton setTitleColor:LMBasicDarkGray forState:UIControlStateDisabled];
        rightButton.enabled = NO;
        [self.buttonView addSubview:rightButton];
        [rightButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.mas_equalTo(middleLineView.mas_left).offset(AUTO_WIDTH(1));
            make.height.right.top.equalTo(self.buttonView);
            
        }];
        self.rightButton = rightButton;
        //创建下边的分割线
        UIView* sepLineView = [[UIView alloc]init];
        sepLineView.backgroundColor = LMBasicLineViewColor;
        [topView addSubview:sepLineView];
        [sepLineView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.bottom.equalTo(topView);
            make.height.mas_equalTo(AUTO_HEIGHT(1));
        }];
        self.sepLineView = sepLineView;
        //创建下边的两个scrollerview
        self.tagScrollView = [[UIScrollView alloc] init];
        self.tagScrollView.delegate = self;
        self.tagScrollView.showsVerticalScrollIndicator = NO;
        self.tagScrollView.backgroundColor = [UIColor whiteColor];
        self.tagScrollView.showsHorizontalScrollIndicator = NO;
        [self addSubview:_tagScrollView];
        
        self.commonTagsScrollView = [[UIScrollView alloc] init];
        self.commonTagsScrollView.showsVerticalScrollIndicator = NO;
        self.commonTagsScrollView.showsHorizontalScrollIndicator = NO;
        self.commonTagsScrollView.backgroundColor = LMBasicLightGray;
        [self addSubview:_commonTagsScrollView];
        
        [_tagScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self);
            make.top.mas_equalTo(topView.mas_bottom);
            make.width.mas_equalTo(DEVICE_SIZE.width);
            make.height.mas_equalTo(AUTO_HEIGHT(100));
        }];
        // 创建中间的view
        UIView* middleView = [[UIView alloc]init];
        middleView.backgroundColor = LMBasicLightGray;
        [self addSubview:middleView];
        [middleView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self);
            make.top.mas_equalTo(self.tagScrollView.mas_bottom);
            make.height.mas_equalTo(AUTO_HEIGHT(70));
        }];
        //创建一个中间的lable
        UILabel* lable = [[UILabel alloc]init];
        lable.text = LMLocalizedString(@"Link Existed tags", nil);
        lable.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
        lable.textColor = [UIColor blackColor];
        lable.backgroundColor = [UIColor clearColor];
        lable.textAlignment = NSTextAlignmentLeft;
        [middleView addSubview:lable];
        [lable mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(middleView).offset(AUTO_WIDTH(20));
            make.right.bottom.equalTo(middleView);
            make.height.mas_equalTo(AUTO_HEIGHT(40));
        }];
        self.addLable = lable;
    
        UIView *line = [[UIView alloc] init];
        [self addSubview:line];
        line.backgroundColor = LMBasicLineViewColor;
        [line mas_makeConstraints:^(MASConstraintMaker *make) {
            make.height.mas_equalTo(0.5);
            make.left.equalTo(self);
            make.right.equalTo(self);
            make.top.mas_equalTo(self.addLable.mas_bottom).offset(0);
        }];
        self.line = line;
        [_commonTagsScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self);
            make.width.mas_equalTo(DEVICE_SIZE.width);
            make.top.mas_equalTo(self.line.mas_bottom);
            make.bottom.mas_equalTo(self);
        }];
}
- (void)reloadData{
    
    
    [[UIMenuController sharedMenuController] setMenuVisible:YES animated:NO];
    
    switch (self.type) {
        case TagsViewTypeEdit:
        {
            [_commonTagsScrollView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.bottom.left.right.equalTo(self);
               make.top.mas_equalTo(self.line.mas_bottom);
            }];
            
            //添加他人的已有tags
            [self addOtherTags];
            //提供可选项
            [self addCommonTags];
        }
            break;
        case TagsViewTypeNone:
        {
            UIView *lastView = nil;
            for (NSString *tagText in self.tags) {
                UILabel *tagLabel = [UILabel new];
                tagLabel.textAlignment = NSTextAlignmentCenter;
                tagLabel.text = tagText;
                
                [self.tagScrollView addSubview:tagLabel];
                
                if (lastView) {
                    [tagLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.centerY.equalTo(_tagScrollView);
                        make.left.equalTo(lastView.mas_right).offset(margin);
                    }];
                } else{
                    [tagLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                        make.centerY.equalTo(_tagScrollView);
                        make.left.equalTo(_tagScrollView).offset(margin);
                    }];
                }
                lastView = tagLabel;
            }
            [lastView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.equalTo(_tagScrollView).offset(-margin);
            }];
        }
            break;
        case TagsViewTypeMutableSelect:
        {
            
        }
            break;
            
        default:
            break;
    }

}

#pragma mark - event 
#pragma mark - 点击添加按钮
-(void)addButtonAction
{
    [self addAction];
}
-(void)addAction
{
    [self endEditing:YES];
    
    //do add tag
    NSString *text = self.tagTextField.text;
    if (text.length) {
       text =  [StringTool filterStr:text];
        if (![self.tags containsObject:text]) {
             [self.tags objectAddObject:text];
              [self addOtherTags];
             [self.selectedTags objectAddObject:text];
            if ([self.delegate respondsToSelector:@selector(tagsViewSaveNewTag:)]) {
                [self.delegate tagsViewSaveNewTag:text];
            }
        }
        if (![self.commomTags containsObject:text]) {
              [self.commomTags objectAddObject:text];
              [self addCommonTags];
        }
    }
    self.tagTextField.text = nil;
    self.rightButton.enabled = NO;
}
- (void)addOtherTags
{
    for (UIView *subView in self.tagScrollView.subviews) {
        [subView removeFromSuperview];
    }
    //创建承载容器
    UIView* container = [UIView new];
    [self.tagScrollView addSubview:container];
    [container mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.tagScrollView);
        make.height.equalTo(self.tagScrollView);
    }];
     UIView *lastView = nil;
      int i = 0;
    [self.selectedTags addObjectsFromArray:self.tags];
    for (NSString *tagText in self.tags) {
        UIButton *tagButton = [UIButton new];
        tagButton.titleLabel.font = [UIFont systemFontOfSize:FONT_SIZE(24)];
        tagButton.tag = i;
        [tagButton setTitleColor:XCColor(55, 198, 92) forState:UIControlStateNormal];
        tagButton.layer.borderWidth = 0.6;
        tagButton.layer.borderColor = GJCFQuickHexColor(@"F2F2F2").CGColor;
        tagButton.layer.cornerRadius = 5;
        tagButton.layer.masksToBounds = YES;
        [tagButton addTarget:self action:@selector(showDeleteButton:) forControlEvents:UIControlEventTouchUpInside];
        [tagButton setTitle:tagText forState:UIControlStateNormal];
        
        CGSize size = [tagText sizeWithFont:tagButton.titleLabel.font constrainedToHeight:100];
        [container addSubview:tagButton];
        [tagButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.equalTo(container);
            make.width.mas_offset(size.width + 40);
            make.height.mas_equalTo(AUTO_HEIGHT(45));
            if (lastView) {
                make.left.mas_equalTo(lastView.mas_right).offset(10);

            }else
            {
                make.left.mas_equalTo(container.mas_left).offset(10);
            }
            
        }];
        lastView = tagButton;
        i ++;
    }
    if (lastView) {
        [container mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.mas_equalTo(lastView.mas_right);
        }];
    }
}

- (void)addCommonTagsWithTag:(NSString *)newTag{
    NSInteger index = self.commonTagsScrollView.subviews.count;
    TagButton *tagBtn = [TagButton new];
    tagBtn.tag = index;
    [tagBtn setTitle:newTag forState:UIControlStateNormal];
    [tagBtn addTarget:self action:@selector(comTagClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.commonTagsScrollView addSubview:tagBtn];
    
    CGSize size = [newTag sizeWithFont:tagBtn.titleLabel.font constrainedToHeight:100];
    
    [tagBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeZero);
        make.right.top.equalTo(_commonTagsScrollView);
    }];

    UIView *lastView = nil;
    for (UIView *subView in self.commonTagsScrollView.subviews) {
        if (lastView) {
            [subView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.centerY.equalTo(_commonTagsScrollView);
                make.left.equalTo(lastView.mas_right).offset(margin);
                make.width.mas_offset(size.width + 40);
            }];
        } else{
            [subView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.centerY.equalTo(_commonTagsScrollView);
                make.left.equalTo(_commonTagsScrollView);
                make.width.mas_offset(size.width + 40);
            }];
        }
        lastView = subView;
    }
    [lastView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_commonTagsScrollView);
    }];
    [_commonTagsScrollView setNeedsLayout];
}

- (void)addCommonTags
{
    if (self.commomTags.count <= 0) {
        self.commomTags = [NSMutableArray arrayWithArray:[[UserDBManager sharedManager] tagList]];
    }
    for (UIView *subView in self.commonTagsScrollView.subviews) {
        [subView removeFromSuperview];
    }
    UIView *lastView = nil;
    int i = 0;
    //创建承载的容器
    UIView* container = [UIView new];
    [self.commonTagsScrollView addSubview:container];
    [container mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.commonTagsScrollView);
        make.height.equalTo(self.commonTagsScrollView);
    }];
    for (NSString *tagText in _commomTags) {
        TagButton *tagBtn = [TagButton new];
        tagBtn.tag = i;
        [tagBtn setTitle:tagText forState:UIControlStateNormal];
        tagBtn.backgroundColor = LMBasicDarkGray;
        [tagBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        CGSize size = [tagText sizeWithFont:tagBtn.titleLabel.font constrainedToHeight:100];
        
        [tagBtn addTarget:self action:@selector(comTagClick:) forControlEvents:UIControlEventTouchUpInside];
        LMUserDetaiLongPressGestureRecognizer *longPress = [[LMUserDetaiLongPressGestureRecognizer alloc] initWithTarget:self action:@selector(comtagLongPress:)];
        longPress.longPressTag = tagBtn.tag;
        longPress.minimumPressDuration = 0.8;
        [tagBtn addGestureRecognizer:longPress];
        [container addSubview:tagBtn];
        [tagBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            if (lastView) {
                make.centerY.equalTo(container);
                make.left.equalTo(lastView.mas_right).offset(margin);
                make.width.mas_offset(size.width + 40);
                make.height.mas_equalTo(size.height + 10);
            }else
            {
                make.centerY.equalTo(container);
                make.left.equalTo(container).offset(margin);
                make.width.mas_offset(size.width + 40);
                make.height.mas_equalTo(size.height + 10);
            }
        }];
        lastView = tagBtn;
        i ++;
    }
    if (lastView) {
        [container mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(lastView.mas_right);
        }];
    }
    self.bottomContainer = container;
}
#pragma mark- 点击下边的按钮
- (void)comTagClick:(UIButton *)sender
{
    if([UIMenuController sharedMenuController]){
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    }
    sender.backgroundColor = LMBasicDarkBlue;
    [sender setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    if (self.bottomCommonButton) {
        self.bottomCommonButton.backgroundColor = LMBasicDarkGray;
        [self.bottomCommonButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        if (self.bottomCommonButton == sender) {
            self.bottomCommonButton.backgroundColor = LMBasicDarkBlue;
            [self.bottomCommonButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
    }
    NSString *tagStr = self.commomTags[sender.tag];
    if ([self.tags containsObject:tagStr]) {
        [self.tags removeObject:tagStr];
        [self.selectedTags removeObject:tagStr];

        if ([self.delegate respondsToSelector:@selector(removeTag:)]) {
            [self.delegate removeTag:tagStr];
        }
    }else
    {
        [self.tags addObject:tagStr];
        [self.selectedTags objectAddObject:tagStr];
        
        if ([self.delegate respondsToSelector:@selector(addTag:)]) {
            [self.delegate addTag:tagStr];
        }
    }
    self.bottomCommonButton = sender;
    [self addOtherTags];
}
- (BOOL) canPerformAction:(SEL)selector withSender:(id) sender {
    if (selector == @selector(deleteItemClicked:) /*|| selector == @selector(copy:)*/ /*<--enable that if you want the copy item */) {
        return YES;
    }else if (selector == @selector(deleteItemBottomClicked:))
    {
        return YES;
    }
    return NO;
}
- (BOOL) canBecomeFirstResponder {
    return YES;
}
#pragma mark - 上标签显示删除事件
- (void)showDeleteButton:(UIButton *)sender
{
    if (self.commonButton) {
         self.commonButton.backgroundColor = [UIColor whiteColor];
         [self.commonButton setTitleColor:LMBasicGreen forState:UIControlStateNormal];
    }
    sender.backgroundColor = LMBasicGreen;
    [sender setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    
    UIMenuController *menuController = [UIMenuController sharedMenuController];
    UIMenuItem *resetMenuItem = [[UIMenuItem alloc] initWithTitle:LMLocalizedString(@"Link Delete", nil) action:@selector(deleteItemClicked:)];
    menuController.integerProperty = sender.tag;
    NSAssert([self becomeFirstResponder], LMLocalizedString(@"Sorry, UIMenuController will not work with %@ since it cannot become first responder", nil), self);
    [menuController setMenuItems:[NSArray arrayWithObject:resetMenuItem]];
    [menuController setTargetRect:sender.frame inView:self.tagScrollView];
    [menuController setMenuVisible:YES animated:YES];
    self.commonButton = sender;
    
}
#pragma mark - 下标签长按
- (void)comtagLongPress:(LMUserDetaiLongPressGestureRecognizer *)sender
{
    if (self.bottomCommonButton) {
        self.bottomCommonButton.backgroundColor = LMBasicDarkGray;
        [self.bottomCommonButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    }

    UIMenuController *menuController = [UIMenuController sharedMenuController];
    UIMenuItem *resetMenuItem = [[UIMenuItem alloc] initWithTitle:LMLocalizedString(@"Link Delete", nil) action:@selector(deleteItemBottomClicked:)];
    menuController.integerProperty = sender.longPressTag;
    NSAssert([self becomeFirstResponder], LMLocalizedString(@"Sorry, UIMenuController will not work with %@ since it cannot become first responder", nil), self);
    [menuController setMenuItems:[NSArray arrayWithObject:resetMenuItem]];
    TagButton* button = self.bottomContainer.subviews[sender.longPressTag];
    [menuController setTargetRect:button.frame inView:self.commonTagsScrollView];
    [menuController setMenuVisible:YES animated:YES];
    button.backgroundColor = LMBasicDarkBlue;
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    self.bottomCommonButton = button;
    
}
#pragma mark - 下标签长按删除操作 代理
-(void)deleteItemBottomClicked:(UIMenuController*)sender
{
    NSInteger index = sender.integerProperty;
    NSString *tagStr = self.commomTags[index];
    [self.commomTags removeObjectAtIndexCheck:index];
    [self addCommonTags];
    if ([self.tags containsObject:tagStr]) {
        [self.tags removeObject:tagStr];
        [self addOtherTags];
    }
    
    
    if ([self.delegate respondsToSelector:@selector(removeBottomTag:)]) {
        [self.delegate removeBottomTag:tagStr];
    }
}
#pragma mark- 点击上边的按钮删除按钮
- (void) deleteItemClicked:(UIMenuController *) sender {
    //移除string
    
    NSInteger index = sender.integerProperty;
    NSString *tagStr = self.tags[index];
    [self.tags removeObjectAtIndexCheck:index];
    [self addOtherTags];
    
    if ([self.delegate respondsToSelector:@selector(removeTag:)]) {
        [self.delegate removeTag:tagStr];
    }
}


#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    DDLogInfo(@"%@",NSStringFromCGPoint(scrollView.contentOffset));
    DDLogInfo(@"%@",NSStringFromCGSize(scrollView.contentSize));
    DDLogInfo(@"%@",NSStringFromCGRect(scrollView.frame));
    [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
}

#pragma mark - UITextFieldDelegate

-(void)textChange:(UITextField*)textField
{
    if (textField.text.length <= 0) {
        self.rightButton.enabled = NO;
    }else
    {
        self.rightButton.enabled = YES;
    }
    if (textField.text.length >= 15) {
        self.tagTextField.text = [textField.text substringToIndex:15];
    }
    
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    
    [self endEditing:YES];
    
    //do add tag
    NSString *text = textField.text;
    if (text.length <= 0) {
        return YES;
    }
    if (![self.tags containsObject:text]) {
        [self.tags objectAddObject:text];
        [self addOtherTags];
         [self.selectedTags objectAddObject:text];
        if ([self.delegate respondsToSelector:@selector(tagsViewSaveNewTag:)]) {
            [self.delegate tagsViewSaveNewTag:text];
        }
    }
    if (![self.commomTags containsObject:text]) {
        [self.commomTags objectAddObject:text];
        [self addCommonTags];
    }
   
    self.tagTextField.text = nil;
    self.rightButton.enabled = NO;
    return YES;
}
#pragma mark - getter setter

- (NSMutableArray *)tags{
    if (!_tags) {
        _tags = [NSMutableArray array];
    }
    return _tags;
}

- (NSMutableArray *)commomTags{
    if (!_commomTags) {
        _commomTags = [NSMutableArray array];
    }
    return _commomTags;
}

- (NSMutableArray *)selectedTags{
    if (!_selectedTags) {
        _selectedTags = [NSMutableArray array];
    }
    return _selectedTags;
        
}

@end


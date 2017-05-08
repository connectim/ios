//
//  LMTableView.h
//  Connect
//
//  Created by Edwin on 16/7/22.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import <UIKit/UIKit.h>

@class LMTableView;

@protocol LMTableViewDelegate <NSObject>

/**
 *  Cell click method
 *
 *  @param view
 *  @param tap
 */
- (void)LMTableView:(LMTableView *)view tapTabelViewCellRecognizer:(UITapGestureRecognizer *)tap;

@end

@interface LMTableView : UIView
@property(nonatomic, strong) id <LMTableViewDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame withBalanceContentStr:(NSString *)content;

@end

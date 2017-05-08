//
//  LMMessageTextView.h
//  Connect
//
//  Created by MoHuilin on 2017/3/10.
//  Copyright © 2017年 Connect. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LMMessageTextViewDeleteCharDeletegate <NSObject>

- (void)deleteBackward;

@end

@interface LMMessageTextView : UITextView

@property(nonatomic, strong) id <LMMessageTextViewDeleteCharDeletegate> deleteCharDelegate;

@end

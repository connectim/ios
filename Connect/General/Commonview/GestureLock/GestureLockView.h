//
//  GestureLockView.h
//  app
//
//  Created by 余钦 on 16/5/4.
//
//

#import <UIKit/UIKit.h>

@class GestureLockView;
@protocol GestureLockViewDelegate <NSObject>

@optional
- (void)lockView:(GestureLockView *)lockView BeganTouch:(NSSet *)touchs;
- (void)lockView:(GestureLockView *)lockView didFinishPath:(NSString *)path;
@end

@interface GestureLockView : UIView
@property (nonatomic, weak) id<GestureLockViewDelegate> delegate;
@end

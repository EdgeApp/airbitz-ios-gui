//
//  DarkenView.h
//
//  See LICENSE for copy, modification, and use permissions
//
//  See AUTHORS for contributing developers
//

#import <UIKit/UIKit.h>

@protocol DarkenViewDelegate;

@interface DarkenView : UIView

@property (assign) id<DarkenViewDelegate> delegate;

@end

@protocol DarkenViewDelegate <NSObject>

@optional
- (void) DarkenViewTapped:(DarkenView *)view;

@end
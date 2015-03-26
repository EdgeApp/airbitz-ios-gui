//
//  TabBarView.h
//  WalletTest
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TabBarViewDelegate;

@interface TabBarView : UIView

@property (assign) id<TabBarViewDelegate> delegate;

- (void)selectButtonAtIndex:(int)index;
- (void)lockButton:(int)idx;
- (void)unlockButton:(int)idx;

@end

@protocol TabBarViewDelegate <NSObject>

@required

@optional
- (void)tabBarView:(TabBarView *)view selectedSubview:(UIView *)subview reselected:(BOOL)bReselected;
- (void)tabBarView:(TabBarView *)view selectedLockedSubview:(UIView *)subview;
@end

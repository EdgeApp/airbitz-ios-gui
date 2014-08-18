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

-(void)selectButtonAtIndex:(int)index;

@end

@protocol TabBarViewDelegate <NSObject>

@required

@optional
- (void)tabVarView:(TabBarView *)view selectedSubview:(UIView *)subview reselected:(BOOL)bReselected;
@end
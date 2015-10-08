//
//  DarkenView.h
//
//  Created by Carson Whitsett on 1/30/14.
//  Copyright (c) 2014 AirBitz, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BlurView.h"

@protocol DarkenViewDelegate;

@interface DarkenView : BlurView

@property (assign) id<DarkenViewDelegate> delegate;

@end

@protocol DarkenViewDelegate <NSObject>

@optional
- (void) DarkenViewTapped:(DarkenView *)view;

@end
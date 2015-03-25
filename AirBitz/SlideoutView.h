//
//  SlideoutView.h
//  AirBitz
//
//  Created by Tom on 3/25/15.
//  Copyright (c) 2015 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SlideoutViewDelegate;

@interface SlideoutView : UIView

@property (nonatomic, assign) id<SlideoutViewDelegate>   delegate;

@end

@protocol SlideoutViewDelegate <NSObject>

@required

@optional

- (void)slideoutAccount;
- (void)slideoutSettings;
- (void)slideoutLogout;
- (void)slideoutBuySell;
- (void)slideoutViewClosed:(SlideoutView *)slideoutView;

@end

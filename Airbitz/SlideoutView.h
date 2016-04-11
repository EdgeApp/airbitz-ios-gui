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

+ (SlideoutView *)CreateWithDelegate:(id)del parentView:(UIView *)parentView withTab:(UIView *)tabBar;

@property (assign) id<SlideoutViewDelegate>   delegate;
@property (nonatomic, strong) NSLayoutConstraint * leftConstraint;

- (void)showSlideout:(BOOL)show;
- (void)showSlideout:(BOOL)show withAnimation:(BOOL)bAnimation;
- (void)handleRecognizer:(UIPanGestureRecognizer *)recognizer fromBlock:(bool) block;
- (BOOL)isOpen;

@end

@protocol SlideoutViewDelegate <NSObject>

@required

@optional

- (void)slideoutAccount;
- (void)slideoutSettings;
- (void)slideoutLogout;
- (void)slideoutBuySell;
- (void)slideoutGiftCard;
- (void)slideoutImport;
- (void)slideoutWallets;
- (void)slideoutAffiliate;

- (void)slideoutWillOpen:(SlideoutView *)slideoutView;
- (void)slideoutWillClose:(SlideoutView *)slideoutView;
- (void)slideoutViewClosed:(SlideoutView *)slideoutView;

@end

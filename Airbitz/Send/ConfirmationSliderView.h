//
//  ConfirmationSliderView.h
//  AirBitz
//
//  Created by Carson Whitsett on 4/2/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ConfirmationSliderViewDelegate;

@interface ConfirmationSliderView : UIView

@property (assign) id<ConfirmationSliderViewDelegate> delegate;

+ (ConfirmationSliderView *)CreateInsideView:(UIView *)parentView withDelegate:(id<ConfirmationSliderViewDelegate>)delegate;

-(void)resetIn:(NSTimeInterval)timeToReset; //places slider back to original position

@end



@protocol ConfirmationSliderViewDelegate <NSObject>

@required
-(void)ConfirmationSliderDidConfirm:(ConfirmationSliderView *)controller;
@end
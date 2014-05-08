//
//  PopupWheelPickerView.h
//  AirBitz
//
//  Created by Adam Harris on 5/6/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PopupWheelPickerViewDelegate;

typedef enum ePopupWheelPickerPosition
{
    PopupWheelPickerPosition_Below,
    PopupWheelPickerPosition_Above,
    PopupWheelPickerPosition_Left,
    PopupWheelPickerPosition_Right
} tPopupWheelPickerPosition;

@interface PopupWheelPickerView : UIView


+ (PopupWheelPickerView *)CreateForView:(UIView *)parentView positionRelativeTo:(UIView *)posView withPosition:(tPopupWheelPickerPosition)position withChoices:(NSArray *)arrayChoices startingSelections:(NSArray *)arraySelections userData:(id)data andDelegate:(id<PopupWheelPickerViewDelegate>)delegate;

+ (PopupWheelPickerView *)CreateForView:(UIView *)parentView relativeToFrame:(CGRect)frame viewForFrame:(UIView *)frameView withPosition:(tPopupWheelPickerPosition)position withChoices:(NSArray *)arrayChoices startingSelections:(NSArray *)arraySelections userData:(id)data andDelegate:(id<PopupWheelPickerViewDelegate>)delegate;

@end

@protocol PopupWheelPickerViewDelegate <NSObject>

@required
- (void)PopupWheelPickerViewExit:(PopupWheelPickerView *)view withSelections:(NSArray *)arraySelections userData:(id)data;
- (void)PopupWheelPickerViewCancelled:(PopupWheelPickerView *)view userData:(id)data;

@optional


@end

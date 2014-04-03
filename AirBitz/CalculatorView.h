//
//  CalculatorView.h
//  AirBitz
//
//  Created by Carson Whitsett on 4/2/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CalculatorViewDelegate;

@interface CalculatorView : UIView

@property (nonatomic, assign) id<CalculatorViewDelegate> delegate;
@property (nonatomic, strong) UITextField *textField;

@end


@protocol CalculatorViewDelegate <NSObject>

@required
- (void) CalculatorDone:(CalculatorView *)calculator;
- (void) CalculatorValueChanged:(CalculatorView *)calculator;
@optional

@end
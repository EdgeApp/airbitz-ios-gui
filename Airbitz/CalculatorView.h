//
//  CalculatorView.h
//  AirBitz
//
//  Created by Carson Whitsett on 4/2/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ABCContext.h"

typedef enum eCalcMode
{
	CALC_MODE_COIN,
	CALC_MODE_FIAT
} tCalcMode;

@protocol CalculatorViewDelegate;

@interface CalculatorView : UIView

@property (nonatomic, assign) id<CalculatorViewDelegate> delegate;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, assign) tCalcMode calcMode;
@property (nonatomic, assign) ABCCurrency *currency;

- (void)hideDoneButton;

@end


@protocol CalculatorViewDelegate <NSObject>

@required
- (void) CalculatorDone:(CalculatorView *)calculator;
- (void) CalculatorValueChanged:(CalculatorView *)calculator;
@optional

@end

//
//  CalculatorView.h
//  AirBitz
//
//  See LICENSE for copy, modification, and use permissions
//
//  See AUTHORS for contributing developers
//

#import <UIKit/UIKit.h>

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
@property (nonatomic, assign) int currencyNum;

@end


@protocol CalculatorViewDelegate <NSObject>

@required
- (void) CalculatorDone:(CalculatorView *)calculator;
- (void) CalculatorValueChanged:(CalculatorView *)calculator;
@optional

@end

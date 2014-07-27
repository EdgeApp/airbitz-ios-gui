//
//  PopupWheelPickerView.h
//
 
//  Copyright (c) 2014, Airbitz
//  All rights reserved.
//
//  Redistribution and use in source and binary forms are permitted provided that
//  the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//  3. Redistribution or use of modified source code requires the express written
//  permission of Airbitz Inc.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those
//  of the authors and should not be interpreted as representing official policies,
//  either expressed or implied, of the Airbitz Project.
//
//  See AUTHORS for contributing developers
//


#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end



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

@property (weak, nonatomic)     IBOutlet UIPickerView           *viewPicker;


+ (PopupWheelPickerView *)CreateForView:(UIView *)parentView positionRelativeTo:(UIView *)posView withPosition:(tPopupWheelPickerPosition)position withChoices:(NSArray *)arrayChoices startingSelections:(NSArray *)arraySelections userData:(id)data andDelegate:(id<PopupWheelPickerViewDelegate>)delegate;

+ (PopupWheelPickerView *)CreateForView:(UIView *)parentView relativeToFrame:(CGRect)frame viewForFrame:(UIView *)frameView withPosition:(tPopupWheelPickerPosition)position withChoices:(NSArray *)arrayChoices startingSelections:(NSArray *)arraySelections userData:(id)data andDelegate:(id<PopupWheelPickerViewDelegate>)delegate;

@end

@protocol PopupWheelPickerViewDelegate <NSObject>

@required

- (void)PopupWheelPickerViewExit:(PopupWheelPickerView *)view withSelections:(NSArray *)arraySelections userData:(id)data;
- (void)PopupWheelPickerViewCancelled:(PopupWheelPickerView *)view userData:(id)data;

@optional

- (CGFloat)PopupWheelPickerView:(PopupWheelPickerView *)pickerView widthForComponent:(NSInteger)component userData:(id)data;

@end

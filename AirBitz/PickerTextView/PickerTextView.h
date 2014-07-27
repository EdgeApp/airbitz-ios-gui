//
//  PickerTextView.h
//  AirBitz
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
#import "PopupPickerView.h"

@protocol PickerTextViewDelegate;

@interface PickerTextView : UIView

@property (nonatomic, assign) id<PickerTextViewDelegate>    delegate;
@property (nonatomic, strong) UITextField                   *textField;
@property (nonatomic, strong) PopupPickerView               *popupPicker; //nil until picker actually appears
@property (nonatomic, assign) tPopupPickerPosition          popupPickerPosition;
@property (nonatomic, assign) NSInteger                     pickerMaxChoicesVisible; //can constrain to a certain number of choices
@property (nonatomic, assign) NSInteger                     pickerWidth;
@property (nonatomic, assign) NSInteger                     pickerCellHeight;
@property (nonatomic, assign) UITableViewCellStyle          pickerTableViewCellStyle;
@property (nonatomic, strong) NSArray                       *arrayChoices;
@property (nonatomic, assign) CGFloat                       cropPointTop;
@property (nonatomic, assign) CGFloat                       cropPointBottom;


- (void)setTextFieldObject:(UITextField *)newTextField;
- (void)setTopMostView:(UIView *)topMostView; //what view will the drop down selector be added to?
- (void)updateChoices:(NSArray *)arrayChoices;
- (void)dismissPopupPicker;

@end

@protocol PickerTextViewDelegate <NSObject>

@required


@optional

- (BOOL)pickerTextViewFieldShouldChange:(PickerTextView *)pickerTextView charactersInRange:(NSRange)range replacementString:(NSString *)string;
- (void)pickerTextViewFieldDidChange:(PickerTextView *)pickerTextView;
- (void)pickerTextViewFieldDidBeginEditing:(PickerTextView *)pickerTextView;
- (BOOL)pickerTextViewShouldEndEditing:(PickerTextView *)pickerTextView;
- (void)pickerTextViewFieldDidEndEditing:(PickerTextView *)pickerTextView;
- (BOOL)pickerTextViewFieldShouldReturn:(PickerTextView *)pickerTextView;
- (void)pickerTextViewPopupSelected:(PickerTextView *)view onRow:(NSInteger)row;
- (BOOL)pickerTextViewPopupFormatCell:(PopupPickerView *)view onRow:(NSInteger)row withCell:(UITableViewCell *)cell;
- (NSInteger)pickerTextViewPopupNumberOfRows:(PopupPickerView *)view;
- (UITableViewCell *)pickerTextViewPopupCellForRow:(PopupPickerView *)view forTableView:(UITableView *)tableView andRow:(NSInteger)row;
- (void)pickerTextViewFieldDidShowPopup:(PickerTextView *)pickerTextView;

@end
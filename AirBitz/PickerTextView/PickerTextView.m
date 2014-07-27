//
//  PickerTextView.m
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



#import <QuartzCore/QuartzCore.h>
#import "PickerTextView.h"

#define PICKER_MAX_CELLS_VISIBLE        3
#define PICKER_WIDTH                    320
#define PICKER_CELL_HEIGHT              44

@interface PickerTextView () <UITextFieldDelegate, PopupPickerViewDelegate>
{
    UIView *_viewTop;
}



@end

@implementation PickerTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        [self initMyVariables];

    }
    return self;
}

- (void)awakeFromNib
{
    [self initMyVariables];
}


#pragma mark - Public Methods

- (void)setTextFieldObject:(UITextField *)newTextField
{
	[self.textField removeFromSuperview];
	
    self.textField = newTextField;

	self.textField.frame = self.bounds;
	[self addSubview:self.textField];
    [self configTextField];
}

- (void)setTopMostView:(UIView *)topMostView
{
    _viewTop = topMostView;
}

- (void)updateChoices:(NSArray *)arrayChoices
{
    self.arrayChoices = arrayChoices;
    [self.popupPicker updateStrings:self.arrayChoices];
    [self setCropPoints];

    if ([arrayChoices count] > 0)
    {
        if (!self.popupPicker)
        {
            [self createPopupPicker];
        }
    }
    else
    {
        [self dismissPopupPicker];
    }
}

#pragma mark - Action Methods


#pragma mark - Misc Methods

- (void)initMyVariables
{
    // create our text view
    CGRect frame = self.frame;
    frame.origin.x = 0;
    frame.origin.y = 0;
    self.textField = [[UITextField alloc] initWithFrame:frame];
    [self addSubview:self.textField];

    self.cropPointTop = -1;
    self.cropPointBottom = -1;

    self.popupPickerPosition = PopupPickerPosition_Below;
    self.popupPicker = nil;

    self.pickerMaxChoicesVisible = PICKER_MAX_CELLS_VISIBLE;
    self.pickerWidth = PICKER_WIDTH;
    self.pickerCellHeight = PICKER_CELL_HEIGHT;

    self.pickerTableViewCellStyle = UITableViewCellStyleDefault;

    _viewTop = [self superview];

    [self configTextField];
}

- (void)configTextField
{
    self.textField.delegate = self;

    // get a callback when there are changes
    [self.textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)dismissPopupPicker
{
    if (self.popupPicker)
    {
        [self.popupPicker removeFromSuperview];
        self.popupPicker = nil;
    }
}

- (void)createPopupPicker
{
    // No arrayChoices? Don't show a popup
    if ([self.arrayChoices count] <= 0)
        return;

    // We already have one open
    if (self.popupPicker)
        return;

    self.popupPicker = [PopupPickerView CreateForView:_viewTop
										 relativeToView:self.textField
                                         relativePosition:self.popupPickerPosition
                                          withStrings:self.arrayChoices
                                          selectedRow:-1
                                            withWidth:_pickerWidth
                                        andCellHeight:_pickerCellHeight
                        ];
    self.popupPicker.tableViewCellStyle = self.pickerTableViewCellStyle;
    [self.popupPicker disableBackgroundTouchDetect];
	self.popupPicker.delegate = self;
    [self setCropPoints];

    if ([self.delegate respondsToSelector:@selector(pickerTextViewFieldDidShowPopup:)])
    {
        return [self.delegate pickerTextViewFieldDidShowPopup:self];
    }
}

- (void)setCropPoints
{
    if (self.popupPicker)
    {
        if (self.cropPointTop != -1)
        {
            [self.popupPicker addCropLine:CGPointMake(0, self.cropPointTop) direction:PopupPickerPosition_Above animated:NO];
        }
        if (self.cropPointBottom != -1)
        {
            [self.popupPicker addCropLine:CGPointMake(0, self.cropPointBottom) direction:PopupPickerPosition_Below animated:NO];
        }
    }
}

#pragma mark - UITextField delegates

- (BOOL)textField:(UITextField *)theTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (nil != self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(pickerTextViewFieldShouldChange:charactersInRange:replacementString:)])
        {
            return [self.delegate pickerTextViewFieldShouldChange:self charactersInRange:range replacementString:string];
        }
    }

    return YES;
}

- (void)textFieldDidChange:(UITextField *)textField
{
    if (nil != self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(pickerTextViewFieldDidChange:)])
        {
            [self.delegate pickerTextViewFieldDidChange:self];
        }
    }
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    BOOL bShouldEnd = YES;

    if (nil != self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(pickerTextViewShouldEndEditing:)])
        {
            bShouldEnd = [self.delegate pickerTextViewShouldEndEditing:self];
        }
    }

    return bShouldEnd;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (nil != self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(pickerTextViewFieldDidBeginEditing:)])
        {
            [self.delegate pickerTextViewFieldDidBeginEditing:self];
        }
    }

    [self createPopupPicker];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (nil != self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(pickerTextViewFieldDidEndEditing:)])
        {
            [self.delegate pickerTextViewFieldDidEndEditing:self];
        }
    }

    [self dismissPopupPicker];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (nil != self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(pickerTextViewFieldShouldReturn:)])
        {
            return [self.delegate pickerTextViewFieldShouldReturn:self];
        }
    }

    if (self.textField.returnKeyType == UIReturnKeyDone)
    {
        [textField resignFirstResponder];
    }

	return YES;
}

#pragma mark - Popup Picker Delegate Methods-

- (void)PopupPickerViewSelected:(PopupPickerView *)view onRow:(NSInteger)row userData:(id)data
{
    BOOL bHandled = NO;

    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(pickerTextViewPopupSelected: onRow:)])
        {
            [self.delegate pickerTextViewPopupSelected:self onRow:row];
            bHandled = YES;
        }
    }

    // if it wasn't handled by our delegate
    if (bHandled == NO)
    {
        // set the text field to the choice
        self.textField.text = [self.arrayChoices objectAtIndex:row];
    }

    //[self dismissPopupPicker];
}

- (void)PopupPickerViewCancelled:(PopupPickerView *)view userData:(id)data
{
    //[self dismissPopupPicker];
}

- (BOOL)PopupPickerViewFormatCell:(PopupPickerView *)view onRow:(NSInteger)row withCell:(UITableViewCell *)cell userData:(id)data
{
    BOOL bFormatted = NO;

    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(pickerTextViewPopupFormatCell: onRow: withCell:)])
        {
            bFormatted = [self.delegate pickerTextViewPopupFormatCell:view onRow:row withCell:cell];
        }
    }

    return bFormatted;
}

- (NSInteger)PopupPickerViewNumberOfRows:(PopupPickerView *)view userData:(id)data
{
    NSInteger nRows = -1; // this allows picker view to use its own logic

    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(pickerTextViewPopupNumberOfRows:)])
        {
            nRows = [self.delegate pickerTextViewPopupNumberOfRows:view];
        }
    }

    return nRows;
}

- (UITableViewCell *)PopupPickerViewCellForRow:(PopupPickerView *)view forTableView:(UITableView *)tableView andRow:(NSInteger)row userData:(id)data
{
    UITableViewCell *cell = nil;

    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(pickerTextViewPopupCellForRow: forTableView: andRow:)])
        {
            cell = [self.delegate pickerTextViewPopupCellForRow:view forTableView:tableView andRow:row];
        }
    }

    return cell;
}

@end

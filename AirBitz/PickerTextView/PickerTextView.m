//
//  PickerTextView.m
//  AirBitz
//
//  Created by Adam Harris on 5/8/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

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

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

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

- (void)updateChoices:(NSArray *)arrayChoices;
{
    self.arrayChoices = arrayChoices;
    [self.popupPicker updateStrings:self.arrayChoices];
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
    self.popupPicker = [PopupPickerView CreateForView:_viewTop
                                      relativeToFrame:self.textField.frame
                                         viewForFrame:self
                                         withPosition:self.popupPickerPosition
                                          withStrings:self.arrayChoices
                                          selectedRow:-1
                                      maxCellsVisible:_pickerMaxChoicesVisible
                                            withWidth:_pickerWidth
                                        andCellHeight:_pickerCellHeight
                        ];
    self.popupPicker.tableViewCellStyle = self.pickerTableViewCellStyle;
    [self.popupPicker disableBackgroundTouchDetect];
    [self.popupPicker assignDelegate:self];
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

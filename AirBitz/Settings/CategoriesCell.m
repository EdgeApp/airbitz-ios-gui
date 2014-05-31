//
//  CategoriesCell.m
//  AirBitz
//
//  Created by AdamHarris on 5/7/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "CategoriesCell.h"

@interface CategoriesCell () <PickerTextViewDelegate>

{
}

@end

@implementation CategoriesCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
    {

    }
    return self;
}

- (void)awakeFromNib
{
	//prevent ugly gray box from appearing behind cell when selected
	self.backgroundColor = [UIColor clearColor];
	self.selectedBackgroundView = [[UIImageView alloc] initWithFrame:self.bounds];
	self.selectedBackgroundView.contentMode = self.backgroundView.contentMode;

	self.pickerTextView.delegate = self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setPickerMaxChoicesVisible:(NSInteger)pickerMaxChoicesVisible
{
    _pickerMaxChoicesVisible = pickerMaxChoicesVisible;
    self.pickerTextView.pickerMaxChoicesVisible = _pickerMaxChoicesVisible;
}

#pragma mark - Action Methods

- (IBAction)buttonDeleteTouched:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(categoriesCellDeleteTouched:)])
	{
		[self.delegate categoriesCellDeleteTouched:self];
	}
}

#pragma mark - PickerTextView Delegates

- (BOOL)pickerTextViewFieldShouldChange:(PickerTextView *)pickerTextView charactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (nil != self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(categoriesCellTextShouldChange:charactersInRange:replacementString:)])
        {
            return [self.delegate categoriesCellTextShouldChange:self charactersInRange:range replacementString:string];
        }
    }

    return YES;
}

- (void)pickerTextViewFieldDidChange:(PickerTextView *)pickerTextView
{
	if ([self.delegate respondsToSelector:@selector(categoriesCellTextDidChange:)])
	{
		[self.delegate categoriesCellTextDidChange:self];
	}
}

- (void)pickerTextViewFieldDidBeginEditing:(PickerTextView *)pickerTextView
{
	if ([self.delegate respondsToSelector:@selector(categoriesCellBeganEditing:)])
	{
		[self.delegate categoriesCellBeganEditing:self];
	}
}

- (void)pickerTextViewFieldDidEndEditing:(PickerTextView *)pickerTextView
{
	if ([self.delegate respondsToSelector:@selector(categoriesCellEndEditing:)])
	{
		[self.delegate categoriesCellEndEditing:self];
	}
}

- (BOOL)pickerTextViewFieldShouldReturn:(PickerTextView *)pickerTextView
{
    if (nil != self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(categoriesCellTextShouldReturn:)])
        {
            return [self.delegate categoriesCellTextShouldReturn:self];
        }
    }

    if (pickerTextView.textField.returnKeyType == UIReturnKeyDone)
    {
        [pickerTextView.textField resignFirstResponder];
    }

	return YES;
}

- (void)pickerTextViewPopupSelected:(PickerTextView *)view onRow:(NSInteger)row
{
    BOOL bHandled = NO;

    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(categoriesCellPopupSelected: onRow:)])
        {
            [self.delegate categoriesCellPopupSelected:self onRow:row];
            bHandled = YES;
        }
    }

    // if it wasn't handled by our delegate
    if (bHandled == NO)
    {
        // set the text field to the choice
        view.textField.text = [view.arrayChoices objectAtIndex:row];
    }
}

- (void)pickerTextViewFieldDidShowPopup:(PickerTextView *)pickerTextView
{
    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(categoriesCellDidShowPopup:)])
        {
            [self.delegate categoriesCellDidShowPopup:self];
        }
    }
}

@end

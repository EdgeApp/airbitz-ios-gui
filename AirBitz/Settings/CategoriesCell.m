//
//  CategoriesCell.m
//  AirBitz
//
//  Created by AdamHarris on 5/7/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "CategoriesCell.h"

@interface CategoriesCell () <UITextFieldDelegate>

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
	
	self.textField.delegate = self;

    // Add a "textFieldDidChange" notification method to the text field control.
    [self.textField addTarget:self
                       action:@selector(textFieldDidChange:)
             forControlEvents:UIControlEventEditingChanged];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Action Methods

- (IBAction)buttonDeleteTouched:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(categoriesCellDeleteTouched:)])
	{
		[self.delegate categoriesCellDeleteTouched:self];
	}
}

#pragma mark - UITextField delegates

- (void)textFieldDidChange:(UITextField *)textField
{
	if ([self.delegate respondsToSelector:@selector(categoriesCellTextDidChange:)])
	{
		[self.delegate categoriesCellTextDidChange:self];
	}
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	if ([self.delegate respondsToSelector:@selector(categoriesCellBeganEditing:)])
	{
		[self.delegate categoriesCellBeganEditing:self];
	}
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if ([self.delegate respondsToSelector:@selector(categoriesCellEndEditing:)])
	{
		[self.delegate categoriesCellEndEditing:self];
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];

    if ([self.delegate respondsToSelector:@selector(categoriesCellTextDidReturn:)])
	{
		[self.delegate categoriesCellTextDidReturn:self];
	}

	return YES;
}
@end

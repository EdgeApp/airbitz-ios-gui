//
//  TextFieldCell.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/31/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "TextFieldCell.h"
@interface TextFieldCell () <UITextFieldDelegate>
{
}
@end

@implementation TextFieldCell

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

#pragma mark UITextField delegates

- (void)textFieldDidChange:(UITextField *)textField
{
	if ([self.delegate respondsToSelector:@selector(textFieldCellTextDidChange:)])
	{
		[self.delegate textFieldCellTextDidChange:self];
	}
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	if ([self.delegate respondsToSelector:@selector(textFieldCellBeganEditing:)])
	{
		[self.delegate textFieldCellBeganEditing:self];
	}
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if ([self.delegate respondsToSelector:@selector(textFieldCellEndEditing:)])
	{
		[self.delegate textFieldCellEndEditing:self];
	}
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];

    if ([self.delegate respondsToSelector:@selector(textFieldCellTextDidReturn:)])
	{
		[self.delegate textFieldCellTextDidReturn:self];
	}

	return YES;
}
@end

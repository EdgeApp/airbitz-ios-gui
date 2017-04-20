//
//  TextViewCell.m
//  Airbitz
//
//  Created by Paul Puey on 2017/04/02.
//  Copyright (c) 2017 AirBitz. All rights reserved.
//

#import "TextViewCell.h"
@interface TextViewCell () <UITextViewDelegate>
{
}
@end

@implementation TextViewCell

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
    [super awakeFromNib];
    
	//prevent ugly gray box from appearing behind cell when selected
	self.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.6];
	self.selectedBackgroundView = [[UIImageView alloc] initWithFrame:self.bounds];
	self.selectedBackgroundView.contentMode = self.backgroundView.contentMode;
	
	self.textView.delegate = self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark UITextView delegates

- (void)textViewDidChange:(UITextView *)textView
{
	if ([self.delegate respondsToSelector:@selector(textViewCellTextDidChange:)])
	{
		[self.delegate textViewCellTextDidChange:self];
	}
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	if ([self.delegate respondsToSelector:@selector(textViewCellBeganEditing:)])
	{
		[self.delegate textViewCellBeganEditing:self];
	}
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	if ([self.delegate respondsToSelector:@selector(textViewCellEndEditing:)])
	{
		[self.delegate textViewCellEndEditing:self];
	}
}

@end

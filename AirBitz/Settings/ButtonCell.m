//
//  ButtonCell.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/31/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "ButtonCell.h"

@implementation ButtonCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
	{
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib
{
	//prevent ugly gray box from appearing behind cell when selected
	self.backgroundColor = [UIColor clearColor];
	self.selectedBackgroundView = [[UIImageView alloc] initWithFrame:self.bounds];
	self.selectedBackgroundView.contentMode = self.backgroundView.contentMode;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(IBAction)ButtonPressed
{
	if([self.delegate respondsToSelector:@selector(buttonCellButtonPressed:)])
	{
		[self.delegate buttonCellButtonPressed:self];
	}
}

@end

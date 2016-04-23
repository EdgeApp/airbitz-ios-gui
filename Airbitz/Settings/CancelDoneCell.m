//
//  CancelDoneCell.m
//  AirBitz
//
//  Created by Carson Whitsett on 4/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "CancelDoneCell.h"
#import "Strings.h"

@implementation CancelDoneCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
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
	[self.cancelButton setTitle:cancelButtonText forState:UIControlStateNormal];
	[self.doneButton setTitle:doneButtonText forState:UIControlStateNormal];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(IBAction)Cancel
{
	if([self.delegate respondsToSelector:@selector(CancelDoneCellCancelPressed)])
	{
		[self.delegate CancelDoneCellCancelPressed];
	}
}

-(IBAction)Done
{
	if([self.delegate respondsToSelector:@selector(CancelDoneCellDonePressed)])
	{
		[self.delegate CancelDoneCellDonePressed];
	}
}

@end

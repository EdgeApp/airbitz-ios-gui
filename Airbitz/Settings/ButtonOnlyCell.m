//
//  ButtonOnlyCell.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/31/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "ButtonOnlyCell.h"
#import "Theme.h"

@implementation ButtonOnlyCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setThemeValues];
    }
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
	//prevent ugly gray box from appearing behind cell when selected
	self.backgroundColor = [UIColor clearColor];
	self.selectedBackgroundView = [[UIImageView alloc] initWithFrame:self.bounds];
	self.selectedBackgroundView.contentMode = self.backgroundView.contentMode;
    
    [self setThemeValues];
}

- (void)setThemeValues {
    self.button.tintColor = [Theme Singleton].colorWhite;
    self.button.titleLabel.font = [UIFont fontWithName:[Theme Singleton].appFont size:18.0];
    self.button.backgroundColor = [Theme Singleton].colorMidPrimary;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(IBAction)ButtonPressed
{
	if([self.delegate respondsToSelector:@selector(buttonOnlyCellButtonPressed:)])
	{
		[self.delegate buttonOnlyCellButtonPressed:self];
	}
}


@end

//
//  ButtonCell.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/31/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "ButtonCell.h"
#import "Theme.h"

@implementation ButtonCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
	{
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

    // cause the font size on the button to adjust to fit
    self.button.titleLabel.numberOfLines = 1;
    self.button.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.button.titleLabel.lineBreakMode = NSLineBreakByClipping;
    
    [self setThemeValues];
}

- (void)setThemeValues {
    self.name.textColor = [Theme Singleton].colorDarkPrimary;
    self.name.font = [UIFont fontWithName:[Theme Singleton].appFont size:18.0];
    
    self.button.tintColor = [Theme Singleton].colorMidPrimary;
    self.button.titleLabel.font = [UIFont fontWithName:[Theme Singleton].appFont size:18.0];
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

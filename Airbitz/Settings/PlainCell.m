//
//  PlainCell.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/31/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "PlainCell.h"
#import "Theme.h"

@implementation PlainCell

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
    [super awakeFromNib];

    //prevent ugly gray box from appearing behind cell when selected
	self.backgroundColor = [UIColor clearColor];
	self.selectedBackgroundView = [[UIImageView alloc] initWithFrame:self.bounds];
	self.selectedBackgroundView.contentMode = self.backgroundView.contentMode;
}

- (void)setThemeValues {
    self.name.textColor = [Theme Singleton].colorDarkPrimary;
    self.name.font = [UIFont fontWithName:[Theme Singleton].appFont size:18.0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

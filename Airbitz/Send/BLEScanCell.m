//
//  BLEScanCell.m
//  AirBitz
//
//  Created by Carson Whitsett on 8/13/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "BLEScanCell.h"
#import "Theme.h"

@implementation BLEScanCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setThemeValues];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self setThemeValues];
}

- (void)setThemeValues {
    self.contactName.font = [UIFont fontWithName:[Theme Singleton].appFont size:14.0];
    
    self.contactBitcoinAddress.font = [UIFont fontWithName:[Theme Singleton].appFont size:14.0];
    
    self.duplicateNamesLabel.font = [UIFont fontWithName:[Theme Singleton].appFont size:14.0];
    self.duplicateNamesLabel.textColor = [Theme Singleton].colorSecondAccent;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

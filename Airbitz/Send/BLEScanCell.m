//
//  BLEScanCell.m
//  AirBitz
//
//  Created by Carson Whitsett on 8/13/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "BLEScanCell.h"

@implementation BLEScanCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

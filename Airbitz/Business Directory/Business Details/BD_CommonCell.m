//
//  BD_CommonCell.m
//  AirBitz
//
//  Created by Paul Puey on 2015/05/04.
//  Copyright (c) 2015 AirBitz. All rights reserved.
//

#import "BD_CommonCell.h"

@implementation BD_CommonCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

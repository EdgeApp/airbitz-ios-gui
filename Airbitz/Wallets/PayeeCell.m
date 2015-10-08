//
//  PayeeCell.m
//  AirBitz
//
//  Created by Adam Harris on 5/29/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "PayeeCell.h"

#define MARGIN 10

@implementation PayeeCell

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
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    CGRect cvf = self.contentView.frame;
    self.imageView.frame = CGRectMake(0.0,
                                      0.0,
                                      cvf.size.height-1,
                                      cvf.size.height-1);
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    //self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    //self.imageView.contentMode = UIViewContentModeScaleToFill;

    CGRect frame = CGRectMake(cvf.size.height + MARGIN,
                              self.textLabel.frame.origin.y,
                              cvf.size.width - cvf.size.height - 2*MARGIN,
                              self.textLabel.frame.size.height);
    self.textLabel.frame = frame;
    
    frame = CGRectMake(cvf.size.height + MARGIN,
                       self.detailTextLabel.frame.origin.y,
                       cvf.size.width - cvf.size.height - 2*MARGIN,
                       self.detailTextLabel.frame.size.height);
    self.detailTextLabel.frame = frame;
}

@end

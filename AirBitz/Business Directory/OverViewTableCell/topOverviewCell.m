//
//  topOverviewCell.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/5/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "topOverviewCell.h"
#import "RibbonView.h"

@interface topOverviewCell ()

@end

@implementation topOverviewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
	{
        // Initialization code
		
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setRibbon:(NSString *)ribbon
{
	RibbonView *ribbonView;
	
	ribbonView = (RibbonView *)[self.contentView viewWithTag:TAG_RIBBON_VIEW];
	if(ribbonView)
	{
		[ribbonView flyIntoPosition];
		if(ribbon.length)
		{
			ribbonView.hidden = NO;
			ribbonView.string = ribbon;
		}
		else
		{
			ribbonView.hidden = YES;
		}
	}
	else
	{
		if(ribbon.length)
		{
			ribbonView = [[RibbonView alloc] initAtLocation:CGPointMake(self.contentView.bounds.origin.x + self.contentView.bounds.size.width, 17.0) WithString:ribbon];
			[self.contentView addSubview:ribbonView];
		}
	}
}



@end

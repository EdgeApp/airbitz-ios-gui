//
//  LatoLabel.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/6/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "LatoLabel.h"
#import "Theme.h"

@implementation LatoLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib {
    [super awakeFromNib];
    self.font = [UIFont fontWithName:[Theme Singleton].appFont size:self.font.pointSize];
//	if((self.tag % 100) == 0)
//	{
//		self.font = [UIFont fontWithName:@"Lato-Regular" size:self.font.pointSize];
//	}
//	else if((self.tag % 100) == 1)
//	{
//		self.font = [UIFont fontWithName:@"Lato-Bold" size:self.font.pointSize];
//	}
//	else //if((self.tag % 100) == 2)
//	{
//		self.font = [UIFont fontWithName:@"Lato-Black" size:self.font.pointSize];
//	}

}
@end

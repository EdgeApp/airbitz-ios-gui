//
//  MontserratLabel.m
//  AirBitz
//
//  See LICENSE for copy, modification, and use permissions
//
//  See AUTHORS for contributing developers
//

#import "MontserratLabel.h"

@implementation MontserratLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib
{
	[super awakeFromNib];
	if((self.tag % 100) == 0)
	{
		self.font = [UIFont fontWithName:@"Montserrat-Regular" size:self.font.pointSize];
	}
	else
	{
		self.font = [UIFont fontWithName:@"Montserrat-Bold" size:self.font.pointSize];
	}
}

@end

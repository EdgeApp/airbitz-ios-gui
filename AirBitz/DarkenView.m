//
//  DarkenView.m
//
//  See LICENSE for copy, modification, and use permissions
//
//  See AUTHORS for contributing developers
//

#import "DarkenView.h"

@implementation DarkenView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if([self.delegate respondsToSelector:@selector(DarkenViewTapped:)])
	{
		[self.delegate DarkenViewTapped:self];
	}
}

@end



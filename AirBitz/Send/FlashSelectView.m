//
//  FlashSelectView.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "FlashSelectView.h"

@interface FlashSelectView ()
{
	UIImageView *buttonImage;
}
@end

@implementation FlashSelectView

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
	buttonImage = [[UIImageView alloc] initWithFrame:self.bounds];
	[self addSubview:buttonImage];
	buttonImage.image = [UIImage imageNamed:@"flash_auto"];
	self.backgroundColor = [UIColor clearColor];
}

-(void)selectItem:(tFlashItem)flashType
{
	switch(flashType)
	{
		case FLASH_ITEM_ON:
			buttonImage.image = [UIImage imageNamed:@"flash_on"];
			break;
		case FLASH_ITEM_AUTO:
			buttonImage.image = [UIImage imageNamed:@"flash_auto"];
			break;
		case FLASH_ITEM_OFF:
			buttonImage.image = [UIImage imageNamed:@"flash_off"];
			break;
	}
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:self];
	
	if(touchPoint.x < self.frame.size.width * 0.33333333)
	{
		buttonImage.image = [UIImage imageNamed:@"flash_on"];
		[self.delegate flashItemSelected:FLASH_ITEM_ON];
	}
	else if(touchPoint.x < self.frame.size.width * 0.66666666)
	{
		buttonImage.image = [UIImage imageNamed:@"flash_auto"];
		[self.delegate flashItemSelected:FLASH_ITEM_AUTO];
	}
	else
	{
		buttonImage.image = [UIImage imageNamed:@"flash_off"];
		[self.delegate flashItemSelected:FLASH_ITEM_OFF];
	}
}


@end

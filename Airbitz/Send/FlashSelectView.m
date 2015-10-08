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
	UIImageView *_buttonImage;
    BOOL        _bAwake;
    CGRect      _originalFrame;
    UIImage     *flashOff;
    UIImage     *flashOn;
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
    flashOff = [UIImage imageNamed:@"flash-off"];
    flashOn = [UIImage imageNamed:@"flash-on"];
	_buttonImage = [[UIImageView alloc] initWithFrame:self.bounds];
	[self addSubview:_buttonImage];
	_buttonImage.image = flashOff;
	self.backgroundColor = [UIColor clearColor];
    _originalFrame = self.frame;
    _bAwake = YES;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];

    if (_bAwake)
    {
        // if our size changed
        if ((_originalFrame.size.height != frame.size.height) ||
            (_originalFrame.size.width  != frame.size.width))
        {
            // we need to change our button's size
            CGFloat perWidthChange = frame.size.width / _originalFrame.size.width;
            CGFloat perHeightChange = frame.size.height / _originalFrame.size.height;
            //CGFloat perChangeMin = (perWidthChange < perHeightChange ? perWidthChange : perHeightChange);
            // note: use perChangeMin on each of these if you want to maintain aspect ratio
            CGFloat buttonNewHeight = _buttonImage.frame.size.height * perHeightChange;
            CGFloat buttonNewWidth = _buttonImage.frame.size.width * perWidthChange;
            CGRect  buttonFrame = _buttonImage.frame;
            buttonFrame.size.width = buttonNewWidth;
            buttonFrame.size.height = buttonNewHeight;
            buttonFrame.origin.x = ((self.frame.size.width - buttonNewWidth) / 2.0);
                        buttonFrame.origin.y = ((self.frame.size.height - buttonNewHeight) / 2.0);
            _buttonImage.frame = buttonFrame;
        }
    }
}

-(void)selectItem:(tFlashItem)flashType
{
	switch(flashType)
	{
		case FLASH_ITEM_ON:
			_buttonImage.image = flashOn;
			break;
		case FLASH_ITEM_OFF:
			_buttonImage.image = flashOff;
			break;
	}
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_buttonImage.image == flashOn) {
		_buttonImage.image = flashOff;
		[self.delegate flashItemSelected:FLASH_ITEM_OFF];
    } else {
		_buttonImage.image = flashOn;
		[self.delegate flashItemSelected:FLASH_ITEM_ON];
    }
}


@end

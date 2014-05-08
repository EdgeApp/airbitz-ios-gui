//
//  PickerTextView.m
//  AirBitz
//
//  Created by Adam Harris on 5/8/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PickerTextView.h"

@interface PickerTextView () <UITextFieldDelegate>
{

}

@end

@implementation PickerTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        [self initMyVariables];

    }
    return self;
}

- (void)awakeFromNib
{
    [self initMyVariables];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

#pragma mark - Public Methods

#pragma mark - Misc Methods

- (void)initMyVariables
{
    // create our text view
    CGRect frame = self.frame;
    frame.origin.x = 0;
    frame.origin.y = 0;
    self.textField = [[UITextField alloc] initWithFrame:frame];
    [self addSubview:self.textField];
}


@end

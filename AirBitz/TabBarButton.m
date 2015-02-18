//
//  TabBarButton.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "TabBarButton.h"
#import "LatoLabel.h"

#define LEFT_BUTTON_TAG        0
#define RIGHT_BUTTON_TAG    4

#define SELECTED_IMAGE_OFFSET    69.0
#define LEFT_BUTTON_X_OFFSET    3.0
#define RIGHT_BUTTON_X_OFFSET    2.0

@interface TabBarButton ()
{
    CGPoint originalImagePosition;
    CGPoint originalLabelPosition;
}

@end

@implementation TabBarButton

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
    self.highlightedBackgroundImage.hidden = YES;
    self.selectedBackgroundImage.hidden = YES;
    self.icon.hidden = NO;
    self.selectedIcon.hidden = YES;
    [self deselectedFont];
    originalImagePosition = self.icon.frame.origin;
    originalLabelPosition = self.label.frame.origin;
    _locked = NO;
}

-(void)selectedFont
{
    //bright text, dark shadow
    self.label.textColor = [UIColor colorWithRed:0.9216 green:0.9608 blue:0.9687 alpha:1.0];
    self.label.shadowColor = [UIColor colorWithRed:0.1098 green:0.1255 blue:0.1373 alpha:0.8];
}

-(void)deselectedFont
{
    //dark text, light shadow
    self.label.textColor = [UIColor colorWithRed:0.1725 green:0.2235 blue:0.2549 alpha:1.0];
    self.label.shadowColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5];
}

-(void)highlight
{
    //user's finger is currently on button
    self.highlightedBackgroundImage.hidden = NO;
    self.selectedBackgroundImage.hidden = YES;
    self.icon.hidden = YES;
    self.selectedIcon.hidden = NO;
    CGRect frame = self.selectedIcon.frame;
    frame.origin.y = originalImagePosition.y - SELECTED_IMAGE_OFFSET;
    if(self.tag == LEFT_BUTTON_TAG)
    {
        frame.origin.x = originalImagePosition.x + LEFT_BUTTON_X_OFFSET;
    }
    else if(self.tag == RIGHT_BUTTON_TAG)
    {
        frame.origin.x = originalImagePosition.x - RIGHT_BUTTON_X_OFFSET;
    }
    self.selectedIcon.frame = frame;
    
    frame = self.label.frame;
    frame.origin.y = originalLabelPosition.y - SELECTED_IMAGE_OFFSET;
    if(self.tag == LEFT_BUTTON_TAG)
    {
        frame.origin.x = originalLabelPosition.x + LEFT_BUTTON_X_OFFSET;
    }
    else if(self.tag == RIGHT_BUTTON_TAG)
    {
        frame.origin.x = originalLabelPosition.x - RIGHT_BUTTON_X_OFFSET;
    }
    self.label.frame = frame;
    [self selectedFont];
}

-(void)select
{
    //user has removed their finger but this button is selected
    self.highlightedBackgroundImage.hidden = YES;
    self.selectedBackgroundImage.hidden = NO;
    self.icon.hidden = YES;
    self.selectedIcon.hidden = NO;
    CGRect frame = self.selectedIcon.frame;
    frame.origin = originalImagePosition;
    self.selectedIcon.frame = frame;
    frame = self.label.frame;
    frame.origin = originalLabelPosition;
    self.label.frame = frame;
    [self selectedFont];
}

-(void)deselect
{
    //user has selected another button so this one is in its deselected state
    self.highlightedBackgroundImage.hidden = YES;
    self.selectedBackgroundImage.hidden = YES;
    self.icon.hidden = NO;
    self.selectedIcon.hidden = YES;
    CGRect frame = self.selectedIcon.frame;
    frame.origin = originalImagePosition;
    self.selectedIcon.frame = frame;
    frame = self.label.frame;
    frame.origin = originalLabelPosition;
    self.label.frame = frame;
    [self deselectedFont];
}

@end

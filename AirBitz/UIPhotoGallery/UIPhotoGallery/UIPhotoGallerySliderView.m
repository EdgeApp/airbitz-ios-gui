//
//  UIPhotoGallerySliderView.m
//  AirBitz
//
//  Created by Allan Wright on 11/21/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "UIPhotoGallerySliderView.h"

@interface UIPhotoGallerySliderView ()
@property (nonatomic, strong) IBOutlet UISlider *slider;
@property (nonatomic, strong) IBOutlet UIView *pageCountView;
@property (nonatomic, strong) IBOutlet UILabel *pageCountLabel;
@end

@implementation UIPhotoGallerySliderView

+ (UIPhotoGallerySliderView *)CreateWithPhotoCount:(NSUInteger)count andCurrentIndex:(NSUInteger)index
{
	UIPhotoGallerySliderView *sliderView = nil;
    sliderView = [[[NSBundle mainBundle] loadNibNamed:@"UIPhotoGallerySliderView"
                                                owner:nil
                                              options:nil]
                  objectAtIndex:0];
    sliderView.slider.minimumValue = 0;
    sliderView.slider.maximumValue = count-1;
    sliderView.slider.value = index;
    [sliderView updateSliderBubble:sliderView.slider];
	return sliderView;
}

- (void)updateSliderBubble:(UISlider *)slider
{
    self.pageCountLabel.text = [NSString stringWithFormat:@"%.0f/%.0f",
                                      self.slider.value+1,
                                      self.slider.maximumValue+1];

    // attach count view to the slider thumb
    CGRect trackRect = [self.slider trackRectForBounds:self.slider.bounds];
    CGRect thumbRect = [self.slider thumbRectForBounds:self.slider.bounds
                                             trackRect:trackRect
                                                 value:self.slider.value];
    int x = thumbRect.origin.x + thumbRect.size.width/2 + self.slider.frame.origin.x;
    self.pageCountView.center = CGPointMake(x,
                                            self.pageCountView.center.y);
}

- (IBAction)sliderValueChanged:(UISlider *)sender
{
    [sender setValue:(int)sender.value animated:NO];
    [self updateSliderBubble:sender];
    if (_delegate)
    {
        [_delegate sliderValueChangedToIndex:(NSUInteger)sender.value];
    }
}

@end

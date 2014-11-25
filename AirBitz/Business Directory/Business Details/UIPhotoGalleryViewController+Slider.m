//
//  UIPhotoGalleryViewController+Slider.m
//  AirBitz
//
//  Created by Allan Wright on 11/24/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "UIPhotoGalleryViewController+Slider.h"

@implementation UIPhotoGalleryViewController (Slider)

- (void)sliderValueChangedToIndex:(NSUInteger)index
{
    [vPhotoGallery scrollToPage:index animated:NO];
}

@end
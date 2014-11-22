//
//  UIPhotoGallerySliderView.h
//  AirBitz
//
//  Created by Allan Wright on 11/21/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UIPhotoGallerySliderViewDelegate;

@interface UIPhotoGallerySliderView : UIView

@property (nonatomic, assign) id<UIPhotoGallerySliderViewDelegate> delegate;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UIView *pageCountView;
@property (nonatomic, strong) UILabel *pageCountLabel;

@end

@protocol UIPhotoGallerySliderViewDelegate <NSObject>

@optional//@required
- (void) SliderValueChanged:(UIPhotoGallerySliderView *)sliderView;

@end
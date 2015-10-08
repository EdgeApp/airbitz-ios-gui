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
+ (UIPhotoGallerySliderView *)CreateWithPhotoCount:(NSUInteger)count andCurrentIndex:(NSUInteger)index;
@end

@protocol UIPhotoGallerySliderViewDelegate <NSObject>

@required
- (void)sliderValueChangedToIndex:(NSUInteger)index;

@end
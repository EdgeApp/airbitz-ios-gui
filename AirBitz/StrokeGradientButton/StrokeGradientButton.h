//
//  StrokeGradientButton.h
//  AirBitz
//
//  Created by Adam Harris on 5/6/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StrokeGradientButton : UIButton

@property (nonatomic, strong) UIColor *topColor;
@property (nonatomic, strong) UIColor *bottomColor;
@property (nonatomic, strong) UIColor *strokeColor;

-(void)setBorderThickness:(float)thickness;
- (void)colorSetTop:(UIColor *)colorTop bottom:(UIColor *)colorBottom text:(UIColor *)colorText border:(UIColor *)colorBorder background:(UIColor *)colorBackground;

@end

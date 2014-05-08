//
//  StrokeGradientButton.m
//  AirBitz
//
//  Created by Adam Harris on 5/6/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "StrokeGradientButton.h"
#import "CommonTypes.h"

#define TOP_COLOR        COLOR_GRADIENT_TOP
#define BOTTOM_COLOR     COLOR_GRADIENT_BOTTOM
#define TEXT_COLOR       [UIColor whiteColor]
#define BORDER_COLOR     [UIColor whiteColor]
#define BACKGROUND_COLOR [UIColor clearColor]

#define BORDER_WIDTH     2
#define CORNER_RADIUS    7


@interface StrokeGradientButton ()

@property (nonatomic, strong) CAGradientLayer *gradient;
@property (nonatomic, strong) UIColor         *colorTop;
@property (nonatomic, strong) UIColor         *colorBottom;
@property (nonatomic, strong) UIColor         *colorText;
@property (nonatomic, strong) UIColor         *colorBorder;
@property (nonatomic, strong) UIColor         *colorBackground;

@end

@implementation StrokeGradientButton

- (void)initMyVariables
{
    self.colorTop = TOP_COLOR;
    self.colorBottom = BOTTOM_COLOR;
    self.colorText = TEXT_COLOR;
    self.colorBorder = BORDER_COLOR;
    self.colorBackground = BACKGROUND_COLOR;

    /*
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        self.colorTop = COLOR_BAR_TINT;
        self.colorBottom = COLOR_BAR_TINT;
    }
     */
    
	self.layer.cornerRadius = CORNER_RADIUS;
	self.layer.borderWidth = BORDER_WIDTH;
	self.layer.borderColor = [self.colorBorder CGColor];
	
	self.gradient = [CAGradientLayer layer];
	self.gradient.frame = CGRectInset(self.bounds, BORDER_WIDTH, BORDER_WIDTH);
	[self updateGradient];
	
	[self.layer insertSublayer:self.gradient atIndex:0];
	
	[self setTitleColor:self.colorText forState:UIControlStateNormal];
	
	[self addTarget:self action:@selector(buttonDown) forControlEvents:UIControlEventTouchDown];
	[self addTarget:self action:@selector(buttonUp) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
    
    self.backgroundColor = self.colorBackground;
}

- (void)colorSetTop:(UIColor *)colorTop bottom:(UIColor *)colorBottom text:(UIColor *)colorText border:(UIColor *)colorBorder background:(UIColor *)colorBackground
{
    self.colorTop = colorTop;
    self.colorBottom = colorBottom;
    self.colorText = colorText;
    self.colorBorder = colorBorder;
    self.colorBackground = colorBackground;
    
    self.layer.borderColor = [self.colorBorder CGColor];
    [self setTitleColor:self.colorText forState:UIControlStateNormal];
    self.backgroundColor = self.colorBackground;
    
    [self updateGradient];
}

- (void)updateGradient
{
	self.gradient.colors = [NSArray arrayWithObjects:(id)[self.colorTop CGColor], (id)[self.colorBottom CGColor], nil];
}

- (void)setBorderThickness:(float)thickness
{
	self.layer.borderWidth = thickness;
	self.gradient.frame = CGRectInset(self.bounds, thickness, thickness);
}

- (void)buttonDown
{
	self.gradient.colors = [NSArray arrayWithObjects:(id)[[self colorDarkenBy:0.55 forColor:self.colorTop] CGColor], (id)[[self colorDarkenBy:0.55 forColor:self.colorBottom] CGColor], nil];
	[self setNeedsDisplay];
}

- (void)buttonUp
{
	[self updateGradient];
	[self setNeedsDisplay];
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
       [self initMyVariables];
    }
    return self;
}

- (void)awakeFromNib
{
	[self initMyVariables];
}


-(void)dealloc
{
	self.gradient = nil;
}

-(UIColor *)colorDarkenBy:(float)amount forColor:(UIColor *)color
{
	//CGColorRef topColor = [self.topColor CGColor];
	
	const CGFloat *topComponents = CGColorGetComponents([color CGColor]);
	
	CGFloat red = topComponents[0];
	CGFloat green = topComponents[1];
	CGFloat blue = topComponents[2];
	
	red *= amount;
	green *= amount;
	blue *= amount;
	
	return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

@end

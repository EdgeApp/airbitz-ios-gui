//
//  BlurView.m
//  Airbitz
//
//  Created by Paul Puey on 2015/05/15.
//  Copyright (c) 2015 AirBitz. All rights reserved.
//
//	Using this UIView gets a Blurred background using UIToolBar on iOS7 and native blur on iOS8

#import "BlurView.h"
#import "Util.h"
#import <UIKit/UIKit.h>
#import <UIKit/UIToolbar.h>

@interface BlurView ()
{
    UIToolbar *toolbarBlur;
    UIView    *blurEffectView;
    BOOL bInitialized;
}
@end

@implementation BlurView



-(void)initMyVariables
{
//	[self setTintColor:[UIColor whiteColor]];
//	[self setPlaceholderTextColor];
	
	
	//UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    /*
	UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 15.0, 15.0)];
	[button setImage:[UIImage imageNamed:@"clearButton.png"] forState:UIControlStateNormal];
	[button setFrame:CGRectMake(0.0f, 0.0f, 15.0f, 15.0f)]; // Required for iOS7
	[button addTarget:self action:@selector(doClear) forControlEvents:UIControlEventTouchUpInside];
	self.rightView = button;
	self.rightViewMode = self.clearButtonMode;
*/

    if (!bInitialized)
    {
        if([UIVisualEffectView class]){

            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
            blurEffectView = (UIVisualEffectView *) [[UIVisualEffectView alloc] initWithEffect:blurEffect];

            [blurEffectView setFrame:self.frame];

            [self addSubview:blurEffectView];

//            UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
//            UIVisualEffectView *vibrancyEffectView = [[UIVisualEffectView alloc] initWithEffect:vibrancyEffect];
//            [vibrancyEffectView setFrame:self.backgroundVibrancyView.bounds];
//
//            [[vibrancyEffectView contentView] addSubview:self.backgroundVibrancyView];
//
//            [[blurEffectView contentView] addSubview:vibrancyEffectView];
//            vibrancyEffectView.center = blurEffectView.center;
        }
        else
        {
            toolbarBlur = [[UIToolbar alloc] initWithFrame:self.frame];
            [self addSubview:toolbarBlur];
        }
        bInitialized = true;

    }
    else
    {
        if (nil == toolbarBlur)
        {
            [blurEffectView setFrame:self.frame];
        }
        else
        {
            toolbarBlur.frame = self.frame;
        }
    }

//    UIView *toolbarBlur = [[UIView alloc] initWithFrame:self.frame];
//        [toolbarBlur.layer setBackgroundColor:[UIColorFromARGB(0x88aa0000) CGColor]];
//
//    [self addSubview:toolbarBlur];

//    toolbarBlur.translatesAutoresizingMaskIntoConstraints = NO;
//    [self addConstraint:[NSLayoutConstraint
//            constraintWithItem:toolbarBlur
//                     attribute:NSLayoutAttributeTrailing
//                     relatedBy:NSLayoutRelationEqual
//                        toItem:self
//                     attribute:NSLayoutAttributeTrailing
//                    multiplier:1.0
//                      constant:0.0]];
//
//    [self addConstraint:[NSLayoutConstraint
//            constraintWithItem:toolbarBlur
//                     attribute:NSLayoutAttributeTop
//                     relatedBy:NSLayoutRelationEqual
//                        toItem:self
//                     attribute:NSLayoutAttributeTop
//                    multiplier:1.0
//                      constant:0.0]];
//
//    [self addConstraint:[NSLayoutConstraint
//            constraintWithItem:toolbarBlur
//                     attribute:NSLayoutAttributeBottom
//                     relatedBy:NSLayoutRelationEqual
//                        toItem:self
//                     attribute:NSLayoutAttributeBottom
//                    multiplier:1.0
//                      constant:0.0]];
//
//    [self addConstraint:[NSLayoutConstraint
//            constraintWithItem:toolbarBlur
//                     attribute:NSLayoutAttributeLeading
//                     relatedBy:NSLayoutRelationEqual
//                        toItem:self
//                     attribute:NSLayoutAttributeLeading
//                    multiplier:1.0
//                      constant:0.0]];

//    self.layer.cornerRadius = 8;
//    self.clipsToBounds = YES;
    [self.layer setBackgroundColor:[UIColorFromARGB(0x14BDDCFF) CGColor]];

}

-(id)drawRect:(CGRect)rect {
    [self initMyVariables];
    return self;
}

-(id)init
{
    [self initMyVariables];
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self initMyVariables];
    }
    return self;
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

-(void)awakeFromNib
{
	[super awakeFromNib];
	[self initMyVariables];
}

@end

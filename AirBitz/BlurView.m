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
#import "Theme.h"
#import <UIKit/UIKit.h>
#import <UIKit/UIToolbar.h>

@interface BlurView ()
{
    UIVisualEffectView    *blurEffectView;
    UIView *backgroundVibrancyView;
    UIView *nonBlur;
    BOOL bInitialized;
}

@property (nonatomic)  NSInteger blurStyle;
@property (nonatomic)  UIBlurEffectStyle currentBlurStyle;

@end

@implementation BlurView



-(void)initMyVariables
{

    if (!bInitialized)
    {
        UIBlurEffect *blurEffect;

        if (self.bSetBlurStyleExtraLight)
        {
            self.currentBlurStyle = UIBlurEffectStyleExtraLight;
        }
        else if (self.bSetBlurStyleDark)
        {
            self.currentBlurStyle = UIBlurEffectStyleDark;
        }
        else
        {
            self.currentBlurStyle = UIBlurEffectStyleLight;
        }

        if ([Theme Singleton].bTranslucencyEnable || self.bForceBlur)
        {
            blurEffect = [UIBlurEffect effectWithStyle:self.currentBlurStyle];

            blurEffectView = (UIVisualEffectView *) [[UIVisualEffectView alloc] initWithEffect:blurEffect];

            [Util addSubviewWithConstraints:self child:blurEffectView];
            [self.layer setBackgroundColor:[UIColorFromARGB(0x00000000) CGColor]];

        }
        else
        {
            CGRect frame = CGRectMake(0, 0, 10, 10);

            nonBlur = [[UIView alloc] initWithFrame:frame];
            if (self.bSetBlurStyleDark)
            {
                [nonBlur.layer setBackgroundColor:[UIColorFromARGB(0xBB000000) CGColor]];
            }
            else if (self.bSetBlurStyleExtraLight || self.bForceWhite)
            {
                [nonBlur.layer setBackgroundColor:[UIColorFromARGB(0xF8F0F0F0) CGColor]];
            }
            else
            {
                [nonBlur.layer setBackgroundColor:[UIColorFromARGB(0xF0CEE8FF) CGColor]];
            }
            [Util addSubviewWithConstraints:self child:nonBlur];
        }
        bInitialized = true;

    }

}

-(void)drawRect:(CGRect)rect
{
    [self initMyVariables];
}

-(id)init
{
//    [self initMyVariables];
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    if ((self = [super initWithCoder:aDecoder]))
    {
//        [self initMyVariables];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
//        [self initMyVariables];
    }
    return self;
}

-(void)awakeFromNib
{
	[super awakeFromNib];
//	[self initMyVariables];
}

@end

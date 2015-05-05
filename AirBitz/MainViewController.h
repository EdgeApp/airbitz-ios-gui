//
//  MainViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//
//  CW:  Loads all of the viewControllers used by the app.  Displays the appropriate viewController content based on which
//	tab bar button is selected

#import <UIKit/UIKit.h>

typedef enum eNavBarSide
{
    NAV_BAR_LEFT,
    NAV_BAR_RIGHT
} tNavBarSide;

@interface MainViewController : UIViewController

+(void)changeNavBarTitle: (NSString*) titleText;
+(void)changeNavBarTitleWithButton: (NSString*) titleText action:(SEL)func fromObject:(id) object;
+(void)changeNavBarTitleWithImage: (UIImage *) titleImage;
+(void)changeNavBarSide: (NSString*) titleText side:(tNavBarSide)navBarSide enable:(BOOL)enable action:(SEL)func fromObject:(id) object;
+(void)moveSelectedViewController: (CGFloat) x;
+(CGFloat) getFooterHeight;
+(CGFloat) getHeaderHeight;

@end

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
#import "AirbitzViewController.h"
#import "AFNetworking.h"
#import "UIImageView+AFNetworking.h"
#import "AB.h"



typedef enum eNavBarSide
{
    NAV_BAR_CENTER,
    NAV_BAR_LEFT,
    NAV_BAR_RIGHT
} tNavBarSide;

@interface MainViewController : AirbitzViewController

@property (nonatomic, strong)        NSArray                *arrayContacts;

@property (nonatomic, strong)        NSMutableDictionary    *dictImages; // images for the contacts and businesses
@property (nonatomic, strong)        NSMutableDictionary    *dictAddresses; // addresses for the contacts and businesses
@property (nonatomic, strong)        NSMutableDictionary    *dictImageURLFromBizName; // urls for business thumbnails
@property (nonatomic, strong)        NSMutableDictionary    *dictBizIds; // bizIds for the businesses
@property (nonatomic, strong)        NSMutableDictionary    *dictImageURLFromBizID;
@property (nonatomic, strong)        NSMutableArray         *arrayPluginBizIDs;
@property (nonatomic, strong)        NSMutableArray         *arrayNearBusinesses; // businesses that match distance criteria

+ (MainViewController *)Singleton;

+ (void)animateSlideIn:(AirbitzViewController *)viewController;
+ (void)animateFadeIn:(UIView *)view;
+ (void)animateFadeOut:(UIView *)view;
+ (void)animateFadeOut:(UIView *)view remove:(BOOL)removeFromView;

+ (void)animateView:(AirbitzViewController *)viewController withBlur:(BOOL)withBlur;
+ (void)animateView:(AirbitzViewController *)viewController withBlur:(BOOL)withBlur animate:(BOOL)animated;
+ (void)animateOut:(AirbitzViewController *)viewController withBlur:(BOOL)withBlur complete:(void(^)(void))cb;
+ (void)showBackground:(BOOL)loggedIn animate:(BOOL)animated;
+ (void)showBackground:(BOOL)loggedIn animate:(BOOL)animated completion:(void (^)(BOOL finished))completion;

+(void)changeNavBarOwner:(UIViewController *)viewController;
+(void)changeNavBar:(UIViewController *)viewController
              title:(NSString*) titleText
               side:(tNavBarSide)navBarSide
             button:(BOOL)bIsButton
             enable:(BOOL)enable
             action:(SEL)func
         fromObject:(id) object;
+(void)changeNavBarTitle:(UIViewController *)viewController
                   title:(NSString*) titleText;
+(void)changeNavBarTitleWithButton:(UIViewController *)viewController title:(NSString*) titleText action:(SEL)func fromObject:(id) object;
+(void)showHideTabBar:(NSNotification *)notification;
+(void)showTabBarAnimated:(BOOL)animated;
+(void)showNavBarAnimated:(BOOL)animated;
+(void)hideTabBarAnimated:(BOOL)animated;
+(void)hideNavBarAnimated:(BOOL)animated;
+(void)lockSidebar:(BOOL)locked;
+(AirbitzViewController *)getSelectedViewController;
+(void)moveSelectedViewController: (CGFloat) x;
+(void)setAlphaOfSelectedViewController: (CGFloat) alpha;
+(CGFloat) getFooterHeight;
+(CGFloat) getHeaderHeight;
+(CGFloat)getWidth;
+(CGFloat)getHeight;
+(CGFloat)getLargestDimension;
+(CGFloat)getSmallestDimension;
+(CGFloat)getSafeOffscreenOffset:(CGFloat) widthOrHeight;
+ (void)generateListOfContactNames;
+ (void)generateListOfNearBusinesses;
+ (void)createFirstWallet;
+ (void)createFirstWallet:(BOOL) popupSpinner;

+ (AFHTTPRequestOperationManager *) createAFManager;

+ (void)fadingAlertHelpPopup:(NSString *)message;
+ (void)fadingAlert:(NSString *)message;
+ (void)fadingAlert:(NSString *)message holdTime:(CGFloat)holdTime;
+ (void)fadingAlertUpdate:(NSString *)message;
+ (void)fadingAlertDismiss;

@end

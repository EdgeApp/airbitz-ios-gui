//
//  CategoriesViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 4/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CategoriesViewControllerDelegate;

@interface CategoriesViewController : UIViewController

@property (assign)            id<CategoriesViewControllerDelegate> delegate;

@end

@protocol CategoriesViewControllerDelegate <NSObject>

@required

- (void)categoriesViewControllerDidFinish:(CategoriesViewController *)controller;

@end
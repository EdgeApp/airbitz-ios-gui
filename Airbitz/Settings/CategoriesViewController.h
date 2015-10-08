//
//  CategoriesViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 4/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AirbitzViewController.h"

@protocol CategoriesViewControllerDelegate;

@interface CategoriesViewController : AirbitzViewController

@property (assign)            id<CategoriesViewControllerDelegate> delegate;

@end

@protocol CategoriesViewControllerDelegate <NSObject>

@required

- (void)categoriesViewControllerDidFinish:(CategoriesViewController *)controller;

@end
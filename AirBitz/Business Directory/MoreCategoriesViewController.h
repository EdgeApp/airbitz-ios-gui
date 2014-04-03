//
//  MoreCategoriesViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/10/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MoreCategoriesViewControllerDelegate;

@interface MoreCategoriesViewController : UIViewController

@property (assign) id<MoreCategoriesViewControllerDelegate> delegate;
@end




@protocol MoreCategoriesViewControllerDelegate <NSObject>

@required
-(void)moreCategoriesViewControllerDone:(MoreCategoriesViewController *)controller withCategory:(NSString *)category;
@end
//
//  DirectoryViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 2/4/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DirectoryViewControllerDelegate;

@interface DirectoryViewController : UIViewController

@property (assign) id<DirectoryViewControllerDelegate> delegate;

@end


@protocol DirectoryViewControllerDelegate <NSObject>

@required
-(GLfloat)getFooterHeight:(UIViewController *)vc;
-(GLfloat)getHeaderHeight:(UIViewController *)vc;
@end

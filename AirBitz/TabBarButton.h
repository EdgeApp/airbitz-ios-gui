//
//  TabBarButton.h
//  AirBitz
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LatoLabel.h"

@interface TabBarButton : UIView

@property (nonatomic, weak) IBOutlet UIImageView *icon;
@property (nonatomic, weak) IBOutlet UIImageView *selectedIcon;
@property (nonatomic, weak) IBOutlet UIImageView *selectedBackgroundImage;
@property (nonatomic, weak) IBOutlet UIImageView *highlightedBackgroundImage;
@property (nonatomic, weak) IBOutlet LatoLabel *label;
@property (nonatomic, assign) BOOL locked;

-(void)highlight;
-(void)select;
-(void)deselect;

@end

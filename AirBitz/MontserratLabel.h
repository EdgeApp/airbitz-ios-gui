//
//  MontserratLabel.h
//  AirBitz
//
//  Created by Carson Whitsett on 2/6/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//
//  Specify a tag in IB to select regular or bold.  The tag is modded with 100
//	so a tag of 1, 101, or 201 all specify BOLD

#import <UIKit/UIKit.h>

#define MONTSERRAT_REGULAR_TAG	0
#define MONTSERRAT_BOLD_TAG		1

@interface MontserratLabel : UILabel

@end

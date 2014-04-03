//
//  categoryCell.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/10/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LatoLabel.h"

@interface categoryCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UIImageView *bkgImage;
@property (nonatomic, weak) IBOutlet LatoLabel *categoryLabel;
@end

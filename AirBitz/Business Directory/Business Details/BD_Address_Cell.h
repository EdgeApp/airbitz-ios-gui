//
//  BD_Address_Cell.h
//  AirBitz
//
//  Created by Carson Whitsett on 2/18/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BD_Address_Cell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *topAddress;
@property (nonatomic, weak) IBOutlet UILabel *botAddress;
@property (nonatomic, weak) IBOutlet UIImageView *bkg_image;
@end

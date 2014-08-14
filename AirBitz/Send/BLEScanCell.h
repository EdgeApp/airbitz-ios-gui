//
//  BLEScanCell.h
//  AirBitz
//
//  Created by Carson Whitsett on 8/13/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BLEScanCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *contactImage;
@property (nonatomic, weak) IBOutlet UIImageView *signalImage;
@property (nonatomic, weak) IBOutlet UILabel *contactName;
@property (nonatomic, weak) IBOutlet UILabel *contactBitcoinAddress;
@end

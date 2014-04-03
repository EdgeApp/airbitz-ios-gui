//
//  WalletCell.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WalletCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *name;
@property (nonatomic, weak) IBOutlet UILabel *amount;
@property (nonatomic, weak) IBOutlet UIImageView *bkgImage;
@end

//
//  TransactionCell.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/3/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LatoLabel.h"
#import "CommonCell.h"

@interface TransactionCell : CommonCell

@property (nonatomic, weak) IBOutlet LatoLabel          *dateLabel;
@property (nonatomic, weak) IBOutlet LatoLabel          *addressLabel;
@property (nonatomic, weak) IBOutlet LatoLabel          *confirmationLabel;
@property (nonatomic, weak) IBOutlet LatoLabel          *amountLabel;
@property (nonatomic, weak) IBOutlet LatoLabel          *balanceLabel;
@property (weak, nonatomic) IBOutlet UIView             *viewPhoto;
@property (weak, nonatomic) IBOutlet UIImageView        *imagePhoto;
@property (weak, nonatomic) IBOutlet LatoLabel          *promoLabel;
@property (weak, nonatomic) IBOutlet UIImageView        *buttonRight;

@end

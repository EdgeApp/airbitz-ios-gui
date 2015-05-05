//
//  BD_CommonCell.h
//  AirBitz
//
//  Created by Paul Puey on 2015/05/04.
//  Copyright (c) 2015 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LatoLabel.h"

@interface BD_CommonCell : UITableViewCell

@property (nonatomic, weak) IBOutlet LatoLabel *leftLabel;
@property (nonatomic, weak) IBOutlet LatoLabel *rightLabel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leftLabelWidth;
@property (nonatomic, weak) IBOutlet UIImageView *cellIcon;


@end

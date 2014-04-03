//
//  BooleanCell.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/31/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol BooleanCellDelegate;

@interface BooleanCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *name;
@property (nonatomic, weak) IBOutlet UIImageView *bkgImage;
@property (nonatomic, weak) IBOutlet UISwitch *state;
@property (assign) id<BooleanCellDelegate> delegate;
@end


@protocol BooleanCellDelegate <NSObject>

@required

@optional
-(void)booleanCell:(BooleanCell *)cell switchToggled:(UISwitch *)theSwitch;
@end
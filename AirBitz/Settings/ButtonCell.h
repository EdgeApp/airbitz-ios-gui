//
//  ButtonCell.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/31/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ButtonCellDelegate;

@interface ButtonCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *name;
@property (nonatomic, weak) IBOutlet UIImageView *bkgImage;
@property (nonatomic, weak) IBOutlet UIButton *button;
@property (assign) id<ButtonCellDelegate> delegate;
@end


@protocol ButtonCellDelegate <NSObject>

@required

@optional
-(void)buttonCellButtonPressed:(ButtonCell *)cell;
@end
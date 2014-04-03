//
//  ButtonOnlyCell.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/31/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ButtonOnlyCellDelegate;

@interface ButtonOnlyCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIButton *button;
@property (assign) id<ButtonOnlyCellDelegate> delegate;
@end

@protocol ButtonOnlyCellDelegate <NSObject>

@required

@optional
-(void)buttonOnlyCellButtonPressed:(ButtonOnlyCell *)cell;
@end
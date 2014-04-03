//
//  CancelDoneCell.h
//  AirBitz
//
//  Created by Carson Whitsett on 4/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CancelDoneCellDelegate;

@interface CancelDoneCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIButton *cancelButton;
@property (nonatomic, weak) IBOutlet UIButton *doneButton;
@property (assign) id<CancelDoneCellDelegate> delegate;
@end


@protocol CancelDoneCellDelegate <NSObject>

@required

@optional
-(void)CancelDoneCellCancelPressed;
-(void)CancelDoneCellDonePressed;
@end
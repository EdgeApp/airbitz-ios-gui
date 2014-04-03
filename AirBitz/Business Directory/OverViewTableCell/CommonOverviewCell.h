//
//  CommonOverviewCell.h
//  AirBitz
//
//  Created by Carson Whitsett on 2/7/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CommonOverviewCellDelegate;

@interface CommonOverviewCell : UITableViewCell

@property (nonatomic, copy) NSString *ribbon;
@property (nonatomic, weak) IBOutlet UILabel *addressLabel;
@property (nonatomic, weak) IBOutlet UILabel *businessNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *bitCoinLabel;
@property (nonatomic, weak) IBOutlet UIImageView *backgroundImageView;
@property (assign) id<CommonOverviewCellDelegate> delegate;
@property (nonatomic, strong) UIView *viewConnectedToMe;		/* the view that gets dragged on screen as user drags cell to the left */

//returns YES if there was a selected cell and dismiss occurred.  OTherwise returns NO (so caller can handle that situation accordingly)
+(BOOL)dismissSelectedCell;

@end




@protocol CommonOverviewCellDelegate <NSObject>

@optional
-(void)OverviewCell:(CommonOverviewCell *) cell didStartDraggingFromPointInCell:(CGPoint)point;
-(void)OverviewCellDidEndDraggingReturnedToStart:(BOOL)returned;
-(void)OverviewCellDraggedWithOffset:(float)xOffset;
-(void)OverviewCellDidDismissSelectedCell:(CommonOverviewCell *)cell;
@end
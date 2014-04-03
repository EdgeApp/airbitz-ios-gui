//
//  CommonOverviewCell.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/7/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "CommonOverviewCell.h"

#define TAP_TIME_THRESHOLD	0.3 /* seconds */

static CommonOverviewCell *selectedCell; //only allow one cell at a time to be selected

@interface CommonOverviewCell ()
{
	CGPoint     firstTouch;
	NSTimeInterval tapTimer;
}
//@property (nonatomic, weak) IBOutlet UIView *cellContentView;

@end

@implementation CommonOverviewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self)
	{
        // Initialization code
		
    }
    return self;
}

-(void)awakeFromNib
{
	self.backgroundColor = [UIColor clearColor];
	//NSLog(@"selectedView: %@", self.selectedBackgroundView);
	self.selectedBackgroundView = [[UIImageView alloc] initWithFrame:self.bounds];
	self.selectedBackgroundView.contentMode = self.backgroundView.contentMode;
	[super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	//NSLog(@"Touches began");
	if(selectedCell == nil)
	{
		selectedCell = self;
		//NSLog(@"Setting selected cell: %@", selectedCell);
		UITouch *touch = [touches anyObject];
		firstTouch = [touch locationInView:self];
		if([self.delegate respondsToSelector:@selector(OverviewCell:didStartDraggingFromPointInCell:)])
		{
			[self.delegate OverviewCell:self didStartDraggingFromPointInCell:firstTouch];
		}
		tapTimer = CACurrentMediaTime();
	}
}


-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
 {
    if(selectedCell == self)
	{
		//if (slideEnabled == NO) return;
		//[self toggleTableScrolling:NO];
		
		UITouch *touch = [touches anyObject];
		CGPoint touchPoint = [touch locationInView:self];
		
		CGRect frame = self.contentView.frame;
		CGFloat xPos;
		
		xPos = touchPoint.x - firstTouch.x;
		
		//prevent user from dragging to the right
		if(xPos > 0)
		{
			xPos = 0;
		}
		frame.origin.x = xPos;
		
		 if([self.delegate respondsToSelector:@selector(OverviewCellDraggedWithOffset:)])
		 {
			 [self.delegate OverviewCellDraggedWithOffset:xPos];
		 }
		 
		 
		 
		self.contentView.frame = frame;
		
		//slide my connected view
		frame = self.viewConnectedToMe.frame;
		frame.origin.x = self.viewConnectedToMe.bounds.size.width + xPos;
		self.viewConnectedToMe.frame = frame;
	}
}


-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	//NSLog(@"Touches Ended");
	if(selectedCell == self)
	{
		if((CACurrentMediaTime() - tapTimer) < TAP_TIME_THRESHOLD)
		{
			UITouch *touch = [touches anyObject];
			CGPoint release = [touch locationInView:self];
			//prevent false tap when user swiped to the right (allows swipe to left)
			//NSLog(@"Touch delta: %f", release.x - firstTouch.x);
			if(release.x < firstTouch.x + 20.0)
			{
				[self springWithThreshold:-self.frame.size.width];  //always follow through, don't spring back
			}
		}
		else
		{
			[self springWithThreshold:self.frame.size.width * 0.5];
		}
	}
}


-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	//NSLog(@"Touches cancelled");
    if(selectedCell == self)
	{
		[self springWithThreshold:self.frame.size.width * 0.5];
	}
}

+(BOOL)dismissSelectedCell
{
	if(selectedCell)
	{
		CGRect frame = selectedCell.contentView.frame;
		CGRect connectedViewFrame = selectedCell.viewConnectedToMe.frame;
		frame.origin = CGPointMake(0, 0);
		connectedViewFrame.origin.x = connectedViewFrame.size.width;
		
		[UIView animateWithDuration:0.35
							  delay: 0.0
							options: UIViewAnimationOptionCurveEaseOut
						 animations:^
		 {
			 selectedCell.contentView.frame = frame;
			 selectedCell.viewConnectedToMe.frame = connectedViewFrame;
		 }
						 completion:^(BOOL finished)
		 {
			 if([selectedCell.delegate respondsToSelector:@selector(OverviewCellDidDismissSelectedCell:)])
			 {
				 [selectedCell.delegate OverviewCellDidDismissSelectedCell:selectedCell];
			 }
			 selectedCell = nil;
			 //NSLog(@"Cleared selected cell");
		 }];
		 return YES;
	}
	else
	{
		return NO;
	}
}

-(void)springWithThreshold:(float)followThroughThreshold
{
	//if current frame position is further than threshold, continue to selected position
	//otherwise, spring back to original position.
    CGRect frame = self.contentView.frame;
	CGRect connectedViewFrame = self.viewConnectedToMe.frame;
	
	//float followThroughThreshold = frame.size.width * 0.5;
	
	if(frame.origin.x < -followThroughThreshold)
	{
		//follow through
		frame.origin = CGPointMake(-frame.size.width, 0);
		connectedViewFrame.origin.x = 0;
		
		[UIView animateWithDuration:0.35
							  delay: 0.0
							options: UIViewAnimationOptionCurveEaseOut
						 animations:^
						 {
							 self.contentView.frame = frame;
							 self.viewConnectedToMe.frame = connectedViewFrame;
						 }
						 completion:^(BOOL finished)
						 {
							 //put table cell back
							 /*
							 CGRect originalCellFrame = self.contentView.frame;
							 originalCellFrame.origin.x = 0;
							 self.contentView.frame = originalCellFrame;
							 selectedCell = nil;
							 NSLog(@"Cleared selected cell");
							 */
							 if([self.delegate respondsToSelector:@selector(OverviewCellDidEndDraggingReturnedToStart:)])
							 {
								 [self.delegate OverviewCellDidEndDraggingReturnedToStart:NO];
							 }
						 }];
	}
	else
	{
		frame.origin = CGPointMake(0, 0);
		connectedViewFrame.origin.x = connectedViewFrame.size.width;
		
		[UIView animateWithDuration:0.35
							  delay: 0.0
							options: UIViewAnimationOptionCurveEaseOut
						 animations:^
						 {
							 self.contentView.frame = frame;
							 self.viewConnectedToMe.frame = connectedViewFrame;
						 }
						 completion:^(BOOL finished)
						 {
							 selectedCell = nil;
							 //NSLog(@"Cleared selected cell");
							 if([self.delegate respondsToSelector:@selector(OverviewCellDidEndDraggingReturnedToStart:)])
							 {
								 [self.delegate OverviewCellDidEndDraggingReturnedToStart:YES];
							 }
							 
						 }];
	}
}

@end

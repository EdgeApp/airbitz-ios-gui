//
//  BalanceView.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "BalanceView.h"

@interface BalanceView ()
{
	BOOL barIsUp;
	CGPoint originalBarPosition;
}
@property (nonatomic, weak) IBOutlet UIView *bar;
@property (nonatomic, weak) IBOutlet UIImageView *barIcon;
@property (nonatomic, weak) IBOutlet UILabel *barAmount;
@property (nonatomic, weak) IBOutlet UILabel *barDenomination;

@end

@implementation BalanceView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        // Initialization code
		[self initMyVariables];
    }
    return self;
}

-(void)awakeFromNib
{
	[self initMyVariables];
}

-(void)initMyVariables
{
	barIsUp = YES;
	originalBarPosition = self.bar.frame.origin;
	self.barAmount.text = self.topAmount.text;
	self.barDenomination.text = self.topDenomination.text;
	self.barIcon.image = [UIImage imageNamed:@"icon_bitcoin_light"];
}

-(void)refresh
{
	if(barIsUp)
	{
		self.barAmount.text = self.topAmount.text;
	}
	else
	{
		self.barAmount.text = self.botAmount.text;
	}
}

+ (BalanceView *)CreateWithDelegate:(id)del
{

	BalanceView *bv;
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
		bv = [[[NSBundle mainBundle] loadNibNamed:@"BalanceView~iphone" owner:self options:nil] objectAtIndex:0];
	}
	else
	{
		bv = [[[NSBundle mainBundle] loadNibNamed:@"BalanceView~ipad" owner:self options:nil] objectAtIndex:0];
	}
	

	bv.delegate = del;
	[bv addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:bv action:@selector(BalanceViewTapped:)]];
	
	return bv;
}

- (void)BalanceViewTapped:(UITapGestureRecognizer *)recognizer
{
	if(barIsUp)
	{
		//move bar down
		barIsUp = NO;
		[UIView animateWithDuration:0.1
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
						 animations:^
		 {
			 CGRect frame = self.bar.frame;
			 frame.origin.y = originalBarPosition.y + frame.size.height;
			 self.bar.frame = frame;
			 self.barAmount.text = self.botAmount.text;
			 self.barDenomination.text = self.botDenomination.text;
			 self.barIcon.image = [UIImage imageNamed:@"icon_USD_light"];
		 }
		 completion:^(BOOL finished)
		 {
			 if([self.delegate respondsToSelector:@selector(BalanceView:changedStateTo:)])
			 {
				 [self.delegate BalanceView:self changedStateTo:BALANCE_VIEW_DOWN];
			 }
		 }];
	}
	else
	{
		barIsUp = YES;
		[UIView animateWithDuration:0.1
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
						 animations:^
		 {
			 CGRect frame = self.bar.frame;
			 frame.origin.y = originalBarPosition.y;
			 self.bar.frame = frame;
			 self.barAmount.text = self.topAmount.text;
			 self.barDenomination.text = self.topDenomination.text;
			 self.barIcon.image = [UIImage imageNamed:@"icon_bitcoin_light"];
		 }
		completion:^(BOOL finished)
		 {
			 if([self.delegate respondsToSelector:@selector(BalanceView:changedStateTo:)])
			 {
				 [self.delegate BalanceView:self changedStateTo:BALANCE_VIEW_UP];
			 }
		 }];
	}
}

@end

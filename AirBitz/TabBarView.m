//
//  TabBarView.m
//  Wallet
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "TabBarView.h"
#import "TabBarButton.h"

#define TAG_FIRST_DIVIDER	10

@interface TabBarView ()
{
	TabBarButton *selectedButton;
}
@end

@implementation TabBarView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        // Initialization code
    }
    return self;
}

-(TabBarButton *)buttonForIndex:(int)index
{
	TabBarButton *button;
	
	for(UIView *view in self.subviews)
	{
		if([view isKindOfClass:[TabBarButton class]])
		{
			if(view.tag == index)
			{
				button = (TabBarButton *)view;
				break;
			}
		}
	}
	return button;
}

-(void)awakeFromNib
{
	TabBarButton *button;
	
	//set up the button characteristics
	button = [self buttonForIndex:0];
	button.label.text = NSLocalizedString(@"Directory", "tab bar button title");
	button.icon.image = [UIImage imageNamed:@"icon_directory_dark"];
	button.selectedIcon.image = [UIImage imageNamed:@"icon_directory"];
	
	button = [self buttonForIndex:1];
	button.label.text = NSLocalizedString(@"Request", "tab bar button title");
	button.icon.image = [UIImage imageNamed:@"icon_request_dark"];
	button.selectedIcon.image = [UIImage imageNamed:@"icon_request"];
	
	button = [self buttonForIndex:2];
	button.label.text = NSLocalizedString(@"Send", "tab bar button title");
	button.icon.image = [UIImage imageNamed:@"icon_send_dark"];
	button.selectedIcon.image = [UIImage imageNamed:@"icon_send"];
	
	button = [self buttonForIndex:3];
	button.label.text = NSLocalizedString(@"Wallets", "tab bar button title");
	button.icon.image = [UIImage imageNamed:@"icon_wallet_dark"];
	button.selectedIcon.image = [UIImage imageNamed:@"icon_wallet"];
	
	button = [self buttonForIndex:4];
	button.label.text = NSLocalizedString(@"Settings", "tab bar button title");
	button.icon.image = [UIImage imageNamed:@"icon_settings_dark"];
	button.selectedIcon.image = [UIImage imageNamed:@"icon_settings"];
}

-(void)showAllDividers
{
	for(UIView *view in self.subviews)
	{
		if(view.tag >= TAG_FIRST_DIVIDER)
		{
			view.hidden = NO;
		}
	}
}

-(void)updateDividers
{
	[self showAllDividers];
	UIView *view = [self viewWithTag:selectedButton.tag - 1 + TAG_FIRST_DIVIDER];
	view.hidden = YES;
	view = [self viewWithTag:selectedButton.tag + TAG_FIRST_DIVIDER];
	view.hidden = YES;
}


-(void)selectButtonAtIndex:(int)index
{
	for(UIView *view in self.subviews)
	{
		if([view isKindOfClass:[TabBarButton class]])
		{
			TabBarButton *button = (TabBarButton *)view;
			if(button.tag == index)
			{
				if(selectedButton != button)
				{
					[selectedButton deselect];
					[button select];
					if ([self.delegate respondsToSelector:@selector(tabVarView:selectedSubview:reselected:)])
					{
						[self.delegate tabVarView:self selectedSubview:button reselected:NO];
					}
					selectedButton = button;
					[self updateDividers];
				}
			}
		}
	}
}

-(void)selectButtonAtPoint:(CGPoint)point
{
	for(UIView *view in self.subviews)
	{
		if([view isKindOfClass:[TabBarButton class]])
		{
			TabBarButton *button = (TabBarButton *)view;
			if(CGRectContainsPoint(button.frame, point))
			{
				if(selectedButton != button)
				{
					[selectedButton deselect];
					[button select];
					if([self.delegate respondsToSelector:@selector(tabVarView:selectedSubview:reselected:)])
					{
						[self.delegate tabVarView:self selectedSubview:button reselected:NO];
					}
					selectedButton = button;
					[self updateDividers];
				}
			}
		}
	}
}

-(void)highlightButtonAtPoint:(CGPoint)point
{
	for(TabBarButton *view in self.subviews)
	{
		if([view isKindOfClass:[TabBarButton class]])
		{
			TabBarButton *button = (TabBarButton *)view;
			if(CGRectContainsPoint(view.frame, point))
			{
				[selectedButton deselect];
				[button highlight];
				
				if(selectedButton != button)
				{
					if ([self.delegate respondsToSelector:@selector(tabVarView:selectedSubview:reselected:)])
					{
						[self.delegate tabVarView:self selectedSubview:button reselected:NO];
					}
					selectedButton = button;
					[self updateDividers];
				}
                else
                {
                    if ([self.delegate respondsToSelector:@selector(tabVarView:selectedSubview:reselected:)])
                    {
                        [self.delegate tabVarView:self selectedSubview:button reselected:YES];
                    }
                }
			}
		}

	}
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	//UITouch *touch = [touches anyObject];
	CGPoint startPoint = [[touches anyObject] locationInView:self];
	
	//NSLog(@"Touches began at %f, %f", startPoint.x, startPoint.y);
	[self highlightButtonAtPoint:startPoint];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	CGPoint startPoint = [[touches anyObject] locationInView:self];
	//NSLog(@"Touches moved to %f, %f", startPoint.x, startPoint.y);
	[self highlightButtonAtPoint:startPoint];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	//NSLog(@"Touches ended");
	[selectedButton select];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	//NSLog(@"Touches cancelled");
	[selectedButton select];
}

@end

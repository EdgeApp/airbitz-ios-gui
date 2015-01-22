//
//  WalletCell.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "WalletCell.h"
#import "CommonTypes.h"

@interface WalletCell ()
{
    int row;
    int tableHeight;
}

@end

@implementation WalletCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    self.bkgImage.image = [UIImage imageNamed:@"bd_highlighted_cell_middle"];
    return self;
}

- (void)setInfo:(int)index tableHeight:(int)height
{
    row = index;
    tableHeight = height;

    [self setBackground:NO];
}

- (void)setBackground:(BOOL)selected
{
    if (selected) {
        if (row == 0) {
            if (row == tableHeight) {
                _bkgImage.image = [UIImage imageNamed:@"bd_highlighted_cell_single"];
            } else {
                _bkgImage.image = [UIImage imageNamed:@"bd_highlighted_cell_top"];
            }
        } else if (row == tableHeight - 1) {
            _bkgImage.image = [UIImage imageNamed:@"bd_highlighted_cell_bottom"];
        } else {
            _bkgImage.image = [UIImage imageNamed:@"bd_highlighted_cell_middle"];
        }
    } else {
        if (row == 0) {
            if (row == tableHeight) {
                _bkgImage.image = [UIImage imageNamed:@"bd_cell_single"];
            } else {
                _bkgImage.image = [UIImage imageNamed:@"bd_cell_top"];
            }
        } else if (row == tableHeight - 1) {
            _bkgImage.image = [UIImage imageNamed:@"bd_cell_bottom"];
        } else {
            _bkgImage.image = [UIImage imageNamed:@"bd_cell_middle"];
        }
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    [self setBackground:selected];
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated
{
	//changes default reorder control image to our image.  This is a hack since iOS provides no way for us to do this via public APIs
	//can likely break in future iOS releases...
	
    [super setEditing: editing animated: YES];
	
    if (editing)
	{
		//for pre-iOS 7
        for (UIView * view in self.subviews)
		{
            if ([NSStringFromClass([view class]) rangeOfString: @"Reorder"].location != NSNotFound)
			{
                for (UIView * subview in view.subviews)
				{
                    if ([subview isKindOfClass: [UIImageView class]])
					{
                        ((UIImageView *)subview).image = [UIImage imageNamed: @"thumb"];
                        [((UIImageView*)subview) setBounds:CGRectMake(0.0, 0.0, 14.0, 11.0)];
                    }
                }
            }
        }
		//for iOS 7
		UIView *scrollView = self.subviews[0];
		for (UIView * view in scrollView.subviews)
		{
			//NSLog(@"Class: %@", NSStringFromClass([view class]));
			if ([NSStringFromClass([view class]) rangeOfString: @"Reorder"].location != NSNotFound)
			{
				for (UIView * subview in view.subviews)
				{
					if ([subview isKindOfClass: [UIImageView class]])
					{
						((UIImageView *)subview).image = [UIImage imageNamed: @"thumb"];
                        [((UIImageView*)subview) setBounds:CGRectMake(0.0, 0.0, 14.0, 11.0)];
                    }
				}
			}
		}
    }
}

@end

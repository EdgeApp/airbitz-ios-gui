//
//  WalletCell.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "WalletCell.h"

@interface WalletCell ()

@end

@implementation WalletCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
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
						((UIImageView*)subview).frame = CGRectMake(0.0, 0.0, 14.0, 11.0);
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
						((UIImageView*)subview).frame = CGRectMake(0.0, 0.0, 14.0, 11.0);
					}
				}
			}
		}
    }
}

@end

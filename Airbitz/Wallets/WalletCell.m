//
//  WalletCell.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "WalletCell.h"
#import "CommonTypes.h"
#import "Theme.h"

@implementation WalletCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setThemeValues];
    }
    return self;
}

- (void)setThemeValues {
    self.name.textColor = [Theme Singleton].colorDarkGray;
    self.amount.textColor = [Theme Singleton].colorDarkGray;
}

- (void) setEditing:(BOOL)editing animated:(BOOL)animated
{
	//changes default reorder control image to our image.  This is a hack since iOS provides no way for us to do this via public APIs
	//can likely break in future iOS releases...
	
    [super setEditing: editing animated: YES];
}

@end

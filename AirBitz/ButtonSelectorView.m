//
//  ButtonSelectorView.m
//  AirBitz
//
//  Created by Carson Whitsett on 4/3/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "ButtonSelectorView.h"

#define TABLE_ROW_HEIGHT	37.0

@interface ButtonSelectorView () <UITableViewDataSource, UITableViewDelegate>
{
	CGRect      _originalButtonFrame;
	UITableView *_selectionTable;
	CGRect      _originalFrame;
	float       _amountToGrow;
}

@end

@implementation ButtonSelectorView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        self.enabled = YES;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
	{
		UIView *view = [[[NSBundle mainBundle] loadNibNamed:@"ButtonSelectorView~iphone" owner:self options:nil] objectAtIndex:0];
		view.frame = self.bounds;
		UIImage *blue_button_image = [self stretchableImage:@"btn_blue.png"];
		[self.button setBackgroundImage:blue_button_image forState:UIControlStateNormal];
		[self.button setBackgroundImage:blue_button_image forState:UIControlStateSelected];
        [self addSubview:view];
		
		_originalButtonFrame = self.button.frame;
		_originalFrame = self.frame;
		//cw temp
		//self.arrayItemsToSelect = [NSArray arrayWithObjects:@"item 1", @"item 2", @"item 3", @"item 4", @"item 5", @"item 6", @"item 7", @"item 8", @"item 9", @"item 10", @"item 11", @"item 12" , nil];
    }
    return self;
}

- (void)setButtonWidth:(CGFloat)width
{
    CGFloat distFromButton = self.button.frame.origin.x - (self.textLabel.frame.origin.x + self.textLabel.frame.size.width);

    CGRect frameLabel = self.textLabel.frame;
    frameLabel.size.width += (self.button.frame.size.width - width);
    self.textLabel.frame = frameLabel;

    CGRect frameButton = self.button.frame;
    frameButton.origin.x += (frameButton.size.width - width);
    frameButton.size.width = width;

    self.button.frame = frameButton;
    _originalButtonFrame = frameButton;

    distFromButton = self.button.frame.origin.x - (self.textLabel.frame.origin.x + self.textLabel.frame.size.width);
}

- (UIImage *)stretchableImage:(NSString *)imageName
{
	UIImage *img = [UIImage imageNamed:imageName];
	UIImage *stretchable = [img resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)]; //top, left, bottom, right
	return stretchable;
}

- (void)close
{
	if (self.button.selected)
	{
		[self hideTable];
	}
}

- (IBAction)ButtonPressed
{
    if (!self.enabled) {
        return;
    }
	if (self.button.selected)
	{
        [self hideTable];
    }
    else
    {
        if (self.delegate)
        {
            if ([self.delegate respondsToSelector:@selector(ButtonSelectorWillShowTable:)])
            {
                [self.delegate ButtonSelectorWillShowTable:self];
            }
        }

        _originalButtonFrame = self.button.frame;
        _originalFrame = self.frame;

		//animate button width (wider)
		self.button.selected = YES;

        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
		[UIView animateWithDuration:0.25
							  delay:0.0
							options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
						 animations:^
		 {
			 CGRect frame = self.button.frame;
			 float distance = frame.origin.x - self.textLabel.frame.origin.x;
			 frame.origin.x -= distance;
			 frame.size.width += distance;
			 self.button.frame = frame;
			 self.textLabel.alpha = 0.0;
			 
		 }
						 completion:^(BOOL finished)
		 {
             [[UIApplication sharedApplication] endIgnoringInteractionEvents];
			 [self showTable];
		 }];
	}
}

- (void)showTable
{
    float yOriginOffset;
    if ([self.textLabel.text isEqualToString:@""])
    {
         yOriginOffset = self.button.frame.size.height;
    }
    else
    {
        yOriginOffset = self.button.frame.size.height / 2;
    }
	
	CGRect tableFrame = self.button.frame;
	tableFrame.origin.x += 1.0;
	tableFrame.size.width -= 2.0;
	tableFrame.origin.y += yOriginOffset;
	tableFrame.size.height = 0.0;
	
	_selectionTable = [[UITableView alloc] initWithFrame:tableFrame];
	_selectionTable.delegate = self;
	_selectionTable.dataSource = self;
	_selectionTable.layer.cornerRadius = 6.0;
	_selectionTable.scrollEnabled = YES;
	_selectionTable.allowsSelection = YES;
	_selectionTable.userInteractionEnabled = YES;
	[self.button.superview insertSubview:_selectionTable belowSubview:self.button];
	
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	//make the table expand from the bottom of the button
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 
		 CGRect frame = _selectionTable.frame;
		 float originalHeight = frame.size.height;

		 frame.size.height = self.arrayItemsToSelect.count * TABLE_ROW_HEIGHT + yOriginOffset;
		 
		 //constrain frame to window (in cases when table has a ton of items) (centered vertically)
		 CGRect frameInWindow = [_selectionTable.superview convertRect:frame toView:self.window];
		 float highestY = self.window.frame.size.height - frameInWindow.origin.y;
		 float diff = frameInWindow.origin.y + frameInWindow.size.height - highestY;
		 if(diff > 0)
		 {
			 frame.size.height -= diff;
		 }
		 
		 _amountToGrow = frame.size.height - originalHeight;
		 
		 _selectionTable.frame = frame;
		 
		 CGRect myFrame = _originalFrame;
		 myFrame.size.height = frame.origin.y + frame.size.height;
		 self.frame = myFrame;
		 
		 //animate our container's frame (if we have a container)
		 if(self.containerView)
		 {
			 frame = self.containerView.frame;
			 frame.size.height += _amountToGrow;
			 self.containerView.frame = frame;
		 }
	 }
	 completion:^(BOOL finished)
	 {
         [[UIApplication sharedApplication] endIgnoringInteractionEvents];
		 [_selectionTable reloadData];
	 }];
	
}

- (void)hideTable
{
    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(ButtonSelectorWillHideTable:)])
        {
            [self.delegate ButtonSelectorWillHideTable:self];
        }
    }

	//shrink the table up under the button, then animate the button back to original size
	self.button.selected = NO;
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 CGRect frame = _selectionTable.frame;
		 frame.size.height = 0.0;
		 _selectionTable.frame = frame;
		 
		 self.frame = _originalFrame;
		 
		 if (self.containerView)
		 {
			 frame = self.containerView.frame;
			 frame.size.height -= _amountToGrow;
			 self.containerView.frame = frame;
		 }
		 
	 }
					 completion:^(BOOL finished)
	 {
		 //animate button back to original size
		 [UIView animateWithDuration:0.25
							   delay:0.0
							 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
						  animations:^
		  {
			  self.button.frame = _originalButtonFrame;
			  self.textLabel.alpha = 1.0;
		  }
						  completion:^(BOOL finished)
		  {
			  [_selectionTable removeFromSuperview];
			  _selectionTable = nil;
		  }];

	 }];
}

#pragma mark UITableView delegates

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	//default section header color was gray.  Needed to add this in order to set the bkg color to white
	UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, self.button.frame.size.height / 2.0)];
	[headerView setBackgroundColor:[UIColor whiteColor]];
	
	return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return self.button.frame.size.height / 2.0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.arrayItemsToSelect.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return TABLE_ROW_HEIGHT;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
	
	//wallet cell
	static NSString *cellIdentifier = @"ButtonSelectorCell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	
	cell.textLabel.text = [self.arrayItemsToSelect objectAtIndex:indexPath.row];
	cell.textLabel.minimumScaleFactor = 0.5;
	cell.textLabel.adjustsFontSizeToFitWidth = YES;
	//cell.textLabel.textColor = [UIColor redColor];
	//NSLog(@"Row: %i, text: %@", indexPath.row, cell.textLabel.text);
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self hideTable];
	
	if ([self.delegate respondsToSelector:@selector(ButtonSelector:willSetButtonTextToString:)])
	{
		NSString *desiredString = [self.arrayItemsToSelect objectAtIndex:indexPath.row ];
		
		[self.button setTitle:[self.delegate ButtonSelector:self willSetButtonTextToString:desiredString] forState:UIControlStateNormal];
	}
	else
	{
		[self.button setTitle:[self.arrayItemsToSelect objectAtIndex:indexPath.row ] forState:UIControlStateNormal];
	}

    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(ButtonSelector:selectedItem:)])
        {
            [self.delegate ButtonSelector:self selectedItem:(int)indexPath.row];
        }
    }
}

@end

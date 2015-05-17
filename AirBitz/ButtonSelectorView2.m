//
//  ButtonSelectorView2.m
//  AirBitz
//
//  Created by Paul Puey 2015/05/08.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "ButtonSelectorView2.h"

#define TABLE_ROW_HEIGHT	50.0
#define TABLE_HEIGHT_PADDING 25.0

@interface ButtonSelectorView2 () <UITableViewDataSource, UITableViewDelegate>
{
	CGRect      _originalButtonFrame;
	UITableView *_selectionTable;
    UIToolbar   *_blurToolbar;
	CGRect      _originalFrame;
	float       _amountToGrow;
}

@end

@implementation ButtonSelectorView2

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
//        self.enabled = YES;
//		UIView *view = [[[NSBundle mainBundle] loadNibNamed:@"ButtonSelectorView2" owner:self options:nil] objectAtIndex:0];
//		view.frame = self.bounds;
//        [view setBackgroundColor:[UIColor clearColor]];
////		UIImage *blue_button_image = [self stretchableImage:@"btn_blue.png"];
////		[self.button setBackgroundImage:blue_button_image forState:UIControlStateNormal];
////		[self.button setBackgroundImage:blue_button_image forState:UIControlStateSelected];
//        [self addSubview:view];
//        [self.superview insertSubview:view aboveSubview:self];
////
//		_originalButtonFrame = self.button.frame;
//		_originalFrame = self.frame;
//		//cw temp
//		//self.arrayItemsToSelect = [NSArray arrayWithObjects:@"item 1", @"item 2", @"item 3", @"item 4", @"item 5", @"item 6", @"item 7", @"item 8", @"item 9", @"item 10", @"item 11", @"item 12" , nil];
    }
    return self;
}

- (id)drawRect:(CGRect)rect
{
    NSLog(@"ButtonSelector2: drawRect");
    self.enabled = YES;
    UIView *view = [[[NSBundle mainBundle] loadNibNamed:@"ButtonSelectorView2" owner:self options:nil] objectAtIndex:0];
    view.frame = self.bounds;
    [view setBackgroundColor:[UIColor clearColor]];
//		UIImage *blue_button_image = [self stretchableImage:@"btn_blue.png"];
//		[self.button setBackgroundImage:blue_button_image forState:UIControlStateNormal];
//		[self.button setBackgroundImage:blue_button_image forState:UIControlStateSelected];
    [self addSubview:view];
//    [self.superview insertSubview:view aboveSubview:self];
//
    _originalButtonFrame = self.button.frame;
    _originalFrame = self.frame;
    //cw temp
    //self.arrayItemsToSelect = [NSArray arrayWithObjects:@"item 1", @"item 2", @"item 3", @"item 4", @"item 5", @"item 6", @"item 7", @"item 8", @"item 9", @"item 10", @"item 11", @"item 12" , nil];
    return self;
}

- (void)setButtonWidth:(CGFloat)width
{
//    CGFloat distFromButton = self.button.frame.origin.x - (self.textLabel.frame.origin.x + self.textLabel.frame.size.width);
//
//    CGRect frameLabel = self.textLabel.frame;
//    frameLabel.size.width += (self.button.frame.size.width - width);
//    self.textLabel.frame = frameLabel;
//
//    CGRect frameButton = self.button.frame;
//    frameButton.origin.x += (frameButton.size.width - width);
//    frameButton.size.width = width;
//
//    self.button.frame = frameButton;
    _originalButtonFrame = self.button.frame;

}

//- (UIImage *)stretchableImage:(NSString *)imageName
//{
//	UIImage *img = [UIImage imageNamed:imageName];
//	UIImage *stretchable = [img resizableImageWithCapInsets:UIEdgeInsetsMake(10, 10, 10, 10)]; //top, left, bottom, right
//	return stretchable;
//}

- (void)open
{
    [self showTable];
}
- (void)close
{
    [self hideTable];
}

- (void)disableButton
{
    self.button.enabled = false;
    self.button.hidden = true;
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
            if ([self.delegate respondsToSelector:@selector(ButtonSelector2WillShowTable:)])
            {
                [self.delegate ButtonSelector2WillShowTable:self];
            }
        }

        _originalButtonFrame = self.button.frame;
        _originalFrame = self.frame;

		//animate button width (wider)
		self.button.selected = YES;

//        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
//		[UIView animateWithDuration:0.25
//							  delay:0.0
//							options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
//						 animations:^
//		 {
//			 CGRect frame = self.button.frame;
//			 float distance = frame.origin.x - self.textLabel.frame.origin.x;
//			 frame.origin.x -= distance;
//			 frame.size.width += distance;
//			 self.button.frame = frame;
//			 self.textLabel.alpha = 0.0;
//
//		 }
//						 completion:^(BOOL finished)
//		 {
             [[UIApplication sharedApplication] endIgnoringInteractionEvents];
			 [self showTable];
//		 }];
	}
}

- (void)showTable
{
    float yOriginOffset;
//    if ([self.textLabel.text isEqualToString:@""])
//    {
    if (self.button.enabled == false)
        yOriginOffset = 0;
    else
        yOriginOffset = self.button.frame.size.height;
//    }
//    else
//    {
//        yOriginOffset = self.button.frame.size.height / 2;
//    }
	
	CGRect tableFrame = self.frame;
//	tableFrame.origin.x += 1.0;
//	tableFrame.size.width -= 2.0;
//	tableFrame.origin.y += yOriginOffset;
	tableFrame.size.height = 0.0;

    _blurToolbar = [[UIToolbar alloc] initWithFrame:tableFrame];
    _selectionTable = [[UITableView alloc] initWithFrame:tableFrame];
	_selectionTable.delegate = self;
	_selectionTable.dataSource = self;
	_selectionTable.layer.cornerRadius = 0.0;
	_selectionTable.scrollEnabled = YES;
	_selectionTable.allowsSelection = YES;
	_selectionTable.userInteractionEnabled = YES;
    _selectionTable.separatorStyle=UITableViewCellSeparatorStyleNone;
    _selectionTable.backgroundColor = [UIColor clearColor];
    [self.superview insertSubview:_blurToolbar aboveSubview:self];
	[self.superview insertSubview:_selectionTable aboveSubview:_blurToolbar];

    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	//make the table expand from the bottom of the button
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 
		 CGRect frame = _selectionTable.frame;
		 float originalHeight = frame.size.height;

		 frame.size.height = self.arrayItemsToSelect.count * TABLE_ROW_HEIGHT + yOriginOffset + TABLE_HEIGHT_PADDING;
		 
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
         _blurToolbar.frame = frame;
		 
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
            [self.delegate ButtonSelector2WillHideTable:self];
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
         _blurToolbar.frame = frame;
		 
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
//			  self.textLabel.alpha = 1.0;
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
	[headerView setBackgroundColor:[UIColor clearColor]];
	
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
    NSUInteger row = [indexPath row];
	
	//wallet cell
	static NSString *cellIdentifier = @"ButtonSelectorCell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        
        
//        UIView* separatorLineView = [[UIView alloc] initWithFrame:CGRectMake(0, cell.bounds.size.height-6, 320, 0.5)];/// change size as you need.
//        separatorLineView.backgroundColor = [UIColor grayColor];// you can also put image here
//        [cell.contentView addSubview:separatorLineView];
    }
    
    cell.textLabel.font = [UIFont fontWithName:@"Lato-Regular" size:17.0];
	cell.textLabel.text = [self.arrayItemsToSelect objectAtIndex:indexPath.row];
	cell.textLabel.minimumScaleFactor = 0.5;
	cell.textLabel.adjustsFontSizeToFitWidth = YES;
	cell.textLabel.textColor = [UIColor darkGrayColor];
    cell.backgroundColor = [UIColor clearColor];
	//NSLog(@"Row: %i, text: %@", indexPath.row, cell.textLabel.text);
    
    if (self.accessoryImage) {
        UIImage *image = self.accessoryImage;
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        CGRect frame = CGRectMake(0.0, 0.0, image.size.width, image.size.height);
        button.frame = frame;
        button.tag = row;
        [button setBackgroundImage:image forState:UIControlStateNormal];
        button.backgroundColor = [UIColor clearColor];
        cell.accessoryView = button;
        cell.accessoryView.hidden = NO;
        [button addTarget:self action:@selector(accessoryButtonTapped:event:)  forControlEvents:UIControlEventTouchUpInside];
    }
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self hideTable];
	
	if ([self.delegate respondsToSelector:@selector(ButtonSelector2:willSetButtonTextToString:)])
	{
		NSString *desiredString = [self.arrayItemsToSelect objectAtIndex:indexPath.row ];
		
		[self.button setTitle:[self.delegate ButtonSelector2:self willSetButtonTextToString:desiredString] forState:UIControlStateNormal];
	}
	else
	{
		[self.button setTitle:[self.arrayItemsToSelect objectAtIndex:indexPath.row ] forState:UIControlStateNormal];
	}

    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(ButtonSelector2:selectedItem:)])
        {
            [self.delegate ButtonSelector2:self selectedItem:(int)indexPath.row];
        }
    }
}

- (void)accessoryButtonTapped:(id)sender event:(id)event
{
    UIButton *button = (UIButton *) sender;
    NSString *account = [self.arrayItemsToSelect objectAtIndex:button.tag];
    
    if ([self.delegate respondsToSelector:@selector(ButtonSelector2DidTouchAccessory:accountString:)])
    {
        [self.delegate ButtonSelector2DidTouchAccessory:self accountString:account];
    }
    [self hideTable];
}


@end

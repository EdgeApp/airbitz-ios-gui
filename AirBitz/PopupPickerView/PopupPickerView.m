//
//  PopupPickerView.m
//  AirBitz
//
//  Created by Adam Harris on 5/5/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PopupPickerView.h"

#define DEFAULT_WIDTH           330

#define DEFAULT_CELL_HEIGHT     35

#define OFFSET_YPOS             45  // how much to offset the y position

#define ARROW_INSET             0.0

#define DATE_PICKER_HEIGHT      216

#define POPUP_STROKE_WIDTH		0.0	//width of the thin border around the entire popup picker

@interface PopupPickerView () <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>
{
    BOOL                        _bShowOptions;
    BOOL                        _bDisableBackgroundTouch;
	IBOutlet UITableView        *table;
	IBOutlet UIView             *innerView;
    IBOutlet UIButton           *m_buttonBackground;
    IBOutlet UIView             *m_viewBorder;
	CGRect						availableSpace;	//space within which the popupPicker can be displayed (in screen coordinates)
}


@property (weak, nonatomic)     IBOutlet UIView         *viewOptions;
@property (weak, nonatomic)     IBOutlet UIButton       *buttonKeyboard;
@property (weak, nonatomic)     IBOutlet UIButton       *buttonTrash;

@property (nonatomic, strong) NSArray                       *strings;
@property (nonatomic, strong) NSArray                       *categories;
@property (nonatomic, strong) UIImage                       *accessoryImage;
@property (nonatomic, assign) tPopupPickerPosition          position;

@end

@implementation PopupPickerView

CGRect usableFrame;
CGRect keyboardFrame;

+(void)initAll
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWasShown:)
												 name:UIKeyboardDidShowNotification
											   object:nil];
	//For Later Use
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification
											   object:nil];
	UIWindow *window = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
	usableFrame = window.frame;
	keyboardFrame = CGRectMake(0, window.frame.origin.y + window.frame.size.height, 0, 0);
}

+(void)freeAll
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}



+ (void)keyboardWasShown:(NSNotification *)notification
{
	// Get the size of the keyboard.
	keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	//NSLog(@"SHOW: KeyboardFrame:%f, %f, %f, %f", keyboardFrame.origin.x, keyboardFrame.origin.y, keyboardFrame.size.width, keyboardFrame.size.height);
}

+ (void)keyboardWillHide:(NSNotification *)notification
{
	keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
	//NSLog(@"HIDE: keyboardFrame:%f, %f, %f, %f", keyboardFrame.origin.x, keyboardFrame.origin.y, keyboardFrame.size.width, keyboardFrame.size.height);
}

- (void)addCropLine:(CGPoint)pointOnScreen direction:(tPopupPickerPosition)cropDirection animated:(BOOL)animated
{
	float distance;
	CGPoint newPoint = [self.superview convertPoint:pointOnScreen fromView:self.window];
	switch (cropDirection)
	{
			case PopupPickerPosition_Above:
				distance = newPoint.y - availableSpace.origin.y;
				if (distance > 0)
				{
					availableSpace.origin.y += distance;
					availableSpace.size.height -= distance;
				}
				[self constrainToKeepoutsAnimated:animated];
			break;
			case PopupPickerPosition_Below:
				distance = (availableSpace.origin.y + availableSpace.size.height) - newPoint.y;
				if (distance > 0)
				{
					availableSpace.size.height -= distance;
				}
				[self constrainToKeepoutsAnimated:animated];
			break;
			default:
				NSLog(@"*** THIS CROP DIRECTION NOT SUPPORTED YET ***");
				break;
	}
}

- (void)constrainToKeepoutsAnimated:(BOOL)animated
{
	float duration = 0.01;
	if (animated)
	{
		duration = 0.35;
	}
	[UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 CGRect frame = self.frame;
		 
		 if(frame.origin.y < availableSpace.origin.y)
		 {
			 frame.size.height += (availableSpace.origin.y - frame.origin.y);
			 frame.origin.y -= (availableSpace.origin.y - frame.origin.y);
		 }
		 
		 if((frame.origin.y + frame.size.height) > (availableSpace.origin.y + availableSpace.size.height))
		 {
			 frame.size.height -= ((frame.origin.y + frame.size.height) - (availableSpace.origin.y + availableSpace.size.height));
		 }
		 
		 //also don't intersect keyboard
		 if((frame.origin.y + frame.size.height) > keyboardFrame.origin.y)
		 {
			 frame.size.height -= ((frame.origin.y + frame.size.height) - keyboardFrame.origin.y);
		 }
		 self.frame = frame;
	 }
	 completion:^(BOOL finished)
	 {
	 }];
}

+ (PopupPickerView *)CreateForView:(UIView *)parentView relativeToView:(UIView *)viewToPointTo relativePosition:(tPopupPickerPosition)position withStrings:(NSArray *)strings fromCategories:(NSArray *)categories selectedRow:(NSInteger)selectedRow /*maxCellsVisible:(NSInteger)maxCellsVisible*/ withWidth:(NSInteger)width withAccessory:(UIImage *)image andCellHeight:(NSInteger)cellHeight roundedEdgesAndShadow:(Boolean)rounded
{
    // create the picker from the xib
    PopupPickerView *popup = [[[NSBundle mainBundle] loadNibNamed:@"PopupPickerView" owner:nil options:nil] objectAtIndex:0];
    [popup setCellHeight:cellHeight];
    
	UIWindow *window = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
	popup->availableSpace = window.frame;
	
    popup.position = position;
    
    // add the popup to the parent
	[parentView addSubview:popup];

    // calculate the border thickness
//    CGFloat borderThickness = (popup.frame.size.height - popup->table.frame.size.height) / 2.0;
    CGFloat borderThickness = 10.0f;
    
    // set the strings and categories
	popup.strings = strings;
    popup.categories = categories;
    
    popup.accessoryImage = image;
    
    // start with the existing frame
    CGRect newFrame = popup.frame;
    
    // give it enough height to handle the items
    int height = 0;
	if(strings)
	{
		height = strings.count * cellHeight + (2 * borderThickness);
	}
	else
	{
		height = [popup.delegate PopupPickerViewNumberOfRows:popup userData:nil] * cellHeight + (2 * borderThickness);
	}
    
    // but not too much height
    if(height > window.frame.size.height * 0.75) {
        height = window.frame.size.height * 0.75;
    }
    newFrame.size.height = height;
    
    // change the width
    newFrame.size.width = width;
    
    // set new height and width
    popup.frame = newFrame;
    
    // calculate the parent's size (for use later)
    CGSize parentFrameSize = parentView.frame.size;
    CGFloat parentRotateRadians = atan2f(parentView.transform.b, parentView.transform.a); 
    if (parentRotateRadians)
    {
        // our parent is rotated so we have to deal with the width and height differences
        CGPoint initialPoint = { parentFrameSize.width, parentFrameSize.height };
        CGPoint rotatedPoint = CGPointApplyAffineTransform(initialPoint, CGAffineTransformMakeRotation(parentRotateRadians));
        parentFrameSize.width = fabs(rotatedPoint.x);
        parentFrameSize.height = fabs(rotatedPoint.y);
    }
    
    // start the position to the upper-left corner of the positioning view
    newFrame.origin = [viewToPointTo.superview convertPoint:viewToPointTo.frame.origin toView:popup.superview];
    
//	CGRect imageFrame = popup.arrowImage.frame;
//	UIImage *image = [UIImage imageNamed:@"picker_left_point.png"];
//	imageFrame.size = image.size;
//	popup.arrowImage.frame = imageFrame;
//	popup.arrowImage.image = image;
	
    // if this is above or below
    if ((PopupPickerPosition_Below == position) || (PopupPickerPosition_Above == position))
    {
        // set the X position directly under the center of the positioning view
        newFrame.origin.x += (viewToPointTo.frame.size.width / 2);        // move to center of view
        newFrame.origin.x -= (popup.frame.size.width / 2);          // bring it left so the center is under the view 
        
        if (PopupPickerPosition_Below == position)
        {
            // put it under the positioning view control
            newFrame.origin.y += viewToPointTo.frame.size.height;
//            newFrame.origin.y += popup.arrowImage.frame.size.height - 10;  // offset by arrow height
        }
        else //PopupPickerPosition_Above
        {
            // put it above the positioning view
            newFrame.origin.y -= newFrame.size.height;
//            newFrame.origin.y -= popup.arrowImage.frame.size.height - 10;  // offset by arrow height
        }
        
        // makes sure the picker is within the parents bounds
        if (newFrame.origin.x < 0.0)
        {
            newFrame.origin.x = 0.0;
        }
        else if ((newFrame.origin.x + newFrame.size.width) > parentFrameSize.width)
        {
            // it's off the right side of the window so bring it back
            newFrame.origin.x = parentFrameSize.width - newFrame.size.width;
        }
        
		float heightSubtract = 0.0;
		CGRect frameInWindow = [viewToPointTo convertRect:newFrame toView:viewToPointTo.window];
		if((frameInWindow.origin.y + frameInWindow.size.height) > (usableFrame.origin.y + usableFrame.size.height))
		{
			heightSubtract = (frameInWindow.origin.y + frameInWindow.size.height) - (usableFrame.origin.y + usableFrame.size.height);
		}
		newFrame.size.height -= heightSubtract;
		
        // set the new frame
        popup.frame = newFrame;
        
        // set up the pointer position
        /*
        CGRect arrowFrame = popup.arrowImage.frame;
        if (PopupPickerPosition_Below == position)
        {
            // move the arrow to the arrow height above the frame
            arrowFrame.origin.y = 0.0 - (arrowFrame.size.height) + ARROW_INSET - 1;
			
			// rotate the image by 90 degrees CW
            CGAffineTransform rotate = CGAffineTransformMakeRotation( M_PI * 0.5 );
            [popup.arrowImage setTransform:rotate];
        }
        else // if (PopupPickerPosition_Above == position)
        {
            // move the arrow to the bottom of the frame
            arrowFrame.origin.y = newFrame.size.height - ARROW_INSET - 1;
            
            // rotate the image by 90 degrees CCW
            CGAffineTransform rotate = CGAffineTransformMakeRotation( M_PI * 1.5 );
            [popup.arrowImage setTransform:rotate];
        }

        // we need the arrow to be centered on the button, start with the pos view in parent coords
        CGRect frameForArrowRef = [viewToPointTo.superview convertRect:viewToPointTo.frame toView:popup];
        
        // put it in the center of the rect
        arrowFrame.origin.x = frameForArrowRef.origin.x + (frameForArrowRef.size.width / 2.0) - (arrowFrame.size.width / 2.0);
        
        // set the final arrow location
        popup.arrowImage.frame = arrowFrame;
         */
    }
    else // if ((PopupPickerPosition_Left == position) || (PopupPickerPosition_Right == position))
    {
        // set the Y position directly beside the center of the positioning view
        newFrame.origin.y += (viewToPointTo.frame.size.height / 2);        // move to center of frame
        newFrame.origin.y -= (popup.frame.size.height / 2);  // bring it up so the center is next to the view
        
        if (PopupPickerPosition_Right == position)
        {
            // put it to the right of the positioning frame
            newFrame.origin.x += viewToPointTo.frame.size.width;
//            newFrame.origin.x += popup.arrowImage.frame.size.width;  // offset by arrow width
        }
        else // if (PopupPickerPosition_Left == position)
        {
            // put it to the left of the positioning frame
            newFrame.origin.x -= newFrame.size.width;             
//            newFrame.origin.x -= (popup.arrowImage.frame.size.width - ARROW_INSET);  // offset by arrow width
        }
        
        // makes sure the picker is within the parents bounds
        if (newFrame.origin.y < 0.0)
        {
            newFrame.origin.y = 0.0;
        }
        else if ((newFrame.origin.y + newFrame.size.height) > parentFrameSize.height)
        {
            // it's off the bottom edge of the window so bring it back 

            newFrame.origin.y = parentFrameSize.height - newFrame.size.height;
        }
        
        // set the new frame
        popup.frame = newFrame;
        
        // set up the pointer position
        /*
        CGRect arrowFrame = popup.arrowImage.frame;
        if (PopupPickerPosition_Right == position)
        {
            // move the arrow to the arrow width left of the frame
            arrowFrame.origin.x = 0.0 - (arrowFrame.size.width) + ARROW_INSET;
        }
        else // if (PopupPickerPosition_Left == position)
        {
            // move the arrow to the right of the frame
            arrowFrame.origin.x = newFrame.size.width - ARROW_INSET;
            
            // rotate the image by 180 degrees
            CGAffineTransform rotate = CGAffineTransformMakeRotation( M_PI );
            [popup.arrowImage setTransform:rotate];
        }
        
        // we need the arrow to be centered on the button, start with the pos view in parent coords
        CGRect frameForArrowRef = [viewToPointTo.superview convertRect:viewToPointTo.frame toView:popup];

        // put it in the center of the rect
        arrowFrame.origin.y = frameForArrowRef.origin.y + (frameForArrowRef.size.height / 2.0) - (arrowFrame.size.height / 2.0);
        
		if((arrowFrame.origin.y + arrowFrame.size.height) > (newFrame.size.height - POPUP_STROKE_WIDTH))
		{
			arrowFrame.origin.y = (newFrame.size.height - arrowFrame.size.height - POPUP_STROKE_WIDTH);
		}
		
		if(arrowFrame.origin.y < POPUP_STROKE_WIDTH)
		{
			arrowFrame.origin.y = POPUP_STROKE_WIDTH;
		}
        // set the final arrow location
        popup.arrowImage.frame = arrowFrame;
         */
    }
    
    // assign the delegate
	popup.delegate = (id<PopupPickerViewDelegate>)parentView;
    
    // select the row if one was specified
    if (selectedRow != -1) 
    {
        //cw table wasn't scrolling to selected position because rows hadn't been filled in yet.  PerformSelector fixed it.
		[popup performSelectorOnMainThread:@selector(selectRow2:) withObject:[NSNumber numberWithInt:(int)selectedRow] waitUntilDone:NO];
    }
    
    if(rounded) {
        // round the corners
        popup.layer.cornerRadius = 10;
        popup->innerView.layer.cornerRadius = 10;
        popup->m_viewBorder.layer.cornerRadius = 10;
    
        // add drop shadow
        popup.layer.shadowColor = [UIColor blackColor].CGColor;
        popup.layer.shadowOpacity = 0.5;
        popup.layer.shadowRadius = 10;
        popup.layer.shadowOffset = CGSizeMake(5.0f, 5.0f);
    }


    return popup;
}

- (void)initMyVariables
{
    // add a black border around the grey 'border'
    m_viewBorder.layer.borderWidth = POPUP_STROKE_WIDTH;
    m_viewBorder.layer.borderColor = [[UIColor blackColor] CGColor];
    
    // start with no delegate
    self.delegate = nil;
    
    // start with no data
    self.userData = nil;
    
    // start with the options hidden
    self.showOptions = NO;

    // start with default style
    self.tableViewCellStyle = UITableViewCellStyleDefault;

    // This will remove extra separators from tableview
    table.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    table.separatorStyle=UITableViewCellSeparatorStyleNone;
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if(self)
	{
		[self initMyVariables];
	}
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
	[self initMyVariables];
}

- (void)dealloc
{
	self.strings = nil;
}

- (void)setCellHeight:(NSInteger)height
{
    table.rowHeight = height;
}

- (void)setShowOptions:(BOOL)showOptions
{
    CGRect frameSelf = self.frame;
    
    if (showOptions)
    {
        if ((self.position == PopupPickerPosition_Left) || (self.position == PopupPickerPosition_Right))
        {
//            CGRect frameArrow = self.arrowImage.frame;
            
            if (frameSelf.origin.y - self.viewOptions.frame.size.height >= 0)
            {
                frameSelf.origin.y -= self.viewOptions.frame.size.height;
//                frameArrow.origin.y += self.viewOptions.frame.size.height;
            }
            else
            {
                frameSelf.origin.y += self.viewOptions.frame.size.height;
//                frameArrow.origin.y -= self.viewOptions.frame.size.height;
            }
            
//            self.arrowImage.frame = frameArrow;
        }
        frameSelf.size.height += self.viewOptions.frame.size.height;
    }
    else
    {
        frameSelf.size.height -= self.viewOptions.frame.size.height;
    }
    self.frame = frameSelf;
    
    
    CGRect frame = table.frame;
    
    if (showOptions)
    {
        // push the table below the options
        frame.origin.y = self.viewOptions.frame.origin.y + self.viewOptions.frame.size.height;
        frame.size.height = innerView.frame.size.height - frame.origin.y;
        self.viewOptions.hidden = NO;
    }
    else
    {
        // make the table cover the inner view
        frame.origin.y = 0;
        frame.size.height = innerView.frame.size.height;
    }
    
    frame.size.width = innerView.frame.size.width;
    table.frame = frame;
    
    self.viewOptions.hidden = !showOptions;
    
    _showOptions = showOptions;
}

- (void)reloadTableData
{
    [table reloadData];
}

-(void)selectRow2:(NSNumber *)row
{
	[self selectRow:row.integerValue];
}

-(void)selectRow:(NSInteger)row
{
	//NSLog(@"Select Row");
	NSIndexPath *ip=[NSIndexPath indexPathForRow:row inSection:0];
	[table selectRowAtIndexPath:ip animated:NO scrollPosition:UITableViewScrollPositionTop];
	[table scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}

-(void)assignDelegate:(id<PopupPickerViewDelegate>)theDelegate
{
    self.delegate = theDelegate;
    
    // hang on to the currently selected row
    NSIndexPath *selectPath = [table indexPathForSelectedRow];
    
    // reload the table so the delegate can have a chance to handle the callbacks
    [table reloadData];
    
    // reselect row
	[table selectRowAtIndexPath:selectPath animated:NO scrollPosition:UITableViewScrollPositionTop];
}

- (void)disableBackgroundTouchDetect
{
    m_buttonBackground.hidden = YES;
    _bDisableBackgroundTouch = YES;
}

- (void)updateStrings:(NSArray *)strings
{
    self.strings = strings;

    [self reloadTableData];
}

#pragma mark - Action

- (IBAction)backgroundButtonTouched:(id)sender 
{
    if (nil != self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(PopupPickerViewCancelled:userData:)])
        {
            [self.delegate PopupPickerViewCancelled:self userData:_userData];
        }
    }
}

- (IBAction)buttonKeyboardTouched:(id)sender
{
    if (nil != self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(PopupPickerViewKeyboard:userData:)])
        {
            [self.delegate PopupPickerViewKeyboard:self userData:_userData];
        }
    }
}

- (IBAction)buttonTrashTouched:(id)sender
{
    if (nil != self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(PopupPickerViewClear:userData:)])
        {
            [self.delegate PopupPickerViewClear:self userData:_userData];
        }
    }
}

#pragma mark - TableView Data Source methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger nRows = -1;
      
    // check if the delegate wants to take this
    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(PopupPickerViewNumberOfRows:userData:)])
        {
            nRows = [self.delegate PopupPickerViewNumberOfRows:self userData:_userData];
        }
    }
    
    // if we don't have a count yet
    if (nRows < 0)
    {
        if (_strings)
        {
            nRows = [_strings count];
        }
        else
        {
            nRows = 0;
        }
    }

	//NSLog(@"Number of rows: %i", nRows);
    return nRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    NSUInteger row = [indexPath row];
    
    // check if the delegate wants to take this
    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(PopupPickerViewCellForRow:forTableView:andRow:userData:)])
        {
            cell = [self.delegate PopupPickerViewCellForRow:self forTableView:tableView andRow:row userData:_userData];
        }
    }

    // if we don't have a cell yet
    if (nil == cell)
    {
        static NSString *PickerTableIdentifier = @"PickerTableIdentifier";
        
        cell = [tableView dequeueReusableCellWithIdentifier:PickerTableIdentifier];
        if (nil == cell)
        {
            cell = [[UITableViewCell alloc] initWithStyle:self.tableViewCellStyle reuseIdentifier:PickerTableIdentifier];
        }

        BOOL bFormatted = NO;
        if (self.delegate)
        {
            if ([self.delegate respondsToSelector:@selector(PopupPickerViewFormatCell:onRow:withCell:userData:)])
            {
                bFormatted = [self.delegate PopupPickerViewFormatCell:self onRow:row withCell:cell userData:_userData];
            }
        }

        if (!bFormatted)
        {
            
        }
    }
	
    cell.textLabel.font = [UIFont fontWithName:@"Lato-Black.ttf" size:17.0];
    cell.textLabel.numberOfLines = 1;
    cell.textLabel.text = [_strings objectAtIndex:row];
    cell.textLabel.textColor = [UIColor blackColor];
    cell.accessoryView.hidden = YES;
    if(self.categories) {
        NSInteger index = [self.categories indexOfObject:cell.textLabel.text];
        if(index == NSNotFound) {
            UIImage *image = [UIImage imageNamed:@"btn_addCategory.png"];
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
    }
    else if (self.accessoryImage) {
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
    
    UIView* separatorLineView = [[UIView alloc] initWithFrame:CGRectMake(0, cell.bounds.size.height-1, 320, 0.5)];
    separatorLineView.backgroundColor = [UIColor lightGrayColor];
    [cell.contentView addSubview:separatorLineView];
    
    return cell;
}

- (void)accessoryButtonTapped:(id)sender event:(id)event
{
    UIButton *button = (UIButton *) sender;
    NSString *newCategory = [self.strings objectAtIndex:button.tag];
    
    if ([self.delegate respondsToSelector:@selector(PopupPickerViewDidTouchAccessory: categoryString:)])
    {
        [self.delegate PopupPickerViewDidTouchAccessory:self categoryString:newCategory];
    }
}

#pragma mark - Table View Delegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(PopupPickerViewSelected:onRow: userData:)])
        {
            [self.delegate PopupPickerViewSelected:self onRow:indexPath.row userData:_userData];
        }
    }

    // remove the highlight on the selected row
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end

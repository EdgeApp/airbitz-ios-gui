//
//  PopupPickerView.m
//  AirBitz
//
//  Created by Adam Harris on 5/5/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PopupPickerView2.h"
#import "MainViewController.h"
#import "Theme.h"
#import "WalletHeaderView.h"

#define DEFAULT_WIDTH           330

#define DEFAULT_CELL_HEIGHT     35

#define OFFSET_YPOS             45  // how much to offset the y position

#define ARROW_INSET             0.0

#define DATE_PICKER_HEIGHT      216

#define POPUP_STROKE_WIDTH		0.0	//width of the thin border around the entire popup picker

@interface PopupPickerView2 () <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>
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
@property (nonatomic, strong)   WalletHeaderView        *headerView;




@property (nonatomic)         BOOL                          bFullSize;
@property (nonatomic, strong) NSString                      *headerText;
@property (nonatomic, strong) NSArray                       *strings;
@property (nonatomic, strong) NSArray                       *categories;
@property (nonatomic, strong) UIImage                       *accessoryImage;
@property (nonatomic, assign) tPopupPicker2Position         position;

@end

@implementation PopupPickerView2

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

//- (void)addCropLine:(CGPoint)pointOnScreen direction:(tPopupPickerPosition)cropDirection animated:(BOOL)animated
//{
//	float distance;
//	CGPoint newPoint = [self.superview convertPoint:pointOnScreen fromView:self.window];
//	switch (cropDirection)
//	{
//			case PopupPickerPosition_Above:
//				distance = newPoint.y - availableSpace.origin.y;
//				if (distance > 0)
//				{
//					availableSpace.origin.y += distance;
//					availableSpace.size.height -= distance;
//				}
//				[self constrainToKeepoutsAnimated:animated];
//			break;
//			case PopupPickerPosition_Below:
//				distance = (availableSpace.origin.y + availableSpace.size.height) - newPoint.y;
//				if (distance > 0)
//				{
//					availableSpace.size.height -= distance;
//				}
//				[self constrainToKeepoutsAnimated:animated];
//			break;
//			default:
//				NSLog(@"*** THIS CROP DIRECTION NOT SUPPORTED YET ***");
//				break;
//	}
//}
//
//- (void)constrainToKeepoutsAnimated:(BOOL)animated
//{
//	float duration = 0.01;
//	if (animated)
//	{
//		duration = 0.35;
//	}
//	[UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionCurveEaseInOut
//					 animations:^
//	 {
//		 CGRect frame = self.frame;
//
//		 if(frame.origin.y < availableSpace.origin.y)
//		 {
//			 frame.size.height += (availableSpace.origin.y - frame.origin.y);
//			 frame.origin.y -= (availableSpace.origin.y - frame.origin.y);
//		 }
//
//		 if((frame.origin.y + frame.size.height) > (availableSpace.origin.y + availableSpace.size.height))
//		 {
//			 frame.size.height -= ((frame.origin.y + frame.size.height) - (availableSpace.origin.y + availableSpace.size.height));
//		 }
//
//		 //also don't intersect keyboard
//		 if((frame.origin.y + frame.size.height) > keyboardFrame.origin.y)
//		 {
//			 frame.size.height -= ((frame.origin.y + frame.size.height) - keyboardFrame.origin.y);
//		 }
//		 self.frame = frame;
//	 }
//	 completion:^(BOOL finished)
//	 {
//	 }];
//}
//
- (void)dismiss
{
    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
                     {
                         [self setAlpha:0];
                     }
                     completion:^(BOOL finished)
                     {
                         [self removeFromSuperview];
                     }];
}
+ (PopupPickerView2 *)CreateForView:(UIView *)parentView
                   relativePosition:(tPopupPicker2Position)position
                        withStrings:(NSArray *)strings
                      withAccessory:(UIImage *)image                    /* optional accessory for each row */
                         headerText:(NSString *)headerText
{
    // create the picker from the xib
    PopupPickerView2 *popup = [[[NSBundle mainBundle] loadNibNamed:@"PopupPickerView2" owner:nil options:nil] objectAtIndex:0];
    [popup setCellHeight:[Theme Singleton].heightPopupPicker];
    
	UIWindow *window = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
	popup->availableSpace = window.frame;
	
    popup.position = position;
        popup.headerText = headerText;
    // add the popup to the parent
	[parentView addSubview:popup];

    popup.bFullSize = YES;

    // set the strings and categories
	popup.strings = strings;
//    popup.categories = categories;

    popup.accessoryImage = image;
    
    // start with the existing frame
    CGRect newFrame = popup.frame;
    
    newFrame.size.height = [MainViewController getHeight] - [MainViewController getHeaderHeight] - [MainViewController getFooterHeight];
    
    // change the width
    newFrame.size.width = [MainViewController getWidth];
    
    // set new height and width
    popup.frame = newFrame;
    
    // calculate the parent's size (for use later)
    CGSize parentFrameSize = parentView.frame.size;
    CGFloat newY;

    newFrame.size.width = [MainViewController getWidth];
    newFrame.origin.x = 0;
    newFrame.size.height = [MainViewController getHeight] - [MainViewController getHeaderHeight] - [MainViewController getFooterHeight];

    if (PopupPicker2Position_Full_Dropping == position)
    {
        newFrame.origin.y = -[MainViewController getHeight];
    }
    else if (PopupPicker2Position_Full_Rising == position)
    {
        newFrame.origin.y = [MainViewController getHeight];
    }
    else if (PopupPicker2Position_Full_Fading == position)
    {
        newFrame.origin.y = [MainViewController getHeaderHeight];
    }
    popup.frame = newFrame;
    [popup setAlpha:0];

    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
                     {
                         CGRect frame = popup.frame;
                         frame.origin.y = [MainViewController getHeaderHeight];
                         popup.frame = frame;
                         [popup setAlpha:1];

                     }
                     completion:^(BOOL finished)
                     {
                     }];

    // assign the delegate
	popup.delegate = (id<PopupPickerView2Delegate>)parentView;
    
    // select the row if one was specified
//    if (selectedRow != -1)
//    {
//        //cw table wasn't scrolling to selected position because rows hadn't been filled in yet.  PerformSelector fixed it.
//		[popup performSelectorOnMainThread:@selector(selectRow2:) withObject:[NSNumber numberWithInt:(int)selectedRow] waitUntilDone:NO];
//    }
    
//    if(rounded) {
//        // round the corners
//        popup.layer.cornerRadius = 10;
//        popup->innerView.layer.cornerRadius = 10;
//        popup->m_viewBorder.layer.cornerRadius = 10;
//
//        // add drop shadow
//        popup.layer.shadowColor = [UIColor blackColor].CGColor;
//        popup.layer.shadowOpacity = 0.5;
//        popup.layer.shadowRadius = 10;
//        popup.layer.shadowOffset = CGSizeMake(5.0f, 5.0f);
//    }
//

    return popup;
}

- (void)initMyVariables
{
    // start with no delegate
    self.delegate = nil;
    
    // start with no data
    self.userData = nil;
    
    // start with the options hidden
    self.showOptions = NO;

    // start with default style
    self.tableViewCellStyle = UITableViewCellStyleDefault;

    // This will remove extra separators from tableview
//    table.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
//    table.separatorStyle=UITableViewCellSeparatorStyleNone;
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

    NSInteger section;

    section = 1;

    NSIndexPath *ip=[NSIndexPath indexPathForRow:row inSection:section];
    [table selectRowAtIndexPath:ip animated:NO scrollPosition:UITableViewScrollPositionTop];
	[table scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
}

-(void)assignDelegate:(id<PopupPickerView2Delegate>)theDelegate
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
        if ([self.delegate respondsToSelector:@selector(PopupPickerView2Cancelled:userData:)])
        {
            [self.delegate PopupPickerView2Cancelled:self userData:_userData];
        }
    }
}

- (IBAction)buttonKeyboardTouched:(id)sender
{
    if (nil != self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(PopupPickerView2Keyboard:userData:)])
        {
            [self.delegate PopupPickerView2Keyboard:self userData:_userData];
        }
    }
}

- (IBAction)buttonTrashTouched:(id)sender
{
    if (nil != self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(PopupPickerView2Clear:userData:)])
        {
            [self.delegate PopupPickerView2Clear:self userData:_userData];
        }
    }
}

#pragma mark - TableView Data Source methods
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.bFullSize)
        return 2;
    else
        return 1;

}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (self.bFullSize)
    {
        if (section == 0)
            return [Theme Singleton].heightPopupPicker;
    }
    return 0;

}

-(UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{

    if (self.bFullSize)
    {
        if (section == 0)
        {
            self.headerView = [WalletHeaderView CreateWithTitle:NSLocalizedString(self.headerText, nil)
                                                                    collapse:NO];
            self.headerView.btn_expandCollapse.hidden = YES;
            self.headerView.btn_expandCollapse.enabled = NO;
            self.headerView.segmentedControlBTCUSD.hidden = YES;
            self.headerView.segmentedControlBTCUSD.enabled = NO;
            self.headerView.btn_addWallet.hidden = NO;
            self.headerView.btn_addWallet.enabled = YES;
            [self.headerView createCloseButton];

            self.headerView.delegate = self;
            return self.headerView;
        }
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger nRows = -1;

    if (self.bFullSize)
    {
        if (section == 0)
            return 0;
    }

    // check if the delegate wants to take this
    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(PopupPickerView2NumberOfRows:userData:)])
        {
            nRows = [self.delegate PopupPickerView2NumberOfRows:self userData:_userData];
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
    NSUInteger section = [indexPath section];

    if (self.bFullSize)
    {
        if (section == 0)
            return nil;
    }


    // check if the delegate wants to take this
    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(PopupPickerView2CellForRow:forTableView:andRow:userData:)])
        {
            cell = [self.delegate PopupPickerView2CellForRow:self forTableView:tableView andRow:row userData:_userData];
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
            if ([self.delegate respondsToSelector:@selector(PopupPickerView2FormatCell:onRow:withCell:userData:)])
            {
                bFormatted = [self.delegate PopupPickerView2FormatCell:self onRow:row withCell:cell userData:_userData];
            }
        }

        if (!bFormatted)
        {
            
        }
    }
	
    cell.textLabel.font = [UIFont fontWithName:@"Lato-Regular" size:17.0];
    cell.textLabel.numberOfLines = 1;
    cell.textLabel.text = [_strings objectAtIndex:row];
    cell.textLabel.textColor = [Theme Singleton].colorTextDark;
    cell.accessoryView.hidden = YES;
    cell.backgroundColor = [UIColor clearColor];
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
    
//    UIView* separatorLineView = [[UIView alloc] initWithFrame:CGRectMake(0, cell.bounds.size.height-1, 320, 0.5)];
//    separatorLineView.backgroundColor = [UIColor lightGrayColor];
//    [cell.contentView addSubview:separatorLineView];
    
    return cell;
}

- (void)accessoryButtonTapped:(id)sender event:(id)event
{
    UIButton *button = (UIButton *) sender;
    NSString *newCategory = [self.strings objectAtIndex:button.tag];
    
    if ([self.delegate respondsToSelector:@selector(PopupPickerView2DidTouchAccessory: categoryString:)])
    {
        [self.delegate PopupPickerView2DidTouchAccessory:self categoryString:newCategory];
    }
}

#pragma mark - Table View Delegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(PopupPickerView2Selected:onRow: userData:)])
        {
            [self.delegate PopupPickerView2Selected:self onRow:indexPath.row userData:_userData];
        }
    }

    // remove the highlight on the selected row
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma WalletHeaderViewDelegate

- (void)walletHeaderView:(WalletHeaderView *)walletHeaderView Expanded:(BOOL)expanded
{

}
- (void)addWallet
{
    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
                     {
                         [self setAlpha:0];

                     }
                     completion:^(BOOL finished)
                     {
                     }];

    [self.delegate PopupPickerView2Cancelled:self userData:_userData];
}


@end

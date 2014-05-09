//
//  PopupPickerView.m
//  AirBitz
//
//  Created by Adam Harris on 5/5/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PopupPickerView.h"

#define DEFAULT_WIDTH           300

#define DEFAULT_CELL_HEIGHT     44

#define OFFSET_YPOS             45  // how much to offset the y position

#define MIN_CELLS_VISIBLE        2

#define ARROW_INSET             1.0

#define DATE_PICKER_HEIGHT      216

@interface PopupPickerView () <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>
{
    BOOL                        _bShowOptions;
    BOOL                        _bDisableBackgroundTouch;
	IBOutlet UITableView        *table;
	IBOutlet UIView             *innerView;
    IBOutlet UIButton           *m_buttonBackground;
    IBOutlet UIView             *m_viewBorder;
}

@property (nonatomic, strong)   IBOutlet UIImageView    *arrowImage;
@property (weak, nonatomic)     IBOutlet UIView         *viewOptions;
@property (weak, nonatomic)     IBOutlet UIButton       *buttonKeyboard;
@property (weak, nonatomic)     IBOutlet UIButton       *buttonTrash;

@property (nonatomic, assign) id<PopupPickerViewDelegate>   delegate;
@property (nonatomic, strong) NSArray                       *strings;
@property (nonatomic, assign) tPopupPickerPosition          position;

@end

@implementation PopupPickerView


+ (PopupPickerView *)CreateForView:(UIView *)parentView positionRelativeTo:(UIView *)posView withPosition:(tPopupPickerPosition)position withStrings:(NSArray *)strings selectedRow:(NSInteger)selectedRow maxCellsVisible:(NSInteger)maxCellsVisible
{
	return [PopupPickerView CreateForView:parentView
                       positionRelativeTo:posView
                             withPosition:position
                              withStrings:strings
                              selectedRow:selectedRow
                          maxCellsVisible:maxCellsVisible
                                withWidth:DEFAULT_WIDTH
                            andCellHeight:DEFAULT_CELL_HEIGHT];
}

+ (PopupPickerView *)CreateForView:(UIView *)parentView positionRelativeTo:(UIView *)posView withPosition:(tPopupPickerPosition)position withStrings:(NSArray *)strings selectedRow:(NSInteger)selectedRow maxCellsVisible:(NSInteger)maxCellsVisible withWidth:(NSInteger)width andCellHeight:(NSInteger)cellHeight
{
	return [PopupPickerView CreateForView:parentView
                          relativeToFrame:posView.frame
                             viewForFrame:[posView superview]
                             withPosition:position
                              withStrings:strings
                              selectedRow:selectedRow
                          maxCellsVisible:maxCellsVisible
                                withWidth:width
                            andCellHeight:cellHeight];
}

+ (PopupPickerView *)CreateForView:(UIView *)parentView relativeToFrame:(CGRect)frame viewForFrame:(UIView *)frameView withPosition:(tPopupPickerPosition)position withStrings:(NSArray *)strings selectedRow:(NSInteger)selectedRow maxCellsVisible:(NSInteger)maxCellsVisible
{
    return [PopupPickerView CreateForView:parentView
                          relativeToFrame:frame
                             viewForFrame:frameView
                             withPosition:position
                              withStrings:strings
                              selectedRow:selectedRow
                          maxCellsVisible:maxCellsVisible
                                withWidth:DEFAULT_WIDTH
                            andCellHeight:DEFAULT_CELL_HEIGHT];
}

+ (PopupPickerView *)CreateForView:(UIView *)parentView relativeToFrame:(CGRect)frame viewForFrame:(UIView *)frameView withPosition:(tPopupPickerPosition)position withStrings:(NSArray *)strings selectedRow:(NSInteger)selectedRow maxCellsVisible:(NSInteger)maxCellsVisible withWidth:(NSInteger)width andCellHeight:(NSInteger)cellHeight
{
    // create the picker from the xib
    PopupPickerView *popup = [[[NSBundle mainBundle] loadNibNamed:@"PopupPickerView" owner:nil options:nil] objectAtIndex:0];
    [popup setCellHeight:cellHeight];
    
    popup.position = position;
    
    // add the popup to the parent
	[parentView addSubview:popup];

    // calculate the border thickness
    CGFloat borderThickness = (popup.frame.size.height - popup->table.frame.size.height) / 2.0;
    
    // set the strings
	popup.strings = strings;
    
    // start with the existing frame
    CGRect newFrame = popup.frame;
    
    // give it enough height to handle the items
    NSInteger nCellsVisible = [strings count];
    if (nCellsVisible < MIN_CELLS_VISIBLE)
    {
        nCellsVisible = MIN_CELLS_VISIBLE;
    }
    if (nCellsVisible > maxCellsVisible)
    {
        nCellsVisible = maxCellsVisible;
    }
    newFrame.size.height = (nCellsVisible * cellHeight) + (2 * borderThickness);
    
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
    newFrame.origin = [frameView convertPoint:frame.origin toView:popup.superview];
    
    // if this is above or below
    if ((PopupPickerPosition_Below == position) || (PopupPickerPosition_Above == position))
    {
        // set up point image
        CGRect imageFrame = popup.arrowImage.frame;
        UIImage *image = [UIImage imageNamed:@"picker_up_point.png"];
        imageFrame.size = image.size;
        popup.arrowImage.frame = imageFrame;
        popup.arrowImage.image = image;

        // set the X position directly under the center of the positioning view
        newFrame.origin.x += (frame.size.width / 2);        // move to center of view
        newFrame.origin.x -= (popup.frame.size.width / 2);          // bring it left so the center is under the view 
        
        if (PopupPickerPosition_Below == position)
        {
            // put it under the positioning view control
            newFrame.origin.y += frame.size.height;             
            newFrame.origin.y += popup.arrowImage.frame.size.height;  // offset by arrow height
        }
        else // if (PopupPickerPosition_Above == position)
        {
            // put it above the positioning view
            newFrame.origin.y -= newFrame.size.height;
            newFrame.origin.y -= popup.arrowImage.frame.size.height;  // offset by arrow height
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
        
        // set the new frame
        popup.frame = newFrame;
        
        // set up the pointer position
        CGRect arrowFrame = popup.arrowImage.frame;
        if (PopupPickerPosition_Below == position)
        {
            // move the arrow to the arrow height above the frame
            arrowFrame.origin.y = 0.0 - (arrowFrame.size.height) + ARROW_INSET;
        }
        else // if (PopupPickerPosition_Above == position)
        {
            // move the arrow to the bottom of the frame
            arrowFrame.origin.y = newFrame.size.height - ARROW_INSET;
            
            // rotate the image by 180 degrees
            CGAffineTransform rotate = CGAffineTransformMakeRotation( M_PI );
            [popup.arrowImage setTransform:rotate];
        }
        
        // we need the arrow to be centered on the button, start with the pos view in parent coords
        CGRect frameForArrowRef = [frameView convertRect:frame toView:popup];
        
        // put it in the center of the rect
        arrowFrame.origin.x = frameForArrowRef.origin.x + (frameForArrowRef.size.width / 2.0) - (arrowFrame.size.width / 2.0);
        
        // set the final arrow location
        popup.arrowImage.frame = arrowFrame;
    }
    else // if ((PopupPickerPosition_Left == position) || (PopupPickerPosition_Right == position))
    {
        // set up pointer image
        CGRect imageFrame = popup.arrowImage.frame;
        UIImage *image = [UIImage imageNamed:@"picker_left_point.png"];
        imageFrame.size = image.size;
        popup.arrowImage.frame = imageFrame;
        popup.arrowImage.image = image;

        // set the Y position directly beside the center of the positioning view
        newFrame.origin.y += (frame.size.height / 2);        // move to center of frame
        newFrame.origin.y -= (popup.frame.size.height / 2);  // bring it up so the center is next to the view
        
        if (PopupPickerPosition_Right == position)
        {
            // put it to the right of the positioning frame
            newFrame.origin.x += frame.size.width;
            newFrame.origin.x += popup.arrowImage.frame.size.width;  // offset by arrow width
        }
        else // if (PopupPickerPosition_Left == position)
        {
            // put it to the left of the positioning frame
            newFrame.origin.x -= newFrame.size.width;             
            newFrame.origin.x -= popup.arrowImage.frame.size.width;  // offset by arrow width
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
        CGRect frameForArrowRef = [frameView convertRect:frame toView:popup];

        // put it in the center of the rect
        arrowFrame.origin.y = frameForArrowRef.origin.y + (frameForArrowRef.size.height / 2.0) - (arrowFrame.size.height / 2.0);
        
        // set the final arrow location
        popup.arrowImage.frame = arrowFrame;
    }
    
    // assign the delegate
    [popup assignDelegate:(id<PopupPickerViewDelegate>)parentView];
    
    // select the row if one was specified
    if (selectedRow != -1) 
    {
        [popup selectRow:selectedRow];
    }

    return popup;
}

- (void)initMyVariables
{
    // add a black border around the grey 'border'
    m_viewBorder.layer.borderWidth = 1;
    m_viewBorder.layer.borderColor = [[UIColor blackColor] CGColor];
    
	//round the corners
	self.layer.cornerRadius = 10;
	innerView.layer.cornerRadius = 10;
    m_viewBorder.layer.cornerRadius = 10;
	
	//add drop shadow
	self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOpacity = 0.5;
    self.layer.shadowRadius = 10;
    self.layer.shadowOffset = CGSizeMake(5.0f, 5.0f);
    
    // start with no delegate
    self.delegate = nil;
    
    // start with no data
    self.userData = nil;
    
    // start with the options hidden
    self.showOptions = NO;
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
            CGRect frameArrow = self.arrowImage.frame;
            
            if (frameSelf.origin.y - self.viewOptions.frame.size.height >= 0)
            {
                frameSelf.origin.y -= self.viewOptions.frame.size.height;
                frameArrow.origin.y += self.viewOptions.frame.size.height;
            }
            else
            {
                frameSelf.origin.y += self.viewOptions.frame.size.height;
                frameArrow.origin.y -= self.viewOptions.frame.size.height;
            }
            
            self.arrowImage.frame = frameArrow;
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

-(void)selectRow:(NSInteger)row
{
	NSIndexPath *ip=[NSIndexPath indexPathForRow:row inSection:0];
	[table selectRowAtIndexPath:ip animated:NO scrollPosition:UITableViewScrollPositionTop];
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

#pragma mark - UIView delegate methods

#if 0 // doesn't seem to be needed now

// this is used to make sure our background button gets touch events outside our view
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    // if the touch was within our table view
    if (CGRectContainsPoint(table.frame, point))
    {
        return table;
    }
    else if (CGRectContainsPoint(self.buttonKeyboard.frame, point))
    {
        return self.buttonKeyboard;
    }
    else if (CGRectContainsPoint(self.buttonTrash.frame, point))
    {
        return self.buttonTrash;
    }
    else if (CGRectContainsPoint(self.viewOptions.frame, point))
    {
        return self.viewOptions;
    }

    if (_bDisableBackgroundTouch)
    {
        return self;
    }
    else
    {
        // everything else goes to background
        return m_buttonBackground;
    }
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesBegan:touches withEvent:event];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    return YES;
}
#endif

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
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:PickerTableIdentifier];
            cell.textLabel.numberOfLines = 1;
        }
        
        cell.textLabel.text = [_strings objectAtIndex:row];
        cell.textLabel.textColor = [UIColor blackColor];
        
        if (self.delegate)
        {
            if ([self.delegate respondsToSelector:@selector(PopupPickerViewFormatCell:onRow:withCell:userData:)])
            {
                [self.delegate PopupPickerViewFormatCell:self onRow:row withCell:cell userData:_userData];
            }
        }
    }
	
    return cell;
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

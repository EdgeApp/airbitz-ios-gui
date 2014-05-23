//
//  PopupWheelPickerView.m
//  AirBitz
//
//  Created by Adam Harris on 5/6/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "PopupWheelPickerView.h"
#import "CommonTypes.h"

#define ARROW_INSET             9.0

@interface PopupWheelPickerView () <UIPickerViewDataSource, UIPickerViewDelegate>
{
	IBOutlet UIView     *innerView;
    IBOutlet UIButton   *m_buttonBackground;
    IBOutlet UIView     *m_viewBorder;
}

@property (nonatomic, retain)   IBOutlet UIImageView            *m_arrowImage;
@property (weak, nonatomic)     IBOutlet UIPickerView           *viewPicker;


@property (nonatomic, assign) id<PopupWheelPickerViewDelegate>  delegate;
@property (nonatomic, assign) id                                userData;
@property (nonatomic, strong) NSArray                           *arrayChoices;
@property (nonatomic, strong) NSArray                           *arrayStartingSelections;

- (void)assignDelegate:(id<PopupWheelPickerViewDelegate>)       delegate;

@end

@implementation PopupWheelPickerView

+ (PopupWheelPickerView *)CreateForView:(UIView *)parentView positionRelativeTo:(UIView *)posView withPosition:(tPopupWheelPickerPosition)position withChoices:(NSArray *)arrayChoices startingSelections:(NSArray *)arraySelections userData:(id)data andDelegate:(id<PopupWheelPickerViewDelegate>)delegate
{
	return [PopupWheelPickerView CreateForView:parentView relativeToFrame:posView.frame viewForFrame:[posView superview] withPosition:position withChoices:arrayChoices startingSelections:arraySelections userData:data andDelegate:delegate];
}

+ (PopupWheelPickerView *)CreateForView:(UIView *)parentView relativeToFrame:(CGRect)frame viewForFrame:(UIView *)frameView withPosition:(tPopupWheelPickerPosition)position withChoices:(NSArray *)arrayChoices startingSelections:(NSArray *)arraySelections userData:(id)data andDelegate:(id<PopupWheelPickerViewDelegate>)delegate
{
    // create the picker from the xib
    PopupWheelPickerView *popup = [[[NSBundle mainBundle] loadNibNamed:@"PopupWheelPickerView" owner:nil options:nil] objectAtIndex:0];


    // add the popup to the parent
	[parentView addSubview:popup];

    // start with the existing frame
    CGRect newFrame = popup.frame;
    
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
    if ((PopupWheelPickerPosition_Below == position) || (PopupWheelPickerPosition_Above == position))
    {
        // set up the image for the pointer
        CGRect imageFrame = popup.m_arrowImage.frame;
        UIImage *image = [UIImage imageNamed:@"picker_left_point.png"];
        imageFrame.size = image.size;
        popup.m_arrowImage.frame = imageFrame;
        popup.m_arrowImage.image = image;

        // set the X position directly under the center of the positioning view
        newFrame.origin.x += (frame.size.width / 2);        // move to center of view
        newFrame.origin.x -= (popup.frame.size.width / 2);          // bring it left so the center is under the view 
        
        if (PopupWheelPickerPosition_Below == position)
        {
            // put it under the positioning view control
            newFrame.origin.y += frame.size.height;             
            newFrame.origin.y += popup.m_arrowImage.frame.size.height;  // offset by arrow height
        }
        else // if (PopupWheelPickerPosition_Above == position)
        {
            // put it above the positioning view
            newFrame.origin.y -= newFrame.size.height;
            newFrame.origin.y -= popup.m_arrowImage.frame.size.height;  // offset by arrow height
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
        CGRect arrowFrame = popup.m_arrowImage.frame;
        if (PopupWheelPickerPosition_Below == position)
        {
            // move the arrow to the arrow height above the frame
            arrowFrame.origin.y = 0.0 - (arrowFrame.size.height) + ARROW_INSET;
			// rotate the image by 90 degrees CW
            CGAffineTransform rotate = CGAffineTransformMakeRotation( M_PI * 0.5 );
            [popup.m_arrowImage setTransform:rotate];
        }
        else // if (PopupWheelPickerPosition_Above == position)
        {
            // move the arrow to the bottom of the frame
            arrowFrame.origin.y = newFrame.size.height - ARROW_INSET;
            
            // rotate the image by 90 degrees CCW
            CGAffineTransform rotate = CGAffineTransformMakeRotation( M_PI * 1.5 );
            [popup.m_arrowImage setTransform:rotate];
        }
        
        // we need the arrow to be centered on the button, start with the pos view in parent coords
        CGRect frameForArrowRef = [frameView convertRect:frame toView:popup];
        
        // put it in the center of the rect
        arrowFrame.origin.x = frameForArrowRef.origin.x + (frameForArrowRef.size.width / 2.0) - (arrowFrame.size.width / 2.0);
        
        // set the final arrow location
        popup.m_arrowImage.frame = arrowFrame;
    }
    else // if ((PopupWheelPickerPosition_Left == position) || (PopupWheelPickerPosition_Right == position))
    {
        // set up pointer image
        CGRect imageFrame = popup.m_arrowImage.frame;
        UIImage *image = [UIImage imageNamed:@"picker_left_point.png"];
        imageFrame.size = image.size;
        popup.m_arrowImage.frame = imageFrame;
        popup.m_arrowImage.image = image;

        // set the Y position directly beside the center of the positioning view
        newFrame.origin.y += (frame.size.height / 2);        // move to center of frame
        newFrame.origin.y -= (popup.frame.size.height / 2);  // bring it up so the center is next to the view
        
        if (PopupWheelPickerPosition_Right == position)
        {
            // put it to the right of the positioning frame
            newFrame.origin.x += frame.size.width;
            newFrame.origin.x += popup.m_arrowImage.frame.size.width;  // offset by arrow width
        }
        else // if (PopupWheelPickerPosition_Left == position)
        {
            // put it to the left of the positioning frame
            newFrame.origin.x -= newFrame.size.width;             
            newFrame.origin.x -= popup.m_arrowImage.frame.size.width;  // offset by arrow width
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
        CGRect arrowFrame = popup.m_arrowImage.frame;
        if (PopupWheelPickerPosition_Right == position)
        {
            // move the arrow to the arrow width left of the frame
            arrowFrame.origin.x = 0.0 - (arrowFrame.size.width) + ARROW_INSET;
        }
        else // if (PopupWheelPickerPosition_Left == position)
        {
            // move the arrow to the right of the frame
            arrowFrame.origin.x = newFrame.size.width - ARROW_INSET;
            
            // rotate the image by 180 degrees
            CGAffineTransform rotate = CGAffineTransformMakeRotation( M_PI );
            [popup.m_arrowImage setTransform:rotate];
        }
        
        // we need the arrow to be centered on the button, start with the pos view in parent coords
        CGRect frameForArrowRef = [frameView convertRect:frame toView:popup];

        // put it in the center of the rect
        arrowFrame.origin.y = frameForArrowRef.origin.y + (frameForArrowRef.size.height / 2.0) - (arrowFrame.size.height / 2.0);
        
        // set the final arrow location
        popup.m_arrowImage.frame = arrowFrame;
    }
    
    // assign the delegate
    [popup assignDelegate:delegate];
    
    popup.userData = data;
    popup.arrayChoices = arrayChoices;
    popup.arrayStartingSelections = arraySelections;

    if (popup.arrayStartingSelections)
    {
        for (int i = 0; i < [popup.arrayChoices count]; i++)
        {
            if ([popup.arrayStartingSelections count] > i)
            {
                NSInteger selection = [[popup.arrayStartingSelections objectAtIndex:i] integerValue];
                if (selection >= 0)
                {
                    [popup.viewPicker selectRow:selection inComponent:i animated:NO];
                }
            }
        }
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

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        innerView.backgroundColor = [UIColor whiteColor];
        self.viewPicker.backgroundColor = [UIColor whiteColor];
    }
    else
    {
        innerView.backgroundColor = [UIColor colorWithRed:(32.0 / 255.0) green:(35.0 / 255.0) blue:(42.0 / 255.0) alpha:1.0];
    }
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

- (void)awakeFromNib
{
    [super awakeFromNib];
	[self initMyVariables];
}

- (void)dealloc
{
}

-(void)assignDelegate:(id<PopupWheelPickerViewDelegate>)theDelegate
{
    self.delegate = theDelegate;
}

#pragma mark - Action Methods

- (IBAction)buttonOkayTouched:(id)sender
{
    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(PopupWheelPickerViewExit: withSelections: userData:)])
        {
            // build the choices made array
            NSMutableArray *arraySelections = [[NSMutableArray alloc] initWithCapacity:[self.arrayChoices count]];
            for (int i = 0; i < [self.arrayChoices count]; i++)
            {
                [arraySelections addObject:[NSNumber numberWithInteger:[self.viewPicker selectedRowInComponent:i]]];
            }

            [self.delegate PopupWheelPickerViewExit:self withSelections:arraySelections userData:_userData];
        }
    }
}

- (IBAction)buttonCancelTouched:(id)sender
{
    if (nil != self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(PopupWheelPickerViewCancelled: userData:)])
        {
            [self.delegate PopupWheelPickerViewCancelled:self userData:_userData];
        }
    }
}

#pragma mark - Picker Data Source Methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return [self.arrayChoices count];
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [[self.arrayChoices objectAtIndex:component] count];
}

#pragma mark - Picker Delegate Methods

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{

}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    UILabel *label = [[UILabel alloc] init];
    label.opaque = NO;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor blackColor];
    label.font = [UIFont boldSystemFontOfSize:17];
    [label setTextAlignment:NSTextAlignmentCenter];

    label.text = [[self.arrayChoices objectAtIndex:component] objectAtIndex:row];

    return label;
}


@end

//
//  DividerView.m
//
//  Copyright (c) 2014, Airbitz
//  All rights reserved.
//
//  Redistribution and use in source and binary forms are permitted provided that
//  the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//  3. Redistribution or use of modified source code requires the express written
//  permission of Airbitz Inc.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those
//  of the authors and should not be interpreted as representing official policies,
//  either expressed or implied, of the Airbitz Project.
//
//  See AUTHORS for contributing developers
//

/*  DividerView has two states:
	userControllable YES/NO
	
	When userControllable is YES:
		User can tap and drag DividerView
		DividerView will send touchEvents to delegate (for it to decide how to behave based on user actions)
		Vertical positioning is controlled by user
		
	When userControllable is NO:
		Touch events on DividerView are ignored
		Vertical positioning is controlled by delegate setting frame.origin
*/

#import "DividerView.h"

@interface DividerView ()


@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *dragbarView;
@property (nonatomic, weak) IBOutlet UIImageView *dividerbarView;

@end
@implementation DividerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)awakeFromNib
{
	self.titleLabel.alpha = 1.0;
             self.dragbarView.hidden = true;
             self.dividerbarView.hidden = false;
	self.userInteractionEnabled = NO;
}

-(void)setUserControllable:(BOOL)userControllable
{
	_userControllable = userControllable;
	if(userControllable)
	{
		self.userInteractionEnabled = YES;
		[UIView animateWithDuration:0.35
							  delay:0.0
							options:UIViewAnimationOptionCurveLinear
						 animations:^
		 {
			 self.titleLabel.alpha = 0.0;
                         self.dragbarView.hidden = false;
                         self.dividerbarView.hidden = true;

		 }
		 completion:^(BOOL finished)
		 {
			 
		 }];
	}
	else
	{
		self.userInteractionEnabled = NO;
		[UIView animateWithDuration:0.35
							  delay:0.0
							options:UIViewAnimationOptionCurveLinear
						 animations:^
		 {
			 self.titleLabel.alpha = 1.0;
             self.dragbarView.hidden = true;
             self.dividerbarView.hidden = false;
		 }
		 completion:^(BOOL finished)
		 {
			 
		 }];
	}
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	if([self.delegate respondsToSelector:@selector(DividerViewTouchesBegan:withEvent:)])
	{
		[self.delegate DividerViewTouchesBegan:touches withEvent:event];
	}
	//[super touchesBegan:touches withEvent:event];
	//[self.nextResponder touchesBegan:touches withEvent:event];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	if([self.delegate respondsToSelector:@selector(DividerViewTouchesMoved:withEvent:)])
	{
		[self.delegate DividerViewTouchesMoved:touches withEvent:event];
	}
	//[super touchesMoved:touches withEvent:event];
	//[self.nextResponder touchesMoved:touches withEvent:event];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	if([self.delegate respondsToSelector:@selector(DividerViewTouchesEnded:withEvent:)])
	{
		[self.delegate DividerViewTouchesEnded:touches withEvent:event];
	}
	//[super touchesEnded:touches withEvent:event];
	//[self.nextResponder touchesEnded:touches withEvent:event];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
	if([self.delegate respondsToSelector:@selector(DividerViewTouchesCancelled:withEvent:)])
	{
		[self.delegate DividerViewTouchesCancelled:touches withEvent:event];
	}
	//[super touchesCancelled:touches withEvent:event];
	//[self.nextResponder touchesCancelled:touches withEvent:event];
}

@end

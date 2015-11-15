//
//  InfoView.m
//
//  Created by Carson Whitsett on 1/17/14.
//  Copyright (c) 2014 AirBitz, Inc.  All rights reserved.
//

#import "InfoView.h"
#import "DarkenView.h"
#import "MainViewController.h"

@interface InfoView () <UIWebViewDelegate, UIScrollViewDelegate>
{
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *agreeButtonHeight;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (nonatomic, weak) IBOutlet BlurView *darkenView;
@property (nonatomic, weak) IBOutlet UIView *contentView;
@property (nonatomic, weak) IBOutlet UIWebView *webView;
@property (nonatomic, assign)       BOOL bAgreeButton;
@end

@implementation InfoView

static InfoView *currentView = nil;
static NSString *currentHtml = nil;

+ (InfoView *)CreateWithDelegate:(id<InfoViewDelegate>)delegate
{
    if (currentView) {
        [currentView removeFromSuperview];
        currentView = nil;
        currentHtml = nil;
    }
    InfoView *iv;
    iv = [[[NSBundle mainBundle] loadNibNamed:@"InfoView~iphone" owner:nil options:nil] objectAtIndex:0];
    iv.delegate = delegate;
    currentView = iv;
    currentHtml = nil;
    iv.bAgreeButton = NO;
    iv.agreeButtonHeight.constant = 0;
    iv.agreeButton.hidden = YES;
    return iv;
}

+ (InfoView *)CreateWithHTML:(NSString *)strHTML forView:(UIView *)theView;
{
    return [InfoView CreateWithHTML:strHTML forView:theView agreeButton:NO delegate:nil];
}

+ (InfoView *)CreateWithHTML:(NSString *)strHTML
                     forView:(UIView *)theView
                 agreeButton:(BOOL)bAgreeButton
                    delegate:(id<InfoViewDelegate>) delegate;
{
    // Are we already showing this help page?
    if (currentHtml && [strHTML isEqualToString:currentHtml]) {
        return currentView;
    }
    // If not, dismiss any current help pages
    if (currentView) {
        [currentView removeFromSuperview];
        currentView = nil;
        currentHtml = nil;
    }
	InfoView *iv;

    iv = [[[NSBundle mainBundle] loadNibNamed:@"InfoView~iphone" owner:nil options:nil] objectAtIndex:0];

    CGRect frame;

    frame = theView.bounds;
    frame.origin.y += [MainViewController getHeaderHeight];
    frame.size.height -= [MainViewController getFooterHeight] + [MainViewController getHeaderHeight];

    iv.frame = frame;
	iv.delegate = delegate;
    iv.webView.scrollView.delegate = iv;

    [iv enableScrolling:YES];
	NSString* path = [[NSBundle mainBundle] pathForResource:strHTML ofType:@"html"];
	iv.htmlInfoToDisplay = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    [theView addSubview:iv];
    currentView = iv;
    currentHtml = strHTML;

    iv.agreeButtonHeight.constant  = 0;

    iv.bAgreeButton = bAgreeButton;
    if (bAgreeButton)
    {
        iv.agreeButton.hidden = NO;
        iv.closeButton.hidden = YES;
    }
    else
    {
        iv.agreeButton.hidden = YES;
        iv.closeButton.hidden = NO;
    }

	return iv;
}

- (void) initMyVariables
{
	self.webView.layer.cornerRadius = 0.0;
	self.webView.clipsToBounds = YES;
	self.webView.delegate = self;
	
	
	self.darkenView.alpha = 0.0;
	self.contentView.alpha = 0.0;
	self.contentView.transform = CGAffineTransformMakeScale(0.7, 0.7);
	self.contentView.layer.cornerRadius = 7.0;

    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	[UIView animateWithDuration:0.25
						  delay:0.0
						options:UIViewAnimationOptionCurveLinear
					 animations:^
	 {
		 self.darkenView.alpha = 0.5;
	 }
	 completion:^(BOOL finished)
	 {
		 [UIView animateWithDuration:0.15
							   delay:0.0
							 options:UIViewAnimationOptionCurveEaseIn
						  animations:^
		  {
			  self.contentView.alpha = 1.0;
			  self.contentView.transform = CGAffineTransformMakeScale(1.2, 1.2);
		  }
		 completion:^(BOOL finished)
		  {
			  [UIView animateWithDuration:0.15
									delay:0.0
								  options:UIViewAnimationOptionCurveEaseOut
							   animations:^
			   {
				   self.contentView.transform = CGAffineTransformMakeScale(1.0, 1.0);
			   }
				completion:^(BOOL finished)
			   {
                   [[UIApplication sharedApplication] endIgnoringInteractionEvents];
			   }];
		  }];
	 }];
}

-(void)enableScrolling:(BOOL)scrollEnabled
{
	self.webView.scrollView.scrollEnabled = scrollEnabled;
	self.webView.scrollView.bounces = scrollEnabled;
}

-(void)setHtmlInfoToDisplay:(NSString *)htmlInfoToDisplay
{
	_htmlInfoToDisplay = htmlInfoToDisplay;
	[self.webView loadHTMLString:_htmlInfoToDisplay baseURL:nil];
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

- (IBAction)IAgreeButton:(id)sender {
    [self Done:nil];
}

-(IBAction)Done:(UIButton *)sender
{
	[UIView animateWithDuration:0.25
						  delay:0.0
						options:UIViewAnimationOptionCurveLinear
					 animations:^
	 {
		 self.darkenView.alpha = 0.0;
		 self.contentView.alpha = 0.0;
	 }
	 completion:^(BOOL finished)
	 {
         [self dismiss];
         currentView = nil;
         currentHtml = nil;
	 }];
}

-(void)dismiss
{
     BOOL bExitHandled = NO;
     if (self.delegate)
     {
         if ([self.delegate respondsToSelector:@selector(InfoViewFinished:)])
         {
             [self.delegate InfoViewFinished:self];
             bExitHandled = YES;
         }
     }
     
     if (!bExitHandled)
     {
         [self removeFromSuperview];
     }
    currentView = nil;
    currentHtml = nil;
}

#pragma mark UIWebView delegates

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType
{
    if ( inType == UIWebViewNavigationTypeLinkClicked )
	{
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
	
    return YES;
}

#pragma mark UIScrollView delegates

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    float bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height;
    if (bottomEdge >= scrollView.contentSize.height)
    {
        // we are at the end
        if (self.bAgreeButton)
        {
            self.agreeButtonHeight.constant = 50;
            self.agreeButton.hidden = NO;
        }
    }
}

@end

//
//  InfoView.m
//
//  Created by Carson Whitsett on 1/17/14.
//  Copyright (c) 2014 AirBitz, Inc.  All rights reserved.
//

#import "InfoView.h"
#import "DarkenView.h"

@interface InfoView () <DarkenViewDelegate, UIWebViewDelegate>
{
}

@property (nonatomic, weak) IBOutlet DarkenView *darkenView;
@property (nonatomic, weak) IBOutlet UIView *contentView;
@property (nonatomic, weak) IBOutlet UIWebView *webView;
@end

@implementation InfoView


+ (InfoView *)CreateWithDelegate:(id<InfoViewDelegate>)delegate
{
	InfoView *iv;
	
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
		iv = [[[NSBundle mainBundle] loadNibNamed:@"InfoView~iphone" owner:nil options:nil] objectAtIndex:0];
	}
	else
	{
		iv = [[[NSBundle mainBundle] loadNibNamed:@"InfoView~ipad" owner:nil options:nil] objectAtIndex:0];
		
	}
	iv.delegate = delegate;
	return iv;
}

+ (void)CreateWithHTML:(NSString *)strHTML forView:(UIView *)theView
{
	InfoView *iv;

	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	{
		iv = [[[NSBundle mainBundle] loadNibNamed:@"InfoView~iphone" owner:nil options:nil] objectAtIndex:0];
	}
	else
	{
		iv = [[[NSBundle mainBundle] loadNibNamed:@"InfoView~ipad" owner:nil options:nil] objectAtIndex:0];

	}

	iv.delegate = nil;
	iv.frame = theView.bounds;
	[iv enableScrolling:NO];
	NSString* path = [[NSBundle mainBundle] pathForResource:strHTML ofType:@"html"];
	iv.htmlInfoToDisplay = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    [theView addSubview:iv];
}

- (void) initMyVariables
{
	self.webView.layer.cornerRadius = 4.0;
	self.webView.clipsToBounds = YES;
	self.webView.delegate = self;
	
	
	self.darkenView.delegate = self;
	self.darkenView.alpha = 0.0;
	self.contentView.alpha = 0.0;
	self.contentView.transform = CGAffineTransformMakeScale(0.7, 0.7);
	self.contentView.layer.cornerRadius = 7.0;


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
	 }];
}

-(void)DarkenViewTapped:(DarkenView *)view
{
	[self Done:nil];
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

@end

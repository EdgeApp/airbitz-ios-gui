//
//  PasswordVerifyView.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/21/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "PasswordVerifyView.h"
#import "Strings.h"
#import "Util.h"
#import "AB.h"
#import "Theme.h"

@interface PasswordVerifyView ()

@property (nonatomic, weak) IBOutlet UILabel *crackMessageLabel;

@end

@implementation PasswordVerifyView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

+ (PasswordVerifyView *)CreateInsideView:(UIView *)parentView withDelegate:(id<PasswordVerifyViewDelegate>)delegate
{
	PasswordVerifyView *pv;
	
    pv = [[[NSBundle mainBundle] loadNibNamed:@"PasswordVerifyView" owner:nil options:nil] objectAtIndex:0];

	[parentView addSubview:pv];
	CGRect frame = pv.frame;
//	frame.origin.x = (parentView.frame.size.width - frame.size.width) / 2;
    frame.origin.x = 0;
	frame.origin.y = -frame.size.height;
	pv.frame = frame;
	pv.delegate = delegate;
//	pv.layer.cornerRadius = 5;
//    pv.layer.shadowColor = [[UIColor blackColor] CGColor];
//    pv.layer.shadowRadius = 5.0f;
//    pv.layer.shadowOpacity = 1.0f;
//    pv.layer.shadowOffset = CGSizeMake(0.0, 0.0);
//    pv.layer.masksToBounds = NO;
	
    [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                          delay:[Theme Singleton].animationDelayTimeDefault
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 CGRect frame = pv.frame;
		 frame.origin.y = 0.0;
		 pv.frame = frame;
		 
		 
	 }
					 completion:^(BOOL finished)
	 {
		 //self.dividerView.alpha = 0.0;
	 }];
	return pv;
}

-(void)dismiss
{
    [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                          delay:[Theme Singleton].animationDelayTimeDefault
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 CGRect frame = self.frame;
		 frame.origin.y = -frame.size.height;
		 self.frame = frame;
		 
		 
	 }
	 completion:^(BOOL finished)
	 {
		 [self.delegate PasswordVerifyViewDismissed:self];
	 }];
}

-(void)setPassword:(NSString *)password
{
	_password = password;
	
    ABCPasswordRuleResult *result = [ABCContext checkPasswordRules:self.password];
    
//    if (result)
		
	NSMutableString *crackString = [[NSMutableString alloc] initWithString:timeToCrackText];
    
	if(result.secondsToCrack < 60.0)
	{
		[crackString appendFormat:@"%.2lf seconds", result.secondsToCrack];
	}
	else if(result.secondsToCrack < 3600)
	{
		[crackString appendFormat:@"%.2lf minutes", result.secondsToCrack / 60.0];
	}
	else if(result.secondsToCrack < 86400)
	{
		[crackString appendFormat:@"%.2lf hours", result.secondsToCrack / 3600.0];
	}
	else if(result.secondsToCrack < 604800)
	{
		[crackString appendFormat:@"%.2lf days", result.secondsToCrack / 86400.0];
	}
	else if(result.secondsToCrack < 604800)
	{
		[crackString appendFormat:@"%.2lf days", result.secondsToCrack / 86400.0];
	}
	else if(result.secondsToCrack < 2419200)
	{
		[crackString appendFormat:@"%.2lf weeks", result.secondsToCrack / 604800.0];
	}
	else if(result.secondsToCrack < 29030400)
	{
		[crackString appendFormat:@"%.2lf months", result.secondsToCrack / 2419200.0];
	}
	else
	{
		[crackString appendFormat:@"%.2lf years", result.secondsToCrack / 29030400.0];
	}
	self.crackMessageLabel.text = crackString;
    
    UILabel* label;
    UIImageView *imageView;
    
    int i = 0;
    
    label = (UILabel *)[self viewWithTag:i + 20];
    imageView = (UIImageView *)[self viewWithTag:i + 10];
    if(label) label.text = mustHaveUpperCase;
    if(imageView) {
        if (result.noUpperCase)
            imageView.image = [UIImage imageNamed:@"White-Dot"];
        else
            imageView.image = [UIImage imageNamed:@"Green-check"];
    }
    
    i++;
    label = (UILabel *)[self viewWithTag:i + 20];
    imageView = (UIImageView *)[self viewWithTag:i + 10];
    if(label) label.text = mustHaveLowerCase;
    if(imageView) {
        if (result.noLowerCase)
            imageView.image = [UIImage imageNamed:@"White-Dot"];
        else
            imageView.image = [UIImage imageNamed:@"Green-check"];
    }

    i++;
    label = (UILabel *)[self viewWithTag:i + 20];
    imageView = (UIImageView *)[self viewWithTag:i + 10];
    if(label) label.text = mustHaveNumber;
    if(imageView) {
        if (result.noNumber)
            imageView.image = [UIImage imageNamed:@"White-Dot"];
        else
            imageView.image = [UIImage imageNamed:@"Green-check"];
    }
    
    i++;
    label = (UILabel *)[self viewWithTag:i + 20];
    imageView = (UIImageView *)[self viewWithTag:i + 10];
    if(label) label.text = [NSString stringWithFormat:mustHaveMoreCharacters, [ABCContext getMinimumPasswordLength]];
    if(imageView) {
        if (result.tooShort)
            imageView.image = [UIImage imageNamed:@"White-Dot"];
        else
            imageView.image = [UIImage imageNamed:@"Green-check"];
    }
}

@end

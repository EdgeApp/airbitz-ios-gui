//
//  WalletMakerView.m
//  AirBitz
//
//  Created by Carson Whitsett on 4/4/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "WalletMakerView.h"
#import "ABC.h"

@interface WalletMakerView () <ButtonSelectorDelegate>
{
	CGRect originalFrame;
}

@property (nonatomic, weak) IBOutlet ButtonSelectorView     *buttonSelectorView;
@property (nonatomic, weak) IBOutlet UITextField            *textField;
@property (weak, nonatomic) IBOutlet UILabel                *labelOnline;
@property (weak, nonatomic) IBOutlet UILabel                *labelOffline;
@property (weak, nonatomic) IBOutlet UISwitch               *switchOnlineOffline;


@end

@implementation WalletMakerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        // Initialization code
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
	{
		UIView *view = [[[NSBundle mainBundle] loadNibNamed:@"WalletMakerView~iphone" owner:self options:nil] objectAtIndex:0];
		view.frame = self.bounds;
        [self addSubview:view];
		
		self.buttonSelectorView.delegate = self;
		
		originalFrame = self.frame;
		
		tABC_Currency *currencyArray;
		tABC_Error error;
		int numCurrencies;
		tABC_CC result = ABC_GetCurrencies(&currencyArray, &numCurrencies, &error);
		if(result == ABC_CC_Ok)
		{
			/*
			 typedef struct sABC_Currency
			 {
			 char    *szCode;		// currency ISO 4217 code
			 int     num;			// currency ISO 4217 num
			 char    *szDescription; // currency description
			 char    *szCountries;	// currency countries
			 } tABC_Currency;
			 */
			
			NSMutableArray *arrayCurrencyStrings = [[NSMutableArray alloc] init];
			for(int i=0; i<numCurrencies; i++)
			{
				//populate with currency code and description
				[arrayCurrencyStrings addObject:[NSString stringWithFormat:@"%s - %@", currencyArray[i].szCode, [NSString stringWithUTF8String:currencyArray[i].szDescription]]];
			}
			
			self.buttonSelectorView.arrayItemsToSelect = arrayCurrencyStrings;

		}

        [self reset];
    }
    return self;
}

#pragma mark - Action Methods

- (IBAction)switchValueChanged:(id)sender
{
    [self updateDisplay];
}

- (IBAction)buttonCancelTouched:(id)sender
{

    [self exit];
}

- (IBAction)buttonDoneTouched:(id)sender
{

}

#pragma mark - Public Methods

- (void)reset
{
    [self.textField resignFirstResponder];
    self.textField.text = @"";
    [self.switchOnlineOffline setOn:NO];
    [self.buttonSelectorView close];
    self.buttonSelectorView.textLabel.text = NSLocalizedString(@"Currency:", @"name of button on wallets view");
	[self.buttonSelectorView.button setTitle:@"USD" forState:UIControlStateNormal];
    [self updateDisplay];
}

#pragma mark - Misc Methods

- (void)updateDisplay
{
    if ([self.switchOnlineOffline isOn])
    {
        self.labelOnline.textColor = [UIColor darkGrayColor];
        self.labelOffline.textColor = [UIColor whiteColor];
    }
    else
    {
        self.labelOffline.textColor = [UIColor darkGrayColor];
        self.labelOnline.textColor = [UIColor whiteColor];
    }
}

- (void)exit
{
    [self.textField resignFirstResponder];
    [self.buttonSelectorView close];
    
    if (self.delegate)
    {
        if ([self.delegate respondsToSelector:@selector(walletMakerViewExit:)])
        {
            [self.delegate walletMakerViewExit:self];
        }
    }
}

#pragma mark - ButtonSelector Delegates

-(void)ButtonSelector:(ButtonSelectorView *)view selectedItem:(int)itemIndex
{
}

-(NSString *)ButtonSelector:(ButtonSelectorView *)view willSetButtonTextToString:(NSString *)desiredString
{
	NSString *result = [[desiredString componentsSeparatedByString:@" - "] firstObject];
	return result;
}

@end

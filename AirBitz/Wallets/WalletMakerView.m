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

-(id)initWithCoder:(NSCoder *)aDecoder
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
		
    }
    return self;
}

#pragma mark ButtonSelector delegates

-(void)ButtonSelector:(ButtonSelectorView *)view selectedItem:(int)itemIndex
{
}

-(NSString *)ButtonSelector:(ButtonSelectorView *)view willSetButtonTextToString:(NSString *)desiredString
{
	NSString *result = [[desiredString componentsSeparatedByString:@" - "] firstObject];
	return result;
}

@end

//
//  WalletMakerView.m
//  AirBitz
//
//  Created by Carson Whitsett on 4/4/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "WalletMakerView.h"
#import "ABC.h"
#import "User.h"
#import "CommonTypes.h"
#import "OfflineWalletViewController.h"
#import "Util.h"
#import "CoreBridge.h"
#import "ButtonSelectorView2.h"
#import "PopupPickerView.h"
#import "MainViewController.h"
#import "Theme.h"

@interface WalletMakerView () <PopupPickerViewDelegate, UITextFieldDelegate>
{
    BOOL                        _bCurrencyPopup;
    BOOL                        _bCreatingWallet;
	CGRect                      _originalFrame;
    int                         _currencyChoice;
    NSMutableArray              *arrayCurrencyCodes;
    NSMutableArray              *arrayCurrencyNums;
    NSMutableArray              *arrayCurrencyStrings;


}

@property (weak, nonatomic) IBOutlet UIImageView            *imageEditBox;
@property (weak, nonatomic) IBOutlet UILabel                *labelOnline;
@property (weak, nonatomic) IBOutlet UILabel                *labelOffline;
@property (weak, nonatomic) IBOutlet UISwitch               *switchOnlineOffline;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, copy)     NSString                    *strReason;
@property (nonatomic, assign)   BOOL                        bSuccess;
@property (weak, nonatomic) IBOutlet PopupPickerView *popupPickerCurrency;
@property (weak, nonatomic) IBOutlet UIButton *buttonCurrency;


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

- (void)drawRect:(CGRect)rect
{
	{
		UIView *view = [[[NSBundle mainBundle] loadNibNamed:@"WalletMakerView~iphone" owner:self options:nil] objectAtIndex:0];
		view.frame = self.bounds;
        [self addSubview:view];

        self.textField.delegate = self;

        _bCreatingWallet = NO;
		
		_originalFrame = self.frame;
		
		tABC_Currency *currencyArray;
		tABC_Error error;
		int numCurrencies;
		tABC_CC result = ABC_GetCurrencies(&currencyArray, &numCurrencies, &error);
		if(result == ABC_CC_Ok)
		{
            arrayCurrencyCodes = [[NSMutableArray alloc] init];
            arrayCurrencyNums = [[NSMutableArray alloc] init];
			arrayCurrencyStrings = [[NSMutableArray alloc] init];
			for(int i = 0; i < numCurrencies; i++)
			{
				//populate with currency code and description
				[arrayCurrencyStrings addObject:[NSString stringWithFormat:@"%s - %@",
                                                currencyArray[i].szCode,
                                                [NSString stringWithUTF8String:currencyArray[i].szDescription]]];

                [arrayCurrencyNums addObject:[NSNumber numberWithInt:currencyArray[i].num]];
                [arrayCurrencyCodes addObject:[NSString stringWithUTF8String:currencyArray[i].szCode]];
			}

		}

        [self reset];
    }
    return;
}

#pragma mark - Action Methods

- (IBAction)buttonCurrencyTapped:(id)sender
{
    [self.textField resignFirstResponder];

    if (!_bCurrencyPopup)
    {

        self.popupPickerCurrency = [PopupPickerView CreateForView:self
                                                   relativeToView:self.buttonCurrency
                                                 relativePosition:PopupPickerPosition_Below
                                                      withStrings:arrayCurrencyStrings
                                                   fromCategories:nil
                                                      selectedRow:-1
                                                        withWidth:[MainViewController getWidth]
                                                    withAccessory:nil
                                                    andCellHeight:[Theme Singleton].heightPopupPicker
                                            roundedEdgesAndShadow:NO
        ];
        _bCurrencyPopup = YES;
    }
    else
    {
        [self.popupPickerCurrency removeFromSuperview];
        [self.textField becomeFirstResponder];
        _bCurrencyPopup = NO;
    }

}


- (IBAction)buttonCancelTouched:(id)sender
{

    [self exit];
}

- (IBAction)buttonDoneTouched:(id)sender
{
    [self createWallet];
}

#pragma mark - Public Methods

- (void)reset
{
    int currencyNum;
    NSString *currencyString;
//    CGRect frame = self.viewBlocker.frame;
//    self.viewBlocker.hidden = YES;
    self.activityIndicator.hidden = YES;
    [self.textField resignFirstResponder];
    self.textField.text = @"";
    [self.switchOnlineOffline setOn:NO];
    [self.popupPickerCurrency removeFromSuperview];
    _bCurrencyPopup = NO;
//    [self.buttonSelectorView close];
//    self.buttonSelectorView.textLabel.text = NSLocalizedString(@"Currency:", @"name of button on wallets view");
    
    // Default currency for new wallets should be the currency set in the account settings
    currencyNum = [[User Singleton] defaultCurrencyNum];
    currencyString = [CoreBridge currencyAbbrevLookup:currencyNum];
//	[self.buttonSelectorView.button setTitle:currencyString forState:UIControlStateNormal];
//    ABLog(2,self.buttonSelectorView.button.currentTitle);

    _currencyChoice = (int) [arrayCurrencyCodes indexOfObject:currencyString];
    [self.buttonCurrency setTitle:currencyString forState:UIControlStateNormal];
    [self.buttonCurrency.titleLabel setTextColor:[Theme Singleton].colorTextLink];
//    [self.buttonCurrency.layer setBorderColor:[[Theme Singleton].colorTextLink CGColor]];
//    [self.buttonCurrency.layer setBorderWidth:2.0];
//    [self.buttonCurrency.layer setCornerRadius:8.0];
    [self updateDisplay];
}

#pragma mark - Misc Methods

- (void)updateDisplay
{
//    self.buttonSelectorView.hidden = NO;
    self.textField.hidden = NO;
    self.imageEditBox.hidden = NO;
}

//- (BOOL)onlineSelected
//{
//    return ![self.switchOnlineOffline isOn];
//}
//
- (void)createWallet
{
    if (self.textField.text)
    {
        if ([self.textField.text length])
        {
            [self createOnlineWallet];
            [self exit];
        }
    }
}

- (void)createOnlineWallet
{
    [self blockUser:YES];
    _bCreatingWallet = YES;
    [CoreBridge clearSyncQueue];
    [CoreBridge postToSyncQueue:^{
        tABC_Error error;
        char *szUUID = NULL;
        ABC_CreateWallet([[User Singleton].name UTF8String],
                                [[User Singleton].password UTF8String],
                                [self.textField.text UTF8String],
                                [[arrayCurrencyNums objectAtIndex:_currencyChoice] intValue],
                                &szUUID,
                                &error);
        _bSuccess = error.code == ABC_CC_Ok ? YES: NO;
        _strReason = [Util errorMap:&error];
        if (szUUID) {
            free(szUUID);
        }
        [self performSelectorOnMainThread:@selector(createWalletComplete) withObject:nil waitUntilDone:FALSE];
    }];
}

- (void)createWalletComplete
{
    [self blockUser:NO];
    _bCreatingWallet = NO;
    [CoreBridge startWatchers];
    [CoreBridge refreshWallets];

    //ABLog(2,@"Wallet create complete");
    if (_bSuccess)
    {
        [self exit];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:NSLocalizedString(@"Create Wallet", nil)
							  message:[NSString stringWithFormat:@"Wallet creation failed:\n%@", _strReason]
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];
    }
}

- (void)blockUser:(BOOL)bBlock
{
//    self.viewBlocker.hidden = !bBlock;
    self.activityIndicator.hidden = NO;
    [self.textField resignFirstResponder];
}

- (void)exit
{
    if (!_bCreatingWallet)
    {
        [self.textField resignFirstResponder];
//        [self.buttonSelectorView close];

        if (self.delegate)
        {
            if ([self.delegate respondsToSelector:@selector(walletMakerViewExit:)])
            {
                [self.delegate walletMakerViewExit:self];
            }
        }
    }
}

- (IBAction)PopupPickerViewSelected:(PopupPickerView *)view onRow:(NSInteger)row userData:(id)data
{
    _currencyChoice = (int) row;
    NSNumber *currencyNum = [arrayCurrencyNums objectAtIndex:_currencyChoice];
    NSString *currencyString = [CoreBridge currencyAbbrevLookup:[currencyNum intValue]];

    [self.buttonCurrency setTitle:currencyString forState:UIControlStateNormal];
    [self.popupPickerCurrency removeFromSuperview];
    _bCurrencyPopup = NO;
    [self.textField becomeFirstResponder];
}

#pragma mark - ButtonSelector Delegates
//
//-(void)ButtonSelector:(ButtonSelectorView *)view selectedItem:(int)itemIndex
//{
//    _currencyChoice = itemIndex;
//}
//
//-(NSString *)ButtonSelector:(ButtonSelectorView *)view willSetButtonTextToString:(NSString *)desiredString
//{
//	NSString *result = [[desiredString componentsSeparatedByString:@" - "] firstObject];
//	return result;
//}
//
//- (void)ButtonSelectorWillShowTable:(ButtonSelectorView *)view
//{
//    [self.textField resignFirstResponder];
//}
//
#pragma mark - UITextField delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.popupPickerCurrency removeFromSuperview];
    _bCurrencyPopup = NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (!_bCreatingWallet)
    {
        [textField resignFirstResponder];

        [self createWallet];
    }

	return YES;
}

@end

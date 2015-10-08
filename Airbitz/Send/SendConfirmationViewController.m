//
//  SendConfirmationViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/27/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "SendConfirmationViewController.h"
#import "ABC.h"
#import "InfoView.h"
#import "ConfirmationSliderView.h"
#import "User.h"
#import "CalculatorView.h"
#import "SendStatusViewController.h"
#import "TransactionDetailsViewController.h"
#import "CoreBridge.h"
#import "Util.h"
#import "AudioController.h"
#import "MainViewController.h"
#import "Theme.h"
#import "ButtonSelectorView2.h"
#import "FadingAlertView.h"
#import "PopupPickerView2.h"

@interface SendConfirmationViewController () <UITextFieldDelegate, ConfirmationSliderViewDelegate, CalculatorViewDelegate,
                                              TransactionDetailsViewControllerDelegate,
                                              ButtonSelector2Delegate, InfoViewDelegate>
{
    ConfirmationSliderView              *_confirmationSlider;
    UITextField                         *_selectedTextField;
    int64_t                             _maxAmount;
    BOOL                                _bAddressIsWalletUUID;
    NSString                            *_sendTo;
    NSString                            *_destUUID;
    BOOL                                _maxLocked;
    int64_t                             _totalSentToday;
    BOOL                                _pinRequired;
    BOOL                                _passwordRequired;
    NSString                            *_strReason;
    int                                 _callbackTimestamp;
    UIAlertView                         *_alert;
    NSTimer                             *_pinTimer;
    BOOL                                bWalletListDropped;
    BOOL                                _currencyNumOverride;
    int                                 _currencyNum;

}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keypadViewBottom;
@property (weak, nonatomic) IBOutlet UIView                 *viewDisplayArea;

@property (weak, nonatomic) IBOutlet UIImageView            *imageTopEmboss;
@property (weak, nonatomic) IBOutlet UILabel                *labelSendFromTitle;
@property (weak, nonatomic) IBOutlet ButtonSelectorView2    *walletSelector;
@property (weak, nonatomic) IBOutlet UILabel                *labelSendToTitle;
@property (nonatomic, weak) IBOutlet UILabel                *addressLabel;
@property (weak, nonatomic) IBOutlet UIView                 *viewBTC;
@property (nonatomic, weak) IBOutlet UILabel                *amountBTCSymbol;
@property (nonatomic, weak) IBOutlet UILabel                *amountBTCLabel;
@property (nonatomic, weak) IBOutlet UITextField            *amountBTCTextField;
@property (weak, nonatomic) IBOutlet UIView                 *viewFiat;
@property (nonatomic, weak) IBOutlet UILabel                *amountFiatSymbol;
@property (nonatomic, weak) IBOutlet UILabel                *amountFiatLabel;
@property (nonatomic, weak) IBOutlet UITextField            *amountFiatTextField;
@property (nonatomic, weak) IBOutlet UIButton               *maxAmountButton;
@property (nonatomic, weak) IBOutlet UIButton               *helpButton;
@property (nonatomic, weak) IBOutlet UILabel                *conversionLabel;
@property (weak, nonatomic) IBOutlet UILabel                *labelPINTitle;
@property (weak, nonatomic) IBOutlet UIImageView            *imagePINEmboss;
@property (nonatomic, weak) IBOutlet UITextField            *withdrawlPIN;
@property (nonatomic, weak) IBOutlet UIView                 *confirmSliderContainer;
@property (nonatomic, weak) IBOutlet CalculatorView         *keypadView;
@property (nonatomic, strong) PopupPickerView2              *popupPicker;


@property (nonatomic, strong) SendStatusViewController          *sendStatusController;
@property (nonatomic, strong) TransactionDetailsViewController  *transactionDetailsController;
@property (nonatomic, strong) InfoView                          *infoView;

@end

@implementation SendConfirmationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _bAdvanceToTx = YES;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _bAdvanceToTx = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    // Added gesture recognizer to control keyboard
//    [self setupGestureRecognizer];

    // resize ourselves to fit in area
    [Util resizeView:self.view withDisplayView:self.viewDisplayArea];

    self.withdrawlPIN.delegate = self;
    self.amountBTCTextField.delegate = self;
    self.amountFiatTextField.delegate = self;
    self.keypadView.delegate = self;
    self.walletSelector.delegate = self;
    [self.walletSelector disableButton];

#ifdef __IPHONE_8_0
    [self.keypadView removeFromSuperview];
#endif
    self.amountBTCTextField.inputView = self.keypadView;
    self.amountFiatTextField.inputView = self.keypadView;

    // make sure the edit fields are in front of the blocker
    [self.viewDisplayArea bringSubviewToFront:self.amountBTCTextField];
    [self.viewDisplayArea bringSubviewToFront:self.amountFiatTextField];
    [self.viewDisplayArea bringSubviewToFront:self.withdrawlPIN];

    _sendTo = [NSString safeStringWithUTF8String:_spendTarget.pSpend->szName];
    if (_spendTarget.pSpend->bSigned)
    {
        self.addressLabel.textColor = [Theme Singleton].colorButtonGreen;
    }
    _bAddressIsWalletUUID = NO;
    if ([[NSString safeStringWithUTF8String:_spendTarget.pSpend->szDestUUID] length]) {
        _bAddressIsWalletUUID = YES;
        NSAssert((_spendTarget.destWallet != nil), @"Empty destWallet");
        _destUUID = [NSString safeStringWithUTF8String:_spendTarget.pSpend->szDestUUID];
        NSMutableArray *newArr = [[NSMutableArray alloc] init];
        for (Wallet *w in [CoreBridge Singleton].arrayWallets) {
            if (![w.strName isEqualToString:_sendTo]) {
                [newArr addObject:w];
            } else {
                _bAddressIsWalletUUID = YES;
            }
        }
    }

    CGRect frame = self.keypadView.frame;
    frame.origin.y = self.view.frame.size.height;
    self.keypadView.frame = frame;
    
    _confirmationSlider = [ConfirmationSliderView CreateInsideView:self.confirmSliderContainer withDelegate:self];
    _maxLocked = NO;

    // Should this be threaded?
    _totalSentToday = [CoreBridge getTotalSentToday:[CoreBridge Singleton].currentWallet];

    [self checkAuthorization];
    [_confirmationSlider resetIn:0.1];

    // add left to right swipe detection for going back
//    [self installLeftToRightSwipeDetection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabBarButtonReselect:) name:NOTIFICATION_TAB_BAR_BUTTON_RESELECT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(myTextDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:self.withdrawlPIN];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(exchangeRateUpdate:)
                                                 name:NOTIFICATION_EXCHANGE_RATE_CHANGE
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateViews:) name:NOTIFICATION_WALLETS_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(transactionDetailsExit) name:NOTIFICATION_TRANSACTION_DETAILS_EXITED object:nil];
}

- (void)viewWillAppear
{
    [_confirmationSlider resetIn:0.1];
}

- (void)transactionDetailsExit
{
    // An async tx details happened and exited. Drop everything and kill ourselves or we'll
    // corrupt the background. This is needed on every subview of a primary screen
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
}

- (void)updateViews:(NSNotification *)notification
{
    if ([CoreBridge Singleton].arrayWallets && [CoreBridge Singleton].currentWallet)
    {
        self.walletSelector.arrayItemsToSelect = [CoreBridge Singleton].arrayWalletNames;
        [self.walletSelector.button setTitle:[CoreBridge Singleton].currentWallet.strName forState:UIControlStateNormal];
        self.walletSelector.selectedItemIndex = [CoreBridge Singleton].currentWalletID;

        if (_currencyNumOverride)
            self.keypadView.currencyNum = _currencyNum;
        else
            self.keypadView.currencyNum = [CoreBridge Singleton].currentWallet.currencyNum;

        NSString *walletName = [NSString stringWithFormat:@"From: %@ ▼", [CoreBridge Singleton].currentWallet.strName];
        [MainViewController changeNavBarTitleWithButton:self title:walletName action:@selector(didTapTitle:) fromObject:self];
        if (!([[CoreBridge Singleton].arrayWallets containsObject:[CoreBridge Singleton].currentWallet]))
        {
            [FadingAlertView create:self.view
                            message:[Theme Singleton].walletHasBeenArchivedText
                           holdTime:FADING_ALERT_HOLD_TIME_FOREVER];
        }

        [self updateTextFieldContents];

    }
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [_pinTimer invalidate];
    _pinTimer = nil;
    [self dismissErrorMessage];
    [super viewWillDisappear:animated];
//    [self dismissGestureRecognizer];
    [self.infoView dismiss];
    [self dismissKeyboard];
}

//- (void)setupGestureRecognizer
//{
//    tap = [[UITapGestureRecognizer alloc]
//        initWithTarget:self
//                action:@selector(dismissKeyboard)];
//}
//
//- (void)dismissGestureRecognizer
//{
//    [self.view removeGestureRecognizer:tap];
//}
//
- (void)myTextDidChange:(NSNotification *)notification
{
    if(_pinRequired && notification.object == self.withdrawlPIN)
    {
        if(self.withdrawlPIN.text.length == 4)
        {
            [self.withdrawlPIN resignFirstResponder];
        }
    }
    else
    {
        ABLog(2,@"Text changed for some field");
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    [self.view addGestureRecognizer:tap];
    self.amountBTCTextField.text = [CoreBridge formatSatoshi:_spendTarget.pSpend->amount withSymbol:false];
    self.maxAmountButton.hidden = ![_spendTarget isMutable];

    NSString *prefix;
    NSString *suffix;
    
    if (!_bAddressIsWalletUUID && [_sendTo length] > 10)
    {
        prefix = [_sendTo substringToIndex:5];
        suffix = [_sendTo substringFromIndex: [_sendTo length] - 5];
        self.addressLabel.text = [NSString stringWithFormat:@"%@...%@", prefix, suffix];
    }
    else
    {
        self.addressLabel.text = _sendTo;
    }

    _currencyNumOverride = NO;
    _currencyNum = [CoreBridge Singleton].currentWallet.currencyNum;
    self.amountFiatLabel.textColor = [Theme Singleton].colorTextLinkOnDark;
    
    tABC_CC result;
    double currency;
    tABC_Error error;
    
    result = ABC_SatoshiToCurrency([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                                   _spendTarget.pSpend->amount, &currency, _currencyNum, &error);
                
    if(result == ABC_CC_Ok)
    {
        self.amountFiatTextField.text = [NSString stringWithFormat:@"%.2f", currency];
    }
    [self startCalcFees];
    [self pickBestResponder];
    [self exchangeRateUpdate:nil];

    _pinTimer = [NSTimer scheduledTimerWithTimeInterval:PIN_REQUIRED_PERIOD_SECONDS
        target:self
        selector:@selector(updateTextFieldContents)
        userInfo:nil
        repeats:NO];

    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBar:self title:[Theme Singleton].backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(Back:) fromObject:self];
    [MainViewController changeNavBar:self title:[Theme Singleton].helpButtonText side:NAV_BAR_RIGHT button:true enable:true action:@selector(info:) fromObject:self];

    [self updateViews:nil];
}

- (void)pickBestResponder
{
    if (_spendTarget.pSpend->amount) {
        // If the PIN is empty, then focus
        if ([self.withdrawlPIN.text length] <= 0) {
            if (_pinRequired || _passwordRequired) {
                [self.withdrawlPIN becomeFirstResponder];
            }
        }
    } else {
        self.amountFiatTextField.text = nil;
        self.amountBTCTextField.text = nil;
        [self.amountFiatTextField becomeFirstResponder];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Notification Handlers

- (void)exchangeRateUpdate: (NSNotification *)notification
{
    [self updateTextFieldContents];
}

#pragma mark - Actions Methods

- (IBAction)info:(id) sender
{
    [self dismissErrorMessage];
    [self.view endEditing:YES];
    [self dismissKeyboard];
    [self setInfoView:[InfoView CreateWithHTML:@"infoSendConfirmation" forView:self.view]];
    [self.infoView setDelegate:self];
}

- (IBAction)fundsInfo
{
    [self dismissErrorMessage];
    [self.view endEditing:YES];
    [self dismissKeyboard];
    [self setInfoView:[InfoView CreateWithHTML:@"infoInsufficientFunds" forView:self.view]];
    [self.infoView setDelegate:self];
}

- (IBAction)Back:(id)sender
{
    [self dismissErrorMessage];

    [self.withdrawlPIN resignFirstResponder];
    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         CGRect frame = self.view.frame;
         frame.origin.x = frame.size.width;
         self.view.frame = frame;
     }
     completion:^(BOOL finished)
     {
            if ([self.delegate respondsToSelector:@selector(sendConfirmationViewControllerDidFinish:withBack:withError:withTxId:)]) {
                [self.delegate sendConfirmationViewControllerDidFinish:self withBack:YES withError:NO withTxId:nil];
            } else {
                [self.delegate sendConfirmationViewControllerDidFinish:self];
            }
            [self dismissKeyboard];
     }];
}

- (IBAction)ChangeFiatButton:(id)sender
{
    tPopupPicker2Position popupPosition = PopupPicker2Position_Full_Fading;
    NSString *headerText;

    NSInteger curChoice = -1;
    NSArray *arrayPopupChoices = nil;

    arrayPopupChoices = [CoreBridge Singleton].arrayCurrencyStrings;
    popupPosition = PopupPicker2Position_Full_Fading;
    headerText = NSLocalizedString(@"Select Currency", nil);

    self.popupPicker = [PopupPickerView2 CreateForView:self.viewDisplayArea
                                      relativePosition:popupPosition
                                           withStrings:arrayPopupChoices
                                         withAccessory:nil
                                            headerText:headerText
    ];
    self.popupPicker.userData = nil;
    //prevent popup from extending behind tool bar
    self.popupPicker.delegate = self;

}

- (IBAction)selectMaxAmount
{
    [self dismissErrorMessage];
    if ([CoreBridge Singleton].currentWallet != nil && _maxLocked == NO)
    {
        _maxLocked = YES;
        _selectedTextField = self.amountBTCTextField;

        // We use a serial queue for this calculation
        [CoreBridge postToMiscQueue:^{
            int64_t maxAmount = [_spendTarget maxSpendable:[CoreBridge Singleton].currentWallet.strUUID];
            dispatch_async(dispatch_get_main_queue(), ^{
                _maxLocked = NO;
                _maxAmount = maxAmount;
                _spendTarget.pSpend->amount = maxAmount;
                self.amountBTCTextField.text = [CoreBridge formatSatoshi:_spendTarget.pSpend->amount withSymbol:false];

                [self updateTextFieldContents];
                if (_pinRequired || _passwordRequired) {
                    [self.withdrawlPIN becomeFirstResponder];
                } else {
                    [self dismissKeyboard];
                }
            });
        }];
    }
}

#pragma mark - Popup Picker Delegate Methods

- (void)PopupPickerView2Selected:(PopupPickerView2 *)view onRow:(NSInteger)row userData:(id)data
{
    _currencyNum = [[[CoreBridge Singleton].arrayCurrencyNums objectAtIndex:row] intValue];
    _currencyNumOverride = YES;

    [self dismissPopupPicker];

    [self updateViews:nil];
}

- (void)PopupPickerView2Cancelled:(PopupPickerView2 *)view userData:(id)data
{
    // dismiss the picker
    [self dismissPopupPicker];
}

- (void)dismissPopupPicker
{
    if (self.popupPicker)
    {
        [self.popupPicker removeFromSuperview];
        self.popupPicker = nil;
    }
}

#pragma mark - Misc Methods

- (void)dismissKeyboard
{
    [self.withdrawlPIN resignFirstResponder];
    [self.amountFiatTextField resignFirstResponder];
    [self.amountBTCTextField resignFirstResponder];
}


- (void)showSendStatus:(NSArray *)params
{
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
    self.sendStatusController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SendStatusViewController"];


    [Util addSubviewControllerWithConstraints:self child:self.sendStatusController];

    self.sendStatusController.messageLabel.text = NSLocalizedString(@"Sending...", @"status message");

    [Util animateControllerFadeIn:self.sendStatusController];
}

- (void)hideSendStatus
{
    [Util animateControllerFadeOut:self.sendStatusController];
}

- (void)initiateSendRequest
{
    if ([CoreBridge Singleton].currentWallet)
    {
        [self performSelectorOnMainThread:@selector(showSendStatus:) withObject:nil waitUntilDone:FALSE];
        _callbackTimestamp = [[NSDate date] timeIntervalSince1970];

        _spendTarget.srcWallet = [CoreBridge Singleton].currentWallet;
        [CoreBridge postToMiscQueue:^{
            tABC_Error error;
            NSString *txId = [_spendTarget approve:_overrideCurrency
                                             error:&error];
            if (error.code == ABC_CC_Ok) {
                [self txSendSuccess:_spendTarget.srcWallet withTx:txId];
            } else {
                [self txSendFailed:error];
            }
        }];
    }
}

- (void)didTapTitle: (UIButton *)sender
{
    if (bWalletListDropped)
    {
        [self.walletSelector close];
        bWalletListDropped = false;
    }
    else
    {
        [self.walletSelector open];
        bWalletListDropped = true;
    }

}



- (void)launchTransactionDetailsWithTransaction:(Wallet *)wallet withTx:(Transaction *)transaction
{
//    [self.view removeGestureRecognizer:tap];

    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
    self.transactionDetailsController = [mainStoryboard instantiateViewControllerWithIdentifier:@"TransactionDetailsViewController"];
    
    self.transactionDetailsController.delegate = self;
    self.transactionDetailsController.transaction = transaction;
    self.transactionDetailsController.wallet = [CoreBridge Singleton].currentWallet;
    if (_spendTarget.pSpend->szRet) {
        self.transactionDetailsController.returnUrl = [NSString safeStringWithUTF8String:_spendTarget.pSpend->szRet];
    }
    self.transactionDetailsController.bOldTransaction = NO;
    self.transactionDetailsController.transactionDetailsMode = TD_MODE_SENT;
    CGRect frame = self.view.bounds;
    frame.origin.x = frame.size.width;
    self.transactionDetailsController.view.frame = frame;
    
    [self.view addSubview:self.transactionDetailsController.view];
    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         self.transactionDetailsController.view.frame = self.view.bounds;
     }
                     completion:^(BOOL finished)
     {
     }];
    
}

- (void)failedToSend:(NSArray *)params
{
    if (_alert != nil) {
        [_alert dismissWithClickedButtonIndex:1 animated:NO];
        _alert = nil;
    }
    NSString *title = params[0];
    NSString *message = params[1];
    _alert = [[UIAlertView alloc]
                            initWithTitle:title
                            message:message
                            delegate:nil
                            cancelButtonTitle:@"OK"
                            otherButtonTitles:nil];
    [_alert show];
    [self hideSendStatus];
}

- (void)showTransactionDetails:(NSArray *)params
{
    if ([params count] < 2) {
        ABLog(2,@"Not enought args\n");
        return;
    }
    Wallet *wallet = params[0];
    NSString *txId = params[1];
    Transaction *transaction = [CoreBridge getTransaction:wallet.strUUID withTx:txId];
    [self launchTransactionDetailsWithTransaction:wallet withTx:transaction];
}

- (void)updateTextFieldContents
{
    double currency;
    int64_t satoshi;
    tABC_Error error;

    if (_selectedTextField == self.amountBTCTextField)
    {
        _spendTarget.pSpend->amount = [CoreBridge denominationToSatoshi: self.amountBTCTextField.text];
        if (ABC_SatoshiToCurrency([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                                  _spendTarget.pSpend->amount, &currency, _currencyNum, &error) == ABC_CC_Ok)
        {
            self.amountFiatTextField.text = [NSString stringWithFormat:@"%.2f", currency];
        }
    }
    else if (_selectedTextField == self.amountFiatTextField)
    {
        currency = [self.amountFiatTextField.text doubleValue];
        if (ABC_CurrencyToSatoshi([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                                  currency, _currencyNum, &satoshi, &error) == ABC_CC_Ok)
        {
            _spendTarget.pSpend->amount = satoshi;
            self.amountBTCTextField.text = [CoreBridge formatSatoshi:satoshi
                                                          withSymbol:false
                                                    cropDecimals:[CoreBridge currencyDecimalPlaces]];
        }
    }
    self.amountBTCSymbol.text = [User Singleton].denominationLabelShort;
    self.amountBTCLabel.text = [User Singleton].denominationLabel;
    self.amountFiatSymbol.text = [CoreBridge currencySymbolLookup:_currencyNum];
    self.amountFiatLabel.text = [CoreBridge currencyAbbrevLookup:_currencyNum];
    self.conversionLabel.text = [CoreBridge conversionStringFromNum:_currencyNum withAbbrev:YES];

    [self checkAuthorization];
    [self startCalcFees];
}

- (void)checkAuthorization
{
    _passwordRequired = NO;
    _pinRequired = NO;
    if (!_bAddressIsWalletUUID && [User Singleton].bDailySpendLimit
                && _spendTarget.pSpend->amount + _totalSentToday >= [User Singleton].dailySpendLimitSatoshis) {
        // Show password
        _passwordRequired = YES;
        _labelPINTitle.hidden = NO;
        _labelPINTitle.text = NSLocalizedString(@"Password", nil);
        _withdrawlPIN.hidden = NO;
        _withdrawlPIN.keyboardType = UIKeyboardTypeDefault;
        _imagePINEmboss.hidden = NO;
    } else if (!_bAddressIsWalletUUID
                && [User Singleton].bSpendRequirePin
                && _spendTarget.pSpend->amount >= [User Singleton].spendRequirePinSatoshis
                && ![CoreBridge recentlyLoggedIn]) {
        // Show PIN pad
        _pinRequired = YES;
        _labelPINTitle.hidden = NO;
        _labelPINTitle.text = NSLocalizedString(@"4 Digit PIN", nil);
        _withdrawlPIN.hidden = NO;
        _withdrawlPIN.keyboardType = UIKeyboardTypeNumberPad;
        _imagePINEmboss.hidden = NO;
    } else {
        _labelPINTitle.hidden = YES;
        _withdrawlPIN.hidden = YES;
        _imagePINEmboss.hidden = YES;
    }
}

- (void)startCalcFees
{
    // Don't caculate fees until there is a value
    if (_spendTarget.pSpend->amount == 0)
    {
        self.conversionLabel.text = [CoreBridge conversionStringFromNum:_currencyNum withAbbrev:YES];
        self.conversionLabel.textColor = [UIColor darkGrayColor];
        self.amountBTCTextField.textColor = [UIColor whiteColor];
        self.amountFiatTextField.textColor = [UIColor whiteColor];

        // hide the help button next to insufficient funds if we don't call calcFees
        self.helpButton.hidden = YES;
        return;
    }
    [CoreBridge postToMiscQueue:^{
        [self calcFees];
    }];
}

- (void)calcFees
{
    uint64_t fees = 0;
    tABC_Error errorCode = [_spendTarget calcSendFees:[CoreBridge Singleton].currentWallet.strUUID totalFees:&fees];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateFeeFieldContents:fees error:&errorCode];
    });
}

- (void)updateFeeFieldContents:(uint64_t)txFees error:(tABC_Error *)calcError
{
    UIColor *color, *colorConversionLabel;
    _maxAmountButton.selected = NO;
    if (_maxAmount > 0 && _maxAmount == _spendTarget.pSpend->amount)
    {
        color = [UIColor colorWithRed:255/255.0f green:166/255.0f blue:52/255.0f alpha:1.0f];
        colorConversionLabel = [UIColor colorWithRed:255/255.0f green:180/255.0f blue:80/255.0f alpha:1.0f];
        [_maxAmountButton setBackgroundColor:UIColorFromARGB(0xFFfca600) ];
    }
    else
    {
        color = [UIColor whiteColor];
        colorConversionLabel = [UIColor darkGrayColor];
        [_maxAmountButton setBackgroundColor:UIColorFromARGB(0xFF72b83b) ];
    }
    if (ABC_CC_Ok == calcError->code)
    {
        tABC_Error error;
        double currencyFees = 0.0;
        self.conversionLabel.textColor = colorConversionLabel;
        self.amountBTCTextField.textColor = color;
        self.amountFiatTextField.textColor = color;

        NSMutableString *coinFeeString = [[NSMutableString alloc] init];
        NSMutableString *fiatFeeString = [[NSMutableString alloc] init];
        [coinFeeString appendString:@"+ "];
        [coinFeeString appendString:[CoreBridge formatSatoshi:txFees withSymbol:false]];
        [coinFeeString appendString:@" "];
        [coinFeeString appendString:[User Singleton].denominationLabel];

        if (ABC_SatoshiToCurrency([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], 
                                  txFees, &currencyFees, _currencyNum, &error) == ABC_CC_Ok)
        {
            [fiatFeeString appendString:@"+ "];
            [fiatFeeString appendString:[CoreBridge formatCurrency:currencyFees
                                                   withCurrencyNum:_currencyNum
                                                        withSymbol:false]];
            [fiatFeeString appendString:@" "];
            [fiatFeeString appendString:[CoreBridge currencyAbbrevLookup:_currencyNum]];
        }
        self.amountBTCLabel.text = coinFeeString; 
        self.amountFiatLabel.text = fiatFeeString;
        self.conversionLabel.text = [CoreBridge conversionStringFromNum:_currencyNum withAbbrev:YES];

        self.helpButton.hidden = YES;
        self.conversionLabel.layer.shadowOpacity = 0.0f;
    }
    else
    {
        NSString *message = [Util errorMap:calcError];
        self.conversionLabel.text = message;
        self.conversionLabel.textColor = [UIColor redColor];

        NSDictionary *labelAttr = @{NSFontAttributeName:self.conversionLabel.font};
        CGSize labelRect = [self.conversionLabel.text sizeWithAttributes:labelAttr];

        CGRect convRect = self.conversionLabel.frame;
        CGRect helpRect;
        helpRect.size = self.helpButton.frame.size;
        helpRect.origin.x = convRect.origin.x + labelRect.width;
        helpRect.origin.y = convRect.origin.y - helpRect.size.height / 4;
        [self.helpButton setFrame:helpRect];
        self.helpButton.hidden = NO;
        self.conversionLabel.layer.shadowColor = [[UIColor whiteColor] CGColor];
        self.conversionLabel.layer.shadowRadius = 5.0f;
        self.conversionLabel.layer.shadowOpacity = 1.0f;
        self.conversionLabel.layer.shadowOffset = CGSizeMake(0.0, 0.0);
        self.conversionLabel.layer.masksToBounds = NO;

        self.amountBTCTextField.textColor = [UIColor redColor];
        self.amountFiatTextField.textColor = [UIColor redColor];
    }
    [self alineTextFields:self.amountBTCLabel alignWith:self.amountBTCTextField];
    [self alineTextFields:self.amountFiatLabel alignWith:self.amountFiatTextField];
}

- (void)alineTextFields:(UILabel *)child alignWith:(UITextField *)parent
{
    NSDictionary *attributes = @{NSFontAttributeName: parent.font};
    CGSize parentText = [parent.text sizeWithAttributes:attributes];

    CGRect parentField = parent.frame;
    CGRect childField = child.frame;
    int origX = childField.origin.x;
    int newX = parentField.origin.x + parentText.width;
    int newWidth = childField.size.width + (origX - newX);
    childField.origin.x = newX;
    childField.size.width = newWidth;
    child.frame = childField;
}

//- (void)installLeftToRightSwipeDetection
//{
//    UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeLeftToRight:)];
//    gesture.direction = UISwipeGestureRecognizerDirectionRight;
//    [self.view addGestureRecognizer:gesture];
//}

// used by the guesture recognizer to ignore exit
- (BOOL)haveSubViewsShowing
{
    return (self.sendStatusController != nil || self.transactionDetailsController != nil);
}

- (void)dismissErrorMessage
{
    [FadingAlertView dismiss:YES];
}

#pragma mark infoView Delegates

- (void)InfoViewFinished:(InfoView *)infoView
{
    [infoView removeFromSuperview];
    self.infoView = nil;
}


#pragma mark - UITextField delegates

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    if (textField == _withdrawlPIN) {
        return YES;
    }
    if (![_spendTarget isMutable]) {
        return NO;
    }
    return _bAdvanceToTx;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    _selectedTextField = textField;
    if (_selectedTextField == self.amountBTCTextField)
        self.keypadView.calcMode = CALC_MODE_COIN;
    else if (_selectedTextField == self.amountFiatTextField)
        self.keypadView.calcMode = CALC_MODE_FIAT;
    self.keypadView.textField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
}

#pragma mark - ButtonSelectorView2 delegates

- (void)ButtonSelector2:(ButtonSelectorView2 *)view selectedItem:(int)itemIndex
{
    NSIndexPath *indexPath = [[NSIndexPath alloc]init];
    indexPath = [NSIndexPath indexPathForItem:itemIndex inSection:0];
    [CoreBridge makeCurrentWalletWithIndex:indexPath];
    bWalletListDropped = false;
}

- (void)ButtonSelector2WillShowTable:(ButtonSelectorView2 *)view
{
    [self dismissKeyboard];
//    [self dismissGestureRecognizer];
}

- (void)ButtonSelector2WillHideTable:(ButtonSelectorView2 *)view
{
    [self pickBestResponder];
//    [self setupGestureRecognizer];
}

#pragma mark - ConfirmationSlider delegates

- (void)ConfirmationSliderDidConfirm:(ConfirmationSliderView *)controller
{
    [self dismissErrorMessage];

    User *user = [User Singleton];

    if (kInvalidEntryWait == [User Singleton].sendState)
    {
        NSTimeInterval remaining = [user getRemainingInvalidEntryWait];
        NSString *entry = _pinRequired ? @"PIN" : @"password";
        if(remaining < 1.5) {
            [self fadingAlertDelayed:[NSString stringWithFormat:
                NSLocalizedString(@"Please wait 1 second before retrying %@", nil), entry]];
        }
        else
        {
           [self fadingAlertDelayed:[NSString stringWithFormat:
                NSLocalizedString(@"Please wait %.0f seconds before retrying %@", nil), remaining, entry]];
        }
        [_confirmationSlider resetIn:remaining];
    }
    else
    {
        //make sure PIN is good
        if (_pinRequired && !self.withdrawlPIN.text.length) {
            [self fadingAlertDelayed:NSLocalizedString(@"Please enter your PIN", nil)];
            [_withdrawlPIN becomeFirstResponder];
            [_withdrawlPIN selectAll:nil];
            [_confirmationSlider resetIn:1.0];
            return;
        }

        NSString *PIN = [User Singleton].strPIN;
        if (_pinRequired && ![self.withdrawlPIN.text isEqualToString:PIN]) {
            if (kInvalidEntryWait == [user sendInvalidEntry])
            {
                NSTimeInterval remaining = [user getRemainingInvalidEntryWait];
                [self fadingAlertDelayed:[NSString stringWithFormat:NSLocalizedString(@"Incorrect PIN. Please wait %.0f seconds and try again.", nil), remaining]];
            }
            else
            {
                [self fadingAlertDelayed:NSLocalizedString(@"Incorrect PIN", nil)];
            }
            [_withdrawlPIN becomeFirstResponder];
            [_withdrawlPIN selectAll:nil];
            [_confirmationSlider resetIn:1.0];

        } else if (_passwordRequired) {
            [Util checkPasswordAsync:self.withdrawlPIN.text withSelector:@selector(handlePasswordCheck:) controller:self];
        } else {
            [self continueChecks];
        }
    }
}

- (void)fadingAlertDelayed:(NSString *)message
{
    [CoreBridge postToMiscQueue:^{
        [NSThread sleepForTimeInterval:0.2f];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MainViewController fadingAlert:message];
        });
    }];
}

- (void)handlePasswordCheck:(NSNumber *)authenticated
{
    BOOL bAuthenticated = [authenticated boolValue];
    if (bAuthenticated) {
        [self continueChecks];
    } else {
        [MainViewController fadingAlert:NSLocalizedString(@"Incorrect password", nil)];
        [_withdrawlPIN becomeFirstResponder];
        [_withdrawlPIN selectAll:nil];
        [_confirmationSlider resetIn:1.0];
    }
}

- (void)continueChecks
{
    if (_spendTarget.pSpend->amount == 0) {
        [self fadingAlertDelayed:NSLocalizedString(@"Please enter an amount to send", nil)];
        [_confirmationSlider resetIn:1.0];
    } else {
        [self initiateSendRequest];
    }
}

- (void)tooSmallAlert
{
    [self fadingAlertDelayed:NSLocalizedString(@"Amount is too small", nil)];
}

#pragma mark - Calculator delegates

- (void)CalculatorDone:(CalculatorView *)calculator
{
    [self.amountFiatTextField resignFirstResponder];
    [self.amountBTCTextField resignFirstResponder];
    if (_pinRequired || _passwordRequired) {
        [self.withdrawlPIN becomeFirstResponder];
    }
}

- (void)CalculatorValueChanged:(CalculatorView *)calculator
{
    [self updateTextFieldContents];
}

#pragma mark - TransactionDetailsViewController delegates

- (void)TransactionDetailsViewControllerDone:(TransactionDetailsViewController *)controller
{
    [controller.view removeFromSuperview];
    [controller removeFromParentViewController];
    self.transactionDetailsController = nil;

    [self.sendStatusController.view removeFromSuperview];
    [self.sendStatusController removeFromParentViewController];
    self.sendStatusController = nil;

    [self.delegate sendConfirmationViewControllerDidFinish:self];
}

#pragma mark - ABC Callbacks

- (void)txSendSuccess:(Wallet *)wallet withTx:(NSString *)txId
{
    NSArray *params = [NSArray arrayWithObjects: wallet, txId, nil];
    [[AudioController controller] playSent];

    int maxDelay = 3;
    int delay = MIN(maxDelay, MAX(0, maxDelay - ([[NSDate date] timeIntervalSince1970] - _callbackTimestamp)));
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        if (_bAdvanceToTx) {
            [self showTransactionDetails:params];
        } else {
            if ([self.delegate respondsToSelector:@selector(sendConfirmationViewControllerDidFinish:withBack:withError:withTxId:)]) {
                [self.delegate sendConfirmationViewControllerDidFinish:self withBack:NO withError:NO withTxId:txId];
            } else {
                [self.delegate sendConfirmationViewControllerDidFinish:self];
            }
            [self hideSendStatus];
        }
        [_confirmationSlider resetIn:1.0];
    });
}

- (void)txSendFailed:(tABC_Error)Error
{
    NSString *title = NSLocalizedString(@"Error during send", nil);
    NSString *message = [Util errorMap:&Error];
    NSArray *params = [NSArray arrayWithObjects: title, message, nil];
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [_confirmationSlider resetIn:1.0];
        if (_bAdvanceToTx) {
            [self performSelectorOnMainThread:@selector(failedToSend:) withObject:params waitUntilDone:FALSE];
        } else {
            if ([self.delegate respondsToSelector:@selector(sendConfirmationViewControllerDidFinish:withBack:withError:withTxId:)]) {
                [self.delegate sendConfirmationViewControllerDidFinish:self withBack:NO withError:NO withTxId:nil];
            } else {
                [self.delegate sendConfirmationViewControllerDidFinish:self];
            }
            [self hideSendStatus];
        }
    });
}

#pragma mark - GestureReconizer methods

//- (void)didSwipeLeftToRight:(UIGestureRecognizer *)gestureRecognizer
//{
//    if (![self haveSubViewsShowing])
//    {
//        [self Back:nil];
//    }
//}
//
#pragma mark - Custom Notification Handlers

// called when a tab bar button that is already selected, is reselected again
- (void)tabBarButtonReselect:(NSNotification *)notification
{
    if (![self haveSubViewsShowing])
    {
        [self Back:nil];
    }
}

@end

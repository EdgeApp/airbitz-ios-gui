//
//  SendConfirmationViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/27/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "SendConfirmationViewController.h"
#import "InfoView.h"
#import "ConfirmationSliderView.h"
#import "User.h"
#import "CalculatorView.h"
#import "SendStatusViewController.h"
#import "TransactionDetailsViewController.h"
#import "ABCContext.h"
#import "Util.h"
#import "AudioController.h"
#import "MainViewController.h"
#import "Theme.h"
#import "ButtonSelectorView2.h"
#import "FadingAlertView.h"
#import "PopupPickerView2.h"

#define REFRESH_PERIOD_SECONDS 30

@interface SendConfirmationViewController () <UITextFieldDelegate, ConfirmationSliderViewDelegate, CalculatorViewDelegate, UIAlertViewDelegate,
                                              TransactionDetailsViewControllerDelegate, PopupPickerView2Delegate,
                                              ButtonSelector2Delegate, InfoViewDelegate>
{
    ConfirmationSliderView              *_confirmationSlider;
    UITextField                         *_selectedTextField;
    int64_t                             _maxAmount;
    BOOL                                _maxLocked;
    int64_t                             _totalSentToday;
    BOOL                                _pinRequired;
    BOOL                                _passwordRequired;
    NSString                            *_strReason;
    int                                 _callbackTimestamp;
    UIAlertView                         *_alert;
    UIAlertView                         *_changeFeeAlert;
    ABCSpendFeeLevel                    _feeLevel;
    NSTimer                             *_refreshTimer;
    BOOL                                bWalletListDropped;
    BOOL                                _currencyOverride;
    ABCCurrency                         *_currency;
    ABCSpend                            *_spend;
    uint64_t                            _amountSatoshi;
    NSNumberFormatter                   *_numberFormatter;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keypadViewBottom;
@property (weak, nonatomic) IBOutlet UIView                 *viewDisplayArea;

@property (weak, nonatomic) IBOutlet UIButton               *addressButton;
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
        _bSignOnly = NO;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _bAdvanceToTx = YES;
        _bSignOnly = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

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

    
    CGRect frame = self.keypadView.frame;
    frame.origin.y = self.view.frame.size.height;
    self.keypadView.frame = frame;
    
    _confirmationSlider = [ConfirmationSliderView CreateInsideView:self.confirmSliderContainer withDelegate:self];
    _maxLocked = NO;
    _feeLevel = ABCSpendFeeLevelStandard;
    _numberFormatter = [[NSNumberFormatter alloc] init];
    [_numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [_numberFormatter setMinimumFractionDigits:0];
    [_numberFormatter setMaximumFractionDigits:2];

    // Should this be threaded?
    _totalSentToday = [abcAccount.currentWallet getTotalSentToday];

    [self checkAuthorization];
    [_confirmationSlider resetIn:0.1];

    // add left to right swipe detection for going back
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabBarButtonReselect:) name:NOTIFICATION_TAB_BAR_BUTTON_RESELECT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(myTextDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:self.withdrawlPIN];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(exchangeRateUpdate:)
                                                 name:NOTIFICATION_EXCHANGE_RATE_CHANGED
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
    if (abcAccount.arrayWallets && abcAccount.currentWallet)
    {
        self.walletSelector.arrayItemsToSelect = abcAccount.arrayWalletNames;
        [self.walletSelector.button setTitle:abcAccount.currentWallet.name forState:UIControlStateNormal];
        self.walletSelector.selectedItemIndex = abcAccount.currentWalletIndex;

        if (_currencyOverride)
            self.keypadView.currency = _currency;
        else
            self.keypadView.currency = abcAccount.currentWallet.currency;

        NSString *walletName = [NSString stringWithFormat:@"From: %@ ▼", abcAccount.currentWallet.name];
        [MainViewController changeNavBarTitleWithButton:self title:walletName action:@selector(didTapTitle:) fromObject:self];
        if (!([abcAccount.arrayWallets containsObject:abcAccount.currentWallet]))
        {
            [FadingAlertView create:self.view
                            message:walletHasBeenArchivedText
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
    [_refreshTimer invalidate];
    _refreshTimer = nil;
    [self dismissErrorMessage];
    [super viewWillDisappear:animated];
//    [self dismissGestureRecognizer];
    [self.infoView dismiss];
    [self dismissKeyboard];
}

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
        ABCLog(2,@"Text changed for some field");
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSString *prefix;
    NSString *suffix;

    
    if (self.destWallet)
    {
        // This is a wallet to wallet transfer
        self.addressLabel.text = self.destWallet.name;
        self.addressButton.enabled = false;
    }
    else if (self.paymentRequest)
    {
        // This is a BIP70 payment request
        _amountSatoshi = self.paymentRequest.amountSatoshi;
        self.addressLabel.textColor = [Theme Singleton].colorButtonGreen;

        self.bAmountImmutable = YES;
        self.amountBTCTextField.text = [abcAccount.settings.denomination satoshiToBTCString:self.paymentRequest.amountSatoshi withSymbol:false];
        if (self.paymentRequest.merchant && [self.paymentRequest.merchant length] > 0)
            self.addressLabel.text = [NSString stringWithFormat:@"%@ (%@)", self.paymentRequest.merchant, self.paymentRequest.domain];
        else
            self.addressLabel.text = self.paymentRequest.domain;
        self.addressButton.enabled = false;
    }
    else if (self.parsedURI && self.parsedURI.address)
    {
        self.addressLabel.textColor = [Theme Singleton].colorTextLink;
        self.addressButton.enabled = true;
        
        // This is a standard bitcoin address/URI
        if (self.parsedURI.metadata && self.parsedURI.metadata.payeeName)
            self.addressLabel.text = [NSString stringWithFormat:@"%@ (%@...)",
                                      self.parsedURI.metadata.payeeName,
                                      [self.parsedURI.address substringToIndex:6]];
        else
        {
            prefix = [_parsedURI.address substringToIndex:5];
            suffix = [_parsedURI.address substringFromIndex: [_parsedURI.address length] - 5];
            self.addressLabel.text = [NSString stringWithFormat:@"%@...%@", prefix, suffix];
        }
        _amountSatoshi = _parsedURI.amountSatoshi;
    }
    else
    {
        ABCLog(1, @"***Invalid settings sent to SendConfimationViewController***");
    }

    self.maxAmountButton.hidden = self.bAmountImmutable;
    
    _currencyOverride = NO;
    _currency = abcAccount.currentWallet.currency;
    self.amountFiatLabel.textColor = [Theme Singleton].colorTextLinkOnDark;
    
    if (_amountSatoshi)
    {
        self.amountBTCTextField.text = [abcAccount.settings.denomination satoshiToBTCString:_amountSatoshi withSymbol:NO];
        double fCurrency = [abcAccount.exchangeCache satoshiToCurrency:_amountSatoshi currencyCode:_currency.code error:nil];
        self.amountFiatTextField.text = [NSString stringWithFormat:@"%.2f", fCurrency];
    }
    else
    {
        self.amountFiatTextField.text = nil;
        self.amountBTCTextField.text = nil;
    }
    
    [self exchangeRateUpdate:nil];

    _refreshTimer = [NSTimer scheduledTimerWithTimeInterval:REFRESH_PERIOD_SECONDS
        target:self
        selector:@selector(updateTextFieldContents)
        userInfo:nil
        repeats:NO];

    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_LEFT button:true enable:true action:@selector(Back:) fromObject:self];
    [MainViewController changeNavBar:self title:helpButtonText side:NAV_BAR_RIGHT button:true enable:true action:@selector(info:) fromObject:self];

    [self updateViews:nil];
    [self pickBestResponder];
}

- (void)buildSpend
{
    ABCError *error = nil;
    _spend = [abcAccount.currentWallet createNewSpend:&error];
    _spend.feeLevel = _feeLevel;
    
    if (!error)
    {
        if (_destWallet)
        {
            ABCMetaData *sourceMetaData = [ABCMetaData alloc];
            ABCMetaData *destMetaData   = [ABCMetaData alloc];
            
            // Setup source wallet metadata
            sourceMetaData.payeeName = [NSString stringWithFormat:transferToWalletText, _destWallet.name];
            sourceMetaData.category  = [NSString stringWithFormat:@"%@:%@:%@",abcStringTransferCategory,wallet_category, _destWallet.name];
            [_spend setMetaData:sourceMetaData];
            
            // Setup dest wallet metadata
            destMetaData.payeeName   = [NSString stringWithFormat:transferFromWalletText, abcAccount.currentWallet.name];
            destMetaData.category    = [NSString stringWithFormat:@"%@:%@:%@",abcStringTransferCategory,wallet_category, abcAccount.currentWallet.name];
            
            [_spend addTransfer:_destWallet amount:_amountSatoshi destMeta:destMetaData];
        }
        else if (_paymentRequest)
        {
            [_spend addPaymentRequest:_paymentRequest];
        }
        else if (_parsedURI)
        {
            [_spend setMetaData:_parsedURI.metadata];
            [_spend addAddress:_parsedURI.address amount:_amountSatoshi];
            if ([_address2 length] > 20 && _amountSatoshi2)
                [_spend addAddress:_address2 amount:_amountSatoshi2];
            
        }
    }
}

- (void)pickBestResponder
{
    if (_amountSatoshi) {
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

- (IBAction)TouchAddressButton:(id)sender
{
    NSMutableString *baseUrl = [[NSMutableString alloc] init];
    if ([abc isTestNet]) {
        [baseUrl appendString:@"https://testnet.blockexplorer.com/"];
    } else {
        [baseUrl appendString:@"https://insight.bitpay.com/"];
    }
    NSString *urlString = [NSString stringWithFormat:@"%@/address/%@",
                           baseUrl, _parsedURI.address];

    NSURL *url = [[NSURL alloc] initWithString:urlString];
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)info:(id) sender
{
    [self dismissErrorMessage];
    [self.view endEditing:YES];
    [self dismissKeyboard];
    [self setInfoView:[InfoView CreateWithHTML:@"info_send_confirmation" forView:self.view]];
    [self.infoView setDelegate:self];
}

- (IBAction)fundsInfo
{
    [self dismissErrorMessage];
    [self.view endEditing:YES];
    [self dismissKeyboard];
    [self setInfoView:[InfoView CreateWithHTML:@"info_insufficient_funds" forView:self.view]];
    [self.infoView setDelegate:self];
}

- (IBAction)Back:(id)sender
{
    [self dismissErrorMessage];

    [self.withdrawlPIN resignFirstResponder];
    [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                          delay:[Theme Singleton].animationDelayTimeDefault
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         CGRect frame = self.view.frame;
         frame.origin.x = frame.size.width;
         self.view.frame = frame;
     }
     completion:^(BOOL finished)
     {
            if ([self.delegate respondsToSelector:@selector(sendConfirmationViewControllerDidFinish:withBack:withError:transaction:withUnsentTx:)]) {
                [self.delegate sendConfirmationViewControllerDidFinish:self withBack:YES withError:NO transaction:nil withUnsentTx:nil];
            } else {
                [self.delegate sendConfirmationViewControllerDidFinish:self];
            }
            [self dismissKeyboard];
     }];
}

- (IBAction)ChangeFeeButton:(id)sender
{
    // Popup fee selection
    _changeFeeAlert = [[UIAlertView alloc]
                       initWithTitle:change_mining_fee_popup_title
                       message:change_mining_fee_popup_message
                       delegate:self
                       cancelButtonTitle:cancelButtonText
                       otherButtonTitles:change_mining_fee_low, change_mining_fee_standard, change_mining_fee_high, nil];

    [_changeFeeAlert show];
}

- (IBAction)ChangeFiatButton:(id)sender
{
    tPopupPicker2Position popupPosition = PopupPicker2Position_Full_Fading;
    NSString *headerText;

    NSArray *arrayPopupChoices = nil;

    arrayPopupChoices = [ABCCurrency listCurrencyStrings];
    popupPosition = PopupPicker2Position_Full_Fading;
    headerText = selectCurrencyText;

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
    if (abcAccount.currentWallet != nil && _maxLocked == NO)
    {
        _maxLocked = YES;
        _selectedTextField = self.amountBTCTextField;

        [self buildSpend];
        
        [_spend getMaxSpendable:^(uint64_t amountSpendable) {
            _maxLocked = NO;
            _maxAmount = amountSpendable;
            _amountSatoshi = _maxAmount;
            self.amountBTCTextField.text = [abcAccount.settings.denomination satoshiToBTCString:_amountSatoshi withSymbol:false];
            
            [self updateTextFieldContents:YES];
            if (_pinRequired || _passwordRequired) {
                [self.withdrawlPIN becomeFirstResponder];
            } else {
                [self dismissKeyboard];
            }

        } error:^(ABCError *error) {
            
        }];
    }
}

#pragma mark - Popup Picker Delegate Methods

- (void)PopupPickerView2Selected:(PopupPickerView2 *)view onRow:(NSInteger)row userData:(id)data
{
    _currency = [[ABCCurrency listCurrencies] objectAtIndex:row];
    _currencyOverride = YES;

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

    self.sendStatusController.messageLabel.text = sendingDotDotDot;

    [Util animateControllerFadeIn:self.sendStatusController];
}

- (void)hideSendStatus
{
    [Util animateControllerFadeOut:self.sendStatusController];
}

- (void)initiateSendRequest
{
    if (abcAccount.currentWallet)
    {
        [self performSelectorOnMainThread:@selector(showSendStatus:) withObject:nil waitUntilDone:FALSE];
        _callbackTimestamp = [[NSDate date] timeIntervalSince1970];

        [self buildSpend];
        
        if (_bSignOnly)
        {
            [_spend signTx:^(ABCUnsentTx *unsentTx) {
                [self txSendSuccess:abcAccount.currentWallet withTx:nil unsentTx:unsentTx];
            } error:^(ABCError *error) {
                [self txSendFailed:error];
            }];
        }
        else
        {
            [_spend signBroadcastAndSave:^(ABCTransaction *transaction) {
                [self txSendSuccess:abcAccount.currentWallet withTx:transaction unsentTx:nil];
            } error:^(ABCError *error) {
                [self txSendFailed:error];
            }];
        }
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



- (void)launchTransactionDetailsWithTransaction:(ABCWallet *)wallet withTx:(ABCTransaction *)transaction
{
//    [self.view removeGestureRecognizer:tap];

    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
    self.transactionDetailsController = [mainStoryboard instantiateViewControllerWithIdentifier:@"TransactionDetailsViewController"];
    
    self.transactionDetailsController.delegate = self;
    self.transactionDetailsController.transaction = transaction;
    self.transactionDetailsController.wallet = abcAccount.currentWallet;
    if (_parsedURI && _parsedURI.returnURI) {
        self.transactionDetailsController.returnUrl = _parsedURI.returnURI;
    }
    self.transactionDetailsController.bOldTransaction = NO;
    self.transactionDetailsController.transactionDetailsMode = TD_MODE_SENT;
    CGRect frame = self.view.bounds;
    frame.origin.x = frame.size.width;
    self.transactionDetailsController.view.frame = frame;
    
    [self.view addSubview:self.transactionDetailsController.view];
    [UIView animateWithDuration:[Theme Singleton].animationDurationTimeDefault
                          delay:[Theme Singleton].animationDelayTimeDefault
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
    NSString *msg2;
    unsigned long code = (unsigned long) [((NSNumber *) params[1]) integerValue];
    
    if ([params[2] isEqualToString:params[3]])
        msg2 = @"";
    else
        msg2 = params[3];
    
    NSString *message = [NSString stringWithFormat:@"Error Code:%lu\n\n%@\n\n%@", code, params[2], msg2];
    _alert = [[UIAlertView alloc]
                            initWithTitle:title
                            message:message
                            delegate:nil
                            cancelButtonTitle:okButtonText
                            otherButtonTitles:nil];
    [_alert show];
    [self hideSendStatus];
}

- (void)showTransactionDetails:(ABCWallet *)wallet transaction:(ABCTransaction *)transaction
{
    [self launchTransactionDetailsWithTransaction:wallet withTx:transaction];
}

- (void)updateTextFieldContents
{
    [self updateTextFieldContents:NO];
}
- (void)updateTextFieldContents:(BOOL)bAllowBTCUpdate
{
    double fCurrency;

    if (_selectedTextField == self.amountBTCTextField)
    {
        _amountSatoshi = [abcAccount.settings.denomination btcStringToSatoshi:self.amountBTCTextField.text];
        fCurrency = [abcAccount.exchangeCache satoshiToCurrency:_amountSatoshi currencyCode:_currency.code error:nil];
        
        NSNumber *num = [NSNumber numberWithDouble:fCurrency];
        self.amountFiatTextField.text = [_numberFormatter stringFromNumber:num];
    }
    else if ((_selectedTextField == self.amountFiatTextField) && !self.bAmountImmutable && bAllowBTCUpdate)
    {
        NSNumber *num = [_numberFormatter numberFromString:self.amountFiatTextField.text];
        fCurrency = [num doubleValue];

        _amountSatoshi = [abcAccount.exchangeCache currencyToSatoshi:fCurrency currencyCode:_currency.code error:nil];
        self.amountBTCTextField.text = [abcAccount.settings.denomination satoshiToBTCString:_amountSatoshi
                                                                                 withSymbol:false
                                                                               cropDecimals:YES];
    }
    self.amountBTCSymbol.text = abcAccount.settings.denomination.symbol;
    self.amountBTCLabel.text = abcAccount.settings.denomination.label;
    self.amountFiatSymbol.text = _currency.symbol;
    self.amountFiatLabel.text = _currency.code;
    self.conversionLabel.text = [abcAccount createExchangeRateString:_currency includeCurrencyCode:YES];

    [self checkAuthorization];
    [self startCalcFees];
}

- (void)checkAuthorization
{
    _passwordRequired = NO;
    _pinRequired = NO;
    if (!_destWallet && [User Singleton].bDailySpendLimit
                && _amountSatoshi + _totalSentToday >= [User Singleton].dailySpendLimitSatoshis) {
        // Show password
        _passwordRequired = YES;
        _labelPINTitle.hidden = NO;
        _labelPINTitle.text = passwordText;
        _withdrawlPIN.hidden = NO;
        _withdrawlPIN.keyboardType = UIKeyboardTypeDefault;
        _imagePINEmboss.hidden = NO;
    } else if (!_destWallet
                && abcAccount.settings.bSpendRequirePin
                && _amountSatoshi >= abcAccount.settings.spendRequirePinSatoshis
                && ![abcAccount recentlyLoggedIn]) {
        // Show PIN pad
        _pinRequired = YES;
        _labelPINTitle.hidden = NO;
        _labelPINTitle.text = fourDigitPINText;
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
    // Don't calculate fees until there is a value
    if (_amountSatoshi == 0)
    {
        self.conversionLabel.text = [abcAccount createExchangeRateString:_currency includeCurrencyCode:YES];
        self.conversionLabel.textColor = [UIColor darkGrayColor];
        self.amountBTCTextField.textColor = [UIColor whiteColor];
        self.amountFiatTextField.textColor = [UIColor whiteColor];

        // hide the help button next to insufficient funds if we don't call calcFees
        self.helpButton.hidden = YES;
        return;
    }
    [self buildSpend];
    [_spend getFees:^(uint64_t totalFees) {
        [self updateFeeFieldContents:totalFees+_amountSatoshi2 error:NO errorString:nil];
    } error:^(ABCError *error) {
        [self updateFeeFieldContents:0 error:YES errorString:error.userInfo[NSLocalizedDescriptionKey]];
    }];
}

- (void)updateFeeFieldContents:(uint64_t)txFees error:(BOOL)bError errorString:(NSString *)errorString;
{
    UIColor *color, *colorConversionLabel;
    _maxAmountButton.selected = NO;
    if (_maxAmount > 0 && _maxAmount == _amountSatoshi)
    {
        color = [Theme Singleton].colorButtonOrangeLight;
        colorConversionLabel = [UIColor darkGrayColor];
        [_maxAmountButton setBackgroundColor:[Theme Singleton].colorButtonOrange];
    }
    else
    {
        color = [UIColor whiteColor];
        colorConversionLabel = [UIColor darkGrayColor];
        [_maxAmountButton setBackgroundColor:UIColorFromARGB(0xFF72b83b) ];
    }
    if (!bError)
    {
        double currencyFees = 0.0;
        self.conversionLabel.textColor = colorConversionLabel;
        self.amountBTCTextField.textColor = color;
        self.amountFiatTextField.textColor = color;

        NSMutableString *coinFeeString = [[NSMutableString alloc] init];
        NSMutableString *fiatFeeString = [[NSMutableString alloc] init];
        [coinFeeString appendString:@"+ "];
        [coinFeeString appendString:[abcAccount.settings.denomination satoshiToBTCString:txFees withSymbol:false]];
        [coinFeeString appendString:@" "];
        [coinFeeString appendString:abcAccount.settings.denomination.label];

        currencyFees = [abcAccount.exchangeCache satoshiToCurrency:txFees currencyCode:_currency.code error:nil];
        [fiatFeeString appendString:@"+ "];
        NSNumber *number = [NSNumber numberWithDouble:currencyFees];
        NSString *string = [_numberFormatter stringFromNumber:number];
        if (string)
            [fiatFeeString appendString:string];
        [fiatFeeString appendString:@" "];
        [fiatFeeString appendString:_currency.code];
        
        self.amountBTCLabel.text = coinFeeString;
        self.amountFiatLabel.text = fiatFeeString;
        self.conversionLabel.text = [abcAccount createExchangeRateString:_currency includeCurrencyCode:YES];

        self.helpButton.hidden = YES;
        self.conversionLabel.layer.shadowOpacity = 0.0f;
    }
    else
    {
        self.conversionLabel.text = errorString;
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
    [FadingAlertView dismiss:FadingAlertDismissFast];
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
    if (self.bAmountImmutable) {
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
    [abcAccount makeCurrentWalletWithIndex:indexPath];
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
    [self dismissKeyboard];

    User *user = [User Singleton];

    if (kInvalidEntryWait == [User Singleton].sendState)
    {
        NSTimeInterval remaining = [user getRemainingInvalidEntryWait];
        NSString *entry = _pinRequired ? pinText : passwordText;
        if(remaining < 1.5) {
            [self fadingAlertDelayed:[NSString stringWithFormat:pleaseWait1SecondFormatString, entry]];
        }
        else
        {
           [self fadingAlertDelayed:[NSString stringWithFormat:pleaseWaitXXXSecondsFormatString, remaining, entry]];
        }
        [_confirmationSlider resetIn:remaining];
    }
    else
    {
        //make sure PIN is good
        if (_pinRequired && !self.withdrawlPIN.text.length) {
            [self fadingAlertDelayed:pleaseEnterYourPIN];
            [_withdrawlPIN becomeFirstResponder];
            [_withdrawlPIN selectAll:nil];
            [_confirmationSlider resetIn:1.0];
            return;
        }

        if (_pinRequired && ![abcAccount checkPIN:self.withdrawlPIN.text]) {
            if (kInvalidEntryWait == [user sendInvalidEntry])
            {
                NSTimeInterval remaining = [user getRemainingInvalidEntryWait];
                [self fadingAlertDelayed:[NSString stringWithFormat:incorrectPINPleaseWaitXXX, remaining]];
            }
            else
            {
                [self fadingAlertDelayed:incorrectPIN];
            }
            [_withdrawlPIN becomeFirstResponder];
            [_withdrawlPIN selectAll:nil];
            [_confirmationSlider resetIn:1.0];

        } else if (_passwordRequired) {
            BOOL matched = [abcAccount checkPassword:self.withdrawlPIN.text];
            if (matched) {
                [self continueChecks];
            } else {
                [self fadingAlertDelayed:incorrectPasswordText];
                [_withdrawlPIN becomeFirstResponder];
                [_withdrawlPIN selectAll:nil];
                [_confirmationSlider resetIn:1.0];
            }
        } else {
            [self continueChecks];
        }
    }
}

- (void)fadingAlertDelayed:(NSString *)message
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [NSThread sleepForTimeInterval:0.2f];
        dispatch_async(dispatch_get_main_queue(), ^{
            [MainViewController fadingAlert:message];
        });
    });
}

- (void)continueChecks
{
    if (_amountSatoshi == 0) {
        [self fadingAlertDelayed:pleaseEnterAnAmountToSend];
        [_confirmationSlider resetIn:1.0];
    } else {
        [self initiateSendRequest];
    }
}

- (void)tooSmallAlert
{
    [self fadingAlertDelayed:amountIsTooSmall];
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
    [self updateTextFieldContents:YES];
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

- (void)txSendSuccess:(ABCWallet *)wallet withTx:(ABCTransaction *)transaction unsentTx:(ABCUnsentTx *)unsentTx
{
    [[AudioController controller] playSent];
    
    int maxDelay = 1;
    int delay = MIN(maxDelay, MAX(0, maxDelay - ([[NSDate date] timeIntervalSince1970] - _callbackTimestamp)));
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        if (_bAdvanceToTx) {
            [self showTransactionDetails:wallet transaction:transaction];
        } else {
            if ([self.delegate respondsToSelector:@selector(sendConfirmationViewControllerDidFinish:withBack:withError:transaction:withUnsentTx:)]) {
                
                [self.delegate sendConfirmationViewControllerDidFinish:self withBack:NO withError:NO transaction:transaction withUnsentTx:unsentTx];
            } else {
                [self.delegate sendConfirmationViewControllerDidFinish:self];
            }
            [self hideSendStatus];
        }
        [_confirmationSlider resetIn:1.0];
    });
}

- (void)txSendFailed:(ABCError *)error;
{
    NSString *title = errorDuringSend;
    NSArray *params = [NSArray arrayWithObjects: title, [NSNumber numberWithInteger:error.code], error.userInfo[NSLocalizedDescriptionKey], error.userInfo[NSLocalizedFailureReasonErrorKey],nil];
//    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [_confirmationSlider resetIn:1.0];
        if (_bAdvanceToTx) {
            [self performSelectorOnMainThread:@selector(failedToSend:) withObject:params waitUntilDone:FALSE];
        } else {
            if ([self.delegate respondsToSelector:@selector(sendConfirmationViewControllerDidFinish:withBack:withError:transaction:withUnsentTx:)]) {
                [self.delegate sendConfirmationViewControllerDidFinish:self withBack:NO withError:NO transaction:nil withUnsentTx:nil];
            } else {
                [self.delegate sendConfirmationViewControllerDidFinish:self];
            }
            [self hideSendStatus];
        }
//    });
}

#pragma mark - UIAlertView delegates

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView == _changeFeeAlert)
    {
        if (0 == buttonIndex)
        {
            return;
        }
        else if (1 == buttonIndex)
        {
            // fee low
            ABCLog(0, @"Set fee low");
            _feeLevel = ABCSpendFeeLevelLow;
        }
        else if (2 == buttonIndex)
        {
            // fee standard
            ABCLog(0, @"Set fee std");
            _feeLevel = ABCSpendFeeLevelStandard;
        }
        else if (3 == buttonIndex)
        {
            // fee high
            ABCLog(0, @"Set fee high");
            _feeLevel = ABCSpendFeeLevelHigh;
        }
        [self startCalcFees];
    }
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

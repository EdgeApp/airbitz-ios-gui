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
#import "CommonTypes.h"


@interface SendConfirmationViewController () <UITextFieldDelegate, ConfirmationSliderViewDelegate, CalculatorViewDelegate, TransactionDetailsViewControllerDelegate, UIGestureRecognizerDelegate, InfoViewDelegate>
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
    Transaction                         *_completedTransaction;    // nil until sendTransaction is successfully completed
    UITapGestureRecognizer              *tap;
    UIAlertView                         *_alert;
}

@property (weak, nonatomic) IBOutlet UIView                 *viewDisplayArea;

@property (weak, nonatomic) IBOutlet UIImageView            *imageTopEmboss;
@property (weak, nonatomic) IBOutlet UILabel                *labelSendFromTitle;
@property (weak, nonatomic) IBOutlet UILabel                *labelSendFrom;
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
@property (weak, nonatomic) IBOutlet UILabel                *txFeesLabel;
@property (weak, nonatomic) IBOutlet UIImageView            *imagePINEmboss;
@property (nonatomic, weak) IBOutlet UITextField            *withdrawlPIN;
@property (nonatomic, weak) IBOutlet UIView                 *confirmSliderContainer;
@property (nonatomic, weak) IBOutlet UIButton               *btn_alwaysConfirm;
@property (weak, nonatomic) IBOutlet UILabel                *labelAlwaysConfirm;
@property (nonatomic, weak) IBOutlet CalculatorView         *keypadView;
@property (nonatomic, weak) IBOutlet UIView                 *errorMessageView;
@property (nonatomic, weak) IBOutlet UILabel                *errorMessageText;

@property (nonatomic, strong) SendStatusViewController          *sendStatusController;
@property (nonatomic, strong) TransactionDetailsViewController  *transactionDetailsController;
@property (nonatomic, strong) InfoView                          *infoView;

@end

@implementation SendConfirmationViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    // Added gesture recognizer to control keyboard
    tap = [[UITapGestureRecognizer alloc] 
        initWithTarget:self
                action:@selector(dismissKeyboard)];

    // resize ourselves to fit in area
    [Util resizeView:self.view withDisplayView:self.viewDisplayArea];

    self.keypadView.currencyNum = self.wallet.currencyNum;
    self.withdrawlPIN.delegate = self;
    self.amountBTCTextField.delegate = self;
    self.amountFiatTextField.delegate = self;
    self.keypadView.delegate = self;
    self.amountBTCTextField.inputView = self.keypadView;
    self.amountFiatTextField.inputView = self.keypadView;

    // make sure the edit fields are in front of the blocker
    [self.viewDisplayArea bringSubviewToFront:self.amountBTCTextField];
    [self.viewDisplayArea bringSubviewToFront:self.amountFiatTextField];
    [self.viewDisplayArea bringSubviewToFront:self.withdrawlPIN];

    [self setWalletLabel];
    
    CGRect frame = self.keypadView.frame;
    frame.origin.y = self.view.frame.size.height;
    self.keypadView.frame = frame;
    
    _confirmationSlider = [ConfirmationSliderView CreateInsideView:self.confirmSliderContainer withDelegate:self];
    _maxLocked = NO;

    // Should this be threaded?
    _totalSentToday = [CoreBridge getTotalSentToday:self.wallet];

    [self updateDisplayLayout];
    [self checkAuthorization];

    // add left to right swipe detection for going back
    [self installLeftToRightSwipeDetection];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabBarButtonReselect:) name:NOTIFICATION_TAB_BAR_BUTTON_RESELECT object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(myTextDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:self.withdrawlPIN];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(exchangeRateUpdate:)
                                                 name:NOTIFICATION_EXCHANGE_RATE_CHANGE
                                               object:nil];
    
    self.errorMessageView.alpha = 0.0;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.view removeGestureRecognizer:tap];
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
        NSLog(@"Text changed for some field");
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.view addGestureRecognizer:tap];
    self.amountBTCSymbol.text = [User Singleton].denominationLabelShort;
    self.amountBTCLabel.text = [User Singleton].denominationLabel;
    self.amountBTCTextField.text = [CoreBridge formatSatoshi:self.amountToSendSatoshi withSymbol:false];
    self.amountFiatSymbol.text = [CoreBridge currencySymbolLookup:self.wallet.currencyNum];
    self.amountFiatLabel.text = [CoreBridge currencyAbbrevLookup:self.wallet.currencyNum];
    self.conversionLabel.text = [CoreBridge conversionString:self.wallet];
    
    NSString *prefix;
    NSString *suffix;
    
    if ([self.sendToAddress length] > 10 && !self.bAddressIsWalletUUID)
    {
        prefix = [self.sendToAddress substringToIndex:5];
        suffix = [self.sendToAddress substringFromIndex: [self.sendToAddress length] - 5];
        self.addressLabel.text = [NSString stringWithFormat:@"%@...%@", prefix, suffix];
    }
    else
    {
        self.addressLabel.text = self.sendToAddress;
    }
    
    
    
    
    tABC_CC result;
    double currency;
    tABC_Error error;
    
    result = ABC_SatoshiToCurrency([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                                   self.amountToSendSatoshi, &currency, self.wallet.currencyNum, &error);
                
    if(result == ABC_CC_Ok)
    {
        self.amountFiatTextField.text = [NSString stringWithFormat:@"%.2f", currency];
    }
    [self startCalcFees];
    
    if (self.amountToSendSatoshi)
    {
        // If the PIN is empty, then focus
        if ([self.withdrawlPIN.text length] <= 0)
        {
            if (_pinRequired || _passwordRequired) {
                [self.withdrawlPIN becomeFirstResponder];
            }
        }
    }
    else
    {
        self.amountFiatTextField.text = nil;
        self.amountBTCTextField.text = nil;
        [self.amountFiatTextField becomeFirstResponder];
    }
    [self exchangeRateUpdate:nil]; 
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Notification Handlers

- (void)exchangeRateUpdate: (NSNotification *)notification
{
    // only update if on the BTC field
    if (_selectedTextField == self.amountBTCTextField)
    {
        [self updateTextFieldContents];
    }
}

#pragma mark - Actions Methods

- (IBAction)info
{
    [self.view endEditing:YES];
    [self dismissKeyboard];
    [self setInfoView:[InfoView CreateWithHTML:@"infoSendConfirmation" forView:self.view]];
    [self.infoView setDelegate:self];
}

- (IBAction)fundsInfo
{
    [self.view endEditing:YES];
    [self dismissKeyboard];
    [self setInfoView:[InfoView CreateWithHTML:@"infoInsufficientFunds" forView:self.view]];
    [self.infoView setDelegate:self];
}

- (IBAction)Back:(id)sender
{
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
         [self.delegate sendConfirmationViewControllerDidFinish:self];
     }];
}

- (IBAction)alwaysConfirm:(UIButton *)sender
{
    if(sender.selected)
    {
        sender.selected = NO;
    }
    else
    {
        sender.selected = YES;
    }
}

- (IBAction)selectMaxAmount
{
    if (self.wallet != nil && _maxLocked == NO)
    {
        _maxLocked = YES;
        _selectedTextField = self.amountBTCTextField;

        // We use a serial queue for this calculation
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            int64_t maxAmount = [CoreBridge maxSpendable:self.wallet.strUUID
                                               toAddress:[self getDestAddress]
                                              isTransfer:self.bAddressIsWalletUUID];
            dispatch_async(dispatch_get_main_queue(), ^{
                _maxLocked = NO;
                _maxAmount = maxAmount;
                self.amountToSendSatoshi = maxAmount;
                self.amountBTCTextField.text = [CoreBridge formatSatoshi:self.amountToSendSatoshi withSymbol:false];

                [self updateTextFieldContents];
                if (_pinRequired || _passwordRequired) {
                    [self.withdrawlPIN becomeFirstResponder];
                }
            });
        });
    }
}

#pragma mark - Misc Methods

- (void)dismissKeyboard
{
    [self.withdrawlPIN resignFirstResponder];
    [self.amountFiatTextField resignFirstResponder];
    [self.amountBTCTextField resignFirstResponder];
}

- (void)updateDisplayLayout
{
    // if we are on a smaller screen
    if (IS_IPHONE4 )
    {
        // be prepared! lots and lots of magic numbers here to jam the controls to fit on a small screen

        int topShift = 22;
        int valueShift = 47;
        int pinShift = 67;
        CGRect frame;

        self.imageTopEmboss.hidden = YES;
        
        frame = self.labelSendFromTitle.frame;
        frame.origin.y -= topShift;
        self.labelSendFromTitle.frame = frame;
        
        frame = self.labelSendFrom.frame;
        frame.origin.y -= topShift;
        self.labelSendFrom.frame = frame;
        
        frame = self.labelSendToTitle.frame;
        frame.origin.y -= topShift + 10;
        self.labelSendToTitle.frame = frame;
        
        frame = self.addressLabel.frame;
        frame.origin.y -= topShift + 10;
        self.addressLabel.frame = frame;
        
        frame = self.conversionLabel.frame;
        frame.origin.y -= (topShift + 22);
        self.conversionLabel.frame = frame;

        frame = self.maxAmountButton.frame;
        frame.origin.y -= (topShift + 22);
        self.maxAmountButton.frame = frame;
        
        frame = self.viewBTC.frame;
        frame.origin.y -= valueShift;
        self.viewBTC.frame = frame;

        frame = self.viewFiat.frame;
        frame.origin.y -= (valueShift + 2);
        self.viewFiat.frame = frame;

        frame = self.imagePINEmboss.frame;
        frame.origin.y -= pinShift;
        self.imagePINEmboss.frame = frame;
        
        frame = self.labelPINTitle.frame;
        frame.origin.y -= pinShift;
        self.labelPINTitle.frame = frame;
        
        frame = self.withdrawlPIN.frame;
        frame.origin.y -= pinShift;
        self.withdrawlPIN.frame = frame;
        
        frame = self.confirmSliderContainer.frame;
        frame.origin.y -= pinShift;
        self.confirmSliderContainer.frame = frame;

        /*
        frame = self.amountBTCTextField.frame;
        frame.origin.y -= 5;
        self.amountBTCTextField.frame = frame;
        frame = self.amountFiatTextField.frame;
        frame.origin.y = self.viewFiat.frame.origin.y + 7;
        self.amountFiatTextField.frame = frame;


        frame = self.btn_alwaysConfirm.frame;
        frame.origin.y = self.confirmSliderContainer.frame.origin.y + self.confirmSliderContainer.frame.size.height + 25;
        self.btn_alwaysConfirm.frame = frame;

        frame = self.labelAlwaysConfirm.frame;
        frame.origin.y = self.btn_alwaysConfirm.frame.origin.y + self.btn_alwaysConfirm.frame.size.height + 0;
        self.labelAlwaysConfirm.frame = frame;
         */
    }
}

- (void)showSendStatus:(NSArray *)params
{
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
    self.sendStatusController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SendStatusViewController"];



    CGRect frame = self.view.bounds;
    //frame.origin.x = frame.size.width;
    self.sendStatusController.view.frame = frame;
    [self.view addSubview:self.sendStatusController.view];
    self.sendStatusController.view.alpha = 0.0;

    self.sendStatusController.messageLabel.text = NSLocalizedString(@"Sending...", @"status message");

    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         self.sendStatusController.view.alpha = 1.0;
     }
     completion:^(BOOL finished)
     {
     }];
}

- (void)hideSendStatus
{
    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
    {
        self.sendStatusController.view.alpha = 0.0;
    }
    completion:^(BOOL finished)
    {
        [self.sendStatusController.view removeFromSuperview];
        self.sendStatusController = nil;
    }];
}

- (void)initiateSendRequest
{
    tABC_Error Error;
    tABC_CC result;
    double currency;
    
    result = ABC_SatoshiToCurrency([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                                   self.amountToSendSatoshi, &currency, self.wallet.currencyNum, &Error);
    if (result == ABC_CC_Ok)
    {
        if (self.wallet)
        {
            [self performSelectorOnMainThread:@selector(showSendStatus:) withObject:nil waitUntilDone:FALSE];
            _callbackTimestamp = [[NSDate date] timeIntervalSince1970];

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                char *szTxId = NULL;
                tABC_Error Error;
                tABC_CC result;
                tABC_TxDetails Details;
                memset(&Details, 0, sizeof(tABC_TxDetails));
                Details.amountSatoshi = self.amountToSendSatoshi;
                Details.amountCurrency = currency;
                // These will be calculated for us
                Details.amountFeesAirbitzSatoshi = 0;
                Details.amountFeesMinersSatoshi = 0;
                // If this is a transfer, populate the comments
                if (self.nameLabel) {
                    Details.szName = (char *)[self.nameLabel UTF8String];
                } else {
                    Details.szName = "";
                }
                Details.szCategory = "";
                Details.szNotes = "";
                Details.attributes = 0x2;

                if (self.bAddressIsWalletUUID)
                {
                    NSString *categoryText = NSLocalizedString(@"Transfer:Wallet:", nil);
                    tABC_TransferDetails Transfer;
                    Transfer.szSrcWalletUUID = strdup([self.wallet.strUUID UTF8String]);
                    Transfer.szSrcName = strdup([self.destWallet.strName UTF8String]);
                    Transfer.szSrcCategory = strdup([[NSString stringWithFormat:@"%@%@", categoryText, self.destWallet.strName] UTF8String]);

                    Transfer.szDestWalletUUID = strdup([self.destWallet.strUUID UTF8String]);
                    Transfer.szDestName = strdup([self.wallet.strName UTF8String]);
                    Transfer.szDestCategory = strdup([[NSString stringWithFormat:@"%@%@", categoryText, self.wallet.strName] UTF8String]);

                    result = ABC_InitiateTransfer([[User Singleton].name UTF8String],
                                                [[User Singleton].password UTF8String],
                                                &Transfer, &Details,
                                                &szTxId,
                                                &Error);

                    free(Transfer.szSrcWalletUUID);
                    free(Transfer.szSrcName);
                    free(Transfer.szSrcCategory);
                    free(Transfer.szDestWalletUUID);
                    free(Transfer.szDestName);
                    free(Transfer.szDestCategory);
                } else {
                    result = ABC_InitiateSendRequest([[User Singleton].name UTF8String],
                                                [[User Singleton].password UTF8String],
                                                [self.wallet.strUUID UTF8String],
                                                [self.sendToAddress UTF8String],
                                                &Details,
                                                &szTxId,
                                                &Error);
                }
                if (result == ABC_CC_Ok) {
                    [self txSendSuccess:self.wallet.strUUID withTx:[NSString stringWithUTF8String:szTxId]];
                } else {
                    [self txSendFailed:Error];
                }
                free(szTxId);
            });
        }
    }
}

- (void)setWalletLabel
{
    if (self.wallet)
    {
        NSMutableString *label = [[NSMutableString alloc] init];
        [label appendFormat:@"%@ (%@)", self.wallet.strName,
            [CoreBridge formatSatoshi:self.wallet.balance]];
        self.labelSendFrom.text = label;
    }
}

- (void)launchTransactionDetailsWithTransaction:(Wallet *)wallet withTx:(Transaction *)transaction
{
    [self.view removeGestureRecognizer:tap];

    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
    self.transactionDetailsController = [mainStoryboard instantiateViewControllerWithIdentifier:@"TransactionDetailsViewController"];
    
    self.transactionDetailsController.delegate = self;
    self.transactionDetailsController.transaction = transaction;
    self.transactionDetailsController.wallet = self.wallet;
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
        NSLog(@"Not enought args\n");
        return;
    }
    NSString *walletUUID = params[0];
    NSString *txId = params[1];
    Wallet *wallet = [CoreBridge getWallet:walletUUID];
    Transaction *transaction = [CoreBridge getTransaction:walletUUID withTx:txId];
    [self launchTransactionDetailsWithTransaction:wallet withTx:transaction];
}

- (void)updateTextFieldContents
{
    double currency;
    int64_t satoshi;
    tABC_Error error;

    if (_selectedTextField == self.amountBTCTextField)
    {
        self.amountToSendSatoshi = [CoreBridge denominationToSatoshi: self.amountBTCTextField.text];
        if (ABC_SatoshiToCurrency([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                                  self.amountToSendSatoshi, &currency, self.wallet.currencyNum, &error) == ABC_CC_Ok)
        {
            self.amountFiatTextField.text = [NSString stringWithFormat:@"%.2f", currency];
        }
    }
    else if (_selectedTextField == self.amountFiatTextField)
    {
        currency = [self.amountFiatTextField.text doubleValue];
        if (ABC_CurrencyToSatoshi([[User Singleton].name UTF8String], [[User Singleton].password UTF8String],
                                  currency, self.wallet.currencyNum, &satoshi, &error) == ABC_CC_Ok)
        {
            self.amountToSendSatoshi = satoshi;
            self.amountBTCTextField.text = [CoreBridge formatSatoshi:satoshi
                                                          withSymbol:false
                                                    cropDecimals:[CoreBridge currencyDecimalPlaces]];
        }
    }
    [self checkAuthorization];
    [self startCalcFees];
}

- (void)checkAuthorization
{
    _passwordRequired = NO;
    _pinRequired = NO;

    if ([User Singleton].bDailySpendLimit 
            && self.amountToSendSatoshi + _totalSentToday >= [User Singleton].dailySpendLimitSatoshis) {
        // Show password
        _passwordRequired = YES;
        _labelPINTitle.hidden = NO;
        _labelPINTitle.text = NSLocalizedString(@"Password", nil);
        _withdrawlPIN.hidden = NO;
        _withdrawlPIN.keyboardType = UIKeyboardTypeDefault;
        _imagePINEmboss.hidden = NO;
    } else if ([User Singleton].bSpendRequirePin && self.amountToSendSatoshi >= [User Singleton].spendRequirePinSatoshis) {
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
    if (self.amountToSendSatoshi == 0)
    {
        self.conversionLabel.text = [CoreBridge conversionString:self.wallet];
        self.conversionLabel.textColor = [UIColor whiteColor];
        self.amountBTCTextField.textColor = [UIColor whiteColor];
        self.amountFiatTextField.textColor = [UIColor whiteColor];

        // hide the help button next to insufficient funds if we don't call calcFees
        self.helpButton.hidden = YES;
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self calcFees];
    });
}

- (void)calcFees
{
    int64_t fees = 0;
    NSString *dest = [self getDestAddress];
    BOOL sufficent =
        [CoreBridge calcSendFees:self.wallet.strUUID
                          sendTo:dest
                    amountToSend:self.amountToSendSatoshi
                  storeResultsIn:&fees
                  walletTransfer:self.bAddressIsWalletUUID];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateFeeFieldContents:fees hasEnough:sufficent];
    });
}

- (void)updateFeeFieldContents:(int64_t)txFees hasEnough:(BOOL)sufficientFunds
{
    UIColor *color;
    _maxAmountButton.selected = NO;
    if (_maxAmount > 0 && _maxAmount == self.amountToSendSatoshi)
    {
        color = [UIColor colorWithRed:255/255.0f green:166/255.0f blue:52/255.0f alpha:1.0f];
        [_maxAmountButton setBackgroundImage:[UIImage imageNamed:@"btn_use_max.png"]
                                    forState:UIControlStateNormal];

    }
    else
    {
        color = [UIColor whiteColor];
        [_maxAmountButton setBackgroundImage:[UIImage imageNamed:@"btn_max.png"]
                                    forState:UIControlStateNormal];
    }
    if (sufficientFunds)
    {
        tABC_Error error;
        double currencyFees = 0.0;
        self.conversionLabel.textColor = color;
        self.amountBTCTextField.textColor = color;
        self.amountFiatTextField.textColor = color;

        NSMutableString *coinFeeString = [[NSMutableString alloc] init];
        NSMutableString *fiatFeeString = [[NSMutableString alloc] init];
        [coinFeeString appendString:@"+ "];
        [coinFeeString appendString:[CoreBridge formatSatoshi:txFees withSymbol:false]];
        [coinFeeString appendString:@" "];
        [coinFeeString appendString:[User Singleton].denominationLabel];

        if (ABC_SatoshiToCurrency([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], 
                                  txFees, &currencyFees, self.wallet.currencyNum, &error) == ABC_CC_Ok)
        {
            [fiatFeeString appendString:@"+ "];
            [fiatFeeString appendString:[CoreBridge formatCurrency:currencyFees
                                                   withCurrencyNum:self.wallet.currencyNum
                                                        withSymbol:false]];
            [fiatFeeString appendString:@" "];
            [fiatFeeString appendString:self.wallet.currencyAbbrev];
        }
        self.amountBTCLabel.text = coinFeeString; 
        self.amountFiatLabel.text = fiatFeeString;
        self.conversionLabel.text = [CoreBridge conversionString:self.wallet];
        
        self.helpButton.hidden = YES;
        self.conversionLabel.layer.shadowOpacity = 0.0f;
    }
    else
    {
        NSString *message = NSLocalizedString(@"Insufficient funds", nil);
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

- (void)installLeftToRightSwipeDetection
{
    UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeLeftToRight:)];
    gesture.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:gesture];
}

// used by the guesture recognizer to ignore exit
- (BOOL)haveSubViewsShowing
{
    return (self.sendStatusController != nil || self.transactionDetailsController != nil);
}

- (void)showFadingError:(NSString *)message
{
    self.errorMessageText.text = message;
    self.errorMessageView.alpha = 1.0;
    [UIView animateWithDuration:ERROR_MESSAGE_FADE_DURATION
                          delay:ERROR_MESSAGE_FADE_DELAY
                        options:UIViewAnimationOptionCurveLinear
                     animations:^
     {
         self.errorMessageView.alpha = 0.0;
     }
     completion:^(BOOL finished)
     {
     }];
}

#pragma mark infoView Delegates

- (void)InfoViewFinished:(InfoView *)infoView
{
    [infoView removeFromSuperview];
    self.infoView = nil;
}


#pragma mark - UITextField delegates

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

#pragma mark - ConfirmationSlider delegates

- (void)ConfirmationSliderDidConfirm:(ConfirmationSliderView *)controller
{
    User *user = [User Singleton];

    if (kInvalidEntryWait == [User Singleton].sendState)
    {
        NSTimeInterval remaining = [user getRemainingInvalidEntryWait];
        NSString *entry = _pinRequired ? @"PIN" : @"password";
        [self showFadingError:[NSString stringWithFormat:
                NSLocalizedString(@"Please wait %.0f seconds before retrying %@",
                nil),
                remaining,
                entry]];
    }
    else
    {
        //make sure PIN is good
        if (_pinRequired && !self.withdrawlPIN.text.length) {
            [self showFadingError:NSLocalizedString(@"Please enter your PIN", nil)];
            [_withdrawlPIN becomeFirstResponder];
            [_withdrawlPIN selectAll:nil];
            [_confirmationSlider resetIn:1.0];
            return;
        }

        NSString *PIN = [CoreBridge getPIN];
        if (_pinRequired && ![self.withdrawlPIN.text isEqualToString:PIN]) {
            if (kInvalidEntryWait == [user invalidEntry])
            {
                NSTimeInterval remaining = [user getRemainingInvalidEntryWait];
                [self showFadingError:[NSString stringWithFormat:NSLocalizedString(@"Incorrect PIN. Please wait %.0f seconds and try again.", nil), remaining]];
            }
            else
            {
                [self showFadingError:NSLocalizedString(@"Incorrect PIN", nil)];
            }
            [_withdrawlPIN becomeFirstResponder];
            [_withdrawlPIN selectAll:nil];
        } else if (_passwordRequired && ![self.withdrawlPIN.text isEqualToString:[User Singleton].password]) {
            if (kInvalidEntryWait == [user invalidEntry])
            {
                NSTimeInterval remaining = [user getRemainingInvalidEntryWait];
                [self showFadingError:[NSString stringWithFormat:NSLocalizedString(@"Incorrect password. Please wait %.0f seconds and try again.", nil), remaining]];
            }
            else
            {
                [self showFadingError:NSLocalizedString(@"Incorrect password", nil)];
            }
            [_withdrawlPIN becomeFirstResponder];
            [_withdrawlPIN selectAll:nil];
        } else if (self.amountToSendSatoshi == 0) {
            [self showFadingError:NSLocalizedString(@"Please enter an amount to send", nil)];
        } else {
            NSLog(@"SUCCESS!");
            [self initiateSendRequest];
        }
    }
    [_confirmationSlider resetIn:1.0];
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
    self.transactionDetailsController = nil;

    [self.sendStatusController.view removeFromSuperview];
    self.sendStatusController = nil;

    [self.delegate sendConfirmationViewControllerDidFinish:self];
}

#pragma mark - ABC Callbacks

- (void)txSendSuccess:(NSString *)walletUUID withTx:(NSString *)txId
{
    NSArray *params = [NSArray arrayWithObjects: walletUUID, txId, nil];

    int maxDelay = 3;
    int delay = MIN(maxDelay, MAX(0, maxDelay - ([[NSDate date] timeIntervalSince1970] - _callbackTimestamp)));
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delay * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        [self showTransactionDetails:params];
    });
}

- (void)txSendFailed:(tABC_Error)Error
{
    NSString *title = NSLocalizedString(@"Error during send", nil);
    NSString *message = [Util errorMap:&Error];
    NSArray *params = [NSArray arrayWithObjects: title, message, nil];
    [self performSelectorOnMainThread:@selector(failedToSend:) withObject:params waitUntilDone:FALSE];
}

- (NSString *)getDestAddress
{
    if (self.bAddressIsWalletUUID) {
        return self.destWallet.strUUID;
    } else {
        return self.sendToAddress;
    }
}


#pragma mark - GestureReconizer methods

- (void)didSwipeLeftToRight:(UIGestureRecognizer *)gestureRecognizer
{
    if (![self haveSubViewsShowing])
    {
        [self Back:nil];
    }
}

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

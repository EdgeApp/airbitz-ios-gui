//
//  ImportWalletViewController.m
//  AirBitz
//
//  Created by Adam Harris on 5/19/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "CommonTypes.h"
#import "ABC.h"
#import "ImportWalletViewController.h"
#import "ButtonSelectorView.h"
#import "FlashSelectView.h"
#import "StylizedTextField.h"
#import "Util.h"
#import "User.h"
#import "LatoLabel.h"
#import "ZBarSDK.h"
#import "InfoView.h"
#import "CoreBridge.h"
#import "FadingAlertView.h"
#import "DL_URLServer.h"
#import "Server.h"
#import "CJSONDeserializer.h"
#import "PickerTextView.h"
#import <Social/Social.h>

#define WALLET_BUTTON_WIDTH 210

#define SCANNER_DELAY_SECS  0

typedef enum eImportState
{
    ImportState_PrivateKey,
    ImportState_EnterPassword,
    ImportState_RetryPassword,
    ImportState_Importing
} tImportState;

@interface ImportWalletViewController () <ButtonSelectorDelegate, UITextFieldDelegate, FlashSelectViewDelegate, ZBarReaderDelegate,
                                          ZBarReaderViewDelegate, UIGestureRecognizerDelegate, FadingAlertViewDelegate,
                                          DL_URLRequestDelegate, UIAlertViewDelegate>
{
    ZBarReaderView          *_readerView;
    ZBarReaderController    *_readerPicker;
    NSTimer                 *_startScannerTimer;
    NSInteger               _selectedWallet;
    BOOL                    _bUsingImagePicker;
    BOOL                    _bPasswordRequired;
    tImportState            _state;
    ImportDataModel         _dataModel;
    FadingAlertView         *_fadingAlert;
    NSString                *_sweptAddress;
    NSString                *_tweet;
    NSString                *_privateKey;
    NSString                *_sweptTXID;
    uint64_t                _sweptAmount;
    UIAlertView             *_sweptAlert;
    UIAlertView             *_tweetAlert;
    UIAlertView             *_receivedAlert;
    NSTimer                 *_callbackTimer;
}

@property (weak, nonatomic) IBOutlet UIView             *viewPassword;
@property (weak, nonatomic) IBOutlet StylizedTextField  *textPassword;
@property (weak, nonatomic) IBOutlet ButtonSelectorView *buttonSelector;
@property (weak, nonatomic) IBOutlet StylizedTextField  *textPrivateKey;
@property (weak, nonatomic) IBOutlet UIImageView        *scanFrame;
@property (weak, nonatomic) IBOutlet UIImageView        *imageFlashFrame;
@property (weak, nonatomic) IBOutlet FlashSelectView    *flashSelector;
@property (weak, nonatomic) IBOutlet UIView             *viewDisplay;
@property (weak, nonatomic) IBOutlet UIView				*qrView;
@property (weak, nonatomic) IBOutlet UIImageView        *imagePasswordEmboss;
@property (weak, nonatomic) IBOutlet UIImageView        *imageApproved;
@property (weak, nonatomic) IBOutlet UIImageView        *imageNotApproved;
@property (weak, nonatomic) IBOutlet LatoLabel          *labelPasswordStatus;

@property (nonatomic, strong) NSArray  *arrayWallets;
@property (nonatomic, copy)   NSString *strPassword;
@property (nonatomic, weak) IBOutlet UILabel *scanningErrorLabel;

@end

@implementation ImportWalletViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _readerView = nil;
    _sweptAddress = nil;
    _tweet = nil;
    _privateKey = nil;
    _sweptTXID = nil;

    // resize ourselves to fit in area
    [Util resizeView:self.view withDisplayView:self.viewDisplay];
    [Util resizeView:nil withDisplayView:self.viewPassword];

    _bUsingImagePicker = NO;
    _state = ImportState_PrivateKey;

    self.flashSelector.delegate = self;
    self.textPrivateKey.delegate = self;

	self.buttonSelector.delegate = self;
	self.buttonSelector.textLabel.text = NSLocalizedString(@"To:", nil);
    [self.buttonSelector setButtonWidth:WALLET_BUTTON_WIDTH];

    // get a callback when the private key changes
    [self.textPrivateKey addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    [self setWalletData];

    [self updateDisplayLayout];

    [self updateDisplay];

    _dataModel = kWIF;
    
    // add left to right swipe detection for going back
    [self installLeftToRightSwipeDetection];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (_bUsingImagePicker == NO)
    {
        [self performSelector:@selector(startQRReader) withObject:nil afterDelay:SCANNER_DELAY_SECS];
        //_startScannerTimer = [NSTimer scheduledTimerWithTimeInterval:SCANNER_DELAY_SECS target:self selector:@selector(startQRReader:) userInfo:nil repeats:NO];

        [self.flashSelector selectItem:FLASH_ITEM_OFF];
    }

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(tabBarButtonReselect:) name:NOTIFICATION_TAB_BAR_BUTTON_RESELECT object:nil];
    [center addObserver:self selector:@selector(sweepDoneCallback:) name:NOTIFICATION_SWEEP object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[_startScannerTimer invalidate];
	_startScannerTimer = nil;

	[self closeCameraScanner];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - Action Methods

- (IBAction)buttonBackTouched:(id)sender
{
	[self.view endEditing:YES];
    [self resignAllResponders];
    [self animatedExit];
}

- (IBAction)buttonCameraTouched:(id)sender
{
    [self resignAllResponders];
    [self showImageScanner];
}

- (IBAction)buttonInfoTouched:(id)sender
{
    [self resignAllResponders];
    [InfoView CreateWithHTML:@"infoImportWallet" forView:self.view];
}

#pragma mark - Misc Methods

- (void)updateDisplay
{
    BOOL bHideEnter = YES;

    if ((![self.textPrivateKey isFirstResponder]) && ([self.textPrivateKey.text length] == 0))
    {
        bHideEnter = NO;
    }

    if (_state == ImportState_PrivateKey)
    {
        self.viewDisplay.hidden = NO;
        self.viewPassword.hidden = YES;
    }
    else
    {
        self.viewDisplay.hidden = YES;
        self.viewPassword.hidden = NO;

        self.imageApproved.hidden = YES;
        self.imageNotApproved.hidden = YES;
        self.textPassword.hidden = YES;
        self.imagePasswordEmboss.hidden = YES;
        self.textPassword.enabled = NO;

        if (_bPasswordRequired)
        {
            self.textPassword.hidden = NO;
            self.imagePasswordEmboss.hidden = NO;
        }

        if (_state == ImportState_EnterPassword)
        {
            self.textPassword.enabled = YES;
            self.labelPasswordStatus.text = NSLocalizedString(@"Enter password to decode wallet", nil);
            self.textPassword.hidden = NO;
            self.imagePasswordEmboss.hidden = NO;
        }
        else if (_state == ImportState_RetryPassword)
        {
            self.textPassword.enabled = YES;
            self.labelPasswordStatus.text = NSLocalizedString(@"Incorrect password.\nTry again", nil);
            self.textPassword.hidden = NO;
            self.imagePasswordEmboss.hidden = NO;
            self.imageNotApproved.hidden = NO;
        }
        else if (_state == ImportState_Importing)
        {
            NSMutableString *statusMessage = [NSMutableString string];
            if (_bPasswordRequired)
            {
                [statusMessage appendString:NSLocalizedString(@"Password Correct.\n", nil)];
                self.imageApproved.hidden = NO;
            }
            [statusMessage appendString:[[NSString alloc] initWithFormat:NSLocalizedString(@"Importing funds from %@ into wallet...", nil), _sweptAddress]];
            self.labelPasswordStatus.text = [NSString stringWithString:statusMessage];
        }
    }
}

- (void)updateDisplayLayout
{
    // update for iPhone 4
    if (IS_IPHONE4 )
    {
        CGRect frame;

        // put the scan frame bottom right to the top of the flash frame
        frame = self.scanFrame.frame;
        frame.size.height = 275;
        self.scanFrame.frame = frame;
    }
 

}

- (void)requestPassword
{
    _state = ImportState_EnterPassword;
    [self updateDisplay];
    [self.textPassword becomeFirstResponder];
}

- (void)setWalletData
{
    // load all the non-archive wallets
    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
    [CoreBridge loadWallets:arrayWallets archived:nil];

    // create the array of wallet names
    NSMutableArray *arrayWalletNames = [[NSMutableArray alloc] initWithCapacity:[arrayWallets count]];
    for (int i = 0; i < [arrayWallets count]; i++)
    {
        Wallet *wallet = [arrayWallets objectAtIndex:i];
        [arrayWalletNames addObject:[NSString stringWithFormat:@"%@ (%@)", wallet.strName, [CoreBridge formatSatoshi:wallet.balance]]];

    }

    if ([arrayWallets count] > 0)
    {
        Wallet *wallet = [arrayWallets objectAtIndex:0];
        _selectedWallet = 0;
        self.buttonSelector.arrayItemsToSelect = [arrayWalletNames copy];
        [self.buttonSelector.button setTitle:wallet.strName forState:UIControlStateNormal];
        self.buttonSelector.selectedItemIndex = (int) _selectedWallet;
    }

    self.arrayWallets = arrayWallets;
}

- (void)checkEnteredPassword
{
    self.strPassword = self.textPassword.text;

    // TODO: core needs to check if password is correct
    // self.strPassword
    // for now assume it is as long as it isn't blank
    BOOL bPasswordValid = YES;
    if ([self.strPassword length] == 0)
    {
        bPasswordValid = NO;
    }

    if (bPasswordValid)
    {
        [self importWallet];
    }
    else
    {
        _state = ImportState_RetryPassword;
        [self updateDisplay];
        [self.textPassword becomeFirstResponder];
    }
}

- (void)expireImport
{
    [self showFadingError:NSLocalizedString(@"Import failed. Please check your internet connection", nil)];
    [self updateState];
}

- (void)cancelImportExpirationTimer
{
    if (_callbackTimer)
    {
        [_callbackTimer invalidate];
        _callbackTimer = nil;
    }
}

- (void)importWallet
{
    bool bSuccess = NO;

    if ([_privateKey length])
    {
        Wallet *wallet = [self.arrayWallets objectAtIndex:_selectedWallet];
        _sweptAddress = [CoreBridge sweepKey:_privateKey
                                  intoWallet:wallet.strUUID
                                withCallback:ABC_Sweep_Complete_Callback];
        if (nil != _sweptAddress && _sweptAddress.length)
        {
            bSuccess = YES;
            _state = ImportState_Importing;
            [self updateDisplay];

            _callbackTimer = [NSTimer scheduledTimerWithTimeInterval:30 * 60
                                                              target:self
                                                            selector:@selector(expireImport)
                                                            userInfo:nil
                                                             repeats:NO];
        }
        else
        {
            bSuccess = NO;
        }
    }
    
    if (NO == bSuccess)
    {
        _sweptAddress = nil;
        [self showFadingError:NSLocalizedString(@"Invalid private key", nil)];
        [self updateState];
    }
}

- (BOOL)processZBarResults:(ZBarSymbolSet *)syms
{
    BOOL bSuccess = YES;

    NSString *symbolData;
	for (ZBarSymbol *sym in syms)
	{
		symbolData = (NSString *)sym.data;
        symbolData = [symbolData stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		break; //just grab first one
	}

    if (nil != symbolData && 0 != [symbolData length])
    {
        NSRange schemeMarkerRange = [symbolData rangeOfString:@"://"];
        if (NSNotFound != schemeMarkerRange.location)
        {
            NSString *scheme = [symbolData substringWithRange:NSMakeRange(0, schemeMarkerRange.location)];
            if (nil != scheme && 0 != [scheme length])
            {
                if (NSNotFound != [scheme rangeOfString:HIDDEN_BITZ_URI_SCHEME].location)
                {
                    _dataModel = kHBURI;
                    // start the sweep
                    _privateKey = [symbolData substringFromIndex:schemeMarkerRange.location + schemeMarkerRange.length];

                    [self performSelector:@selector(importWallet)
                               withObject:nil
                               afterDelay:0.0];

                    bSuccess = YES;
                }
                else if (NSNotFound != [scheme rangeOfString:BITCOIN_URI_SCHEME].location)
                {
                    // valid bitcoin URI... we could pop up a helpful message
                    // "You've scanned an address. Would you like to send to it?"
                    // Yes | No

                    bSuccess = NO;
                }
                else
                {
                    bSuccess = NO;
                }
            }
            else
            {
                bSuccess = NO;
            }
        }
        else
        {
            // assume this must be a private key
            _dataModel = kWIF;
            _privateKey = symbolData;

            [self updateDisplay];
            
            [self performSelector:@selector(importWallet)
                       withObject:nil
                       afterDelay:0.0];
            return YES;
        }
    }
    else
    {
        bSuccess = NO;
    }

    if (!bSuccess)
    {
        [self showFadingError:NSLocalizedString(@"Invalid private key", nil)];
    }
    
    return bSuccess;
}

- (void)showImageScanner
{
#if !TARGET_IPHONE_SIMULATOR
    [self closeCameraScanner];

    _bUsingImagePicker = YES;

    _readerPicker = [ZBarReaderController new];
    _readerPicker.readerDelegate = self;
    if ([ZBarReaderController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        _readerPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    [_readerPicker.scanner setSymbology:ZBAR_I25 config:ZBAR_CFG_ENABLE to:0];
    _readerPicker.showsHelpOnFail = NO;

    [self presentViewController:_readerPicker animated:YES completion:nil];
    //[self presentModalViewController:_readerPicker animated: YES];
#endif
}

- (void)startQRReader
{
#if !TARGET_IPHONE_SIMULATOR
    if (!_readerView)
    {
        _readerView = [ZBarReaderView new];
        if ([_readerView isDeviceAvailable])
        {
            [self.scanningErrorLabel setHidden:YES];
            [self.flashSelector setHidden:NO];
        }
        else
        {
            self.scanningErrorLabel.text = NSLocalizedString(@"Camera unavailable", @"");
            [self.scanningErrorLabel setHidden:NO];
            [self.flashSelector setHidden:YES];
        }
        
        [self.qrView insertSubview:_readerView belowSubview:self.scanFrame];
        _readerView.frame = self.scanFrame.frame;
        _readerView.readerDelegate = self;
        _readerView.tracksSymbols = NO;

        _readerView.tag = READER_VIEW_TAG;

        if (self.textPrivateKey.text.length)
        {
            _readerView.alpha = 0.0;
        }

        [_readerView start];
        [self flashItemSelected:FLASH_ITEM_OFF];
    }
    else
    {
        [_readerView start];
    }
#endif
}

- (void)closeCameraScanner
{
    if (_readerView)
    {
        [_readerView stop];
        [_readerView removeFromSuperview];
        _readerView = nil;
    }
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
    return NO;
}

- (void)resignAllResponders
{
    [self.textPrivateKey resignFirstResponder];
    [self.buttonSelector resignFirstResponder];
}

- (void)animatedExit
{
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
		 [self exit];
	 }];
}

- (void)exit
{
	[self.delegate importWalletViewControllerDidFinish:self];
}

- (void)showFadingError:(NSString *)message
{
    _fadingAlert = [FadingAlertView CreateInsideView:self.view withDelegate:self];
    _fadingAlert.message = message;
    _fadingAlert.fadeDelay = ERROR_MESSAGE_FADE_DELAY;
    _fadingAlert.fadeDuration = ERROR_MESSAGE_FADE_DURATION;
    [_fadingAlert showFading];
}

- (void)dismissErrorMessage
{
    [_fadingAlert dismiss:NO];
    _fadingAlert = nil;
}

- (void)tweetCancelled
{
    [self showFadingError:NSLocalizedString(@"Import the private key again to retry Twitter", nil)];
}

- (void)showSweepDoneAlerts
{
    if (_sweptAlert)
    {
        [_sweptAlert show];
    }
    if (_receivedAlert)
    {
        [_receivedAlert show];
    }
}

- (void)updateState
{
    if (nil == _tweetAlert && nil == _sweptAlert && nil == _receivedAlert)
    {
        _state = ImportState_PrivateKey;
        [self updateDisplay];
        [self startQRReader];
    }
}

- (void)sendTweet
{
    // invoke Twitter to send tweet
    SLComposeViewController *slComposerSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    [slComposerSheet setInitialText:_tweet];
    [slComposerSheet setCompletionHandler:^(SLComposeViewControllerResult result) {
        switch (result) {
            case SLComposeViewControllerResultCancelled:
                [self tweetCancelled];
            default:
                [self updateState];
                break;
        }
    }];
    [self presentViewController:slComposerSheet animated:YES completion:nil];
}

#pragma mark - AlertView delegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (_tweetAlert == alertView)
    {
        _tweetAlert = nil;
        if (1 == buttonIndex)
        {
            [self performSelector:@selector(sendTweet)
                       withObject:nil
                       afterDelay:0.0];
        }
        else
        {
            [self tweetCancelled];
            [self updateState];
        }
    }
    else if (_sweptAlert == alertView)
    {
        _sweptAlert = nil;
        [self updateState];
    }
	else if (_receivedAlert == alertView)
	{
        if (1 == buttonIndex)
        {
            Wallet *wallet = [self.arrayWallets objectAtIndex:_selectedWallet];
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_VIEW_SWEEP_TX
                                                                object:nil
                                                              userInfo:@{KEY_TX_DETAILS_EXITED_WALLET_UUID:wallet.strUUID,
                                                                         KEY_TX_DETAILS_EXITED_TX_ID:_sweptTXID}];
        }

        _receivedAlert = nil;
        [self updateState];
	}
}

#pragma mark - FadingAlertView delegate

- (void)fadingAlertDismissed:(FadingAlertView *)view
{
    _fadingAlert = nil;
}

#pragma mark - ButtonSelectorView delegate

- (void)ButtonSelector:(ButtonSelectorView *)view selectedItem:(int)itemIndex
{
	//NSLog(@"Selected item %i", itemIndex);
    _selectedWallet = itemIndex;
}

- (void)ButtonSelectorWillShowTable:(ButtonSelectorView *)view
{
    [self.textPrivateKey resignFirstResponder];
}

#pragma mark - UITextField delegates

- (void)textFieldDidChange:(UITextField *)textField
{
    if (_state == ImportState_PrivateKey)
    {
        [self updateDisplay];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];

    if (_state == ImportState_PrivateKey && [self.textPrivateKey.text length])
    {
        [self updateDisplay];

        _dataModel = kWIF;
        _privateKey = self.textPrivateKey.text;
        [self importWallet];
    }

	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (_state == ImportState_PrivateKey)
    {
        [self.buttonSelector close];

        [self updateDisplay];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (_state == ImportState_PrivateKey)
    {
        [self updateDisplay];
    }
}

#pragma mark - DLURLServer Callbacks

- (void)onDL_URLRequestCompleteWithStatus:(tDL_URLRequestStatus)status resultData:(NSData *)data resultObj:(id)object
{
    bool bSuccess = NO;

    if (nil == _tweetAlert)
    {
        NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];

        NSError *myError;
        NSDictionary *dict = [[CJSONDeserializer deserializer] deserializeAsDictionary:jsonData error:&myError];
        if (dict)
        {
            NSString *token = [dict objectForKey:@"token"];
            _tweet = [dict objectForKey:@"tweet"];
            if (token && _tweet)
            {
                if (0 == _sweptAmount)
                {
                    NSString *zmessage = [dict objectForKey:@"zero_message"];
                    if (zmessage)
                    {
                        _tweetAlert = [[UIAlertView alloc]
                                       initWithTitle:NSLocalizedString(@"Sorry", nil)
                                       message:zmessage
                                       delegate:self
                                       cancelButtonTitle:@"No"
                                       otherButtonTitles:@"OK", nil];
                        [_tweetAlert show];
                        bSuccess = YES;
                    }
                }
                else
                {
                    NSString *message = [dict objectForKey:@"message"];
                    if (message)
                    {
                        _tweetAlert = [[UIAlertView alloc]
                                       initWithTitle:NSLocalizedString(@"Congratulations", nil)
                                       message:message
                                       delegate:self
                                       cancelButtonTitle:@"No"
                                       otherButtonTitles:@"OK", nil];
                        [_tweetAlert show];
                        bSuccess = YES;
                    }
                }
            }
        }
    }
}

#pragma mark - Flash Select Delegates

-(void)flashItemSelected:(tFlashItem)flashType
{
	//NSLog(@"Flash Item Selected: %i", flashType);
	AVCaptureDevice *device = _readerView.device;
	if (device)
	{
		switch (flashType)
		{
            case FLASH_ITEM_OFF:
                if ([device isTorchModeSupported:AVCaptureTorchModeOff])
                {
                    NSError *error = nil;
                    if ([device lockForConfiguration:&error])
                    {
                        device.torchMode = AVCaptureTorchModeOff;
                        [device unlockForConfiguration];
                    }
                }
                break;
            case FLASH_ITEM_ON:
                if ([device isTorchModeSupported:AVCaptureTorchModeOn])
                {
                    NSError *error = nil;
                    if ([device lockForConfiguration:&error])
                    {
                        device.torchMode = AVCaptureTorchModeOn;
                        [device unlockForConfiguration];
                    }
                }
                break;
		}
	}
}

#pragma mark - ZBar's Delegate methods

#if !TARGET_IPHONE_SIMULATOR

- (void)readerView:(ZBarReaderView *)view didReadSymbols:(ZBarSymbolSet *)syms fromImage:(UIImage *)img
{
    if ([self processZBarResults:syms])
    {
        [view stop];
    }
    else
    {
        [view start];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)reader
{
    [reader dismissViewControllerAnimated:YES completion:nil];
    _bUsingImagePicker = NO;

    [self startQRReader];
}

- (void)imagePickerController:(UIImagePickerController *)reader didFinishPickingMediaWithInfo:(NSDictionary*) info
{
    id<NSFastEnumeration> results = [info objectForKey:ZBarReaderControllerResults];

    BOOL bSuccess = [self processZBarResults:(ZBarSymbolSet *)results];

    [reader dismissViewControllerAnimated:YES completion:nil];
    _bUsingImagePicker = NO;

    if (!bSuccess)
    {
        [self startQRReader];
    }
}

- (void)readerControllerDidFailToRead:(ZBarReaderController*)reader
                             withRetry:(BOOL)retry
{
    _privateKey = @"";
    [reader dismissViewControllerAnimated:YES completion:nil];

    [self showFadingError:NSLocalizedString(@"Unable to scan QR code", nil)];

    _bUsingImagePicker = NO;
    [self startQRReader];
}

#endif


#pragma mark - GestureReconizer methods

- (void)didSwipeLeftToRight:(UIGestureRecognizer *)gestureRecognizer
{
    if (![self haveSubViewsShowing])
    {
        [self buttonBackTouched:nil];
    }
}

#pragma mark - Custom Notification Handlers

// called when a tab bar button that is already selected, is reselected again
- (void)tabBarButtonReselect:(NSNotification *)notification
{
    if (![self haveSubViewsShowing])
    {
        [self buttonBackTouched:nil];
    }
}

- (void)sweepDoneCallback:(NSNotification *)notification
{
    [self cancelImportExpirationTimer];

    NSDictionary *userInfo = [notification userInfo];
    tABC_CC result = [[userInfo objectForKey:KEY_SWEEP_CORE_CONDITION_CODE] intValue];
    uint64_t amount = [[userInfo objectForKey:KEY_SWEEP_TX_AMOUNT] unsignedLongLongValue];
    if (nil == _sweptAlert && nil == _receivedAlert)
    {
        _sweptAmount = amount;

        if (ABC_CC_Ok == result)
        {
            if (kHBURI == _dataModel)
            {
                // make a query with the last bytes of the address
                const int hBitzIDLength = 4;
                if (nil != _sweptAddress && hBitzIDLength <= _sweptAddress.length)
                {
                    NSString *hiddenBitzID = [_sweptAddress substringFromIndex:[_sweptAddress length]-hBitzIDLength];
                    NSString *hiddenBitzURI = [NSString stringWithFormat:@"%@%@%@", SERVER_API, @"/hiddenbits/", hiddenBitzID];
                    [[DL_URLServer controller] issueRequestURL:hiddenBitzURI
                                                    withParams:nil
                                                    withObject:self
                                                  withDelegate:self
                                            acceptableCacheAge:CACHE_24_HOURS
                                                   cacheResult:YES];
                }
            }

            if (0 < amount)
            {
                // handle received bitcoin
                _sweptTXID = [userInfo objectForKey:KEY_SWEEP_TX_ID];
                if (_sweptTXID && [_sweptTXID length])
                {
                    _receivedAlert = [[UIAlertView alloc]
                                      initWithTitle:NSLocalizedString(@"Received Funds", nil)
                                      message:NSLocalizedString(@"Bitcoin received. Tap for details.", nil)
                                      delegate:self
                                      cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                                      otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
                }
                else
                {
                    _sweptTXID = nil;
                }
            }
            else
            {
                NSString *message = NSLocalizedString(@"Failed to import because there is 0 bitcoin remaining at this address", nil);
                _sweptAlert = [[UIAlertView alloc]
                               initWithTitle:NSLocalizedString(@"Error", nil)
                               message:message
                               delegate:self
                               cancelButtonTitle:@"OK"
                               otherButtonTitles:nil, nil];
            }
        }
        else
        {
            tABC_Error temp;
            temp.code = result;
            NSString *message = [Util errorMap:&temp];
            _sweptAlert = [[UIAlertView alloc]
                           initWithTitle:NSLocalizedString(@"Error", nil)
                           message:message
                           delegate:self
                           cancelButtonTitle:@"OK"
                           otherButtonTitles:nil, nil];
        }

        [self performSelectorOnMainThread:@selector(showSweepDoneAlerts)
                               withObject:nil
                            waitUntilDone:NO];
    }
}

@end
//
//  SendViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "SendViewController.h"
#import "Notifications.h"
#import "ABC.h"
#import "SendConfirmationViewController.h"
#import "FlashSelectView.h"
#import "User.h"
#import "ButtonSelectorView.h"
#import "CommonTypes.h"
#import "Util.h"
#import "InfoView.h"
#import "ZBarSDK.h"
#import "CoreBridge.h"
#import "SyncView.h"

#define WALLET_BUTTON_WIDTH         210

#define POPUP_PICKER_LOWEST_POINT   360
#define POPUP_PICKER_TABLE_HEIGHT   (IS_IPHONE5 ? 180 : 90)

@interface SendViewController () <SendConfirmationViewControllerDelegate, FlashSelectViewDelegate, UITextFieldDelegate, ButtonSelectorDelegate, ZBarReaderDelegate, ZBarReaderViewDelegate, PickerTextViewDelegate, SyncViewDelegate>
{
	ZBarReaderView                  *_readerView;
    ZBarReaderController            *_readerPicker;
	NSTimer                         *_startScannerTimer;
	int                             _selectedWalletIndex;
	SendConfirmationViewController  *_sendConfirmationViewController;
    BOOL                            _bUsingImagePicker;
	SyncView                        *_syncingView;
}
@property (weak, nonatomic) IBOutlet UIImageView            *scanFrame;
@property (weak, nonatomic) IBOutlet FlashSelectView        *flashSelector;
@property (nonatomic, weak) IBOutlet ButtonSelectorView     *buttonSelector;
@property (weak, nonatomic) IBOutlet UIImageView            *imageTopFrame;
@property (weak, nonatomic) IBOutlet UILabel                *labelSendTo;
@property (weak, nonatomic) IBOutlet UIImageView            *imageSendTo;
@property (weak, nonatomic) IBOutlet UIImageView            *imageFlashFrame;

@property (nonatomic, strong) NSArray   *arrayWallets;
@property (nonatomic, strong) NSArray   *arrayWalletNames;
@property (nonatomic, strong) NSArray   *arrayChoicesIndexes;

@end

@implementation SendViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
	{
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

    // resize ourselves to fit in area
    [Util resizeView:self.view withDisplayView:nil];

    [self updateDisplayLayout];

    _bUsingImagePicker = NO;
	
	self.flashSelector.delegate = self;
	self.buttonSelector.delegate = self;

    // set up the specifics on our picker text view
    self.pickerTextSendTo.textField.borderStyle = UITextBorderStyleNone;
    self.pickerTextSendTo.textField.backgroundColor = [UIColor clearColor];
    self.pickerTextSendTo.textField.font = [UIFont systemFontOfSize:14];
    self.pickerTextSendTo.textField.clearButtonMode = UITextFieldViewModeNever;
    self.pickerTextSendTo.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.pickerTextSendTo.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.pickerTextSendTo.textField.spellCheckingType = UITextSpellCheckingTypeNo;
    self.pickerTextSendTo.textField.textColor = [UIColor whiteColor];
    self.pickerTextSendTo.textField.returnKeyType = UIReturnKeyDone;
    self.pickerTextSendTo.textField.tintColor = [UIColor whiteColor];
    self.pickerTextSendTo.textField.textAlignment = NSTextAlignmentCenter;
    self.pickerTextSendTo.textField.placeholder = NSLocalizedString(@"Bitcoin address or wallet", nil);
    self.pickerTextSendTo.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.pickerTextSendTo.textField.placeholder
                                                                                            attributes:@{NSForegroundColorAttributeName: [UIColor lightTextColor]}];
    [self.pickerTextSendTo setTopMostView:self.view];
    //self.pickerTextSendTo.pickerMaxChoicesVisible = PICKER_MAX_CELLS_VISIBLE;
    self.pickerTextSendTo.cropPointBottom = POPUP_PICKER_LOWEST_POINT;
    self.pickerTextSendTo.delegate = self;

	self.buttonSelector.textLabel.text = NSLocalizedString(@"From:", @"From: text on Send Bitcoin screen");
    [self.buttonSelector setButtonWidth:WALLET_BUTTON_WIDTH];

    _selectedWalletIndex = 0;
}

- (void)viewWillAppear:(BOOL)animated
{
	[self loadWalletInfo];
    if (_bUsingImagePicker == NO)
    {
        _startScannerTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(startCameraScanner:) userInfo:nil repeats:NO];

        [self.flashSelector selectItem:FLASH_ITEM_OFF];
    }
    [self syncTest];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[_startScannerTimer invalidate];
	_startScannerTimer = nil;

	[self closeCameraScanner];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)resetViews
{
    if (_sendConfirmationViewController)
    {
        [_sendConfirmationViewController.view removeFromSuperview];
        _sendConfirmationViewController = nil;
    }
}

#pragma mark - Action Methods

- (IBAction)info
{
	[self.view endEditing:YES];
    [self resignAllResonders];
    [InfoView CreateWithHTML:@"infoSend" forView:self.view];
}

- (IBAction)buttonCameraTouched:(id)sender
{
    [self resignAllResonders];
    [self showImageScanner];
}

#pragma mark - Misc Methods

- (void)resignAllResonders
{
    [self.pickerTextSendTo.textField resignFirstResponder];
}

- (void)updateDisplayLayout
{
    // if we are on a smaller screen
    if (!IS_IPHONE5)
    {
        // be prepared! lots and lots of magic numbers here to jam the controls to fit on a small screen

        CGRect frame;

        /*
        // put the flash view at the bottom
        frame = self.imageFlashFrame.frame;
        frame.size.height = 60;
        frame.origin.y = self.view.frame.size.height - frame.size.height + 0.0;
        self.imageFlashFrame.frame = frame;

        frame = self.flashSelector.frame;
        frame.origin.y = self.imageFlashFrame.frame.origin.y + 8.0;
        frame.size.height = 48.0;
        self.flashSelector.frame = frame;
*/
        // put the scan frame bottom right to the top of the flash frame
        frame = self.scanFrame.frame;
        frame.size.height = 275;
        self.scanFrame.frame = frame;
    }
}

- (void)loadWalletInfo
{
    // load all the non-archive wallets
    NSMutableArray *arrayWallets = [[NSMutableArray alloc] init];
    [CoreBridge loadWallets:arrayWallets archived:nil];

    // create the arrays of wallet info
    _selectedWalletIndex = 0;
    NSMutableArray *arrayWalletNames = [[NSMutableArray alloc] initWithCapacity:[arrayWallets count]];
    for (int i = 0; i < [arrayWallets count]; i++)
    {
        Wallet *wallet = [arrayWallets objectAtIndex:i];
        [arrayWalletNames addObject:[NSString stringWithFormat:@"%@ (%@)", wallet.strName, [CoreBridge formatSatoshi:wallet.balance]]];
        
        if ([_walletUUID isEqualToString: wallet.strUUID])
            _selectedWalletIndex = i;
    }
    
    if (_selectedWalletIndex < [arrayWallets count])
    {
        Wallet *wallet = [arrayWallets objectAtIndex:_selectedWalletIndex];
        
        self.buttonSelector.arrayItemsToSelect = [arrayWalletNames copy];
        [self.buttonSelector.button setTitle:wallet.strName forState:UIControlStateNormal];
        self.buttonSelector.selectedItemIndex = (int) _selectedWalletIndex;
    }
    self.arrayWallets = arrayWallets;
    self.arrayWalletNames = arrayWalletNames;
}

// if bToIsUUID NO, then it is assumed the strTo is an address
- (void)showSendConfirmationTo:(NSString *)strTo amount:(long long)amount nameLabel:(NSString *)nameLabel toIsUUID:(BOOL)bToIsUUID
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	_sendConfirmationViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SendConfirmationViewController"];

	_sendConfirmationViewController.delegate = self;
	_sendConfirmationViewController.sendToAddress = strTo;
    _sendConfirmationViewController.bAddressIsWalletUUID = bToIsUUID;
	_sendConfirmationViewController.amountToSendSatoshi = amount;
    _sendConfirmationViewController.wallet = [self.arrayWallets objectAtIndex:_selectedWalletIndex];
    if (bToIsUUID)
    {
        Wallet *destWallet = [CoreBridge getWallet:strTo];
        _sendConfirmationViewController.destWallet = destWallet;
        _sendConfirmationViewController.sendToAddress = destWallet.strName;
    }
	_sendConfirmationViewController.selectedWalletIndex = _selectedWalletIndex;
	_sendConfirmationViewController.nameLabel = nameLabel;

    NSLog(@"Sending to: %@, isUUID: %@, wallet: %@", _sendConfirmationViewController.sendToAddress, (_sendConfirmationViewController.bAddressIsWalletUUID ? @"YES" : @"NO"), _sendConfirmationViewController.wallet.strName);
	
	CGRect frame = self.view.bounds;
	frame.origin.x = frame.size.width;
	_sendConfirmationViewController.view.frame = frame;
	[self.view addSubview:_sendConfirmationViewController.view];
	
	
	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 _sendConfirmationViewController.view.frame = self.view.bounds;
	 }
	 completion:^(BOOL finished)
	 {
	 }];
}

- (BOOL)processZBarResults:(ZBarSymbolSet *)syms
{
    BOOL bSuccess = YES;

	for(ZBarSymbol *sym in syms)
	{
		NSString *text = (NSString *)sym.data;

		tABC_Error Error;
		tABC_BitcoinURIInfo *uri;
		ABC_ParseBitcoinURI([text UTF8String], &uri, &Error);
		[Util printABC_Error:&Error];

		if (uri != NULL)
		{
			if (uri->szAddress)
			{
				printf("    address: %s\n", uri->szAddress);

				printf("    amount: %lld\n", uri->amountSatoshi);

				NSString *label;
				if (uri->szLabel)
				{
					printf("    label: %s\n", uri->szLabel);
					label = [NSString stringWithUTF8String:uri->szLabel];
				}
				else
				{
					label = @"";
				}
				if (uri->szMessage)
				{
                    printf("    message: %s\n", uri->szMessage);
				}
                bSuccess = YES;
                [self showSendConfirmationTo:[NSString stringWithUTF8String:uri->szAddress] amount:uri->amountSatoshi nameLabel:label toIsUUID:NO];
			}
			else
			{
				printf("No address!");
                bSuccess = NO;
			}
		}
		else
		{
			printf("URI parse failed!");
            bSuccess = NO;
		}

        if (!bSuccess)
        {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"Invalid Bitcoin Address", nil)
                                  message:NSLocalizedString(@"", nil)
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alert show];
        }

		ABC_FreeURIInfo(uri);
        
		break; //just grab first one
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

- (void)startCameraScanner:(NSTimer *)timer
{
    [self closeCameraScanner];

#if !TARGET_IPHONE_SIMULATOR
    // NSLog(@"Scanning...");

	_readerView = [ZBarReaderView new];
	[self.view insertSubview:_readerView belowSubview:self.scanFrame];
	_readerView.frame = self.scanFrame.frame;
	_readerView.readerDelegate = self;
	_readerView.tracksSymbols = NO;

	_readerView.tag = 99999999;
	if ([self.pickerTextSendTo.textField.text length])
	{
		_readerView.alpha = 0.0;
	}
	[_readerView start];
	[self flashItemSelected:FLASH_ITEM_OFF];
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

- (NSArray *)createNewSendToChoices:(NSString *)strCur
{
    BOOL bUseAll = YES;

    if (strCur)
    {
        if ([strCur length])
        {
            bUseAll = NO;
        }
    }

    NSMutableArray *arrayChoices = [[NSMutableArray alloc] init];
    NSMutableArray *arrayChoicesIndexes = [[NSMutableArray alloc] init];

    for (int i = 0; i < [self.arrayWallets count]; i++)
    {
        // if this is not our currently selected wallet in the wallet selector
        // in other words, we can move funds from and to the same wallet
        if (_selectedWalletIndex != i)
        {
            Wallet *wallet = [self.arrayWallets objectAtIndex:i];

            BOOL bAddIt = bUseAll;
            if (!bAddIt)
            {
                // if we can find our current string within this wallet name
                if ([wallet.strName rangeOfString:strCur options:NSCaseInsensitiveSearch].location != NSNotFound)
                {
                    bAddIt = YES;
                }
            }

            if (bAddIt)
            {
                [arrayChoices addObject:[NSString stringWithFormat:@"%@ (%@)", wallet.strName, [CoreBridge formatSatoshi:wallet.balance]]];
                [arrayChoicesIndexes addObject:[NSNumber numberWithInt:i]];
            }
        }
    }

    self.arrayChoicesIndexes = arrayChoicesIndexes;

    return arrayChoices;
}

#pragma mark - Flash Select Delegates

- (void)flashItemSelected:(tFlashItem)flashType
{
	//NSLog(@"Flash Item Selected: %i", flashType);
	AVCaptureDevice *device = _readerView.device;
	if(device)
	{
		switch(flashType)
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

#pragma mark - SendConfirmationViewController Delegates

- (void)sendConfirmationViewControllerDidFinish:(SendConfirmationViewController *)controller
{
    [self loadWalletInfo];
	self.pickerTextSendTo.textField.text = @"";
    [self startCameraScanner:nil];
	[_sendConfirmationViewController.view removeFromSuperview];
	_sendConfirmationViewController = nil;
}

#pragma mark - ButtonSelectorView delegates

- (void)ButtonSelector:(ButtonSelectorView *)view selectedItem:(int)itemIndex
{
    _selectedWalletIndex = itemIndex;
    Wallet *wallet = [self.arrayWallets objectAtIndex:_selectedWalletIndex];
    [self.buttonSelector.button setTitle:wallet.strName forState:UIControlStateNormal];
    self.buttonSelector.selectedItemIndex = _selectedWalletIndex;
    _walletUUID = wallet.strUUID;
}

- (void)ButtonSelectorWillShowTable:(ButtonSelectorView *)view
{
    [self resignAllResonders];
}

- (void)ButtonSelectorWillHideTable:(ButtonSelectorView *)view
{

}

#pragma mark - ZBar's Delegate methods

- (void)readerView: (ZBarReaderView*) view didReadSymbols: (ZBarSymbolSet*) syms fromImage: (UIImage*) img
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

#if !TARGET_IPHONE_SIMULATOR

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)reader
{
    [reader dismissViewControllerAnimated:YES completion:nil];
    _bUsingImagePicker = NO;
    _startScannerTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(startCameraScanner:) userInfo:nil repeats:NO];
}

- (void)imagePickerController:(UIImagePickerController *)reader didFinishPickingMediaWithInfo:(NSDictionary*) info
{
    id<NSFastEnumeration> results = [info objectForKey:ZBarReaderControllerResults];
    //UIImage *image = [info objectForKey: UIImagePickerControllerOriginalImage];

    BOOL bSuccess = [self processZBarResults:(ZBarSymbolSet *)results];

    [reader dismissViewControllerAnimated:YES completion:nil];
    //[[controller presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    //[reader dismissModalViewControllerAnimated: YES];

    _bUsingImagePicker = NO;

    if (!bSuccess)
    {
        _startScannerTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(startCameraScanner:) userInfo:nil repeats:NO];
    }
}

- (void)readerControllerDidFailToRead:(ZBarReaderController*)reader
                            withRetry:(BOOL)retry
{
    [reader dismissViewControllerAnimated:YES completion:nil];

    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"QR Code Scan Failure", nil)
                          message:NSLocalizedString(@"Unable to scan QR code", nil)
                          delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    [alert show];

    _bUsingImagePicker = NO;
    _startScannerTimer = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(startCameraScanner:) userInfo:nil repeats:NO];
}

#endif

#pragma mark - PickerTextView Delegates

- (void)pickerTextViewFieldDidChange:(PickerTextView *)pickerTextView
{
    NSArray *arrayChoices = [self createNewSendToChoices:pickerTextView.textField.text];

    [pickerTextView updateChoices:arrayChoices];
}

- (void)pickerTextViewFieldDidBeginEditing:(PickerTextView *)pickerTextView
{
    NSArray *arrayChoices = [self createNewSendToChoices:pickerTextView.textField.text];

    [pickerTextView updateChoices:arrayChoices];
}

- (BOOL)pickerTextViewShouldEndEditing:(PickerTextView *)pickerTextView
{
    // unhighlight text
    // note: for some reason, if we don't do this, the text won't select next time the user selects it
    [pickerTextView.textField setSelectedTextRange:[pickerTextView.textField textRangeFromPosition:pickerTextView.textField.beginningOfDocument toPosition:pickerTextView.textField.beginningOfDocument]];

    return YES;
}

- (void)pickerTextViewFieldDidEndEditing:(PickerTextView *)pickerTextView
{
    //[self forceCategoryFieldValue:pickerTextView.textField forPickerView:pickerTextView];
}

- (BOOL)pickerTextViewFieldShouldReturn:(PickerTextView *)pickerTextView
{
	[pickerTextView.textField resignFirstResponder];
    [self processURI];
    return YES;
}

- (void)processURI
{
    BOOL bSuccess = YES;
    tABC_BitcoinURIInfo *uri = NULL;

    if (_pickerTextSendTo.textField.text.length)
	{
        BOOL bIsUUID = NO;
        
        
        NSString *label;
        NSString *strTo = _pickerTextSendTo.textField.text;

        // see if the text corresponds to one of the wallets
        NSInteger index = [self.arrayWalletNames indexOfObject:_pickerTextSendTo.textField.text];
        if (index != NSNotFound)
        {
            bIsUUID = YES;
            Wallet *wallet = [self.arrayWallets objectAtIndex:index];
            //NSLog(@"using UUID for wallet: %@", wallet.strName);
            strTo = wallet.strUUID;

            [self closeCameraScanner];
            [self showSendConfirmationTo:strTo amount:0.0 nameLabel:@" " toIsUUID:bIsUUID];

        }
        else
        {
            tABC_Error Error;
            ABC_ParseBitcoinURI([strTo UTF8String], &uri, &Error);
            [Util printABC_Error:&Error];
            
            if (uri != NULL)
            {
                if (uri->szAddress)
                {
                    printf("    address: %s\n", uri->szAddress);
                    
                    printf("    amount: %lld\n", uri->amountSatoshi);
                    
                    if (uri->szLabel)
                    {
                        printf("    label: %s\n", uri->szLabel);
                        label = [NSString stringWithUTF8String:uri->szLabel];
                    }
                    else
                    {
                        label = NSLocalizedString(@"", nil);
                    }
                    if (uri->szMessage)
                    {
                        printf("    message: %s\n", uri->szMessage);
                    }
                }
                else
                {
                    printf("No address!");
                    bSuccess = NO;
                }
            }
            else
            {
                printf("URI parse failed!");
                bSuccess = NO;
            }
            
        }

        if (!bSuccess)
        {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:NSLocalizedString(@"Invalid Bitcoin Address", nil)
                                  message:NSLocalizedString(@"", nil)
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            [self closeCameraScanner];
            [self showSendConfirmationTo:[NSString stringWithUTF8String:uri->szAddress] amount:uri->amountSatoshi nameLabel:label toIsUUID:NO];
            
        }
	}

    if (uri)
    {
        ABC_FreeURIInfo(uri);
    }
}

- (void)pickerTextViewPopupSelected:(PickerTextView *)pickerTextView onRow:(NSInteger)row
{
    // set the text field to the choice
    NSInteger index = [[self.arrayChoicesIndexes objectAtIndex:row] integerValue];
    Wallet *wallet = [self.arrayWallets objectAtIndex:index];
    pickerTextView.textField.text = wallet.strName;
	[pickerTextView.textField resignFirstResponder];

    if (pickerTextView.textField.text.length)
	{
        [self closeCameraScanner];
        //NSLog(@"using UUID for wallet: %@", wallet.strName);
		[self showSendConfirmationTo:wallet.strUUID amount:0.0 nameLabel:@" " toIsUUID:YES];
	}
}

- (void)pickerTextViewFieldDidShowPopup:(PickerTextView *)pickerTextView
{
    // forces the size of the popup picker on the picker text view to a certain size

    // Note: we have to do this because right now the size will start as max needed but as we dynamically
    //       alter the choices, we may end up with more choices than we originally started with
    //       so we want the table to always be as large as it can be

    // first start the popup pickerit right under the control and squished down
    CGRect frame = pickerTextView.popupPicker.frame;
    frame.size.height = POPUP_PICKER_TABLE_HEIGHT;
    pickerTextView.popupPicker.frame = frame;
}

#pragma - Sync View methods

- (void)SyncViewDismissed:(SyncView *)sv
{
    [_syncingView removeFromSuperview];
    _syncingView = nil;
}

- (void)syncTest
{
    Wallet *wallet = [self.arrayWallets objectAtIndex:_selectedWalletIndex];
    if (![CoreBridge watcherIsReady:wallet.strUUID] && !_syncingView)
    {
        _syncingView = [SyncView createView:self.view forWallet:wallet.strUUID];
        _syncingView.delegate = self;
    }
    if (_syncingView)
    {
        [self resignAllResonders];
    }
}


@end

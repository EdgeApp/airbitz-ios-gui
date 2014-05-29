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
#import "PickerTextView.h"

#define WALLET_BUTTON_WIDTH         193

#define POPUP_PICKER_LOWEST_POINT   360
#define POPUP_PICKER_TABLE_HEIGHT   (IS_IPHONE5 ? 180 : 90)

@interface SendViewController () <SendConfirmationViewControllerDelegate, FlashSelectViewDelegate, UITextFieldDelegate, ButtonSelectorDelegate, ZBarReaderDelegate, ZBarReaderViewDelegate, PickerTextViewDelegate>
{
	ZBarReaderView                  *_readerView;
    ZBarReaderController            *_readerPicker;
	NSTimer                         *_startScannerTimer;
	int                             _selectedWalletIndex;
	NSString                        *_selectedWalletUUID;
	SendConfirmationViewController  *_sendConfirmationViewController;
    BOOL                            _bUsingImagePicker;
}
@property (weak, nonatomic) IBOutlet UIImageView            *scanFrame;
@property (weak, nonatomic) IBOutlet FlashSelectView        *flashSelector;
@property (weak, nonatomic) IBOutlet PickerTextView         *pickerTextSendTo;
@property (nonatomic, weak) IBOutlet ButtonSelectorView     *buttonSelector;
@property (weak, nonatomic) IBOutlet UIImageView            *imageTopFrame;
@property (weak, nonatomic) IBOutlet UILabel                *labelSendTo;
@property (weak, nonatomic) IBOutlet UIImageView            *imageSendTo;
@property (weak, nonatomic) IBOutlet UIImageView            *imageFlashFrame;
@property (weak, nonatomic) IBOutlet UIView                 *viewMiddle;

@property (nonatomic, strong) NSArray   *arrayWallets;

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
    self.pickerTextSendTo.textField.clearButtonMode = UITextFieldViewModeAlways;
    self.pickerTextSendTo.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.pickerTextSendTo.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.pickerTextSendTo.textField.spellCheckingType = UITextSpellCheckingTypeNo;
    self.pickerTextSendTo.textField.textColor = [UIColor whiteColor];
    self.pickerTextSendTo.textField.returnKeyType = UIReturnKeyDone;
    self.pickerTextSendTo.textField.placeholder = NSLocalizedString(@"Bitcoin address or wallet", nil);
    [self.pickerTextSendTo setTopMostView:self.view];
    //self.pickerTextSendTo.pickerMaxChoicesVisible = PICKER_MAX_CELLS_VISIBLE;
    self.pickerTextSendTo.cropPointBottom = POPUP_PICKER_LOWEST_POINT;
    self.pickerTextSendTo.delegate = self;

	self.buttonSelector.textLabel.text = @"";
    [self.buttonSelector setButtonWidth:WALLET_BUTTON_WIDTH];

	[self setWalletButtonTitle];
}

- (void)viewWillAppear:(BOOL)animated
{
	//NSLog(@"Starting timer");

    if (_bUsingImagePicker == NO)
    {
        _startScannerTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(startCameraScanner:) userInfo:nil repeats:NO];

        [self.flashSelector selectItem:FLASH_ITEM_AUTO];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
	//NSLog(@"Invalidating timer");
	[_startScannerTimer invalidate];
	_startScannerTimer = nil;

	[self closeCameraScanner];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

        // put the flash view at the bottom
        frame = self.imageFlashFrame.frame;
        frame.size.height = 60;
        frame.origin.y = self.view.frame.size.height - frame.size.height + 0.0;
        self.imageFlashFrame.frame = frame;

        frame = self.flashSelector.frame;
        frame.origin.y = self.imageFlashFrame.frame.origin.y + 8.0;
        frame.size.height = 48.0;
        self.flashSelector.frame = frame;

        // put the scan frame bottom right to the top of the flash frame
        frame = self.scanFrame.frame;
        frame.size.height = self.imageFlashFrame.frame.origin.y - self.scanFrame.frame.origin.y + 0.0;
        self.scanFrame.frame = frame;
    }
}

- (void)setWalletButtonTitle
{
	tABC_WalletInfo **aWalletInfo = NULL;
    unsigned int nCount;
	tABC_Error Error;
    ABC_GetWallets([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], &aWalletInfo, &nCount, &Error);
    [Util printABC_Error:&Error];
	
    //printf("Wallets:\n");
	
	if (nCount)
	{
		tABC_WalletInfo *info = aWalletInfo[_selectedWalletIndex];
		
		_selectedWalletUUID = [NSString stringWithUTF8String:info->szUUID];
		[self.buttonSelector.button setTitle:[NSString stringWithUTF8String:info->szName] forState:UIControlStateNormal];
		self.buttonSelector.selectedItemIndex = _selectedWalletIndex;
	}
	
    // assign list of wallets to buttonSelector
	NSMutableArray *walletsArray = [[NSMutableArray alloc] init];
	
    for (int i = 0; i < nCount; i++)
    {
        tABC_WalletInfo *pInfo = aWalletInfo[i];
		[walletsArray addObject:[NSString stringWithUTF8String:pInfo->szName]];
    }
	
	self.buttonSelector.arrayItemsToSelect = [walletsArray copy];
    self.arrayWallets = walletsArray;
    ABC_FreeWalletInfoArray(aWalletInfo, nCount);
}

- (void)showSendConfirmationWithAddress:(NSString *)address amount:(long long)amount nameLabel:(NSString *)nameLabel
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	_sendConfirmationViewController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SendConfirmationViewController"];
	
	_sendConfirmationViewController.delegate = self;
	_sendConfirmationViewController.sendToAddress = address;
	_sendConfirmationViewController.amountToSendSatoshi = amount;
	_sendConfirmationViewController.selectedWalletIndex = self.buttonSelector.selectedItemIndex;
	_sendConfirmationViewController.nameLabel = nameLabel;
	
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
					label = NSLocalizedString(@"Anonymous", nil);
				}
				if (uri->szMessage)
				{
                    printf("    message: %s\n", uri->szMessage);
				}
                    bSuccess = YES;
                    [self showSendConfirmationWithAddress:[NSString stringWithUTF8String:uri->szAddress] amount:uri->amountSatoshi nameLabel:label];
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
	[self flashItemSelected:FLASH_ITEM_AUTO];
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

    if (bUseAll)
    {
        [arrayChoices addObjectsFromArray:self.arrayWallets];
    }
    else
    {
        for (NSString *strCurWallet in self.arrayWallets)
        {
            // if it is in there or we are adding all
            if ([strCurWallet rangeOfString:strCur options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                [arrayChoices addObject:strCurWallet];
            }

        }
    }

    // remove our currently selected wallet
    NSString *strCurWallet = [self.arrayWallets objectAtIndex:_selectedWalletIndex];
    NSInteger indexOfCurWalletInChoices = [arrayChoices indexOfObject:strCurWallet];
    if (indexOfCurWalletInChoices != NSNotFound)
    {
        [arrayChoices removeObjectAtIndex:indexOfCurWalletInChoices];
    }

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
				case FLASH_ITEM_AUTO:
					if ([device isTorchModeSupported:AVCaptureTorchModeAuto])
					{
						NSError *error = nil;
						if ([device lockForConfiguration:&error])
						{
							device.torchMode = AVCaptureTorchModeAuto;
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
	self.pickerTextSendTo.textField.text = nil;
    [self startCameraScanner:nil];
	[_sendConfirmationViewController.view removeFromSuperview];
	_sendConfirmationViewController = nil;
}

#pragma mark - ButtonSelectorView delegates

- (void)ButtonSelector:(ButtonSelectorView *)view selectedItem:(int)itemIndex
{
    _selectedWalletIndex = itemIndex;
    [self setWalletButtonTitle];
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

    if (pickerTextView.textField.text.length)
	{
        [self closeCameraScanner];
		[self showSendConfirmationWithAddress:pickerTextView.textField.text amount:0.0 nameLabel:@" "];
	}

	return YES;
}

- (void)pickerTextViewPopupSelected:(PickerTextView *)pickerTextView onRow:(NSInteger)row
{
    // set the text field to the choice
    pickerTextView.textField.text = [pickerTextView.arrayChoices objectAtIndex:row];
	[pickerTextView.textField resignFirstResponder];

    if (pickerTextView.textField.text.length)
	{
        [self closeCameraScanner];
		[self showSendConfirmationWithAddress:pickerTextView.textField.text amount:0.0 nameLabel:@" "];
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

@end

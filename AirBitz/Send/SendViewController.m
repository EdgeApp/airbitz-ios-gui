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

@interface SendViewController () <SendConfirmationViewControllerDelegate, FlashSelectViewDelegate, UITextFieldDelegate, ButtonSelectorDelegate, ZBarReaderDelegate, ZBarReaderViewDelegate>
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
@property (nonatomic, weak) IBOutlet UITextField            *sendToTextField;
@property (nonatomic, weak) IBOutlet ButtonSelectorView     *buttonSelector;
@property (weak, nonatomic) IBOutlet UIImageView            *imageTopFrame;
@property (weak, nonatomic) IBOutlet UILabel                *labelSendTo;
@property (weak, nonatomic) IBOutlet UIImageView            *imageSendTo;
@property (weak, nonatomic) IBOutlet UIImageView            *imageFlashFrame;
@property (weak, nonatomic) IBOutlet UIView                 *viewMiddle;

@property (nonatomic, strong) UIButton  *buttonBlocker;

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
	self.sendToTextField.delegate = self;
	self.buttonSelector.delegate = self;

    // set up our user blocking button
    self.buttonBlocker = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonBlocker.backgroundColor = [UIColor clearColor];
    [self.buttonBlocker addTarget:self action:@selector(buttonBlockerTouched:) forControlEvents:UIControlEventTouchUpInside];
    self.buttonBlocker.frame = self.view.bounds;
    self.buttonBlocker.hidden = YES;
    [self.view addSubview:self.buttonBlocker];
    [self.view bringSubviewToFront:self.buttonBlocker];
    [self.view bringSubviewToFront:self.sendToTextField];

	self.buttonSelector.textLabel.text = NSLocalizedString(@"Send From:", @"Label text on Send Bitcoin screen");
	
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
    [InfoView CreateWithHTML:@"infoSend" forView:self.view];
}

- (IBAction)buttonBlockerTouched:(id)sender
{
	[self.sendToTextField resignFirstResponder];
    [self blockUser:NO];
}

- (IBAction)buttonCameraTouched:(id)sender
{
    [self showImageScanner];
}

#pragma mark - Misc Methods

- (void)blockUser:(BOOL)bBlock
{
    if (bBlock)
    {
        [self.view bringSubviewToFront:self.buttonBlocker];
        [self.view bringSubviewToFront:self.sendToTextField];
        self.buttonBlocker.hidden = NO;
    }
    else
    {
        self.buttonBlocker.hidden = YES;
    }
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
	
	if(nCount)
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
	if(self.sendToTextField.text.length)
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


#pragma mark - UITextField delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	[_readerView stop];
	[UIView animateWithDuration:1.0
						  delay:0.0
						options:UIViewAnimationOptionCurveLinear
					 animations:^
	 {
		 _readerView.alpha = 0.0;
	 }
	 completion:^(BOOL finished)
	 {

	 }];
    [self.view bringSubviewToFront:self.buttonBlocker];
    [self blockUser:YES];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self blockUser:NO];
	[textField resignFirstResponder];
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if (textField.text.length)
	{
		[self showSendConfirmationWithAddress:textField.text amount:0.0 nameLabel:@" "];
	}
	else
	{
		[_readerView start];
		[UIView animateWithDuration:1.0
							  delay:0.0
							options:UIViewAnimationOptionCurveLinear
						 animations:^
		 {
			 _readerView.alpha = 1.0;
		 }
						 completion:^(BOOL finished)
		 {
			 
		 }];
	}
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
	self.sendToTextField.text = nil;
	[_readerView start];
	[_sendConfirmationViewController.view removeFromSuperview];
	_sendConfirmationViewController = nil;
}

#pragma mark - ButtonSelectorView delegates

- (void)ButtonSelector:(ButtonSelectorView *)view selectedItem:(int)itemIndex
{
    _selectedWalletIndex = itemIndex;
    [self setWalletButtonTitle];
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


@end

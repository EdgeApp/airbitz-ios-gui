//
//  SendViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "SendViewController.h"
#import "Notifications.h"
#import "ABC.h"
#import "SendConfirmationViewController.h"
#import "FlashSelectView.h"
#import <AVFoundation/AVFoundation.h>
#import "User.h"
#import "ButtonSelectorView.h"
#import "CommonTypes.h"
#import "Util.h"
#import "InfoView.h"

@interface SendViewController () <SendConfirmationViewControllerDelegate, FlashSelectViewDelegate, UITextFieldDelegate, ButtonSelectorDelegate>
{
	ZBarReaderView                  *_reader;
	NSTimer                         *_startScannerTimer;
	int                             _selectedWalletIndex;
	NSString                        *_selectedWalletUUID;
	SendConfirmationViewController  *_sendConfirmationViewController;
}
@property (weak, nonatomic) IBOutlet UIImageView            *scanFrame;
@property (weak, nonatomic) IBOutlet FlashSelectView        *flashSelector;
@property (nonatomic, weak) IBOutlet UITextField            *sendToTextField;
@property (nonatomic, weak) IBOutlet ButtonSelectorView     *buttonSelector;
@property (weak, nonatomic) IBOutlet UIImageView            *imageTopFrame;
@property (weak, nonatomic) IBOutlet UILabel                *labelSendTo;
@property (weak, nonatomic) IBOutlet UIImageView            *imageSendTo;
@property (weak, nonatomic) IBOutlet UILabel                *labelScanQRCode;
@property (weak, nonatomic) IBOutlet UIImageView            *imageFlashFrame;

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

-(void)viewWillAppear:(BOOL)animated
{
	//NSLog(@"Starting timer");
    
	_startScannerTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(startScanner:) userInfo:nil repeats:NO];
	
	[self.flashSelector selectItem:FLASH_ITEM_AUTO];

}

-(void)viewWillDisappear:(BOOL)animated
{
	//NSLog(@"Invalidating timer");
	[_startScannerTimer invalidate];
	_startScannerTimer = nil;
	
	[_reader stop];
	
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

        frame = self.imageTopFrame.frame;
        frame.origin.y = 64.0;
        frame.size.height = 73.0;
        self.imageTopFrame.frame = frame;

        frame = self.buttonSelector.frame;
        frame.origin.y = self.imageTopFrame.frame.origin.y + 0.0;
        self.buttonSelector.frame = frame;

        frame = self.imageSendTo.frame;
        frame.origin.y = self.buttonSelector.frame.origin.y + self.buttonSelector.frame.size.height + 0.0;
        self.imageSendTo.frame = frame;

        frame = self.sendToTextField.frame;
        frame.origin.y = self.imageSendTo.frame.origin.y + 2.0;
        self.sendToTextField.frame = frame;

        frame = self.labelSendTo.frame;
        frame.origin.y = self.sendToTextField.frame.origin.y + 5.0;
        self.labelSendTo.frame = frame;

        //frame = self.labelScanQRCode.frame;
        //frame.origin.y = self.imageTopFrame.frame.origin.y + self.imageTopFrame.frame.size.height + 0.0;
        //self.labelScanQRCode.frame = frame;
        self.labelScanQRCode.hidden = YES;

        frame = self.scanFrame.frame;
        frame.origin.y = self.imageTopFrame.frame.origin.y + self.imageTopFrame.frame.size.height + 0.0;
        self.scanFrame.frame = frame;

        frame = self.imageFlashFrame.frame;
        frame.origin.y = self.scanFrame.frame.origin.y + self.scanFrame.frame.size.height + 0.0;
        frame.size.height = 41.0;
        self.imageFlashFrame.frame = frame;

        frame = self.flashSelector.frame;
        frame.origin.y = self.imageFlashFrame.frame.origin.y + 0.0;
        frame.size.height = 40.0;
        self.flashSelector.frame = frame;
    }
}

-(void)setWalletButtonTitle
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

-(void)showSendConfirmationWithAddress:(NSString *)address amount:(long long)amount nameLabel:(NSString *)nameLabel
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

-(void)startScanner:(NSTimer *)timer
{

#if !TARGET_IPHONE_SIMULATOR
    // NSLog(@"Scanning...");

	_reader = [ZBarReaderView new];
	[self.view insertSubview:_reader belowSubview:self.scanFrame];
	_reader.frame = self.scanFrame.frame;
	_reader.readerDelegate = self;
	_reader.tracksSymbols = NO;

	_reader.tag = 99999999;
	if(self.sendToTextField.text.length)
	{
		_reader.alpha = 0.0;
	}
	[_reader start];
	[self flashItemSelected:FLASH_ITEM_AUTO];
#endif
}

-(void)closeCameraScanner
{
	UIView * v = [self.view viewWithTag:99999999];
	if (nil != v)
	{
		[v removeFromSuperview];
	}

	//[self.view endEditing:YES];
}


#pragma mark - UITextField delegates

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
	[_reader stop];
	[UIView animateWithDuration:1.0
						  delay:0.0
						options:UIViewAnimationOptionCurveLinear
					 animations:^
	 {
		 _reader.alpha = 0.0;
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
		[_reader start];
		[UIView animateWithDuration:1.0
							  delay:0.0
							options:UIViewAnimationOptionCurveLinear
						 animations:^
		 {
			 _reader.alpha = 1.0;
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
	AVCaptureDevice *device = _reader.device;
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
	[_reader start];
	[_sendConfirmationViewController.view removeFromSuperview];
	_sendConfirmationViewController = nil;
	
}

#pragma mark - ZBar's Delegate method
- (void)readerView: (ZBarReaderView*) view didReadSymbols: (ZBarSymbolSet*) syms fromImage: (UIImage*) img
{
	for(ZBarSymbol *sym in syms)
	{
		NSString *text = (NSString *)sym.data;
		
		//NSLog(@"text: %@", (NSString *)sym.data);
		[view stop];
		
		tABC_Error Error;
		tABC_BitcoinURIInfo *uri;
		//printf("Parsing URI: %s\n", [text UTF8String]);
		//ABC_ParseBitcoinURI("bitcoin:1585j6GvTMz6gkCgjK3kpm9SBkEZCdN5aW?amount=0.00000100&label=MyName&message=MyNotes", &uri, &Error);
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
				[self showSendConfirmationWithAddress:[NSString stringWithUTF8String:uri->szAddress] amount:uri->amountSatoshi nameLabel:label];
			}
			else
			{
				printf("No address!");
				[view start];
			}
		}
		else
		{
			printf("URI parse failed!");
			[view start];
		}

		ABC_FreeURIInfo(uri);
		//[self closeCameraScanner];
		
		//reader = nil;
		break; //just grab first one
	}
}

#pragma mark - ButtonSelectorView delegates

- (void)ButtonSelector:(ButtonSelectorView *)view selectedItem:(int)itemIndex
{
	//NSLog(@"Selected item %i", itemIndex);
    _selectedWalletIndex = itemIndex;
    [self setWalletButtonTitle];
}

@end

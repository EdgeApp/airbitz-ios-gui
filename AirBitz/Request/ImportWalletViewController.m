//
//  ImportWalletViewController.m
//  AirBitz
//
//  Created by Adam Harris on 5/19/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "CommonTypes.h"
#import "ABC.h"
#import "ImportWalletViewController.h"
#import "ButtonSelectorView.h"
#import "FlashSelectView.h"
#import "StylizedTextField.h"
#import "Util.h"
#import "User.h"

#define WALLET_BUTTON_WIDTH 150

@interface ImportWalletViewController () <ButtonSelectorDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet ButtonSelectorView *buttonSelector;
@property (weak, nonatomic) IBOutlet StylizedTextField  *textPrivateKey;
@property (weak, nonatomic) IBOutlet UIImageView        *scanFrame;
@property (weak, nonatomic) IBOutlet UIImageView        *imageFlashFrame;
@property (weak, nonatomic) IBOutlet FlashSelectView    *flashSelector;

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

	self.buttonSelector.delegate = self;
	self.buttonSelector.textLabel.text = NSLocalizedString(@"Import Wallet:", nil);
    [self.buttonSelector setButtonWidth:WALLET_BUTTON_WIDTH];

    // get a callback when the private key changes
    [self.textPrivateKey addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    [self setWalletButtonTitle];

    [self updateDisplayLayout];
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

#pragma - Action Methods

- (IBAction)buttonBackTouched:(id)sender
{
    [self animatedExit];
}

- (IBAction)buttonCameraTouched:(id)sender
{
}

- (IBAction)buttonInfoTouched:(id)sender
{
}

#pragma mark - Misc Methods

- (void)updateDisplayLayout
{
    // update for iPhone 4
    if (!IS_IPHONE5)
    {

    }
}

- (void)setWalletButtonTitle
{
	tABC_WalletInfo **aWalletInfo = NULL;
    unsigned int nCount;
	tABC_Error Error;
    ABC_GetWallets([[User Singleton].name UTF8String], [[User Singleton].password UTF8String], &aWalletInfo, &nCount, &Error);
    [Util printABC_Error:&Error];

	if (nCount)
	{
		tABC_WalletInfo *info = aWalletInfo[0];

		[self.buttonSelector.button setTitle:[NSString stringWithUTF8String:info->szName] forState:UIControlStateNormal];
		self.buttonSelector.selectedItemIndex = 0;
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

#pragma mark - ButtonSelectorView delegate

- (void)ButtonSelector:(ButtonSelectorView *)view selectedItem:(int)itemIndex
{
	NSLog(@"Selected item %i", itemIndex);
}

- (void)ButtonSelectorWillShowTable:(ButtonSelectorView *)view
{
    [self.textPrivateKey resignFirstResponder];
}

#pragma mark - UITextField delegates

- (void)textFieldDidChange:(UITextField *)textField
{

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{


	[textField resignFirstResponder];

	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self.buttonSelector close];

}

- (void)textFieldDidEndEditing:(UITextField *)textField
{

}

@end

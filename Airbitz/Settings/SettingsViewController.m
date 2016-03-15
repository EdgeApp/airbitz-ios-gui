//
//  SettingsViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "SettingsViewController.h"
#import "RadioButtonCell.h"
#import "PlainCell.h"
#import "TextFieldCell.h"
#import "BooleanCell.h"
#import "ButtonCell.h"
#import "ButtonOnlyCell.h"
#import "SignUpViewController.h"
#import "DebugViewController.h"
#import "PasswordRecoveryViewController.h"
#import "PopupPickerView2.h"
#import "PopupWheelPickerView.h"
#import "CommonTypes.h"
#import "CategoriesViewController.h"
#import "SpendingLimitsViewController.h"
#import "TwoFactorShowViewController.h"
#import "Util.h"
#import "InfoView.h"
#import "LocalSettings.h"
#import "AirbitzCore.h"
#import "Theme.h"
#import "MainViewController.h"
#import "PopupPickerView.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "FadingAlertView.h"
#import "Affiliate.h"

#define DISTANCE_ABOVE_KEYBOARD             10  // how far above the keyboard to we want the control
#define ANIMATION_DURATION_KEYBOARD_UP      0.30
#define ANIMATION_DURATION_KEYBOARD_DOWN    0.25

#define SECTION_BITCOIN_DENOMINATION    0
#define SECTION_USERNAME                1
#define SECTION_NAME                    2
#define SECTION_OPTIONS                 3
#define SECTION_DEFAULT_EXCHANGE        4
#define SECTION_DEBUG                   5

// If we are in debug include the DEBUG section in settings
#if (DEBUG || 1) // Always enable debug section for now
#define SECTION_COUNT                   6
#else 
#define SECTION_COUNT                   5
#endif

#define DENOMINATION_CHOICES            3

#define ROW_BITCOIN                     0
#define ROW_MBITCOIN                    1
#define ROW_UBITCOIN                    2

#define ROW_PASSWORD                    0
#define ROW_PIN                         1
#define ROW_RECOVERY_QUESTIONS          2

#define ROW_SEND_NAME                   0
#define ROW_FIRST_NAME                  1
#define ROW_LAST_NAME                   2
#define ROW_NICKNAME                    3

#define ROW_AUTO_LOG_OFF                0
#define ROW_DEFAULT_CURRENCY            1
#define ROW_CHANGE_CATEGORIES           2
#define ROW_SPEND_LIMITS                3
#define ROW_TFA                         4
#define ROW_MERCHANT_MODE               5
#define ROW_BLE                         6
#define ROW_PIN_RELOGIN                 7
#define ROW_TOUCHID                     8

#define ARRAY_LOGOUT        @[@[@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9", \
                                @"10",@"11",@"12",@"13",@"14",@"15",@"16",@"17",@"18",@"19", \
                                @"20",@"21",@"22",@"23",@"24",@"25",@"26",@"27",@"28",@"29", \
                                @"30",@"31",@"32",@"33",@"34",@"35",@"36",@"37",@"38",@"39", \
                                @"40",@"41",@"42",@"43",@"44",@"45",@"46",@"47",@"48",@"49", \
                                @"50",@"51",@"52",@"53",@"54",@"55",@"56",@"57",@"58",@"59", \
                                @"60"], \
                              @[@"second(s)",@"minute(s)",@"hour(s)",@"day(s)"]]
#define ARRAY_LOGOUT_SECONDS @[@1, @60, @3600, @86400] // how many seconds in each of the 'types'

typedef NS_ENUM(NSUInteger, ABCLogoutSecondsType)
{
    ABCLogoutSecondsTypeSeconds = 0,
    ABCLogoutSecondsTypeMinutes,
    ABCLogoutSecondsTypeHours,
    ABCLogoutSecondsTypeDays
};


#define PICKER_MAX_CELLS_VISIBLE        (!IS_IPHONE4 ? 9 : 8)
#define PICKER_WIDTH                    160
#define PICKER_CELL_HEIGHT              44

@interface SettingsViewController () <UITableViewDataSource, UITableViewDelegate, BooleanCellDelegate, ButtonCellDelegate, TextFieldCellDelegate,
                                      ButtonOnlyCellDelegate, SignUpViewControllerDelegate, PasswordRecoveryViewControllerDelegate,
                                      PopupPickerView2Delegate, PopupWheelPickerViewDelegate, CategoriesViewControllerDelegate,
                                      SpendingLimitsViewControllerDelegate, TwoFactorShowViewControllerDelegate, DebugViewControllerDelegate,
                                      CBCentralManagerDelegate>
{
	TextFieldCell                   *_activeTextFieldCell;
	UITapGestureRecognizer          *_tapGesture;
    SignUpViewController            *_signUpController;
    PasswordRecoveryViewController  *_passwordRecoveryController;
    CategoriesViewController        *_categoriesController;
    SpendingLimitsViewController    *_spendLimitsController;
    TwoFactorShowViewController     *_tfaViewController;
    DebugViewController             *_debugViewController;
    BOOL                            _bKeyboardIsShown;
	BOOL							_showBluetoothOption;
    CGRect                          _frameStart;
    CGFloat                         _keyboardHeight;
    UIAlertView                     *_passwordCheckAlert;
    UIAlertView                     *_passwordIncorrectAlert;
    NSString                        *_tempPassword;

}

@property (nonatomic, weak) IBOutlet UITableView    *tableView;
@property (weak, nonatomic) IBOutlet UIView         *viewMain;

@property (nonatomic, strong) PopupPickerView2       *popupPicker;
@property (nonatomic, strong) PopupWheelPickerView  *popupWheelPicker;
@property (nonatomic, strong) UIButton              *buttonBlocker;

@property (nonatomic, strong) CBCentralManager		*centralManager;
@end

@implementation SettingsViewController

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
    [Util resizeView:self.view withDisplayView:self.viewMain];

	// Do any additional setup after loading the view.
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.delaysContentTouches = NO;
    _tempPassword = nil;

    self.popupPicker = nil;
    self.buttonBlocker = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonBlocker.backgroundColor = [UIColor clearColor];
    [self.buttonBlocker addTarget:self action:@selector(buttonBlockerTouched:) forControlEvents:UIControlEventTouchUpInside];
    self.buttonBlocker.frame = self.view.bounds;
    self.buttonBlocker.hidden = YES;
    [self.viewMain addSubview:self.buttonBlocker];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(refresh:)
                                                 name:NOTIFICATION_DATA_SYNC_UPDATE object:nil];
	_showBluetoothOption = NO;
    [self refresh:nil];
	
	 _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:@{CBCentralManagerOptionShowPowerAlertKey: @(NO)}];

    // Fix table insets
    CGPoint pt;
    pt.x = 0;
    pt.y = -[MainViewController getHeaderHeight];
    [self.tableView setContentInset:UIEdgeInsetsMake([MainViewController getHeaderHeight],0,[MainViewController getFooterHeight],0)];
    [self.tableView setContentOffset:pt];

    [self updateViews];
}

- (void)updateViews
{
    [MainViewController changeNavBarOwner:self];
    [MainViewController changeNavBarTitle:self title:settingsText];

    [MainViewController changeNavBar:self title:backButtonText side:NAV_BAR_LEFT button:true enable:false action:nil fromObject:self];
    [MainViewController changeNavBar:self title:helpButtonText side:NAV_BAR_RIGHT button:true enable:true action:@selector(Info) fromObject:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	self.centralManager = nil;
}

- (void)refresh:(NSNotification *)notification
{	
    [abcAccount.settings loadSettings];

    _frameStart = self.tableView.frame;
    _keyboardHeight = 0.0;

    // register for keyboard notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    _bKeyboardIsShown = NO;

    [_tableView reloadData];
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - BLE

- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
	if (central.state == CBCentralManagerStatePoweredOn)
	{
		_showBluetoothOption = YES;
		[_tableView reloadData];
	}
}

#pragma mark - Misc Methods

- (void)saveSettings
{
    NSError *error = [abcAccount.settings saveSettings];
    // update the settings in the core

    if (error)
    {
        UIAlertView *alert =
        [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unable to save Settings", nil)
                                   message:error.userInfo[NSLocalizedDescriptionKey]
                                  delegate:self
                         cancelButtonTitle:cancelButtonText
                         otherButtonTitles:okButtonText, nil];
        [alert show];
    }
}

// returns the cell for the given section and row in the table
// Note: this can return nil if the row is not currently queued
- (UITableViewCell *)cellForSection:(NSInteger)section andRow:(NSInteger)row
{
    NSIndexPath *cellPath = [NSIndexPath indexPathForRow:row inSection:section];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:cellPath];

    return cell;
}

// modifies the denomination choice in the settings
- (void)setDenominationChoice:(NSInteger)nChoice
{
    // set the new values
    abcAccount.settings.denomination = [ABCDenomination getDenominationForIndex:(int) nChoice];

    // update the settings in the core
    [self saveSettings];
}

- (void)bringUpSignUpViewInMode:(tSignUpMode)mode
{
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
    _signUpController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SignUpViewController"];

    _signUpController.mode = mode;
    _signUpController.delegate = self;

    [Util addSubviewControllerWithConstraints:self child:_signUpController];
    [MainViewController animateSlideIn:_signUpController];
}

- (void)bringUpRecoveryQuestionsView
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	_passwordRecoveryController = [mainStoryboard instantiateViewControllerWithIdentifier:@"PasswordRecoveryViewController"];

	_passwordRecoveryController.delegate = self;
	_passwordRecoveryController.mode = PassRecovMode_Change;

    [Util addSubviewControllerWithConstraints:self child:_passwordRecoveryController];
    [MainViewController animateSlideIn:_passwordRecoveryController];

}

- (void)bringUpCategoriesView
{
    {
        UIStoryboard *settingsStoryboard = [UIStoryboard storyboardWithName:@"Settings" bundle: nil];
        _categoriesController = [settingsStoryboard instantiateViewControllerWithIdentifier:@"CategoriesViewController"];

        _categoriesController.delegate = self;

        [Util addSubviewControllerWithConstraints:self child:_categoriesController];
        [MainViewController animateSlideIn:_categoriesController];

    }
}

- (void)bringUpSpendingLimits
{
    {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
        _spendLimitsController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SpendingLimitsViewController"];
        _spendLimitsController.delegate = self;

        [Util addSubviewControllerWithConstraints:self child:_spendLimitsController];

        [MainViewController animateSlideIn:_spendLimitsController];
    }
}

- (void)bringUpTwoFactor
{
    UIStoryboard *settingsStoryboard = [UIStoryboard storyboardWithName:@"Settings" bundle: nil];
    _tfaViewController = [settingsStoryboard instantiateViewControllerWithIdentifier:@"TwoFactorShowViewController"];
    _tfaViewController.delegate = self;

    [Util addSubviewControllerWithConstraints:self child:_tfaViewController];
    [MainViewController animateSlideIn:_tfaViewController];

}

- (void)bringUpDebugView
{
    UIStoryboard *settingsStoryboard = [UIStoryboard storyboardWithName:@"Settings" bundle: nil];
    _debugViewController = [settingsStoryboard instantiateViewControllerWithIdentifier:@"DebugViewController"];
    _debugViewController.delegate = self;

    [Util addSubviewControllerWithConstraints:self child:_debugViewController];
    [MainViewController animateSlideIn:_debugViewController];
}

// returns how much the current first responder is obscured by the keyboard
// negative means above the keyboad by that amount
- (CGFloat)obscuredAmountFor:(UIView *)theView
{
    CGFloat obscureAmount = 0.0;

    // determine how much we are obscured if any
    if (theView)
    {
        UIWindow *frontWindow = [[UIApplication sharedApplication] keyWindow];

        CGPoint pointInWindow = [frontWindow.rootViewController.view convertPoint:theView.frame.origin fromView:self.tableView];

        CGFloat distFromBottom = frontWindow.frame.size.height - pointInWindow.y;
        obscureAmount = (_keyboardHeight + theView.frame.size.height) - distFromBottom;

    }

    return obscureAmount;
}

- (void)moveToClearKeyboardFor:(UIView *)theView withDuration:(CGFloat)duration
{
    CGRect newFrame = self.tableView.frame;

    // determine how much we are obscured
    CGFloat obscureAmount = [self obscuredAmountFor:theView];
    obscureAmount += (CGFloat) DISTANCE_ABOVE_KEYBOARD;

    // if obscured too much
    //ABCLog(2,@"obscure amount final = %f", obscureAmount);
    if (obscureAmount != 0.0)
    {
        // it is obscured so move it to compensate
        //ABCLog(2,@"need to compensate");
        newFrame.origin.y -= obscureAmount;
    }

    //ABCLog(2,@"old origin: %f, new origin: %f", _frameStart.origin.y, newFrame.origin.y);

    // if our new position puts us lower then we were originally
    if (newFrame.origin.y > _frameStart.origin.y)
    {
        newFrame.origin.y = _frameStart.origin.y;
    }

    // if we need to move
    if (self.tableView.frame.origin.y != newFrame.origin.y)
    {
        CGFloat offsetChangeY = _frameStart.origin.y - newFrame.origin.y;
        CGFloat curOffsetY = self.tableView.contentOffset.y;
        CGPoint p = CGPointMake(0, curOffsetY + offsetChangeY);

        [self.tableView setContentOffset:p animated:YES];
    }
}

- (void)blockUser:(BOOL)bBlock
{
    self.buttonBlocker.hidden = !bBlock;
}

- (void)dismissPopupPicker
{
    if (self.popupPicker)
    {
        [self.popupPicker removeFromSuperview];
        self.popupPicker = nil;
    }

    if (self.popupWheelPicker)
    {
        [self.popupWheelPicker removeFromSuperview];
        self.popupWheelPicker = nil;
    }

    [self blockUser:NO];
}

// gets the string for the 'auto log off after' button
- (NSString *)logoutDisplay
{
    NSMutableString *strRetVal = [[NSMutableString alloc] init];

    int amount = 0;
    NSString *strType = @"";
    NSInteger maxVal = [[[ARRAY_LOGOUT objectAtIndex:0] lastObject] intValue];
    if (abcAccount.settings.secondsAutoLogout <= [[ARRAY_LOGOUT_SECONDS objectAtIndex:ABCLogoutSecondsTypeSeconds] integerValue] * maxVal)
    {
        strType = @"second";
        amount = abcAccount.settings.secondsAutoLogout;
    }
    else if (abcAccount.settings.secondsAutoLogout <= [[ARRAY_LOGOUT_SECONDS objectAtIndex:ABCLogoutSecondsTypeMinutes] integerValue] * maxVal)
    {
        strType = @"minute";
        amount = abcAccount.settings.secondsAutoLogout / [[ARRAY_LOGOUT_SECONDS objectAtIndex:ABCLogoutSecondsTypeMinutes] integerValue];
    }
    else if (abcAccount.settings.secondsAutoLogout <= [[ARRAY_LOGOUT_SECONDS objectAtIndex:ABCLogoutSecondsTypeHours] integerValue] * maxVal)
    {
        strType = @"hour";
        amount = abcAccount.settings.secondsAutoLogout / [[ARRAY_LOGOUT_SECONDS objectAtIndex:ABCLogoutSecondsTypeHours] integerValue];
    }
    else
    {
        strType = @"day";
        amount = abcAccount.settings.secondsAutoLogout / [[ARRAY_LOGOUT_SECONDS objectAtIndex:ABCLogoutSecondsTypeDays] integerValue];
    }

    [strRetVal appendFormat:@"%d %@", amount, strType];
    if (amount != 1)
    {
        [strRetVal appendString:@"s"];
    }

    return strRetVal;
}

// gets the array of selections for array of choices in 'auto log off after'
- (NSArray *)logoutSelections
{
    int finalType = 0;
    int finalAmount = 0;

    NSMutableArray *arraySelections = [[NSMutableArray alloc] init];
    NSInteger maxVal = [[[ARRAY_LOGOUT objectAtIndex:0] lastObject] intValue];

    // go through each of the types
    for (int type = 0; type < [[ARRAY_LOGOUT objectAtIndex:1] count]; type++)
    {
        // if the number is below or equal to this types maximum
        if (abcAccount.settings.secondsAutoLogout <= [[ARRAY_LOGOUT_SECONDS objectAtIndex:type] integerValue] * maxVal)
        {
            finalType = type;
            for (int amountIndex = 0; amountIndex < [[ARRAY_LOGOUT objectAtIndex:0] count]; amountIndex++)
            {
                int secondsBase = [[[ARRAY_LOGOUT objectAtIndex:0] objectAtIndex:amountIndex] intValue];
                int secondsMult = [[ARRAY_LOGOUT_SECONDS objectAtIndex:type] intValue];
                if (abcAccount.settings.secondsAutoLogout >= (secondsBase * secondsMult))
                {
                    finalAmount = amountIndex;
                }
                else
                {
                    break;
                }
            }
            break;
        }
    }

    [arraySelections addObject:[NSNumber numberWithInt:finalAmount]];
    [arraySelections addObject:[NSNumber numberWithInt:finalType]];

    return arraySelections;
}

- (void)resetViews
{
    if (_signUpController)
    {
        [_signUpController.view removeFromSuperview];
        [_signUpController removeFromParentViewController];
        _signUpController = nil;
    }
    if (_passwordRecoveryController)
    {
        [_passwordRecoveryController.view removeFromSuperview];
        [_passwordRecoveryController removeFromParentViewController];
        _passwordRecoveryController = nil;
    }
    if (_categoriesController)
    {
        [_categoriesController.view removeFromSuperview];
        [_categoriesController removeFromParentViewController];
        _categoriesController = nil;
    }
    if (_spendLimitsController)
    {
        [_spendLimitsController.view removeFromSuperview];
        [_spendLimitsController removeFromParentViewController];
        _spendLimitsController = nil;
    }
    if (_tfaViewController)
    {
        [_tfaViewController.view removeFromSuperview];
        [_tfaViewController removeFromParentViewController];
        _tfaViewController = nil;
    }
    if (_debugViewController)
    {
        [_debugViewController.view removeFromSuperview];
        [_debugViewController removeFromParentViewController];
        _debugViewController = nil;
    }
    
}



#pragma mark - Action Methods

- (IBAction)buttonBlockerTouched:(id)sender
{
    [self dismissPopupPicker];
}

- (IBAction)Back
{
	[self.delegate SettingsViewControllerDone:self];
}

- (IBAction)Info
{
    [InfoView CreateWithHTML:@"infoSettings" forView:self.view];
}

#pragma mark - textFieldCell delegates

- (void)textFieldCellTextDidChange:(TextFieldCell *)cell
{
    NSInteger section = (cell.tag >> 8);
    NSInteger row = cell.tag & 0xff;

    if (section == SECTION_NAME)
    {
        if (row == ROW_FIRST_NAME)
        {
            abcAccount.settings.firstName = [NSString stringWithString:cell.textField.text];
        }
        else if (row == ROW_LAST_NAME)
        {
            abcAccount.settings.lastName = [NSString stringWithString:cell.textField.text];
        }
        else if (row == ROW_NICKNAME)
        {
            abcAccount.settings.nickName = [NSString stringWithString:cell.textField.text];
        }

    }
}

- (void)textFieldCellBeganEditing:(TextFieldCell *)cell
{
	//scroll the tableView so that this cell is above the keyboard
	_activeTextFieldCell = cell;
	if (!_tapGesture)
	{
		_tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
		[self.tableView	addGestureRecognizer:_tapGesture];
	}
}

- (void)handleTapFrom:(UITapGestureRecognizer *)recognizer
{
    //Code to handle the gesture
	[self.view endEditing:YES];
	[self.tableView removeGestureRecognizer:_tapGesture];
	_tapGesture = nil;
}

- (void)textFieldCellEndEditing:(TextFieldCell *)cell
{
	[_activeTextFieldCell resignFirstResponder];
	_activeTextFieldCell = nil;
    [self saveSettings];
}

- (void)textFieldCellTextDidReturn:(TextFieldCell *)cell
{
    NSInteger section = (cell.tag >> 8);
    NSInteger row = cell.tag & 0xff;

    if (section == SECTION_NAME)
    {
        if (row == ROW_FIRST_NAME)
        {
            TextFieldCell *nextCell = (TextFieldCell *) [self cellForSection:SECTION_NAME andRow:ROW_LAST_NAME];
            if (nextCell)
            {
                [nextCell.textField becomeFirstResponder];
            }
        }
        else if (row == ROW_LAST_NAME)
        {
            TextFieldCell *nextCell = (TextFieldCell *) [self cellForSection:SECTION_NAME andRow:ROW_NICKNAME];
            if (nextCell)
            {
                [nextCell.textField becomeFirstResponder];
            }
        }
    }
}

#pragma mark - Keyboard Notification Methods

- (void)keyboardWillShow:(NSNotification *)n
{
    if (!_activeTextFieldCell)
    {
        return;
    }

    // NOTE: The keyboard notification will fire even when the keyboard is already shown.
    if (_bKeyboardIsShown)
    {
        return;
    }

    // get the height of the keyboard
    NSDictionary* userInfo = [n userInfo];
    NSValue* boundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGSize keyboardSize = [boundsValue CGRectValue].size;
    _keyboardHeight = keyboardSize.height;

    // move ourselves up to clear the keyboard
    [self moveToClearKeyboardFor:_activeTextFieldCell withDuration:ANIMATION_DURATION_KEYBOARD_UP];

    _bKeyboardIsShown = YES;
}

- (void)keyboardWillHide:(NSNotification *)n
{
    _bKeyboardIsShown = NO;
    _keyboardHeight = 0.0;
}

#pragma mark - Custom Table Cells

- (RadioButtonCell *)getRadioButtonCellForTableView:(UITableView *)tableView andIndexPath:(NSIndexPath *)indexPath
{
	RadioButtonCell *cell;
	static NSString *cellIdentifier = @"RadioButtonCell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[RadioButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}

	if (indexPath.row == ROW_BITCOIN)
	{
		cell.name.text = NSLocalizedString(@"Bitcoin", @"settings text");
	}
	if (indexPath.row == ROW_MBITCOIN)
	{
		cell.name.text = NSLocalizedString(@"mBitcoin = (0.001 Bitcoin)", @"settings text");
	}
	if (indexPath.row == ROW_UBITCOIN)
	{
		cell.name.text = NSLocalizedString(@"bits = (0.000001 Bitcoin)", @"settings text");
	}
	cell.radioButton.image = [UIImage imageNamed:(indexPath.row == abcAccount.settings.denomination.index ? @"btn_selected" : @"btn_unselected")];

    cell.tag = (indexPath.section << 8) | (indexPath.row);

	return cell;
}

- (PlainCell *)getPlainCellForTableView:(UITableView *)tableView andIndexPath:(NSIndexPath *)indexPath
{
	PlainCell *cell;
	static NSString *cellIdentifier = @"PlainCell";

	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[PlainCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}

	if (indexPath.section == SECTION_USERNAME)
	{
		if (indexPath.row == ROW_PASSWORD)
		{
			cell.name.text = NSLocalizedString(@"Change password", @"settings text");
		}
		if (indexPath.row == ROW_PIN)
		{
			cell.name.text = NSLocalizedString(@"Change PIN", @"settings text");
		}
		if (indexPath.row == ROW_RECOVERY_QUESTIONS)
		{
			cell.name.text = NSLocalizedString(@"Change recovery questions", @"settings text");
		}
	}
    else if (indexPath.section == SECTION_OPTIONS)
    {
        if (indexPath.row == ROW_CHANGE_CATEGORIES)
        {
			cell.name.text = NSLocalizedString(@"Change Categories", @"settings text");
        } else if (indexPath.row == ROW_SPEND_LIMITS) {
			cell.name.text = NSLocalizedString(@"Spending Limits", @"spending limits text");
        } else if (indexPath.row == ROW_TFA) {
			cell.name.text = NSLocalizedString(@"2 Factor (Enhanced Security)", nil);
        }
    }

    cell.tag = (indexPath.section << 8) | (indexPath.row);

	return cell;
}

- (TextFieldCell *)getTextFieldCellForTableView:(UITableView *)tableView andIndexPath:(NSIndexPath *)indexPath
{
	TextFieldCell *cell;
	static NSString *cellIdentifier = @"TextFieldCell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[TextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	cell.delegate = self;
    cell.backgroundColor = [UIColor clearColor];
    cell.layer.backgroundColor = (__bridge CGColorRef)([UIColor clearColor]);
    
	if (indexPath.section == SECTION_NAME)
	{
		if (indexPath.row == 1)
		{
			cell.textField.placeholder = NSLocalizedString(@"First Name (optional)", @"settings text");
            cell.textField.returnKeyType = UIReturnKeyNext;
            cell.textField.text = abcAccount.settings.firstName;
		}
		if (indexPath.row == 2)
		{
			cell.textField.placeholder = NSLocalizedString(@"Last Name (optional)", @"settings text");
            cell.textField.returnKeyType = UIReturnKeyNext;
            cell.textField.text = abcAccount.settings.lastName;
		}
		if (indexPath.row == 3)
		{
			cell.textField.placeholder = NSLocalizedString(@"Nickname / Handle (optional)", @"settings text");
            cell.textField.returnKeyType = UIReturnKeyDone;
            cell.textField.text = abcAccount.settings.nickName;
		}

        cell.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        cell.textField.spellCheckingType = UITextSpellCheckingTypeNo;

        cell.textField.enabled = abcAccount.settings.bNameOnPayments;
        cell.textField.textColor = cell.textField.enabled ? [UIColor whiteColor] : [UIColor grayColor];
	}

    cell.tag = (indexPath.section << 8) | (indexPath.row);
	
	return cell;
}

- (BooleanCell *)getBooleanCellForTableView:(UITableView *)tableView andIndexPath:(NSIndexPath *)indexPath
{
	BooleanCell *cell;
	static NSString *cellIdentifier = @"BooleanCell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[BooleanCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	cell.delegate = self;
	if (indexPath.section == SECTION_NAME)
	{
		if (indexPath.row == ROW_SEND_NAME)
		{
			cell.name.text = NSLocalizedString(@"Send name on payment request", @"settings text");
            [cell.state setOn:abcAccount.settings.bNameOnPayments animated:NO];
		}
	}
    else if (indexPath.section == SECTION_OPTIONS)
    {
        if (indexPath.row == ROW_BLE)
        {
            if (_showBluetoothOption)
            {
                cell.name.text = NSLocalizedString(@"Bluetooth", @"settings text");
                [cell.state setOn:!LocalSettings.controller.bDisableBLE animated:NO];
                cell.state.userInteractionEnabled = YES;
            }
            else
            {
                cell.name.text = NSLocalizedString(@"Enable Bluetooth in System Settings", @"settings text");
                [cell.state setOn:NO animated:NO];
                cell.state.userInteractionEnabled = NO;
            }

        }
        else if (indexPath.row == ROW_MERCHANT_MODE)
        {
			cell.name.text = NSLocalizedString(@"Merchant Mode", @"settings text");
            [cell.state setOn:LocalSettings.controller.bMerchantMode animated:NO];
        }
        else if (indexPath.row == ROW_PIN_RELOGIN)
        {
			cell.name.text = NSLocalizedString(@"PIN Re-Login", @"settings text");
            [cell.state setOn:[abcAccount isPINLoginEnabled] animated:NO];
            if ([abcAccount passwordExists]) {
                cell.state.userInteractionEnabled = YES;
            } else {
                cell.state.userInteractionEnabled = NO;
            }
        }
        else if (indexPath.row == ROW_TOUCHID)
        {
            if (! [abc hasDeviceCapability:ABCDeviceCapsTouchID])
            {
                cell.name.text = NSLocalizedString(@"TouchID: Unsupported Device", @"settings text");
                cell.state.userInteractionEnabled = NO;
                [cell.state setOn:NO animated:NO];
            }
            else if (![abcAccount passwordExists])
            {
                cell.name.text = NSLocalizedString(@"TouchID: Set password first", @"settings text");
                cell.state.userInteractionEnabled = NO;
                [cell.state setOn:NO animated:NO];
            }
            else
            {
                cell.name.text = NSLocalizedString(@"Use TouchID", @"settings text");

                if ([abcAccount.settings touchIDEnabled])
                    [cell.state setOn:YES animated:NO];
                else
                    [cell.state setOn:NO animated:NO];

                if ([abcAccount passwordExists] && 1) {
                    cell.state.userInteractionEnabled = YES;
                } else {
                    cell.state.userInteractionEnabled = NO;
                }
            }

        }
    }
	
    cell.tag = (indexPath.section << 8) | (indexPath.row);

	return cell;
}

- (ButtonCell *)getButtonCellForTableView:(UITableView *)tableView andIndexPath:(NSIndexPath *)indexPath
{
	ButtonCell *cell;
	static NSString *cellIdentifier = @"ButtonCell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[ButtonCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	cell.delegate = self;
	if (indexPath.section == SECTION_OPTIONS)
	{
		if (indexPath.row == ROW_AUTO_LOG_OFF)
		{
			cell.name.text = NSLocalizedString(@"Auto log off after", @"settings text");
            [cell.button setTitle:[self logoutDisplay] forState:UIControlStateNormal];
		}
		else if (indexPath.row == ROW_DEFAULT_CURRENCY)
		{
			cell.name.text = NSLocalizedString(@"Default Currency", @"settings text");
            [cell.button setTitle:abcAccount.settings.defaultCurrency.code forState:UIControlStateNormal];
		}
	}
	if (indexPath.section == SECTION_DEFAULT_EXCHANGE)
	{
		if (indexPath.row == 0)
		{
			cell.name.text = NSLocalizedString(@"Default Exchange", @"settings text");
		}
        [cell.button setTitle:abcAccount.settings.exchangeRateSource forState:UIControlStateNormal];
	}

    cell.tag = (indexPath.section << 8) | (indexPath.row);

	return cell;
}

- (ButtonOnlyCell *)getDebugButton:(UITableView *)tableView withIndexPath:(NSIndexPath *)indexPath
{
    ButtonOnlyCell *cell;
    static NSString *cellIdentifier = @"ButtonOnlyCell";
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (nil == cell)
    {
        cell = [[ButtonOnlyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.delegate = self;
    [cell.button setTitle:debugButtonText forState:UIControlStateNormal];
    cell.tag = (indexPath.section << 8) | (indexPath.row);
	return cell;
}

- (ButtonOnlyCell *)getAffiliateButton:(UITableView *)tableView withIndexPath:(NSIndexPath *)indexPath
{
    ButtonOnlyCell *cell;
    static NSString *cellIdentifier = @"ButtonOnlyCell";
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (nil == cell)
    {
        cell = [[ButtonOnlyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.delegate = self;
    [cell.button setTitle:getAffiliateLinkButtonText forState:UIControlStateNormal];
    cell.tag = (indexPath.section << 8) | (indexPath.row);
    return cell;
}

#pragma mark - UITableView Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return SECTION_COUNT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch(section)
	{
        case SECTION_BITCOIN_DENOMINATION:
            return 3;
            break;

        case SECTION_USERNAME:
            return 3;
            break;

        case SECTION_NAME:
            return 4;
            break;

        case SECTION_OPTIONS:
            return 9;
            break;

        case SECTION_DEFAULT_EXCHANGE:
            return 1;
            break;

        case SECTION_DEBUG:
            return 2;
            break;

        default:
            return 0;
            break;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [Theme Singleton].heightSettingsTableCell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if (section == SECTION_DEBUG)
	{
		return 0.0;
	}

    return [Theme Singleton].heightSettingsTableHeader;

}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	static NSString *cellIdentifier = @"SettingsSectionHeader";
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		[NSException raise:@"headerView == nil.." format:@"No cells with matching CellIdentifier loaded from your storyboard"];
	}
	UILabel *label = (UILabel *)[cell viewWithTag:1];
	if (section == SECTION_BITCOIN_DENOMINATION)
	{
		label.text = NSLocalizedString(@"BITCOIN DENOMINATION", @"section header in settings table");
	}
	if (section == SECTION_USERNAME)
	{
		label.text = NSLocalizedString(@"ACCOUNT: ", @"section header in settings table");
        label.text = [NSString stringWithFormat:@"%@ %s", label.text, [abcAccount.name UTF8String]];
	}
    if (section == SECTION_NAME)
	{
		label.text = NSLocalizedString(@"NAME", @"section header in settings table");
	}
	if (section == SECTION_OPTIONS)
	{
		label.text = NSLocalizedString(@"OPTIONS", @"section header in settings table");
	}
	if (section == SECTION_DEFAULT_EXCHANGE)
	{
		label.text = NSLocalizedString(@"DEFAULT EXCHANGE RATE", @"section header in settings table");
	}
	if (section == SECTION_DEBUG)
	{
		label.text = NSLocalizedString(@"", nil);
	}
    cell.backgroundColor = [UIColor clearColor];
    cell.selectedBackgroundView = [[UIImageView alloc] initWithFrame:cell.bounds];
    cell.selectedBackgroundView.contentMode = cell.backgroundView.contentMode;

    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
    if (indexPath.section == SECTION_DEBUG) {
        if (indexPath.row == 0)
        {
            cell = [self getAffiliateButton:tableView withIndexPath:indexPath];
        }
        else
        {
            cell = [self getDebugButton:tableView withIndexPath:indexPath];
        }
	}
	else
	{
		if (indexPath.section == SECTION_BITCOIN_DENOMINATION)
		{
			cell = [self getRadioButtonCellForTableView:tableView andIndexPath:(NSIndexPath *)indexPath];
		}
		else if (indexPath.section == SECTION_USERNAME)
		{
            cell = [self getPlainCellForTableView:tableView andIndexPath:indexPath];
		}
        else if (indexPath.section == SECTION_NAME)
		{
			if (indexPath.row == ROW_SEND_NAME)
			{
				cell = [self getBooleanCellForTableView:tableView andIndexPath:indexPath];
			}
			else
			{
				cell = [self getTextFieldCellForTableView:tableView andIndexPath:(NSIndexPath *)indexPath];
			}
		}
		else if (indexPath.section == SECTION_OPTIONS)
		{
            if (indexPath.row == ROW_CHANGE_CATEGORIES || indexPath.row == ROW_SPEND_LIMITS || indexPath.row == ROW_TFA)
            {
                cell = [self getPlainCellForTableView:tableView andIndexPath:indexPath];
            }
            else if (indexPath.row == ROW_MERCHANT_MODE)
            {
				cell = [self getBooleanCellForTableView:tableView andIndexPath:indexPath];
            }
            else if (indexPath.row == ROW_BLE)
            {
                cell = [self getBooleanCellForTableView:tableView andIndexPath:indexPath];
            }
            else if (indexPath.row == ROW_PIN_RELOGIN)
            {
				cell = [self getBooleanCellForTableView:tableView andIndexPath:indexPath];
            }
            else if (indexPath.row == ROW_TOUCHID)
            {
                cell = [self getBooleanCellForTableView:tableView andIndexPath:indexPath];
            }
            else
            {
                cell = [self getButtonCellForTableView:tableView andIndexPath:(NSIndexPath *)indexPath];
            }
		}
		else if (indexPath.section == SECTION_DEFAULT_EXCHANGE)
		{
			cell = [self getButtonCellForTableView:tableView andIndexPath:(NSIndexPath *)indexPath];
		}
	}

	//cell.backgroundColor = backgroundColor;
//	cell.selectedBackgroundView.backgroundColor = [UIColor clearColor];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//ABCLog(2,@"Selected section:%i, row:%i", (int)indexPath.section, (int)indexPath.row);

    // NOTE: if it isn't handled in here it is probably handled in a cell callback (e.g., buttonCellButtonPressed)

    switch (indexPath.section)
	{
        case SECTION_BITCOIN_DENOMINATION:
            [self setDenominationChoice:indexPath.row];
            [tableView reloadData];
            break;

        case SECTION_USERNAME:
            if (indexPath.row == ROW_PASSWORD)
            {
                [self bringUpSignUpViewInMode:SignUpMode_ChangePassword];
            }
            else if (indexPath.row == ROW_PIN)
            {
                [self bringUpSignUpViewInMode:SignUpMode_ChangePIN];
            }
            else if (indexPath.row == ROW_RECOVERY_QUESTIONS)
            {
                [self bringUpRecoveryQuestionsView];
            }
            break;

        case SECTION_NAME:
            break;

        case SECTION_OPTIONS:
            if (indexPath.row == ROW_CHANGE_CATEGORIES)
            {
                [self bringUpCategoriesView];
            }
            else if (indexPath.row == ROW_SPEND_LIMITS)
            {
                [self bringUpSpendingLimits];
            }
            else if (indexPath.row == ROW_TFA)
            {
                [self bringUpTwoFactor];
            }
            break;

        case SECTION_DEFAULT_EXCHANGE:
            break;

        case SECTION_DEBUG:
            break;

        default:
            break;
	}
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - SignUpViewControllerDelegates

-(void)signupViewControllerDidFinish:(SignUpViewController *)controller withBackButton:(BOOL)bBack
{
    [MainViewController animateOut:controller withBlur:NO complete:^(void)
            {
                    _signUpController = nil;
            }];

    // re-load the current account settings
    [abcAccount.settings loadSettings];

    [_tableView reloadData];
    [self updateViews];
}

#pragma mark - PasswordRecoveryViewController Delegate

- (void)passwordRecoveryViewControllerDidFinish:(PasswordRecoveryViewController *)controller
{
    [MainViewController animateOut:controller withBlur:NO complete:^(void)
            {
                    _passwordRecoveryController = nil;
            }];
    [self updateViews];
}

#pragma mark - CategoriesViewController Delegate

- (void)categoriesViewControllerDidFinish:(CategoriesViewController *)controller
{
    [MainViewController animateOut:controller withBlur:NO complete:^(void)
            {
                    _categoriesController = nil;
            }];
    [self updateViews];
}

#pragma mark - SpendingLimitsViewController Delegate

- (void)spendingLimitsViewControllerDone:(SpendingLimitsViewController *)controller withBackButton:(BOOL)bBack
{
    [MainViewController animateOut:controller withBlur:NO complete:^(void)
            {
                    _spendLimitsController = nil;
            }];
    [self updateViews];
}

#pragma mark - TwoFactorShowViewControllerDelegate

- (void)twoFactorShowViewControllerDone:(TwoFactorShowViewController *)controller withBackButton:(BOOL)bBack
{
    [MainViewController animateOut:controller withBlur:NO complete:^(void)
    {
        _tfaViewController = nil;
    }];
    [self updateViews];
}

#pragma mark - BooleanCell Delegate

- (void)booleanCell:(BooleanCell *)cell switchToggled:(UISwitch *)theSwitch
{
    NSInteger section = (cell.tag >> 8);
    NSInteger row = cell.tag & 0xff;

    if ((section == SECTION_NAME) && (row == ROW_SEND_NAME))
    {
        abcAccount.settings.bNameOnPayments = theSwitch.on;

        // update the settings in the core
        [self saveSettings];

        // update the display by reloading the table
        [self.tableView reloadData];
    }
    else if ((section == SECTION_OPTIONS) && (row == ROW_BLE))
    {
        LocalSettings.controller.bDisableBLE = !theSwitch.on;
        [LocalSettings saveAll];
    }
    else if ((section == SECTION_OPTIONS) && (row == ROW_MERCHANT_MODE))
    {
        LocalSettings.controller.bMerchantMode = theSwitch.on;
        [LocalSettings saveAll];
    }
    else if ((section == SECTION_OPTIONS) && (row == ROW_PIN_RELOGIN))
    {
        [abcAccount pinLoginSetup:theSwitch.on];
        
        // update the display by reloading the table
        [self.tableView reloadData];

    }
    else if ((section == SECTION_OPTIONS) && (row == ROW_TOUCHID))
    {
        if (!theSwitch.on)
        {
            [abcAccount.settings disableTouchID];
        }
        else
        {
            //
            // Check if we have a cached password. If so just enable touchID
            // If not, ask them for their password.
            //
            if (![abcAccount.settings enableTouchID])
            {
                [self showPasswordCheckAlertForTouchID];
            }

        }

        // update the display by reloading the table
        [self.tableView reloadData];

    }
}

#pragma mark - ButtonCell Delegate

- (void)buttonCellButtonPressed:(ButtonCell *)cell
{
    NSInteger section = (cell.tag >> 8);
    NSInteger row = cell.tag & 0xff;
    tPopupPicker2Position popupPosition = PopupPicker2Position_Full_Fading;
    NSString *headerText;

//    NSInteger curChoice = -1;
    NSArray *arrayPopupChoices = nil;

    if (SECTION_OPTIONS == section)
    {
        if (row == ROW_AUTO_LOG_OFF)
        {
            // set up current selection
            NSArray *arraySelections = [self logoutSelections];

            [self blockUser:YES];
            self.popupWheelPicker = [PopupWheelPickerView CreateForView:self.viewMain
                                                     positionRelativeTo:cell.button
                                                           withPosition:PopupWheelPickerPosition_Above
                                                            withChoices:ARRAY_LOGOUT
                                                     startingSelections:arraySelections
                                                               userData:cell
                                                            andDelegate:self];
        }
        else if (row == ROW_DEFAULT_CURRENCY)
        {
//            curChoice = [abc.arrayCurrencyNums indexOfObject:[NSNumber numberWithInt:abcAccount.settings.defaultCurrencyNum]];
//            if (curChoice == NSNotFound)
//            {
//                curChoice = -1;
//            }
            arrayPopupChoices = [ABCCurrency listCurrencyStrings];
            popupPosition = PopupPicker2Position_Full_Fading;
            headerText = @"Default Currency";

        }
    }
    else if (SECTION_DEFAULT_EXCHANGE == section)
    {
//        curChoice = NSNotFound;
//        curChoice = [ABCArrayExchanges indexOfObject:abcAccount.settings.exchangeRateSource];
//        if (curChoice == NSNotFound)
//        {
//            curChoice = -1;
//        }
        arrayPopupChoices = ABCArrayExchanges;
        headerText = @"Exchange Rate Data Source";
    }

    // if we are supposed to bring up a popup picker
    if (arrayPopupChoices)
    {
        [self blockUser:YES];
        self.popupPicker = [PopupPickerView2 CreateForView:self.viewMain
                                          relativePosition:popupPosition
                                               withStrings:arrayPopupChoices
                                             withAccessory:nil
                                                headerText:headerText
                            ];
        self.popupPicker.userData = cell;
		//prevent popup from extending behind tool bar
		self.popupPicker.delegate = self;
    }
}

#pragma mark - Button Only Cell Delegate

- (void)buttonOnlyCellButtonPressed:(ButtonOnlyCell *)cell
{
    NSInteger section = (cell.tag >> 8);
    NSInteger row     = (cell.tag & 0xff);
    if (section == SECTION_DEBUG) {
        if (row == 0)
        {
            Affiliate *affiliate = [Affiliate alloc];

            [affiliate getAffliateURL:^(NSString *url)
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Affiliate Link"
                                                                message:url
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            } error:^
            {

            }];
        }
        else if (row == 1)
        {
            [self bringUpDebugView];
        }
    }
}

#pragma mark - Popup Picker Delegate Methods

- (void)PopupPickerView2Selected:(PopupPickerView2 *)view onRow:(NSInteger)row userData:(id)data
{
    UITableViewCell *cell = (UITableViewCell *)data;
    NSInteger sectionCell = (cell.tag >> 8);
    NSInteger rowCell = cell.tag & 0xff;

    if (SECTION_OPTIONS == sectionCell)
    {
        if (rowCell == ROW_DEFAULT_CURRENCY)
        {
            abcAccount.settings.defaultCurrency = [ABCCurrency listCurrencies][row];
            [FadingAlertView create:self.view message:defaultCurrencyInfoText holdTime:FADING_ALERT_HOLD_TIME_FOREVER_ALLOW_TAP];
        }
    }
    else if (SECTION_DEFAULT_EXCHANGE == sectionCell)
    {
        abcAccount.settings.exchangeRateSource = ABCArrayExchanges[row];
    }

    // update the settings in the core
    [self saveSettings];

    // update the display by reloading the table
    [self.tableView reloadData];

    [self dismissPopupPicker];
}

- (void)PopupPickerView2Cancelled:(PopupPickerView2 *)view userData:(id)data
{
    // dismiss the picker
    [self dismissPopupPicker];
}

#pragma mark - Popup Wheel Picker Delegate Methods

- (void)PopupWheelPickerViewExit:(PopupWheelPickerView *)view withSelections:(NSArray *)arraySelections userData:(id)data
{
    int amount = [[[ARRAY_LOGOUT objectAtIndex:0] objectAtIndex:[[arraySelections objectAtIndex:0] intValue]] intValue];
    int type   = [[arraySelections objectAtIndex:1] intValue];
    abcAccount.settings.secondsAutoLogout = amount * [ARRAY_LOGOUT_SECONDS[type] intValue];

    // update the settings in the core
    [self saveSettings];

    // update the display by reloading the table
    [self.tableView reloadData];

    [self dismissPopupPicker];
}

- (void)PopupWheelPickerViewCancelled:(PopupWheelPickerView *)view userData:(id)data
{
    [self dismissPopupPicker];
}


-(void) sendDebugViewControllerDidFinish:(DebugViewController *)controller
{
    [MainViewController animateOut:controller withBlur:NO complete:^
    {
        _debugViewController = nil;
        [self updateViews];
    }];
}

#pragma mark - UIAlertView callbacks

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (alertView == _passwordCheckAlert)
    {
        if (0 == buttonIndex)
        {
            //
            // Need to disable TouchID in settings.
            //
            // Disable TouchID in LocalSettings
            [abcAccount.settings disableTouchID];
            [MainViewController fadingAlert:NSLocalizedString(@"Touch ID Disabled", nil)];
        }
        else
        {
            //
            // Check the password
            //
            _tempPassword = [[alertView textFieldAtIndex:0] text];

            [FadingAlertView create:self.view
                            message:NSLocalizedString(@"Checking password...", nil)
                           holdTime:FADING_ALERT_HOLD_TIME_FOREVER_WITH_SPINNER notify:^(void) {
                if ([abcAccount.settings enableTouchID:_tempPassword])
                {
                    _tempPassword = nil;
                    [MainViewController fadingAlert:NSLocalizedString(@"Touch ID Enabled", nil)];
                    
                    // Enable Touch ID
                    [self.tableView reloadData];
                    
                }
                else
                {
                    [MainViewController fadingAlertDismiss];
                    _tempPassword = nil;
                    _passwordIncorrectAlert = [[UIAlertView alloc]
                                               initWithTitle:NSLocalizedString(@"Incorrect Password", nil)
                                               message:NSLocalizedString(@"Try again?", nil)
                                               delegate:self
                                               cancelButtonTitle:@"NO"
                                               otherButtonTitles:@"YES", nil];
                    [_passwordIncorrectAlert show];
                }
            }];
        }
    }
    else if (_passwordIncorrectAlert == alertView)
    {
        if (buttonIndex == 0)
        {
            [MainViewController fadingAlert:NSLocalizedString(@"Touch ID Disabled", nil)];
            [abcAccount.settings disableTouchID];
        }
        else if (buttonIndex == 1)
        {
            [self showPasswordCheckAlertForTouchID];
        }
    }
}

- (void)showPasswordCheckAlertForTouchID
{
    // Popup to ask user for their password
    NSString *title = NSLocalizedString(@"Touch ID", nil);
    NSString *message = NSLocalizedString(@"Please enter your password to enable Touch ID", nil);
    // show password reminder test
    _passwordCheckAlert = [[UIAlertView alloc] initWithTitle:title
                                                     message:message
                                                    delegate:self
                                           cancelButtonTitle:@"Later"
                                           otherButtonTitles:@"OK", nil];
    _passwordCheckAlert.alertViewStyle = UIAlertViewStyleSecureTextInput;
    [_passwordCheckAlert show];
}

@end

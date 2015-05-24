//
//  SettingsViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "SettingsViewController.h"
#import "RadioButtonCell.h"
#import "ABC.h"
#import "User.h"
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
#import "CoreBridge.h"
#import "Theme.h"
#import "MainViewController.h"
#import "PopupPickerView.h"
#import <CoreBluetooth/CoreBluetooth.h>

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

#define ARRAY_EXCHANGES     @[@"Bitstamp", @"BraveNewCoin", @"Coinbase"]

#define ARRAY_LOGOUT        @[@[@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9", \
                                @"10",@"11",@"12",@"13",@"14",@"15",@"16",@"17",@"18",@"19", \
                                @"20",@"21",@"22",@"23",@"24",@"25",@"26",@"27",@"28",@"29", \
                                @"30",@"31",@"32",@"33",@"34",@"35",@"36",@"37",@"38",@"39", \
                                @"40",@"41",@"42",@"43",@"44",@"45",@"46",@"47",@"48",@"49", \
                                @"50",@"51",@"52",@"53",@"54",@"55",@"56",@"57",@"58",@"59", \
                                @"60"], \
                              @[@"minute(s)",@"hour(s)",@"day(s)"]]
#define ARRAY_LOGOUT_MINUTES @[@1, @60, @1440] // how many minutes in each of the 'types'



#define PICKER_MAX_CELLS_VISIBLE        (!IS_IPHONE4 ? 9 : 8)
#define PICKER_WIDTH                    160
#define PICKER_CELL_HEIGHT              44

typedef struct sDenomination
{
    char *szLabel;
    int64_t satoshi;
} tDenomination ;

tDenomination gaDenominations[DENOMINATION_CHOICES] = {
    {
        "BTC", 100000000 // ABC_DENOMINATION_BTC = 0
    },
    {
        "mBTC", 100000 // ABC_DENOMINATION_MBTC = 1
    },
    {
        "bits", 100 // ABC_DENOMINATION_UBTC = 2
    }
};


@interface SettingsViewController () <UITableViewDataSource, UITableViewDelegate, BooleanCellDelegate, ButtonCellDelegate, TextFieldCellDelegate,
                                      ButtonOnlyCellDelegate, SignUpViewControllerDelegate, PasswordRecoveryViewControllerDelegate,
                                      PopupPickerView2Delegate, PopupWheelPickerViewDelegate, CategoriesViewControllerDelegate,
                                      SpendingLimitsViewControllerDelegate, TwoFactorShowViewControllerDelegate, DebugViewControllerDelegate,
                                      CBCentralManagerDelegate>
{
    tABC_Currency                   *_aCurrencies;
    int                             _currencyCount;
	tABC_AccountSettings            *_pAccountSettings;
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
}

@property (nonatomic, weak) IBOutlet UITableView    *tableView;
@property (weak, nonatomic) IBOutlet UIView         *viewMain;

@property (nonatomic, strong) PopupPickerView2       *popupPicker;
@property (nonatomic, strong) PopupWheelPickerView  *popupWheelPicker;
@property (nonatomic, strong) UIButton              *buttonBlocker;

@property (nonatomic, strong) NSArray               *arrayCurrencyCodes;
@property (nonatomic, strong) NSArray               *arrayCurrencyNums;
@property (nonatomic, strong) NSArray               *arrayCurrencyStrings;
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
    [MainViewController changeNavBarTitle:self title:[Theme Singleton].settingsText];

    [MainViewController changeNavBar:self title:[Theme Singleton].backButtonText side:NAV_BAR_LEFT button:true enable:false action:nil fromObject:self];
    [MainViewController changeNavBar:self title:[Theme Singleton].helpButtonText side:NAV_BAR_RIGHT button:true enable:true action:@selector(Info) fromObject:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	self.centralManager = nil;
}

- (void)refresh:(NSNotification *)notification
{	
	tABC_Error Error;
    Error.code = ABC_CC_Ok;

    // get the currencies
    _aCurrencies = NULL;
    ABC_GetCurrencies(&_aCurrencies, &_currencyCount, &Error);
    [Util printABC_Error:&Error];

    // set up our internal currency arrays
    NSMutableArray *arrayCurrencyCodes = [[NSMutableArray alloc] initWithCapacity:_currencyCount];
    NSMutableArray *arrayCurrencyNums = [[NSMutableArray alloc] initWithCapacity:_currencyCount];
    NSMutableArray *arrayCurrencyStrings = [[NSMutableArray alloc] init];
    for (int i = 0; i < _currencyCount; i++)
    {
        [arrayCurrencyStrings addObject:[NSString stringWithFormat:@"%s - %@",
                                        _aCurrencies[i].szCode,
                                        [NSString stringWithUTF8String:_aCurrencies[i].szDescription]]];
        [arrayCurrencyNums addObject:[NSNumber numberWithInt:_aCurrencies[i].num]];
        [arrayCurrencyCodes addObject:[NSString stringWithUTF8String:_aCurrencies[i].szCode]];
    }
    self.arrayCurrencyCodes = arrayCurrencyCodes;
    self.arrayCurrencyNums = arrayCurrencyNums;
    self.arrayCurrencyStrings = arrayCurrencyStrings;

    // load the current account settings
    _pAccountSettings = NULL;
    ABC_LoadAccountSettings([[User Singleton].name UTF8String],
                            [[User Singleton].password UTF8String],
                            &_pAccountSettings,
                            &Error);
    [Util printABC_Error:&Error];
	
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
	if (_pAccountSettings)
	{
		ABC_FreeAccountSettings(_pAccountSettings);
	}
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
    // update the settings in the core
    tABC_Error Error;
    ABC_UpdateAccountSettings([[User Singleton].name UTF8String],
                              [[User Singleton].password UTF8String],
                              _pAccountSettings,
                              &Error);
    if (ABC_CC_Ok == Error.code)
    {
        [[User Singleton] loadSettings];
    }
    else
    {
        UIAlertView *alert = [[UIAlertView alloc]
                            initWithTitle:NSLocalizedString(@"Unable to save Settings", nil)
                            message:[NSString stringWithFormat:@"%@", [Util errorMap:&Error]]
                            delegate:self
                            cancelButtonTitle:@"Cancel"
                            otherButtonTitles:@"OK", nil];
        [alert show];
        [Util printABC_Error:&Error];
    }
}

// replaces the string in the given variable with a duplicate of another
- (void)replaceString:(char **)ppszValue withString:(const char *)szNewValue
{
    if (ppszValue)
    {
        if (*ppszValue)
        {
            free(*ppszValue);
        }
        *ppszValue = strdup(szNewValue);
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

// looks for the denomination choice in the settings
- (NSInteger)denominationChoice
{
    NSInteger retVal = 0;

    if (_pAccountSettings)
    {
        retVal = (NSInteger) _pAccountSettings->bitcoinDenomination.denominationType;
    }

    return retVal;
}

// modifies the denomination choice in the settings
- (void)setDenominationChoice:(NSInteger)nChoice
{
    if (_pAccountSettings)
    {
        // set the new values
        _pAccountSettings->bitcoinDenomination.satoshi = gaDenominations[nChoice].satoshi;
        _pAccountSettings->bitcoinDenomination.denominationType = (int) nChoice;
        
        // update the settings in the core
        [self saveSettings];
    }
}

- (void)bringUpSignUpViewInMode:(tSignUpMode)mode
{
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
    _signUpController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SignUpViewController"];

    _signUpController.mode = mode;
    _signUpController.delegate = self;

    CGRect frame = self.view.bounds;
    frame.origin.x = frame.size.width;
    _signUpController.view.frame = frame;
    [self.view addSubview:_signUpController.view];

    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         _signUpController.view.frame = self.view.bounds;
     }
                     completion:^(BOOL finished)
     {
         [[UIApplication sharedApplication] endIgnoringInteractionEvents];
     }];
}

- (void)bringUpRecoveryQuestionsView
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	_passwordRecoveryController = [mainStoryboard instantiateViewControllerWithIdentifier:@"PasswordRecoveryViewController"];

	_passwordRecoveryController.delegate = self;
	_passwordRecoveryController.mode = PassRecovMode_Change;

    [Util addSubviewControllerWithConstraints:self.view child:_passwordRecoveryController];
    [MainViewController animateSlideIn:_passwordRecoveryController];

}

- (void)bringUpCategoriesView
{
    {
        UIStoryboard *settingsStoryboard = [UIStoryboard storyboardWithName:@"Settings" bundle: nil];
        _categoriesController = [settingsStoryboard instantiateViewControllerWithIdentifier:@"CategoriesViewController"];

        _categoriesController.delegate = self;

        [Util addSubviewControllerWithConstraints:self.view child:_categoriesController];
        [MainViewController animateSlideIn:_categoriesController];

    }
}

- (void)bringUpSpendingLimits
{
    {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
        _spendLimitsController = [mainStoryboard instantiateViewControllerWithIdentifier:@"SpendingLimitsViewController"];
        _spendLimitsController.delegate = self;

        [Util addSubviewControllerWithConstraints:self.view child:_spendLimitsController];

        [MainViewController animateSlideIn:_spendLimitsController];
    }
}

- (void)bringUpTwoFactor
{
    UIStoryboard *settingsStoryboard = [UIStoryboard storyboardWithName:@"Settings" bundle: nil];
    _tfaViewController = [settingsStoryboard instantiateViewControllerWithIdentifier:@"TwoFactorShowViewController"];
    _tfaViewController.delegate = self;

    [Util addSubviewControllerWithConstraints:self.view child:_tfaViewController];
    [MainViewController animateSlideIn:_tfaViewController];

}

- (void)bringUpDebugView
{
    UIStoryboard *settingsStoryboard = [UIStoryboard storyboardWithName:@"Settings" bundle: nil];
    _debugViewController = [settingsStoryboard instantiateViewControllerWithIdentifier:@"DebugViewController"];
    _debugViewController.delegate = self;

    [Util addSubviewControllerWithConstraints:self.view child:_debugViewController];
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

        //NSLog(@"y coord = %f", theView.frame.origin.y);
        //NSLog(@"y coord in window = %f", pointInWindow.y);
        //NSLog(@"dist from bottom = %f", distFromBottom);
        //NSLog(@"amount Obscured = %f", obscureAmount);
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
    //NSLog(@"obscure amount final = %f", obscureAmount);
    if (obscureAmount != 0.0)
    {
        // it is obscured so move it to compensate
        //NSLog(@"need to compensate");
        newFrame.origin.y -= obscureAmount;
    }

    //NSLog(@"old origin: %f, new origin: %f", _frameStart.origin.y, newFrame.origin.y);

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

// searches the exchanges in the settings for the exchange associated with the given currency number
// NULL is returned if none can be found
// gets the string for the 'auto log off after' button
- (NSString *)logoutDisplay
{
    NSMutableString *strRetVal = [[NSMutableString alloc] init];

    if (_pAccountSettings)
    {
        int amount = 0;
        NSString *strType = @"";
        NSInteger maxVal = [[[ARRAY_LOGOUT objectAtIndex:0] lastObject] intValue];
        if (_pAccountSettings->minutesAutoLogout <= [[ARRAY_LOGOUT_MINUTES objectAtIndex:0] integerValue] * maxVal)
        {
            strType = @"minute";
            amount = _pAccountSettings->minutesAutoLogout;
        }
        else if (_pAccountSettings->minutesAutoLogout <= [[ARRAY_LOGOUT_MINUTES objectAtIndex:1] integerValue] * maxVal)
        {
            strType = @"hour";
            amount = _pAccountSettings->minutesAutoLogout / [[ARRAY_LOGOUT_MINUTES objectAtIndex:1] integerValue];
        }
        else
        {
            strType = @"day";
            amount = _pAccountSettings->minutesAutoLogout / [[ARRAY_LOGOUT_MINUTES objectAtIndex:2] integerValue];
        }

        [strRetVal appendFormat:@"%d %@", amount, strType];
        if (amount != 1)
        {
            [strRetVal appendString:@"s"];
        }
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
        if (_pAccountSettings->minutesAutoLogout <= [[ARRAY_LOGOUT_MINUTES objectAtIndex:type] integerValue] * maxVal)
        {
            finalType = type;
            for (int amountIndex = 0; amountIndex < [[ARRAY_LOGOUT objectAtIndex:0] count]; amountIndex++)
            {
                int minutesBase = [[[ARRAY_LOGOUT objectAtIndex:0] objectAtIndex:amountIndex] intValue];
                int minutesMult = [[ARRAY_LOGOUT_MINUTES objectAtIndex:type] intValue];
                if (_pAccountSettings->minutesAutoLogout >= (minutesBase * minutesMult))
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
        _signUpController = nil;
    }
    if (_passwordRecoveryController)
    {
        [_passwordRecoveryController.view removeFromSuperview];
        _passwordRecoveryController = nil;
    }
    if (_categoriesController)
    {
        [_categoriesController.view removeFromSuperview];
        _categoriesController = nil;
    }
    if (_spendLimitsController)
    {
        [_spendLimitsController.view removeFromSuperview];
        _spendLimitsController = nil;
    }
    if (_tfaViewController)
    {
        [_tfaViewController.view removeFromSuperview];
        _tfaViewController = nil;
    }
    if (_debugViewController)
    {
        [_debugViewController.view removeFromSuperview];
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
            [self replaceString:&(_pAccountSettings->szFirstName) withString:[cell.textField.text UTF8String]];
        }
        else if (row == ROW_LAST_NAME)
        {
            [self replaceString:&(_pAccountSettings->szLastName) withString:[cell.textField.text UTF8String]];
        }
        else if (row == ROW_NICKNAME)
        {
            [self replaceString:&(_pAccountSettings->szNickname) withString:[cell.textField.text UTF8String]];
        }

        [self saveSettings];
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

- (RadioButtonCell *)getRadioButtonCellForTableView:(UITableView *)tableView withImage:(UIImage *)bkgImage andIndexPath:(NSIndexPath *)indexPath
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
	cell.radioButton.image = [UIImage imageNamed:(indexPath.row == [self denominationChoice] ? @"btn_selected" : @"btn_unselected")];

    cell.tag = (indexPath.section << 8) | (indexPath.row);

	return cell;
}

- (PlainCell *)getPlainCellForTableView:(UITableView *)tableView withImage:(UIImage *)bkgImage andIndexPath:(NSIndexPath *)indexPath
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

- (TextFieldCell *)getTextFieldCellForTableView:(UITableView *)tableView withImage:(UIImage *)bkgImage andIndexPath:(NSIndexPath *)indexPath
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
            if (_pAccountSettings && _pAccountSettings->szFirstName)
            {
                cell.textField.text = [NSString stringWithUTF8String:_pAccountSettings->szFirstName];
            }
		}
		if (indexPath.row == 2)
		{
			cell.textField.placeholder = NSLocalizedString(@"Last Name (optional)", @"settings text");
            cell.textField.returnKeyType = UIReturnKeyNext;
            if (_pAccountSettings && _pAccountSettings->szLastName)
            {
                cell.textField.text = [NSString stringWithUTF8String:_pAccountSettings->szLastName];
            }
		}
		if (indexPath.row == 3)
		{
			cell.textField.placeholder = NSLocalizedString(@"Nickname / Handle (optional)", @"settings text");
            cell.textField.returnKeyType = UIReturnKeyDone;
            if (_pAccountSettings && _pAccountSettings->szNickname)
            {
                cell.textField.text = [NSString stringWithUTF8String:_pAccountSettings->szNickname];
            }
		}

        cell.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        cell.textField.spellCheckingType = UITextSpellCheckingTypeNo;

        cell.textField.enabled = _pAccountSettings->bNameOnPayments;
        cell.textField.textColor = cell.textField.enabled ? [UIColor whiteColor] : [UIColor grayColor];
	}

    cell.tag = (indexPath.section << 8) | (indexPath.row);
	
	return cell;
}

- (BooleanCell *)getBooleanCellForTableView:(UITableView *)tableView withImage:(UIImage *)bkgImage andIndexPath:(NSIndexPath *)indexPath
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
            if (_pAccountSettings)
            {
                [cell.state setOn:_pAccountSettings->bNameOnPayments animated:NO];
            }
		}
	}
    else if (indexPath.section == SECTION_OPTIONS)
    {
        if (indexPath.row == ROW_BLE)
        {
			cell.name.text = NSLocalizedString(@"Bluetooth", @"settings text");
            [cell.state setOn:!LocalSettings.controller.bDisableBLE animated:NO];
        }
        else if (indexPath.row == ROW_MERCHANT_MODE)
        {
			cell.name.text = NSLocalizedString(@"Merchant Mode", @"settings text");
            [cell.state setOn:LocalSettings.controller.bMerchantMode animated:NO];
        }
        else if (indexPath.row == ROW_PIN_RELOGIN)
        {
			cell.name.text = NSLocalizedString(@"PIN Re-Login", @"settings text");
            if(_pAccountSettings) {
                [cell.state setOn:!_pAccountSettings->bDisablePINLogin animated:NO];
            }
            if ([CoreBridge passwordExists]) {
                cell.state.userInteractionEnabled = YES;
            } else {
                cell.state.userInteractionEnabled = NO;
            }
        }
    }
	
    cell.tag = (indexPath.section << 8) | (indexPath.row);

	return cell;
}

- (ButtonCell *)getButtonCellForTableView:(UITableView *)tableView withImage:(UIImage *)bkgImage andIndexPath:(NSIndexPath *)indexPath
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
            if (_pAccountSettings)
            {
                NSInteger indexCurrency = [self.arrayCurrencyNums indexOfObject:[NSNumber numberWithInt:_pAccountSettings->currencyNum]];
                if (indexCurrency != NSNotFound)
                {
                    [cell.button setTitle:[self.arrayCurrencyCodes objectAtIndex:indexCurrency] forState:UIControlStateNormal];
                }
            }
		}
	}
	if (indexPath.section == SECTION_DEFAULT_EXCHANGE)
	{
		if (indexPath.row == 0)
		{
			cell.name.text = NSLocalizedString(@"Default Exchange", @"settings text");
		}
        char *szSource = _pAccountSettings->szExchangeRateSource;
        if (szSource) {
            [cell.button setTitle:[NSString stringWithUTF8String:szSource] forState:UIControlStateNormal];
        } else {
            [cell.button setTitle:@"" forState:UIControlStateNormal];
        }
	}

    cell.tag = (indexPath.section << 8) | (indexPath.row);

	return cell;
}

- (ButtonOnlyCell *)getLogoutButton:(UITableView *)tableView withIndexPath:(NSIndexPath *)indexPath
{
    ButtonOnlyCell *cell;
    static NSString *cellIdentifier = @"ButtonOnlyCell";
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (nil == cell)
    {
        cell = [[ButtonOnlyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.delegate = self;
    [cell.button setTitle:NSLocalizedString(@"Logout", @"settings text") forState:UIControlStateNormal];
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
    [cell.button setTitle:NSLocalizedString(@"Debug", @"debug text") forState:UIControlStateNormal];
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
			//assumes bluetooth option is last of the options.
			if(_showBluetoothOption)
			{
				return 8;
			}
			else
			{
				return 7; //return 7 to not show the Bluetooth cell.
			}
            break;

        case SECTION_DEFAULT_EXCHANGE:
            return 1;
            break;

        case SECTION_DEBUG:
            return 1;
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
        label.text = [NSString stringWithFormat:@"%@ %s", label.text, [[User Singleton].name UTF8String]];
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
	return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;
    if (indexPath.section == SECTION_DEBUG) {
		cell = [self getDebugButton:tableView withIndexPath:indexPath];
	}
	else
	{
		UIImage *cellImage;
		if ((indexPath.section == SECTION_OPTIONS) || ([tableView numberOfRowsInSection:indexPath.section] == 1))
		{
			cellImage = [UIImage imageNamed:@"bd_cell_single"];
		}
		else
		{
			if (indexPath.row == 0)
			{
				cellImage = [UIImage imageNamed:@"bd_cell_top"];
				//backgroundColor = [UIColor redColor];
			}
			else
			{
				if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1)
				{
					cellImage = [UIImage imageNamed:@"bd_cell_bottom"];
					//backgroundColor = [UIColor greenColor];
				}
				else
				{
					cellImage = [UIImage imageNamed:@"bd_cell_middle"];
					//backgroundColor = [UIColor blueColor];
				}
			}
		}
		
		if (indexPath.section == SECTION_BITCOIN_DENOMINATION)
		{
			cell = [self getRadioButtonCellForTableView:tableView withImage:cellImage andIndexPath:(NSIndexPath *)indexPath];
		}
		else if (indexPath.section == SECTION_USERNAME)
		{
            cell = [self getPlainCellForTableView:tableView withImage:cellImage andIndexPath:indexPath];
		}
        else if (indexPath.section == SECTION_NAME)
		{
			if (indexPath.row == ROW_SEND_NAME)
			{
				cell = [self getBooleanCellForTableView:tableView withImage:cellImage andIndexPath:indexPath];
			}
			else
			{
				cell = [self getTextFieldCellForTableView:tableView withImage:cellImage andIndexPath:(NSIndexPath *)indexPath];
			}
		}
		else if (indexPath.section == SECTION_OPTIONS)
		{
            if (indexPath.row == ROW_CHANGE_CATEGORIES || indexPath.row == ROW_SPEND_LIMITS || indexPath.row == ROW_TFA)
            {
                cell = [self getPlainCellForTableView:tableView withImage:cellImage andIndexPath:indexPath];
            }
            else if (indexPath.row == ROW_MERCHANT_MODE)
            {
				cell = [self getBooleanCellForTableView:tableView withImage:cellImage andIndexPath:indexPath];
            }
            else if (indexPath.row == ROW_BLE)
            {
                if (_showBluetoothOption)
                {
                    cell = [self getBooleanCellForTableView:tableView withImage:cellImage andIndexPath:indexPath];
                }
                else
                {
                    NSIndexPath *temp = [NSIndexPath indexPathForRow:ROW_PIN_RELOGIN inSection:indexPath.section];
                    cell = [self getBooleanCellForTableView:tableView withImage:cellImage andIndexPath:temp];
                }
            }
            else if (indexPath.row == ROW_PIN_RELOGIN)
            {
				cell = [self getBooleanCellForTableView:tableView withImage:cellImage andIndexPath:indexPath];
            }
            else
            {
                cell = [self getButtonCellForTableView:tableView withImage:cellImage andIndexPath:(NSIndexPath *)indexPath];
            }
		}
		else if (indexPath.section == SECTION_DEFAULT_EXCHANGE)
		{
			cell = [self getButtonCellForTableView:tableView withImage:cellImage andIndexPath:(NSIndexPath *)indexPath];
		}
	}

	//cell.backgroundColor = backgroundColor;
//	cell.selectedBackgroundView.backgroundColor = [UIColor clearColor];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//NSLog(@"Selected section:%i, row:%i", (int)indexPath.section, (int)indexPath.row);

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
}

#pragma mark - SignUpViewControllerDelegates

-(void)signupViewControllerDidFinish:(SignUpViewController *)controller withBackButton:(BOOL)bBack
{
    [MainViewController animateOut:controller withBlur:NO complete:^(void)
            {
                    _signUpController = nil;
            }];

    // re-load the current account settings
    _pAccountSettings = NULL;
	tABC_Error Error;
    Error.code = ABC_CC_Ok;
    ABC_LoadAccountSettings([[User Singleton].name UTF8String],
                            [[User Singleton].password UTF8String],
                            &_pAccountSettings,
                            &Error);

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
        if (_pAccountSettings)
        {
            _pAccountSettings->bNameOnPayments = theSwitch.on;
        }

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
        _pAccountSettings->bDisablePINLogin = !theSwitch.on;
        [self saveSettings];
        
        // update the display by reloading the table
        [self.tableView reloadData];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
        {
            if (theSwitch.on)
            {
                [CoreBridge setupLoginPIN];
            }
            else
            {
                [CoreBridge deletePINLogin];
            }
        });
    }
}

#pragma mark - ButtonCell Delegate

- (void)buttonCellButtonPressed:(ButtonCell *)cell
{
    NSInteger section = (cell.tag >> 8);
    NSInteger row = cell.tag & 0xff;
    NSInteger pickerWidth = PICKER_WIDTH;
    tPopupPicker2Position popupPosition = PopupPicker2Position_Full_Fading;
    NSString *headerText;

    NSInteger curChoice = -1;
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
            if (_pAccountSettings)
            {
                curChoice = [self.arrayCurrencyNums indexOfObject:[NSNumber numberWithInt:_pAccountSettings->currencyNum]];
                if (curChoice == NSNotFound)
                {
                    curChoice = -1;
                }
            }
            arrayPopupChoices = self.arrayCurrencyStrings;
            popupPosition = PopupPicker2Position_Full_Fading;
            headerText = @"Default Currency";

        }
    }
    else if (SECTION_DEFAULT_EXCHANGE == section)
    {
        curChoice = NSNotFound;
        char *szSource = _pAccountSettings->szExchangeRateSource;
        if (szSource)
        {
            curChoice = [ARRAY_EXCHANGES indexOfObject:[NSString stringWithUTF8String:szSource]];
        }
        if (curChoice == NSNotFound)
        {
            curChoice = -1;
        }
        arrayPopupChoices = ARRAY_EXCHANGES;
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
    if (section == SECTION_DEBUG) {
        [self bringUpDebugView];
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
            if (_pAccountSettings)
            {
                _pAccountSettings->currencyNum = [[self.arrayCurrencyNums objectAtIndex:row] intValue];
            }
        }
    }
    else if (SECTION_DEFAULT_EXCHANGE == sectionCell)
    {
        const char *szSourceSel = [[ARRAY_EXCHANGES objectAtIndex:row] UTF8String];
        _pAccountSettings->szExchangeRateSource = strdup(szSourceSel);
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

    // set the amount of minutes
    if (_pAccountSettings)
    {
        _pAccountSettings->minutesAutoLogout = amount * [[ARRAY_LOGOUT_MINUTES objectAtIndex:type] intValue];
    }

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
	[controller.view removeFromSuperview];
	_debugViewController = nil;
}

@end

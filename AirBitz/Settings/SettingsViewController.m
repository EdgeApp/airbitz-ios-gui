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
#import "PasswordRecoveryViewController.h"
#import "PopupPickerView.h"

#define DISTANCE_ABOVE_KEYBOARD             10  // how far above the keyboard to we want the control
#define ANIMATION_DURATION_KEYBOARD_UP      0.30
#define ANIMATION_DURATION_KEYBOARD_DOWN    0.25

#define SECTION_BITCOIN_DENOMINATION    0
#define SECTION_USERNAME                1
#define SECTION_NAME                    2
#define SECTION_OPTIONS                 3
#define SECTION_DEFAULT_EXCHANGE        4
#define SECTION_LOGOUT                  5
#define SECTION_COUNT                   6

#define DENOMINATION_CHOICES            3

#define ROW_PASSWORD                    0
#define ROW_PIN                         1
#define ROW_RECOVERY_QUESTIONS          2

#define ROW_FIRST_NAME                  1
#define ROW_LAST_NAME                   2
#define ROW_NICKNAME                    3

#define ROW_AUTO_LOG_OFF                0
#define ROW_LANGUAGE                    1
#define ROW_DEFAULT_CURRENCY            2

typedef struct sDenomination
{
    char *szLabel;
    int64_t satoshi;
} tDenomination ;

tDenomination gaDenominations[DENOMINATION_CHOICES] = {
    {
        "Bitcoin", 100000000
    },
    {
        "mBitcoin", 100000
    },
    {
        "uBitcoin", 100
    }
};


@interface SettingsViewController () <UITableViewDataSource, UITableViewDelegate, BooleanCellDelegate, ButtonCellDelegate, TextFieldCellDelegate, ButtonOnlyCellDelegate, SignUpViewControllerDelegate, PasswordRecoveryViewControllerDelegate, PopupPickerViewDelegate>
{
	tABC_AccountSettings            *_pAccountSettings;
	TextFieldCell                   *_activeTextFieldCell;
	UITapGestureRecognizer          *_tapGesture;
    SignUpViewController            *_signUpController;
    PasswordRecoveryViewController  *_passwordRecoveryController;
    BOOL                            _bKeyboardIsShown;
    CGRect                          _frameStart;
    CGFloat                         _keyboardHeight;
}

@property (nonatomic, weak) IBOutlet UITableView    *tableView;
@property (weak, nonatomic) IBOutlet UIView         *viewMain;

@property (nonatomic, strong) PopupPickerView       *popupPicker;
@property (nonatomic, strong) UIButton              *buttonBlocker;

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

	// Do any additional setup after loading the view.
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.tableView.delaysContentTouches = NO;
	
	tABC_Error Error;
    Error.code = ABC_CC_Ok;

    _pAccountSettings = NULL;
    ABC_LoadAccountSettings([[User Singleton].name UTF8String],
                            [[User Singleton].password UTF8String],
                            &_pAccountSettings,
                            &Error);
    [self printABC_Error:&Error];
	
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

    self.popupPicker = nil;
    self.buttonBlocker = [UIButton buttonWithType:UIButtonTypeCustom];
    self.buttonBlocker.backgroundColor = [UIColor clearColor];
    [self.buttonBlocker addTarget:self action:@selector(buttonBlockerTouched:) forControlEvents:UIControlEventTouchUpInside];
    self.buttonBlocker.frame = self.view.bounds;
    self.buttonBlocker.hidden = YES;
    [self.view addSubview:self.buttonBlocker];
}

-(void)dealloc
{
	if(_pAccountSettings)
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

#pragma mark - Misc Methods

- (void)saveSettings
{
    // update the settings in the core
    tABC_Error Error;
    ABC_UpdateAccountSettings([[User Singleton].name UTF8String],
                              [[User Singleton].password UTF8String],
                              _pAccountSettings,
                              &Error);
    [self printABC_Error:&Error];
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
        for (int i = 0; i < DENOMINATION_CHOICES; i++)
        {
            if (_pAccountSettings->bitcoinDenomination.satoshi == gaDenominations[i].satoshi)
            {
                retVal = i;
                break;
            }
        }
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
        [self replaceString:&(_pAccountSettings->bitcoinDenomination.szLabel) withString:gaDenominations[nChoice].szLabel];

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

    [UIView animateWithDuration:0.35
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^
     {
         _signUpController.view.frame = self.view.bounds;
     }
                     completion:^(BOOL finished)
     {
     }];
}

- (void)bringUpRecoveryQuestionsView
{
	UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle: nil];
	_passwordRecoveryController = [mainStoryboard instantiateViewControllerWithIdentifier:@"PasswordRecoveryViewController"];

	_passwordRecoveryController.delegate = self;
	_passwordRecoveryController.mode = PassRecovMode_Change;

	CGRect frame = self.view.bounds;
	frame.origin.x = frame.size.width;
	_passwordRecoveryController.view.frame = frame;
	[self.view addSubview:_passwordRecoveryController.view];


	[UIView animateWithDuration:0.35
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 _passwordRecoveryController.view.frame = self.view.bounds;
	 }
					 completion:^(BOOL finished)
	 {
	 }];
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

    [self blockUser:NO];
}

- (void)printABC_Error:(const tABC_Error *)pError
{
    if (pError)
    {
        if (pError->code != ABC_CC_Ok)
        {
            printf("Code: %d, Desc: %s, Func: %s, File: %s, Line: %d\n",
                   pError->code,
                   pError->szDescription,
                   pError->szSourceFunc,
                   pError->szSourceFile,
                   pError->nSourceLine
                   );
        }
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
	NSLog(@"Info button pressed");
}

- (void)buttonOnlyCellButtonPressed:(ButtonOnlyCell *)cell
{
	NSLog(@"Change Categories");
	//log out for now
	[[User Singleton] clear];
	[self.delegate SettingsViewControllerDone:self];
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
	cell.bkgImage.image = bkgImage;
	
	if (indexPath.row == 0)
	{
		cell.name.text = NSLocalizedString(@"Bitcoin", @"settings text");
	}
	if (indexPath.row == 1)
	{
		cell.name.text = NSLocalizedString(@"mBitcoin = (0.001 Bitcoin)", @"settings text");
	}
	if (indexPath.row == 2)
	{
		cell.name.text = NSLocalizedString(@"uBitcoin = (0.000001 Bitcoin)", @"settings text");
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
	cell.bkgImage.image = bkgImage;
	
	if (indexPath.section == SECTION_USERNAME)
	{
		if (indexPath.row == 0)
		{
			cell.name.text = NSLocalizedString(@"Change password", @"settings text");
		}
		if (indexPath.row == 1)
		{
			cell.name.text = NSLocalizedString(@"Change withdrawal PIN", @"settings text");
		}
		if (indexPath.row == 2)
		{
			cell.name.text = NSLocalizedString(@"Change recovery questions", @"settings text");
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
	cell.bkgImage.image = bkgImage;
	cell.delegate = self;
	if (indexPath.section == SECTION_NAME)
	{
		if (indexPath.row == 1)
		{
			cell.textField.placeholder = NSLocalizedString(@"First Name (optional)", @"settings text");
            cell.textField.returnKeyType = UIReturnKeyNext;
            if (_pAccountSettings->szFirstName)
            {
                cell.textField.text = [NSString stringWithUTF8String:_pAccountSettings->szFirstName];
            }
		}
		if (indexPath.row == 2)
		{
			cell.textField.placeholder = NSLocalizedString(@"Last Name (optional)", @"settings text");
            cell.textField.returnKeyType = UIReturnKeyNext;
            if (_pAccountSettings->szLastName)
            {
                cell.textField.text = [NSString stringWithUTF8String:_pAccountSettings->szLastName];
            }
		}
		if (indexPath.row == 3)
		{
			cell.textField.placeholder = NSLocalizedString(@"Nickname / Handle", @"settings text");
            cell.textField.returnKeyType = UIReturnKeyDone;
            if (_pAccountSettings->szNickname)
            {
                cell.textField.text = [NSString stringWithUTF8String:_pAccountSettings->szNickname];
            }
		}

        cell.textField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        cell.textField.spellCheckingType = UITextSpellCheckingTypeNo;

        cell.textField.enabled = _pAccountSettings->bNameOnPayments;
        cell.textField.textColor = cell.textField.enabled ? [UIColor blackColor] : [UIColor grayColor];
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
	cell.bkgImage.image = bkgImage;
	cell.delegate = self;
	if (indexPath.section == SECTION_NAME)
	{
		if (indexPath.row == 0)
		{
			cell.name.text = NSLocalizedString(@"Send name on payment", @"settings text");
            [cell.state setOn:_pAccountSettings->bNameOnPayments animated:NO];
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
	cell.bkgImage.image = bkgImage;
	cell.delegate = self;
	if (indexPath.section == SECTION_OPTIONS)
	{
		if (indexPath.row == 0)
		{
			cell.name.text = NSLocalizedString(@"Auto log off after", @"settings text");
		}
		if (indexPath.row == 1)
		{
			cell.name.text = NSLocalizedString(@"Language", @"settings text");
		}
		if (indexPath.row == 2)
		{
			cell.name.text = NSLocalizedString(@"Default Currency", @"settings text");
		}
	}
	if (indexPath.section == SECTION_DEFAULT_EXCHANGE)
	{
		if (indexPath.row == 0)
		{
			cell.name.text = NSLocalizedString(@"US dollar", @"settings text");
		}
		if (indexPath.row == 1)
		{
			cell.name.text = NSLocalizedString(@"Canadian dollar", @"settings text");
		}
		if (indexPath.row == 2)
		{
			cell.name.text = NSLocalizedString(@"Euro", @"settings text");
		}
		if (indexPath.row == 3)
		{
			cell.name.text = NSLocalizedString(@"Mexican Peso", @"settings text");
		}
		if (indexPath.row == 4)
		{
			cell.name.text = NSLocalizedString(@"Yuan", @"settings text");
		}
	}

    cell.tag = (indexPath.section << 8) | (indexPath.row);

	return cell;
}

- (ButtonOnlyCell *)getButtonOnlyCellForTableView:(UITableView *)tableView withIndexPath:(NSIndexPath *)indexPath
{
	ButtonOnlyCell *cell;
	static NSString *cellIdentifier = @"ButtonOnlyCell";
	
	cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (nil == cell)
	{
		cell = [[ButtonOnlyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
	}
	cell.delegate = self;
	//[cell.button setTitle:NSLocalizedString(@"Change Categories", @"settings text") forState:UIControlStateNormal]; //cw temp replace this button with log out functionality
	[cell.button setTitle:NSLocalizedString(@"Log Out", @"settings text") forState:UIControlStateNormal];
	
    cell.tag = (indexPath.section << 8) | (indexPath.row);

	return cell;
}

#pragma mark - UITableView delegates

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
            return 3;
            break;

        case SECTION_DEFAULT_EXCHANGE:
            return 5;
            break;

        case SECTION_LOGOUT:
            return 1;
            break;
            
        default:
            return 0;
            break;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ((indexPath.section == SECTION_OPTIONS) || (indexPath.section == SECTION_LOGOUT))
	{
		return 47.0;
	}

	return 37.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if (section == SECTION_LOGOUT)
	{
		return 0.0;
	}

	return 37.0;
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
		label.text = NSLocalizedString(@"USERNAME", @"section header in settings table");
	}
    if (section == SECTION_NAME)
	{
		label.text = NSLocalizedString(@"NAME", @"section header in settings table");
	}
	if (section == SECTION_OPTIONS)
	{
        label.text = @" ";
		//label.text = NSLocalizedString(@"OPTIONS", @"section header in settings table");
	}
	if (section == SECTION_DEFAULT_EXCHANGE)
	{
		label.text = NSLocalizedString(@"DEFAULT EXCHANGE", @"section header in settings table");
	}
	
	return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell;

    if (indexPath.section == SECTION_LOGOUT)
	{
		//show Change Categories button
		cell = [self getButtonOnlyCellForTableView:tableView withIndexPath:indexPath];
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
			}
			else
			{
				if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1)
				{
					cellImage = [UIImage imageNamed:@"bd_cell_bottom"];
				}
				else
				{
					cellImage = [UIImage imageNamed:@"bd_cell_middle"];
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
			if (indexPath.row == 0)
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
            cell = [self getButtonCellForTableView:tableView withImage:cellImage andIndexPath:(NSIndexPath *)indexPath];
		}
		else if (indexPath.section == SECTION_DEFAULT_EXCHANGE)
		{
			cell = [self getButtonCellForTableView:tableView withImage:cellImage andIndexPath:(NSIndexPath *)indexPath];
		}
	}

	
	cell.selectedBackgroundView.backgroundColor = [UIColor clearColor];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	//NSLog(@"Selected section:%i, row:%i", (int)indexPath.section, (int)indexPath.row);

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
            break;

        case SECTION_DEFAULT_EXCHANGE:
            break;

        case SECTION_LOGOUT:
            break;

        default:
            break;
	}
}

#pragma mark - SignUpViewControllerDelegates

-(void)signupViewControllerDidFinish:(SignUpViewController *)controller
{
	[controller.view removeFromSuperview];
	_signUpController = nil;
}

#pragma mark - PasswordRecoveryViewController Delegates

- (void)passwordRecoveryViewControllerDidFinish:(PasswordRecoveryViewController *)controller
{
	[controller.view removeFromSuperview];
	_passwordRecoveryController = nil;
}

#pragma mark - BooleanCell Delegate

- (void)booleanCell:(BooleanCell *)cell switchToggled:(UISwitch *)theSwitch
{
    NSInteger section = (cell.tag >> 8);

    // we only have one boolean cell and that's the name on payment option
    if (section == SECTION_NAME)
    {
        _pAccountSettings->bNameOnPayments = theSwitch.on;

        // update the settings in the core
        [self saveSettings];

        // update the display by reloading the table
        [self.tableView reloadData];
    }
}

#pragma mark - ButtonCell Delegate

- (void)buttonCellButtonPressed:(ButtonCell *)cell
{
    NSInteger section = (cell.tag >> 8);
    NSInteger row = cell.tag & 0xff;

    if (SECTION_OPTIONS == section)
    {
        if (row == ROW_AUTO_LOG_OFF)
        {

        }
        else if (row == ROW_LANGUAGE)
        {
            [self blockUser:YES];
            self.popupPicker = [PopupPickerView CreateForView:self.viewMain
                                              relativeToFrame:cell.button.frame
                                                 viewForFrame:[cell.button superview]
                                                 withPosition:PopupPickerPosition_Left
                                                  withStrings:@[@"English",
                                                                @"Spanish",
                                                                @"German",
                                                                @"French",
                                                                @"Italian",
                                                                @"Chinese",
                                                                @"Portuguese",
                                                                @"Japanese"]
                                                  selectedRow:-1
                                              maxCellsVisible:8
                                                    withWidth:150
                                                andCellHeight:44
                                ];
            [self.popupPicker assignDelegate:self];
        }
        else if (row == ROW_DEFAULT_CURRENCY)
        {

        }
    }
}

#pragma mark - popup picker delegate methods

- (void)PopupPickerViewExit:(PopupPickerView *)view onRow:(NSInteger)row userData:(id)data
{

}

- (void)PopupPickerViewCancelled:(PopupPickerView *)view userData:(id)data
{
    // dismiss the picker
    [self dismissPopupPicker];
}

@end

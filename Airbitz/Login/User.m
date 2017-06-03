//
//  User.m
//  AirBitz
//
//  Created by Carson Whitsett on 3/27/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "User.h"
#import "Util.h"
#import "AB.h"
#import "LocalSettings.h"
#import "Affiliate.h"
#import "Strings.h"


#define SPENDING_LIMIT_AMOUNT  @"spending_limit_amount"
#define SPENDING_LIMIT_ENABLED @"spending_limit_enabled"

#define USER_PIN_LOGIN_COUNT @"user_pin_login_count"

#define USER_PIN_LOGIN_COUNT        @"user_pin_login_count"
#define LAST_PASSWORD_LOGIN         @"LAST_PASSWORD_LOGIN"
#define PASSWORD_REMINDER_COUNT     @"PASSWORD_REMINDER_COUNT"
#define PASSWORD_REMINDER_DAYS      @"PASSWORD_REMINDER_DAYS"
#define NUM_NON_PASSWORD_LOGIN      @"NUM_NON_PASSWORD_LOGIN"
#define NUM_PASSWORD_USED           @"NUM_PASSWORD_USED"
#define PASSWORD_RECOVERY_ASK_COUNT @"PASSWORD_RECOVERY_ASK_COUNT"

#define DEFAULT_NUM_PASSWORD_USED 2
#define DEFAULT_NUM_PASSWORD_USED_W_RECOVERY 4
#define PASSWORD_DAYS_INCREMENT_POWER 2
#define PASSWORD_COUNT_INCREMENT_POWER 2
#define PASSWORD_DAYS_MAX_VALUE 64
#define PASSWORD_COUNT_MAX_VALUE 128
#define PASSWORD_WRONG_INCREMENT_DAYS 2
#define PASSWORD_WRONG_INCREMENT_COUNT 4

#define PASSWORD_REMINDER_DAYS_TO_MINS YES

static BOOL bInitialized = NO;

@interface User ()

@end

@implementation User

static User *singleton = nil;  // this will be the one and only object this static singleton class has

+ (void)initAll
{
    if (NO == bInitialized)
    {
        singleton = [[User alloc] init];
        bInitialized = YES;
    }
}

+ (void)freeAll
{
    if (YES == bInitialized)
    {
        // release our singleton
        singleton = nil;

        bInitialized = NO;
    }
}

+ (User *)Singleton
{
    return singleton;
}

+ (BOOL)isLoggedIn
{
    return (0 != abcAccount.name.length);// && abcAccount.password.length;
}

+ (void)login:(ABCAccount *)user;
{
    abcAccount = user;
    [LocalSettings saveAll];
    [[User Singleton] loadLocalSettings];
    Affiliate *affiliate = [Affiliate alloc];
    [affiliate loadAffiliateInfoFromAccountToUser];
    [User initializeCategories:user];
}

- (id)init
{
    self = [super init];
    if(self)
    {
        [self clear];
    }
    self.sendInvalidEntryCount = 0;
    self.sendState = kNormal;
    self.runLoop = [NSRunLoop currentRunLoop];
    self.PINLoginInvalidEntryCount = 0;
    self.needsPasswordCheck = NO;
    self.dictAffiliateInfo = nil;
    self.affiliateInfo = nil;

    self.lastPasswordLogin = [NSDate date];
    self.passwordReminderDays = 0;
    self.passwordReminderCount = 0;
    self.numNonPasswordLogin = 0;
    self.numPasswordUsed = 0;
    self.passwordRecoveryAskCount = 0;
    self.passwordRecoveryAskedThisStartup = NO;

    return self;
}

- (NSString *)userKey:(NSString *)base
{
    return [NSString stringWithFormat:@"%@_%@", abcAccount.name, base];
}

- (void)loadLocalSettings
{
    NSUserDefaults *localConfig = [NSUserDefaults standardUserDefaults];

    self.dailySpendLimitSatoshis = [[localConfig objectForKey:[self userKey:SPENDING_LIMIT_AMOUNT]] unsignedLongLongValue];
    self.bDailySpendLimit = [localConfig boolForKey:[self userKey:SPENDING_LIMIT_ENABLED]];
    
    self.lastPasswordLogin          = [localConfig objectForKey:[self userKey:LAST_PASSWORD_LOGIN]];
    self.passwordReminderDays       = [localConfig integerForKey:[self userKey:PASSWORD_REMINDER_DAYS]];
    self.passwordReminderCount      = [localConfig integerForKey:[self userKey:PASSWORD_REMINDER_COUNT]];
    self.numNonPasswordLogin        = [localConfig integerForKey:[self userKey:NUM_NON_PASSWORD_LOGIN]];
    self.numPasswordUsed            = [localConfig integerForKey:[self userKey:NUM_PASSWORD_USED]];
    self.passwordRecoveryAskCount   = [localConfig integerForKey:[self userKey:PASSWORD_RECOVERY_ASK_COUNT]];
    
    // Check for invalid values and add defaults
    if (self.lastPasswordLogin == nil || self.passwordReminderDays == 0 || self.passwordReminderCount == 0)
    {
        [self resetPasswordReminderToDefaults];
    }
}

- (void)resetPasswordReminderToDefaults;
{
    self.lastPasswordLogin = [NSDate date];
    if ([abc getRecovery2Token:abcAccount.name error:nil]) {
        // Recovery is setup on this account. Set some more friendly defaults
        self.numPasswordUsed = DEFAULT_NUM_PASSWORD_USED_W_RECOVERY;
        self.passwordReminderDays = pow(PASSWORD_DAYS_INCREMENT_POWER, self.numPasswordUsed);
        self.passwordReminderCount = pow(PASSWORD_COUNT_INCREMENT_POWER, self.numPasswordUsed);
    }
    else
    {
        self.numPasswordUsed = DEFAULT_NUM_PASSWORD_USED;
        self.passwordReminderDays = pow(PASSWORD_DAYS_INCREMENT_POWER, self.numPasswordUsed);
        self.passwordReminderCount = pow(PASSWORD_COUNT_INCREMENT_POWER, self.numPasswordUsed);
    }
}

- (void)saveLocalSettings
{
    NSUserDefaults *localConfig = [NSUserDefaults standardUserDefaults];
    [localConfig setObject:@(_dailySpendLimitSatoshis) forKey:[self userKey:SPENDING_LIMIT_AMOUNT]];
    [localConfig setBool:_bDailySpendLimit forKey:[self userKey:SPENDING_LIMIT_ENABLED]];

    [localConfig setObject:self.lastPasswordLogin forKey:[self userKey:LAST_PASSWORD_LOGIN]];
    [localConfig setInteger:self.passwordReminderDays forKey:[self userKey:PASSWORD_REMINDER_DAYS]];
    [localConfig setInteger:self.passwordReminderCount forKey:[self userKey:PASSWORD_REMINDER_COUNT]];
    [localConfig setInteger:self.numNonPasswordLogin forKey:[self userKey:NUM_NON_PASSWORD_LOGIN]];
    [localConfig setInteger:self.numPasswordUsed forKey:[self userKey:NUM_PASSWORD_USED]];
    [localConfig synchronize];
}

+ (void) initializeCategories:(ABCAccount *) account;
{
    if ([account.categories.listCategories count] == 0)
    {
        NSMutableArray *arrayCategories = [[NSMutableArray alloc] init];
        NSMutableArray *arrayCategories2 = [[NSMutableArray alloc] init];

        //
        // Expense categories
        //
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Air Travel", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Alcohol & Bars", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Allowance", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Amusement", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Arts", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"ATM Fee", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Auto & Transport", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Auto Insurance", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Auto Payment", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Baby Supplies", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Babysitter & Daycare", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Bank Fee", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Bills & Utilities", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Books", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Books & Supplies", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Car Wash", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Cash & ATM", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Charity", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Clothing", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, category_coffee_shops]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Credit Card Payment", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Dentist", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Deposit to Savings", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Doctor", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Education", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Electronics & Software", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Entertainment", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Eyecare", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Fast Food", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Fees & Charges", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Financial", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Financial Advisor", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Food & Dining", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Furnishings", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Gas & Fuel", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Gift", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Gifts & Donations", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, category_groceries]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Gym", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Hair", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Health & Fitness", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"HOA Dues", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Hobbies", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Home", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, category_home_improvement]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Home Insurance", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Home Phone", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Home Services", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Home Supplies", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Hotel", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Interest Exp", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Internet", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"IRA Contribution", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Kids", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Kids Activities", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Late Fee", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Laundry", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Lawn & Garden", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Life Insurance", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Misc.", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Mobile Phone", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Mortgage & Rent", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Mortgage Interest", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Movies & DVDs", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Music", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Newspaper & Magazines", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Not Sure", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Parking", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Personal Care", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Pet Food & Supplies", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Pet Grooming", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Pets", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Pharmacy", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Property", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Public Transportation", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Registration", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Rental Car & Taxi", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Restaurants", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Service & Parts", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Service Fee", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, category_shopping]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Spa & Massage", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Sporting Goods", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Sports", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Student Loan", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Tax", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Television", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Tolls", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Toys", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Trade Commissions", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Travel", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Tuition", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Utilities", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Vacation", @"expense category")]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExpenseCategory, NSLocalizedString(@"Vet", @"expense category")]];
        
        //
        // Income categories
        //
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringIncomeCategory, NSLocalizedString(@"Consulting Income", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringIncomeCategory, NSLocalizedString(@"Div Income", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringIncomeCategory, NSLocalizedString(@"Net Salary", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringIncomeCategory, NSLocalizedString(@"Other Income", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringIncomeCategory, NSLocalizedString(@"Rent", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringIncomeCategory, NSLocalizedString(@"Sales", nil)]];
        
        //
        // Exchange Categories
        //
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExchangeCategory, NSLocalizedString(@"Buy Bitcoin", nil)]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringExchangeCategory, NSLocalizedString(@"Sell Bitcoin", nil)]];
        
        //
        // Transfer Categories
        //
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringTransferCategory, @"Bitcoin.de"]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringTransferCategory, @"Bitfinex"]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringTransferCategory, @"Bitstamp"]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringTransferCategory, @"BTC-e"]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringTransferCategory, @"BTCChina"]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringTransferCategory, @"Bter"]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringTransferCategory, @"Quadriga"]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringTransferCategory, @"Taurus"]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringTransferCategory, @"Coinbase"]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringTransferCategory, @"Huobi"]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringTransferCategory, @"Kraken"]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringTransferCategory, @"MintPal"]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@",abcStringTransferCategory, @"OKCoin"]];
        
        //
        // Transfer to Wallet Categories
        //
        
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@:%@",abcStringTransferCategory,wallet_category, @"Airbitz"]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@:%@",abcStringTransferCategory,wallet_category, @"Bitcoin Core"]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@:%@",abcStringTransferCategory,wallet_category, @"Blockchain"]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@:%@",abcStringTransferCategory,wallet_category, @"Electrum"]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@:%@",abcStringTransferCategory,wallet_category, @"Multibit"]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@:%@",abcStringTransferCategory,wallet_category, @"Mycelium"]];
        [arrayCategories addObject:[NSString stringWithFormat:@"%@:%@:%@",abcStringTransferCategory,wallet_category, @"Dark Wallet"]];
        
        // add default categories to core
        for (int i = 0; i < [arrayCategories count]; i++)
        {
            NSString *strCategory = [arrayCategories objectAtIndex:i];
            [arrayCategories2 addObject:strCategory];
            
            [account.categories addCategory:strCategory];
        }
    }
}

- (void)clear
{
    // Delete webview cookies
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in [storage cookies]) {
        [storage deleteCookie:cookie];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];

}

- (SendViewState)sendInvalidEntry
{
    ++self.sendInvalidEntryCount;
    if (SEND_INVALID_ENTRY_COUNT_MAX <= self.sendInvalidEntryCount)
    {
        [self startInvalidEntryWait];
    }
    return self.sendState;
}

- (void)startInvalidEntryWait
{
    if (kInvalidEntryWait == self.sendState)
    {
        return;
    }
    
    self.sendState = kInvalidEntryWait;
    self.sendInvalidEntryCount = 0;
    self.sendInvalidEntryTimer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:INVALID_ENTRY_WAIT]
                                                  interval:INVALID_ENTRY_WAIT
                                                    target:self
                                                  selector:@selector(endInvalidEntryWait)
                                                  userInfo:@{kTimerStart : [NSDate date]}
                                                   repeats:NO];
    [self.runLoop addTimer:self.sendInvalidEntryTimer forMode:NSDefaultRunLoopMode];
}

- (void)endInvalidEntryWait
{
    if (self)
    {
        self.sendState = kNormal;
    }
}

- (NSTimeInterval)getRemainingInvalidEntryWait
{
    if (!self.sendInvalidEntryTimer || ![self.sendInvalidEntryTimer isValid]) {
        return 0;
    }
    NSDate *start = [[self.sendInvalidEntryTimer userInfo] objectForKey:kTimerStart];
    NSDate *current = [NSDate date];
    return INVALID_ENTRY_WAIT - [current timeIntervalSinceDate:start];
}

/* Increment the count of invalid entries and return true if the maximum has
 * been exceeded.
 */
- (bool)haveExceededPINLoginInvalidEntries
{
    ++self.PINLoginInvalidEntryCount;
    if (LOGIN_INVALID_ENTRY_COUNT_MAX <= self.PINLoginInvalidEntryCount)
    {
        return YES;
    }
    return NO;
}

- (void)resetPINLoginInvalidEntryCount
{
    self.PINLoginInvalidEntryCount = 0;
}

// Called when a user successfully enters their password.
- (void)passwordUsed;
{
    self.numNonPasswordLogin = 0;
    self.numPasswordUsed++;
    self.lastPasswordLogin = [NSDate date];
    self.passwordReminderDays  = pow(PASSWORD_DAYS_INCREMENT_POWER, self.numPasswordUsed);
    self.passwordReminderCount = pow(PASSWORD_COUNT_INCREMENT_POWER, self.numPasswordUsed);

    if (self.passwordReminderDays > PASSWORD_DAYS_MAX_VALUE)
        self.passwordReminderDays = PASSWORD_DAYS_MAX_VALUE;
    
    if (self.passwordReminderCount > PASSWORD_DAYS_MAX_VALUE)
        self.passwordReminderCount = PASSWORD_COUNT_MAX_VALUE;
    [self saveLocalSettings];
}

- (void)passwordWrongAndSkipped;
{
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    NSCalendarUnit unit;
    
    if (PASSWORD_REMINDER_DAYS_TO_MINS)
    {
        dayComponent.minute = PASSWORD_WRONG_INCREMENT_DAYS;
        unit = NSCalendarUnitMinute;
    }
    else
    {
        dayComponent.day = PASSWORD_WRONG_INCREMENT_DAYS;
        unit = NSCalendarUnitDay;
    }
    
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    NSDate *nextDate = [theCalendar dateByAddingComponents:dayComponent toDate:[NSDate date] options:0];

    self.passwordReminderDays = [Util timeBetweenDate:self.lastPasswordLogin andDate:nextDate unit:unit];
    self.passwordReminderCount = self.numNonPasswordLogin + PASSWORD_WRONG_INCREMENT_COUNT;

    [self saveLocalSettings];
}


- (void)incPINorTouchIDLogin
{
    self.needsPasswordCheck = NO;
    self.needsPasswordRecoveryPopup = NO;

    self.numNonPasswordLogin++;
    
    if (self.numNonPasswordLogin >= self.passwordReminderCount) {
        self.needsPasswordCheck = YES;
    }
    
    NSCalendarUnit unit = NSCalendarUnitDay;
    
    if (PASSWORD_REMINDER_DAYS_TO_MINS)
        unit = NSCalendarUnitMinute;

    NSInteger days = [Util timeBetweenDate:self.lastPasswordLogin andDate:[NSDate date] unit:unit];

    if (days >= self.passwordReminderDays) {
        self.needsPasswordCheck = YES;
    }
    
    if (!self.needsPasswordCheck && !self.passwordRecoveryAskedThisStartup)
    {
        if (![abc getRecovery2Token:abcAccount.name error:nil])
        {
            // No recovery set. Let ask user to set it up
            if (self.passwordRecoveryAskCount < 3)
            {
                self.needsPasswordRecoveryPopup = YES;
            }
        }
    }
    [self saveLocalSettings];
}

- (void)didAskPasswordRecovery;
{
    self.passwordRecoveryAskCount++;
    self.passwordRecoveryAskedThisStartup = YES;
    self.needsPasswordRecoveryPopup = NO;
    [self saveLocalSettings];
}
@end

//
//  RecipientViewController.m
//  AirBitz
//
//  Created by Adam Harris on 8/14/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "RecipientViewController.h"
#import "CommonTypes.h"
#import "Util.h"
#import "StylizedTextField.h"
#import "InfoView.h"
#import "MontserratLabel.h"

#define KEYBOARD_APPEAR_TIME_SECS 0.3

@interface RecipientViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIView             *viewDisplay;
@property (weak, nonatomic) IBOutlet MontserratLabel    *labelTitle;
@property (weak, nonatomic) IBOutlet StylizedTextField  *textFieldRecipient;
@property (weak, nonatomic) IBOutlet UITableView        *tableContacts;

@property (nonatomic, copy)   NSString                  *strFullName;
@property (nonatomic, copy)   NSString                  *strTarget;
@property (nonatomic, strong) NSArray                   *arrayAutoComplete;

@end

@implementation RecipientViewController

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

    self.arrayAutoComplete = @[];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

    // resize ourselves to fit in area
    [Util resizeView:self.view withDisplayView:self.viewDisplay];
    [self updateDisplayLayout];

    // set the title based on why we were brought up
    self.labelTitle.text = (self.mode == RecipientMode_Email ? @"Email Recipient" : @"SMS Recipient");

    [self.textFieldRecipient becomeFirstResponder];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
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
    [self animatedExit];
}

- (IBAction)buttonInfoTouched:(id)sender
{
    [InfoView CreateWithHTML:@"infoRecipient" forView:self.view];
}

#pragma mark - Misc Methods

- (void)updateDisplayLayout
{
    // update for iPhone 4
    if (!IS_IPHONE5)
    {

        
    }
}

- (void)animatedExit
{
    [self.textFieldRecipient resignFirstResponder];

	[UIView animateWithDuration:EXIT_ANIM_TIME_SECS
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
    [self.delegate RecipientViewControllerDone:self withFullName:self.strFullName andTarget:self.strFullName];
}

#pragma mark - UITableView delegates

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.arrayAutoComplete count];
}

#pragma mark - UITextField delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self animatedExit];

    return YES;
}

- (void)textFieldDidChange:(UITextField *)textField
{

}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect keyboardRect;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardRect];

    [UIView animateWithDuration:KEYBOARD_APPEAR_TIME_SECS
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 CGRect frame = self.tableContacts.frame;
		 frame.size.height -= keyboardRect.size.height;
		 self.tableContacts.frame = frame;
	 }
                     completion:^(BOOL finished)
	 {

	 }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    CGRect keyboardRect;
    [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardRect];

    [UIView animateWithDuration:KEYBOARD_APPEAR_TIME_SECS
						  delay:0.0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^
	 {
		 CGRect frame = self.tableContacts.frame;
		 frame.size.height += keyboardRect.size.height;
		 self.tableContacts.frame = frame;
	 }
                     completion:^(BOOL finished)
	 {

	 }];
}

@end

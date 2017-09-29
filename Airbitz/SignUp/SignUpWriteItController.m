//
//  SignUpWriteItController.m
//  AirBitz
//

#import "SignUpWriteItController.h"
#import "StylizedButtonOutline.h"
#import "Strings.h"
#import "Theme.h"
#import "LatoLabel.h"

@interface SignUpWriteItController ()
{

}

@property (weak, nonatomic) IBOutlet LatoLabel                      *titleText;
@property (nonatomic, weak) IBOutlet LatoLabel                      *labelInfo;
@property (nonatomic, weak) IBOutlet LatoLabel                      *labelWriteIt;
@property (nonatomic, strong) IBOutlet StylizedButtonOutline        *buttonShowHide;
@property (nonatomic, strong) IBOutlet UIView                       *viewShowHide;
@property (weak, nonatomic) IBOutlet LatoLabel                      *titleUsername;
@property (nonatomic, weak) IBOutlet LatoLabel                      *labelUsername;
@property (weak, nonatomic) IBOutlet LatoLabel                      *titlePassword;
@property (nonatomic, weak)  IBOutlet LatoLabel                     *labelPassword;
@property (weak, nonatomic) IBOutlet LatoLabel                      *titlePIN;
@property (nonatomic, weak) IBOutlet LatoLabel                      *labelPIN;
@property (weak, nonatomic) IBOutlet UIButton                       *buttonNext;
@property (nonatomic, assign) BOOL                                  bShow;

@end


@implementation SignUpWriteItController


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.bShow = NO;
    [self showHide];
    self.labelUsername.text = [NSString stringWithFormat:@"%@", self.manager.strUserName];
    self.labelPassword.text = [NSString stringWithFormat:@"%@", self.manager.strPassword];
    self.labelPIN.text = [NSString stringWithFormat:@"%@", self.manager.strPIN];

    [self setThemeValues];
}

- (void)setThemeValues {
    self.titleText.textColor = [Theme Singleton].colorDarkPrimary;
    self.labelInfo.textColor = [Theme Singleton].colorDarkPrimary;
    self.labelWriteIt.textColor = [Theme Singleton].colorSecondAccent;
    self.titleUsername.textColor = [Theme Singleton].colorDarkPrimary;
    self.labelUsername.textColor = [Theme Singleton].colorDarkPrimary;
    self.titlePassword.textColor = [Theme Singleton].colorDarkPrimary;
    self.labelPassword.textColor = [Theme Singleton].colorDarkPrimary;
    self.titlePIN.textColor = [Theme Singleton].colorDarkPrimary;
    self.labelPIN.textColor = [Theme Singleton].colorDarkPrimary;
    
    self.buttonShowHide.titleLabel.font = [UIFont fontWithName:[Theme Singleton].appFont size:15.0];
    self.buttonShowHide.titleLabel.textColor = [Theme Singleton].colorDarkPrimary;
    self.buttonShowHide.tintColor = [Theme Singleton].colorDarkPrimary;
    
    self.buttonNext.titleLabel.font = [UIFont fontWithName:[Theme Singleton].appFont size:15.0];
    self.buttonNext.backgroundColor = [Theme Singleton].colorFirstAccent;
}

- (IBAction)showHide
{
    if (self.bShow)
    {
        self.labelInfo.hidden = YES;
        self.labelWriteIt.hidden = YES;
        self.viewShowHide.hidden = NO;
        [self.buttonShowHide setTitle:hideText forState:UIControlStateNormal];

        self.bShow = NO;
    }
    else
    {
        self.labelInfo.hidden = NO;
        self.labelWriteIt.hidden = NO;
        self.viewShowHide.hidden = YES;
        [self.buttonShowHide setTitle:showText forState:UIControlStateNormal];

        self.bShow = YES;

    }
}


- (IBAction)next
{
    [super next];
}

@end

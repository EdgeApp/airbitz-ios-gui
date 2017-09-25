//
//  SignUpWriteItController.m
//  AirBitz
//

#import "SignUpWriteItController.h"
#import "StylizedButtonOutline.h"
#import "Strings.h"
#import "Theme.h"

@interface SignUpWriteItController ()
{

}

@property (weak, nonatomic) IBOutlet UILabel *titleText;
@property (nonatomic, weak) IBOutlet    UILabel                         *labelInfo;
@property (nonatomic, weak) IBOutlet    UILabel                         *labelWriteIt;
@property (nonatomic, strong) IBOutlet  StylizedButtonOutline           *buttonShowHide;
@property (nonatomic, strong) IBOutlet  UIView                          *viewShowHide;
@property (weak, nonatomic) IBOutlet UILabel *titleUsername;
@property (nonatomic, weak)   IBOutlet  UILabel                         *labelUsername;
@property (weak, nonatomic) IBOutlet UILabel *titlePassword;
@property (nonatomic, weak)   IBOutlet  UILabel                         *labelPassword;
@property (weak, nonatomic) IBOutlet UILabel *titlePIN;
@property (nonatomic, weak)   IBOutlet  UILabel                         *labelPIN;
@property (weak, nonatomic) IBOutlet UIButton *buttonNext;




@property (nonatomic, assign)           BOOL                            bShow;

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
    self.titleText.font = [UIFont fontWithName:[Theme Singleton].appFont size:17.0];
    self.titleText.textColor = [Theme Singleton].colorDarkPrimary;
    
    self.labelInfo.font = [UIFont fontWithName:[Theme Singleton].appFont size:14.0];
    self.labelInfo.textColor = [Theme Singleton].colorDarkPrimary;
    
    self.labelWriteIt.font = [UIFont fontWithName:[Theme Singleton].appFont size:16.0];
    self.labelWriteIt.textColor = [Theme Singleton].colorSecondAccent;
    
    self.titleUsername.font = [UIFont fontWithName:[Theme Singleton].appFont size:15.0];
    self.titleUsername.textColor = [Theme Singleton].colorDarkPrimary;
    
    self.labelUsername.font = [UIFont fontWithName:[Theme Singleton].appFont size:15.0];
    self.labelUsername.textColor = [Theme Singleton].colorDarkPrimary;
    
    self.titlePassword.font = [UIFont fontWithName:[Theme Singleton].appFont size:15.0];
    self.titlePassword.textColor = [Theme Singleton].colorDarkPrimary;
    
    self.labelPassword.font = [UIFont fontWithName:[Theme Singleton].appFont size:15.0];
    self.labelPassword.textColor = [Theme Singleton].colorDarkPrimary;
    
    self.titlePIN.font = [UIFont fontWithName:[Theme Singleton].appFont size:15.0];
    self.titlePIN.textColor = [Theme Singleton].colorDarkPrimary;
    
    self.labelPIN.font = [UIFont fontWithName:[Theme Singleton].appFont size:15.0];
    self.labelPIN.textColor = [Theme Singleton].colorDarkPrimary;
    
    self.buttonShowHide.titleLabel.font = [UIFont fontWithName:[Theme Singleton].appFont size:15.0];
    self.buttonShowHide.titleLabel.textColor = [Theme Singleton].colorDarkPrimary;
    
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

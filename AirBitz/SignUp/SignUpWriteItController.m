//
//  SignUpWriteItController.m
//  AirBitz
//

#import "SignUpWriteItController.h"
#import "StylizedButtonOutline.h"

@interface SignUpWriteItController ()
{

}

@property (nonatomic, weak) IBOutlet    UILabel                         *labelInfo;
@property (nonatomic, weak) IBOutlet    UILabel                         *labelWriteIt;
@property (nonatomic, strong) IBOutlet  StylizedButtonOutline           *buttonShowHide;
@property (nonatomic, strong) IBOutlet  UIView                          *viewShowHide;
@property (nonatomic, weak)   IBOutlet  UILabel                         *labelUsername;
@property (nonatomic, weak)   IBOutlet  UILabel                         *labelPassword;
@property (nonatomic, weak)   IBOutlet  UILabel                         *labelPIN;

@property (nonatomic, assign)           BOOL                            bShow;

@end


@implementation SignUpWriteItController


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.bShow = true;
    self.labelUsername.text = [NSString stringWithFormat:@"%@", self.manager.strUserName];
    self.labelPassword.text = [NSString stringWithFormat:@"%@", self.manager.strPassword];
    self.labelPIN.text = [NSString stringWithFormat:@"%@", self.manager.strPIN];

}



- (IBAction)showHide
{
    if (self.bShow)
    {
        self.labelInfo.hidden = true;
        self.labelWriteIt.hidden = true;
        self.viewShowHide.hidden = false;
        [self.buttonShowHide setTitle:NSLocalizedString(@"Hide", "Hide") forState:UIControlStateNormal];

        self.bShow = false;
    }
    else
    {
        self.labelInfo.hidden = false;
        self.labelWriteIt.hidden = false;
        self.viewShowHide.hidden = true;
        [self.buttonShowHide setTitle:NSLocalizedString(@"Show", "Show") forState:UIControlStateNormal];

        self.bShow = true;

    }
}


- (IBAction)next
{
    [super next];
}

@end

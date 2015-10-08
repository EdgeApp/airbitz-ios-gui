//
//  SendStatusViewController.m
//  AirBitz
//
//  Created by Carson Whitsett on 4/3/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "SendStatusViewController.h"
#import "CommonTypes.h"

@interface SendStatusViewController ()
{
    
}

@property (weak, nonatomic) IBOutlet UIImageView                *imageTopBar;
@property (weak, nonatomic) IBOutlet UIView                     *viewDisplayArea;
@property (weak, nonatomic) IBOutlet UIImageView                *imageBitcoin;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView    *indicator;

@end

@implementation SendStatusViewController

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

    [self updateDisplayLayout];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Misc Methods

- (void)updateDisplayLayout
{
    // center the bitcoin image
    CGFloat spaceAboveAndBelow = (self.viewDisplayArea.frame.size.height - self.imageBitcoin.frame.size.height) / 2.0;
    CGRect frame = self.imageBitcoin.frame;
    frame.origin.y = spaceAboveAndBelow;
    self.imageBitcoin.frame = frame;

    // place the indicator in the center of the space above
    frame = self.indicator.frame;
    frame.origin.y = (spaceAboveAndBelow - self.indicator.frame.size.height) / 2.0;
    self.indicator.frame = frame;

    // place the 'sending' in the cetner of the space below
    frame = self.messageLabel.frame;
    frame.origin.y = self.imageBitcoin.frame.origin.y + self.imageBitcoin.frame.size.height;
    frame.origin.y += (spaceAboveAndBelow - self.messageLabel.frame.size.height) / 2.0;
    self.messageLabel.frame = frame;
}


@end

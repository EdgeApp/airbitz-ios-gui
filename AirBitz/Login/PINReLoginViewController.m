//
//  PINReLoginViewController.m
//  AirBitz
//
//  Created by Allan Wright on 11/1/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import "PINReLoginViewController.h"
#import <APPinView.h>

//@interface PINReLoginViewController ()
//{
//}
//@end

@implementation PINReLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.pinCodeView.selectedPinImage = [UIImage imageNamed:@"large-digit-input_selected"];
    self.pinCodeView.normalPinImage = [UIImage imageNamed:@"large-digit-input"];
}



@end

//
//  SendViewController.h
//  AirBitz
//
//  Created by Carson Whitsett on 2/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PickerTextView.h"

@interface SendViewController : UIViewController

@property (nonatomic, strong) NSString              *walletUUID;
@property (nonatomic, weak) IBOutlet PickerTextView *pickerTextSendTo;

- (void)processURI;
- (void)resetViews;

@end

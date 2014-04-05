//
//  WalletMakerView.h
//  AirBitz
//
//  Created by Carson Whitsett on 4/4/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ButtonSelectorView.h"

@interface WalletMakerView : UIView

@property (nonatomic, weak) IBOutlet ButtonSelectorView *buttonSelectorView;
@property (nonatomic, weak) IBOutlet UITextField *textField;
@end

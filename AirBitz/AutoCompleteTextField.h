//
//  AutoCompleteTextField.h
//  AirBitz
//
//  Created by Carson Whitsett on 4/6/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "StylizedTextField.h"

@protocol AutoCompleteTextFieldDelegate;

@interface AutoCompleteTextField : StylizedTextField

@property (nonatomic, strong) NSArray *arrayAutoCompleteStrings;  //if this is set, then built-in autocomplete of contacts and business names is disabled and this is used instead
@property (nonatomic, assign) BOOL tableAbove;	//set if you want the table to appear above the textField
@property (assign) id<AutoCompleteTextFieldDelegate> autoTextFieldDelegate;

@end

@protocol AutoCompleteTextFieldDelegate <NSObject>

@required

@optional
-(void)autoCompleteTextFieldDidBeginEditing:(AutoCompleteTextField *)textField;
@end
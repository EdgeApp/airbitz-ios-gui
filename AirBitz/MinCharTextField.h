//
//  MinCharTextField.h
//  AirBitz
//
//  See LICENSE for copy, modification, and use permissions
//
//  See AUTHORS for contributing developers
//

#import <UIKit/UIKit.h>
#import "StylizedTextField.h"

@interface MinCharTextField : StylizedTextField

@property (nonatomic, assign) int minimumCharacters;
@property (nonatomic, readonly) BOOL satisfiesMinimumCharacters;
@end

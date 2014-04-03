//
//  ButtonSelectorView.h
//  AirBitz
//
//  Created by Carson Whitsett on 4/3/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//
//	Set the delegate
//	Set arrayItemsToSelect
//	Set selectedItemIndex to specify initial item to display
//	This will call you back with an item index whenever user selects a different item

#import <UIKit/UIKit.h>

@protocol ButtonSelectorDelegate;

@interface ButtonSelectorView : UIView

@property (nonatomic, weak) IBOutlet UILabel *textLabel;
@property (nonatomic, weak) IBOutlet UIButton *button;
@property (nonatomic, assign) id<ButtonSelectorDelegate> delegate;
@property (nonatomic, strong) NSArray *arrayItemsToSelect;			/* set this to an array of NSStrings that will appear in the drop-down */
@property (nonatomic, readwrite) int selectedItemIndex;

@end




@protocol ButtonSelectorDelegate <NSObject>

@required
-(void)ButtonSelector:(ButtonSelectorView *)view selectedItem:(int)itemIndex;
@optional

@end
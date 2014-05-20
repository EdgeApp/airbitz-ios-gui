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
@property (nonatomic, strong) IBOutlet UIView *containerView;	/* if this is embedded within a containerView, specify it here and this will animate the containerView's frame to fit the table */

- (void)setButtonWidth:(CGFloat)width;
- (void)close; /* closes button table and shrinks button if open */

@end

@protocol ButtonSelectorDelegate <NSObject>

@required

- (void)ButtonSelector:(ButtonSelectorView *)view selectedItem:(int)itemIndex;

@optional

- (NSString *)ButtonSelector:(ButtonSelectorView *)view willSetButtonTextToString:(NSString *)desiredString; //allows delegate to alter the new desired button title
- (void)ButtonSelectorWillShowTable:(ButtonSelectorView *)view;
- (void)ButtonSelectorWillHideTable:(ButtonSelectorView *)view;

@end
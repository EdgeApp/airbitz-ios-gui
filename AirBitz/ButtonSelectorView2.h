//
//  ButtonSelectorView2.h
//  AirBitz
//
//  Created by Paul Puey on 2015/05/08.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//
//	Set the delegate
//	Set arrayItemsToSelect
//	Set selectedItemIndex to specify initial item to display
//	This will call you back with an item index whenever user selects a different item

#import <UIKit/UIKit.h>

@protocol ButtonSelector2Delegate;

@interface ButtonSelectorView2 : UIView

//@property (nonatomic, weak) IBOutlet UILabel *textLabel;
@property (nonatomic, weak) IBOutlet UIButton *button;
@property (nonatomic, strong) UIImage *accessoryImage;
@property (nonatomic, assign) id<ButtonSelector2Delegate> delegate;
@property (nonatomic, strong) NSArray *arrayItemsToSelect;			/* set this to an array of NSStrings that will appear in the drop-down */
@property (nonatomic, readwrite) int selectedItemIndex;
//@property (nonatomic, strong) IBOutlet UIView *containerView;	/* if this is embedded within a containerView, specify it here and this will animate the containerView's frame to fit the table */
@property (nonatomic, assign) BOOL enabled;

- (void)setButtonWidth:(CGFloat)width;
- (void)open;
- (void)close; /* closes button table and shrinks button if open */
- (void)disableButton;


@end

@protocol ButtonSelector2Delegate <NSObject>

@required

- (void)ButtonSelector2:(ButtonSelectorView2 *)view selectedItem:(int)itemIndex;

@optional

- (NSString *)ButtonSelector2:(ButtonSelectorView2 *)view willSetButtonTextToString:(NSString *)desiredString; //allows delegate to alter the new desired button title
- (void)ButtonSelector2WillShowTable:(ButtonSelectorView2 *)view;
- (void)ButtonSelector2WillHideTable:(ButtonSelectorView2 *)view;
- (void)ButtonSelector2DidTouchAccessory:(ButtonSelectorView2 *)selector accountString:(NSString *)string;

@end

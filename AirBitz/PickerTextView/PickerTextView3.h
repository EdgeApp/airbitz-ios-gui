//
//  PickerTextView.h
//  AirBitz
//
//  Created by Adam Harris on 5/8/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PopupPickerView.h"
#import "StylizedTextField3.h"

@protocol PickerTextViewDelegate;

@interface PickerTextView3 : UIView

@property (nonatomic, assign) id<PickerTextViewDelegate>    delegate;
@property (nonatomic, strong) StylizedTextField3             *textField;
@property (nonatomic, strong) PopupPickerView               *popupPicker; //nil until picker actually appears
@property (nonatomic, assign) tPopupPickerPosition          popupPickerPosition;
@property (nonatomic, assign) NSInteger                     pickerMaxChoicesVisible; //can constrain to a certain number of choices
@property (nonatomic, assign) NSInteger                     pickerWidth;
@property (nonatomic, assign) NSInteger                     pickerCellHeight;
@property (nonatomic, assign) UITableViewCellStyle          pickerTableViewCellStyle;
@property (nonatomic, strong) NSArray                       *arrayChoices;
@property (nonatomic, strong) NSArray                       *arrayCategories;
@property (nonatomic, assign) CGFloat                       cropPointTop;
@property (nonatomic, assign) CGFloat                       cropPointBottom;


- (void)setTextFieldObject:(UITextField *)newTextField;
- (void)setTopMostView:(UIView *)topMostView; //what view will the drop down selector be added to?
- (void)setCategories:(NSArray *)categories;
- (void)updateChoices:(NSArray *)arrayChoices;
- (void)dismissPopupPicker;

@end

@protocol PickerTextViewDelegate <NSObject>

@required


@optional

- (BOOL)pickerTextViewFieldShouldChange:(PickerTextView3 *)pickerTextView charactersInRange:(NSRange)range replacementString:(NSString *)string;
- (void)pickerTextViewFieldDidChange:(PickerTextView3 *)pickerTextView;
- (void)pickerTextViewFieldDidBeginEditing:(PickerTextView3 *)pickerTextView;
- (BOOL)pickerTextViewShouldEndEditing:(PickerTextView3 *)pickerTextView;
- (void)pickerTextViewFieldDidEndEditing:(PickerTextView3 *)pickerTextView;
- (BOOL)pickerTextViewFieldShouldReturn:(PickerTextView3 *)pickerTextView;
- (void)pickerTextViewPopupSelected:(PickerTextView3 *)view onRow:(NSInteger)row;
- (BOOL)pickerTextViewPopupFormatCell:(PopupPickerView *)view onRow:(NSInteger)row withCell:(UITableViewCell *)cell;
- (NSInteger)pickerTextViewPopupNumberOfRows:(PopupPickerView *)view;
- (UITableViewCell *)pickerTextViewPopupCellForRow:(PopupPickerView *)view forTableView:(UITableView *)tableView andRow:(NSInteger)row;
- (void)pickerTextViewFieldDidShowPopup:(PickerTextView3 *)pickerTextView;
- (void)pickerTextViewDidTouchAccessory:(PickerTextView3 *)pickerTextView categoryString:(NSString *)string;

@end
//
//  PopupPickerView.h
//  AirBitz
//
//  Created by Adam Harris on 5/5/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PopupPickerViewDelegate;

typedef enum ePopupPickerPosition
{
    PopupPickerPosition_Below,
    PopupPickerPosition_Above,
    PopupPickerPosition_Left,
    PopupPickerPosition_Right
} tPopupPickerPosition;

@interface PopupPickerView : UIView

@property (nonatomic, assign) id   userData;
@property (nonatomic, assign) BOOL showOptions;

+(PopupPickerView *)CreateForView:(UIView *)parentView positionRelativeTo:(UIView *)posView withPosition:(tPopupPickerPosition)position withStrings:(NSArray *)strings selectedRow:(NSInteger)selectedRow maxCellsVisible:(NSInteger)maxCellsVisible;
+(PopupPickerView *)CreateForView:(UIView *)parentView relativeToFrame:(CGRect)frame viewForFrame:(UIView *)frameView withPosition:(tPopupPickerPosition)position withStrings:(NSArray *)strings selectedRow:(NSInteger)selectedRow maxCellsVisible:(NSInteger)maxCellsVisible withWidth:(NSInteger)width andCellHeight:(NSInteger)cellHeight;
+(PopupPickerView *)CreateForView:(UIView *)parentView relativeToFrame:(CGRect)frame viewForFrame:(UIView *)frameView withPosition:(tPopupPickerPosition)position withStrings:(NSArray *)strings selectedRow:(NSInteger)selectedRow maxCellsVisible:(NSInteger)maxCellsVisible;
+(PopupPickerView *)CreateForView:(UIView *)parentView positionRelativeTo:(UIView *)posView withPosition:(tPopupPickerPosition)position withStrings:(NSArray *)strings selectedRow:(NSInteger)selectedRow maxCellsVisible:(NSInteger)maxCellsVisible withWidth:(NSInteger)width andCellHeight:(NSInteger)cellHeight;



//- (IBAction)backgroundButtonTouched:(id)sender;

- (void)assignDelegate:(id<PopupPickerViewDelegate>) delegate;
- (void)selectRow:(NSInteger)row;
- (void)setCellHeight:(NSInteger)height;
- (void)reloadTableData;
- (void)disableBackgroundTouchDetect;
- (void)updateStrings:(NSArray *)strings;

@end

@protocol PopupPickerViewDelegate <NSObject>

@required
- (void)PopupPickerViewSelected:(PopupPickerView *)view onRow:(NSInteger)row userData:(id)data;

@optional
- (void)PopupPickerViewCancelled:(PopupPickerView *)view userData:(id)data;
- (void)PopupPickerViewKeyboard:(PopupPickerView *)view userData:(id)data;
- (void)PopupPickerViewClear:(PopupPickerView *)view userData:(id)data;
- (void)PopupPickerViewFormatCell:(PopupPickerView *)view onRow:(NSInteger)row withCell:(UITableViewCell *)cell userData:(id)data;
- (NSInteger)PopupPickerViewNumberOfRows:(PopupPickerView *)view userData:(id)data;
- (UITableViewCell *)PopupPickerViewCellForRow:(PopupPickerView *)view forTableView:(UITableView *)tableView andRow:(NSInteger)row userData:(id)data;

@end

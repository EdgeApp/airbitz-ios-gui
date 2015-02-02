//
//  PopupPickerView.h
//  AirBitz
//
//  Created by Adam Harris on 5/5/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PopupPickerViewDelegate;
@protocol PopupPickerViewDataSource;

typedef enum ePopupPickerPosition
{
    PopupPickerPosition_Below,
    PopupPickerPosition_Above,
    PopupPickerPosition_Left,
    PopupPickerPosition_Right
} tPopupPickerPosition;

@interface PopupPickerView : UIView

@property (nonatomic, strong)   IBOutlet UIImageView            *arrowImage;

@property (nonatomic, assign)   id                              userData;
@property (nonatomic, assign)   BOOL                            showOptions;
@property (nonatomic, assign)   UITableViewCellStyle            tableViewCellStyle;
@property (nonatomic, assign)   id <PopupPickerViewDelegate>    delegate;

+(void)initAll;
+(void)freeAll;

+(PopupPickerView *)CreateForView:(UIView *)parentView				/* the view the picker will reside within */
				  relativeToView:(UIView *)viewToPointTo			/* the view we will appear next to and point to */
				  relativePosition:(tPopupPickerPosition)position	/* where we want to appear relative to viewToPointTo */
				  withStrings:(NSArray *)strings					/* optional list of NSStrings to display.  If you don't provide strings, then subscribe to -PopupPickerViewNumberOfRows and -PopupPickerViewCellForRow to provide data for the picker */
                  fromCategories:(NSArray *)categories              /* optional list of categories */
				  selectedRow:(NSInteger)selectedRow				/* which row is initially selected */
				  withWidth:(NSInteger)width
				  andCellHeight:(NSInteger)cellHeight;

- (void)selectRow:(NSInteger)row;
- (void)setCellHeight:(NSInteger)height;
- (void)reloadTableData;
- (void)disableBackgroundTouchDetect;
- (void)updateStrings:(NSArray *)strings;

-(void)addCropLine:(CGPoint)pointOnScreen direction:(tPopupPickerPosition)cropDirection animated:(BOOL)animated;	/* will add a keepout in the region above, below, left or right of the given point */

@end

@protocol PopupPickerViewDelegate <NSObject>

@required
- (void)PopupPickerViewSelected:(PopupPickerView *)view onRow:(NSInteger)row userData:(id)data;

@optional
- (void)PopupPickerViewCancelled:(PopupPickerView *)view userData:(id)data;
- (void)PopupPickerViewKeyboard:(PopupPickerView *)view userData:(id)data;
- (void)PopupPickerViewClear:(PopupPickerView *)view userData:(id)data;
- (BOOL)PopupPickerViewFormatCell:(PopupPickerView *)view onRow:(NSInteger)row withCell:(UITableViewCell *)cell userData:(id)data;
- (NSInteger)PopupPickerViewNumberOfRows:(PopupPickerView *)view userData:(id)data;
- (UITableViewCell *)PopupPickerViewCellForRow:(PopupPickerView *)view forTableView:(UITableView *)tableView andRow:(NSInteger)row userData:(id)data;
- (void)PopupPickerViewDidAddCategory:(PopupPickerView *)view categoryString:(NSString *)string;
@end


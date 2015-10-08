//
//  PopupPickerView2.h
//  AirBitz
//
//  Created by Adam Harris on 5/5/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PopupPickerView2Delegate;
@protocol PopupPickerView2DataSource;

typedef enum ePopupPicker2Position
{
    PopupPicker2Position_Full_Rising,
    PopupPicker2Position_Full_Dropping,
    PopupPicker2Position_Full_Fading,

} tPopupPicker2Position;

@interface PopupPickerView2 : UIView

//@property (nonatomic, strong)   IBOutlet UIImageView            *arrowImage;

@property (nonatomic, assign)   id                              userData;
@property (nonatomic, assign)   BOOL                            showOptions;
@property (nonatomic, assign)   UITableViewCellStyle            tableViewCellStyle;
@property (nonatomic, assign)   id <PopupPickerView2Delegate>    delegate;

+(void)initAll;
+(void)freeAll;
+ (PopupPickerView2 *)CreateForView:(UIView *)parentView
                   relativePosition:(tPopupPicker2Position)position
                        withStrings:(NSArray *)strings
                      withAccessory:(UIImage *)image                    /* optional accessory for each row */
                         headerText:(NSString *)headerText;

//+(PopupPickerView2 *)CreateForView:(UIView *)parentView				/* the view the picker will reside within */
//				  relativeToView:(UIView *)viewToPointTo			/* the view we will appear next to and point to */
//				  relativePosition:(tPopupPicker2Position)position	/* where we want to appear relative to viewToPointTo */
//				  withStrings:(NSArray *)strings;					/* optional list of NSStrings to display.  If you don't provide strings, then subscribe to -PopupPickerView2NumberOfRows and -PopupPickerView2CellForRow to provide data for the picker */
//                  fromCategories:(NSArray *)categories              /* optional list of categories */
//				  selectedRow:(NSInteger)selectedRow				/* which row is initially selected */
//				  withWidth:(NSInteger)width
//                  withAccessory:(UIImage *)image                    /* optional accessory for each row */
//                  andCellHeight:(NSInteger)cellHeight
//                  roundedEdgesAndShadow:(Boolean)rounded;           /* rounded edges and shadowed */

- (void)selectRow:(NSInteger)row;
- (void)setCellHeight:(NSInteger)height;
- (void)reloadTableData;
- (void)disableBackgroundTouchDetect;
- (void)updateStrings:(NSArray *)strings;
- (void)dismiss;



@end

@protocol PopupPickerView2Delegate <NSObject>

@required
- (void)PopupPickerView2Selected:(PopupPickerView2 *)view onRow:(NSInteger)row userData:(id)data;
- (void)PopupPickerView2Cancelled:(PopupPickerView2 *)view userData:(id)data;

@optional
- (void)PopupPickerView2Keyboard:(PopupPickerView2 *)view userData:(id)data;
- (void)PopupPickerView2Clear:(PopupPickerView2 *)view userData:(id)data;
- (BOOL)PopupPickerView2FormatCell:(PopupPickerView2 *)view onRow:(NSInteger)row withCell:(UITableViewCell *)cell userData:(id)data;
- (NSInteger)PopupPickerView2NumberOfRows:(PopupPickerView2 *)view userData:(id)data;
- (UITableViewCell *)PopupPickerView2CellForRow:(PopupPickerView2 *)view forTableView:(UITableView *)tableView andRow:(NSInteger)row userData:(id)data;
- (void)PopupPickerView2DidTouchAccessory:(PopupPickerView2 *)view categoryString:(NSString *)string;
@end


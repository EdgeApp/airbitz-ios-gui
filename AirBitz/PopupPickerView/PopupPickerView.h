//
//  PopupPickerView.h
//
 
//  Copyright (c) 2014, Airbitz
//  All rights reserved.
//
//  Redistribution and use in source and binary forms are permitted provided that
//  the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//  3. Redistribution or use of modified source code requires the express written
//  permission of Airbitz Inc.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
//  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
//  (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
//  LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
//  ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
//  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those
//  of the authors and should not be interpreted as representing official policies,
//  either expressed or implied, of the Airbitz Project.
//
//  See AUTHORS for contributing developers
//


#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@end



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

@end


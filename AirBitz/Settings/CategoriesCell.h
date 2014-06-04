//
//  CategoriesCell.h
//  AirBitz
//
//  Created by AdamHarris on 5/7/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PickerTextview.h"

@protocol CategoriesCellDelegate;

@interface CategoriesCell : UITableViewCell

@property (nonatomic, weak) IBOutlet PickerTextView *pickerTextView;

@property (assign) id<CategoriesCellDelegate> delegate;
@property (nonatomic, assign) NSInteger       pickerMaxChoicesVisible;

@end


@protocol CategoriesCellDelegate <NSObject>

@required

@optional

- (BOOL)categoriesCellTextShouldChange:(CategoriesCell *)cell charactersInRange:(NSRange)range replacementString:(NSString *)string;
- (void)categoriesCellTextDidChange:(CategoriesCell *)cell;
- (void)categoriesCellBeganEditing:(CategoriesCell *)cell;
- (void)categoriesCellEndEditing:(CategoriesCell *)cell;
- (BOOL)categoriesCellTextShouldReturn:(CategoriesCell *)cell;
- (void)categoriesCellPopupSelected:(CategoriesCell *)cell onRow:(NSInteger)row;
- (void)categoriesCellDeleteTouched:(CategoriesCell *)cell;
- (void)categoriesCellDidShowPopup:(CategoriesCell *)cell;

@end
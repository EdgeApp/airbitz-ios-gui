//
//  CategoriesCell.h
//  AirBitz
//
//  Created by AdamHarris on 5/7/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CategoriesCellDelegate;

@interface CategoriesCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UITextField *textField;

@property (assign) id<CategoriesCellDelegate> delegate;
@end


@protocol CategoriesCellDelegate <NSObject>

@required

@optional

- (void)categoriesCellBeganEditing:(CategoriesCell *)cell;
- (void)categoriesCellEndEditing:(CategoriesCell *)cell;
- (void)categoriesCellTextDidChange:(CategoriesCell *)cell;
- (void)categoriesCellTextDidReturn:(CategoriesCell *)cell;
- (void)categoriesCellDeleteTouched:(CategoriesCell *)cell;

@end
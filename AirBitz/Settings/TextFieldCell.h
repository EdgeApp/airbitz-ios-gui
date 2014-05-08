//
//  TextFieldCell.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/31/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TextFieldCellDelegate;

@interface TextFieldCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UIImageView *bkgImage;
@property (nonatomic, weak) IBOutlet UIImageView *textFieldBkgImage;

@property (assign) id<TextFieldCellDelegate> delegate;
@end


@protocol TextFieldCellDelegate <NSObject>

@required

@optional

- (void)textFieldCellBeganEditing:(TextFieldCell *)cell;
- (void)textFieldCellEndEditing:(TextFieldCell *)cell;
- (void)textFieldCellTextDidChange:(TextFieldCell *)cell;
- (void)textFieldCellTextDidReturn:(TextFieldCell *)cell;

@end
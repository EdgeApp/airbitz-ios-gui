//
//  TextViewCell.h
//  Airbitz
//
//  Created by Paul Puey on 2017/04/02.
//  Copyright (c) 2017 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TextViewCellDelegate;

@interface TextViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UITextView  *textView;
@property (nonatomic, weak) IBOutlet UIImageView *bkgImage;
@property (nonatomic, weak) IBOutlet UIImageView *textFieldBkgImage;

@property (assign) id<TextViewCellDelegate> delegate;
@end


@protocol TextViewCellDelegate <NSObject>

@required

@optional

- (void)textViewCellBeganEditing:(TextViewCell *)cell;
- (void)textViewCellEndEditing:(TextViewCell *)cell;
- (void)textViewCellTextDidChange:(TextViewCell *)cell;

@end

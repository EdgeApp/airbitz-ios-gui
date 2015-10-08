//
//  FlashSelectView.h
//  AirBitz
//
//  Created by Carson Whitsett on 3/28/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum eFlashItem
{
	FLASH_ITEM_ON,
	FLASH_ITEM_OFF
}tFlashItem;

@protocol FlashSelectViewDelegate;

@interface FlashSelectView : UIView

@property (nonatomic, assign) id<FlashSelectViewDelegate> delegate;

-(void)selectItem:(tFlashItem)flashType;

@end




@protocol FlashSelectViewDelegate <NSObject>

@required
- (void) flashItemSelected:(tFlashItem)flashType;
@optional

@end
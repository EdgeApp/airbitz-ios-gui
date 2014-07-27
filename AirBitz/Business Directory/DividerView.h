//
//  DividerView.h
//  AirBitz
//
//  Created by Carson Whitsett on 2/12/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DividerViewDelegate;

@interface DividerView : UIView

@property (nonatomic, readwrite) BOOL userControllable;
@property (assign) id<DividerViewDelegate> delegate;


@end

@protocol DividerViewDelegate <NSObject>

@optional
-(void)DividerViewTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)DividerViewTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)DividerViewTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)DividerViewTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
@end
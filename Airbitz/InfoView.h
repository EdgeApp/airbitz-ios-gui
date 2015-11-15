//
//  InfoView.h
//
//  Created by Carson Whitsett on 1/17/14.
//  Copyright (c) 2014 AirBitz, Inc.  All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InfoViewDelegate;

@interface InfoView : UIView


@property (nonatomic, assign) id<InfoViewDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *agreeButton;
@property (nonatomic, strong) NSString *htmlInfoToDisplay;

+ (InfoView *)CreateWithDelegate:(id<InfoViewDelegate>)delegate;
+ (InfoView *)CreateWithHTML:(NSString *)strHTML forView:(UIView *)theView;
+ (InfoView *)CreateWithHTML:(NSString *)strHTML
                     forView:(UIView *)theView
                 agreeButton:(BOOL)bAgreeButton
                    delegate:(id<InfoViewDelegate>) delegate;

-(void)enableScrolling:(BOOL)scrollEnabled;
-(void)dismiss;

@end


@protocol InfoViewDelegate <NSObject>

@optional
- (void) InfoViewFinished:(InfoView *)infoView;
- (void) InfoViewDidScrollToBottom:(InfoView *)infoView;
@required

@optional

@end
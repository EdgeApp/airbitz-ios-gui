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
@property (nonatomic, strong) NSString *htmlInfoToDisplay;

+ (InfoView *)CreateWithDelegate:(id<InfoViewDelegate>)delegate;

-(void)enableScrolling:(BOOL)scrollEnabled;

@end


@protocol InfoViewDelegate <NSObject>

@required
- (void) InfoViewFinished:(InfoView *)infoView;
@optional

@end
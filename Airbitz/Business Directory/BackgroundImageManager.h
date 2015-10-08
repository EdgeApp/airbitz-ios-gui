//
//  BackgroundImageManager.h
//  AirBitz
//
//  Created by Carson Whitsett on 2/16/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol BackgroundImageManagerDelegate;

@interface BackgroundImageManager : NSObject


-(void)loadImageForBusiness:(NSDictionary *)business;
-(UIImage *)imageForBusiness:(NSDictionary *)business;
-(UIImage *)darkImageForBusiness:(NSDictionary *)business;
-(void)removeImageForBusiness:(NSDictionary *)business;
-(void)removeAllImages;

@property (assign) id<BackgroundImageManagerDelegate> delegate;

@end





@protocol BackgroundImageManagerDelegate <NSObject>

@optional
-(void)BackgroundImageManagerImageLoadedForBizID:(NSNumber *)bizID;
@end
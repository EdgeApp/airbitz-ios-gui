//
//  DateTime.h
//  AirBitz
//
//  Created by Adam Harris on 5/27/14.
//  Copyright (c) 2014 AirBitz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DateTime : NSObject

@property (nonatomic, assign) NSInteger month;
@property (nonatomic, assign) NSInteger day;
@property (nonatomic, assign) NSInteger year;
@property (nonatomic, assign) NSInteger hour;
@property (nonatomic, assign) NSInteger minute;
@property (nonatomic, assign) NSInteger second;
@property (nonatomic, strong) NSDate    *date;

- (void)setWithDate:(NSDate *)date;
- (void)setWithCurrentDateAndTime;

@end

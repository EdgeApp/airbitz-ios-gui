//
//  DateTime.h
//  AirBitz
//
//  See LICENSE for copy, modification, and use permissions
//
//  See AUTHORS for contributing developers
//

#import <Foundation/Foundation.h>

@interface DateTime : NSObject

@property (nonatomic, assign) NSInteger month;
@property (nonatomic, assign) NSInteger day;
@property (nonatomic, assign) NSInteger year;
@property (nonatomic, assign) NSInteger hour;
@property (nonatomic, assign) NSInteger minute;
@property (nonatomic, assign) NSInteger second;

- (void)setWithDate:(NSDate *)date;
- (void)setWithCurrentDateAndTime;

@end

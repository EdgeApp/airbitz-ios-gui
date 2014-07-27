//
//  DateTime.m
//  AirBitz
//
//  See LICENSE for copy, modification, and use permissions
//
//  See AUTHORS for contributing developers
//

#import "DateTime.h"

@implementation DateTime

// overriding the description - used in debugging

- (NSString *)description
{
	return([NSString stringWithFormat:@"%d/%d/%d %d:%.02d:%.02d",
            (int) self.month,
            (int) self.day,
            (int) self.year,
            (int) self.hour,
            (int) self.minute,
            (int) self.second
            ]);
}

- (void)setWithCurrentDateAndTime
{
    NSDate *destinationDate = [NSDate date];

    [self setWithDate:destinationDate];
}

- (void)setWithDate:(NSDate *)date
{
    NSCalendar *gregorian = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [gregorian components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit |
                                                              NSHourCalendarUnit | NSMinuteCalendarUnit |NSSecondCalendarUnit)
                                                    fromDate:date];
    self.day = [dateComponents day];
    self.month = [dateComponents month];
    self.year = [dateComponents year];
    self.hour = [dateComponents hour];
    self.minute = [dateComponents minute];
    self.second = [dateComponents second];
}

@end

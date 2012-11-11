//
//  TimeFormatter.m
//  Kimai-MacOS
//
//  Created by Vinzenz-Emanuel Weber on 11.11.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "TimeFormatter.h"



@implementation TimeFormatter


+ (NSString *)formatedDurationStringWithHours:(NSInteger)hours minutes:(NSInteger)minutes {
    
    NSString *formatedTime = [NSString stringWithFormat:@"%lih %lim", hours, minutes];
    if (hours == 0) {
        formatedTime = [NSString stringWithFormat:@"%lim", minutes];
    }
    
    return formatedTime;
}


+ (NSString *)formatedDurationStringFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate {
    
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSHourCalendarUnit | NSMinuteCalendarUnit
                                                                       fromDate:fromDate
                                                                         toDate:toDate
                                                                        options:0];
    
    return [TimeFormatter formatedDurationStringWithHours:[dateComponents hour] minutes:[dateComponents minute]];
}


+ (NSString *)formatedDurationStringFromTimeInterval:(NSTimeInterval)interval {
    
    NSDate *now = [NSDate date];
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSHourCalendarUnit | NSMinuteCalendarUnit
                                                                       fromDate:now
                                                                         toDate:[now dateByAddingTimeInterval:interval]
                                                                        options:0];
    
    return [TimeFormatter formatedDurationStringWithHours:[dateComponents hour] minutes:[dateComponents minute]];
}


+ (NSString *)formatedWorkingDuration:(NSTimeInterval)timeInterval withCurrentActivity:(KimaiActiveRecording *)activity {
    
    NSDate *now = [NSDate date];
    
    if (activity != nil) {
        NSTimeInterval activityDuration = [now timeIntervalSinceDate:activity.startDate];
        timeInterval += activityDuration;
    }
    
    NSDate *nowPlusDuration = [NSDate dateWithTimeInterval:timeInterval sinceDate:now];
    NSString *totalWorkingHoursToday = [TimeFormatter formatedDurationStringFromDate:now toDate:nowPlusDuration];
    
    return totalWorkingHoursToday;
}



@end

//
//  TimeFormatter.h
//  Kimai-MacOS
//
//  Created by Vinzenz-Emanuel Weber on 11.11.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Kimai.h"

@interface TimeFormatter : NSObject

+ (NSString *)formatedDurationStringWithHours:(NSInteger)hours minutes:(NSInteger)minutes;
+ (NSString *)formatedDurationStringFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate;
+ (NSString *)formatedDurationStringFromTimeInterval:(NSTimeInterval)interval;
+ (NSString *)formatedWorkingDuration:(NSTimeInterval)timeInterval withCurrentActivity:(KimaiActiveRecording *)activity;

@end

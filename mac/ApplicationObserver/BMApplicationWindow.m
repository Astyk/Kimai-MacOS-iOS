//
//  BMApplicationWindow.m
//  RunningApplications
//
//  Created by Vinzenz-Emanuel Weber on 20.03.13.
//  Copyright (c) 2013 blockhaus medienagentur. All rights reserved.
//

#import "BMApplicationWindow.h"
#import "BMApplication.h"


@implementation BMApplicationWindow

@dynamic activateDate;
@dynamic deactivateDate;
@dynamic title;
@dynamic activeDuration;
@dynamic application;


- (void)setDeactivateDate:(NSDate *)deactivateDate {
    
    if (self.activateDate) {
        int timeinterval = [deactivateDate timeIntervalSinceDate:self.activateDate];
        self.activeDuration = [NSNumber numberWithInt:timeinterval];
#if DEBUG
        NSLog(@"Window \"%@\" was open for %i seconds!", self.title, timeinterval);
#endif
    }
    
    // finally set the value for this NSManagedObjectModel
    [self willChangeValueForKey:@"deactivateDate"];
    [self setPrimitiveValue:deactivateDate forKey:@"deactivateDate"];
    [self didChangeValueForKey:@"deactivateDate"];
}


@end

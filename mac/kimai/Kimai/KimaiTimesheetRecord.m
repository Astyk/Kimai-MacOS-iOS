//
//  KimaiTimesheetRecord.m
//  Kimai
//
//  Created by Vinzenz-Emanuel Weber on 28.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "KimaiTimesheetRecord.h"

@implementation KimaiTimesheetRecord

@synthesize start = _start;
@synthesize end = _end;


- (void)setStart:(NSNumber *)start {
    _start = start;
    self.startDate = [NSDate dateWithTimeIntervalSince1970:[start doubleValue]];
}


- (void)setEnd:(NSNumber *)end {
    _end = end;
    self.endDate = [NSDate dateWithTimeIntervalSince1970:[end doubleValue]];
}


- (NSDictionary *)dataDictionary {
    
    if (self.task == nil || self.project == nil) {
        NSLog(@"KimaiTask and KimaiProject has to be set!");
        return nil;
    }
    
    NSDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                          self.project.projectID, @"projectId",
                          self.task.activityID, @"taskId",
                          self.startDate.description, @"start",
                          self.endDate.description, @"end",
                          self.statusID, @"statusId",
                          nil];
    
    return dict;

}


@end


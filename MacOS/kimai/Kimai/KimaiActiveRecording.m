//
//  KimaiActiveRecording.m
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 18.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "KimaiActiveRecording.h"

@implementation KimaiActiveRecording

@synthesize start = _start;

- (void)setStart:(NSNumber *)start {
    _start = start;
    self.startDate = [NSDate dateWithTimeIntervalSince1970:[start doubleValue]];
}

@end

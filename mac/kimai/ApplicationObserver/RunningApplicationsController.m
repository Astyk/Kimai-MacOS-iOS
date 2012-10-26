//
//  RunningApplicationsController.m
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 19.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "RunningApplicationsController.h"

@implementation RunningApplicationsController

- (id)init
{
    self = [super init];
    if (self) {
        
        NSArray *runningApplicationsArray = [[NSWorkspace sharedWorkspace] runningApplications];
        
        [runningApplicationsArray addObserver:self
                                   forKeyPath:@""
                                      options:NSKeyValueObservingOptionNew
                                      context:nil];

    }
    return self;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == nil) {
        NSLog(@"%@", object);
        
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

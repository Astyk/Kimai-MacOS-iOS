//
//  RunningApplicationsController.h
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 19.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BMApplicationWindow.h"
#import "BMApplication.h"

@interface RunningApplicationsController : NSArrayController

@property (nonatomic, strong) BMApplication *currentApplication;
@property (nonatomic, strong) BMApplicationWindow *currentApplicationWindow;

@end

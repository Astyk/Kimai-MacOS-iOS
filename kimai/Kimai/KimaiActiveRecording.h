//
//  KimaiActiveRecording.h
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 18.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "KimaiObject.h"

@interface KimaiActiveRecording : KimaiObject

@property (strong) NSNumber *timeEntryID;

@property (strong) NSNumber *customerID;
@property (strong) NSString *customerName;

@property (strong) NSNumber *projectID;
@property (strong) NSString *projectName;

@property (strong) NSNumber *activityID;
@property (strong) NSString *activityName;

@property (strong) NSNumber *servertime;
@property (strong) NSNumber *start;
@property (strong) NSNumber *duration;
@property (strong) NSNumber *end;

@end

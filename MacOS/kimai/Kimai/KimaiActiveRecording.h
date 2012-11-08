//
//  KimaiActiveRecording.h
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 18.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "KimaiObject.h"

@interface KimaiActiveRecording : KimaiObject {
    NSNumber *_start;
}

@property (nonatomic, strong) NSNumber *timeEntryID;

@property (nonatomic, strong) NSNumber *customerID;
@property (nonatomic, strong) NSString *customerName;

@property (nonatomic, strong) NSNumber *projectID;
@property (nonatomic, strong) NSString *projectName;

@property (nonatomic, strong) NSNumber *activityID;
@property (nonatomic, strong) NSString *activityName;

@property (nonatomic, strong) NSNumber *servertime;
@property (nonatomic, strong) NSNumber *start;
@property (nonatomic, strong) NSNumber *duration;
@property (nonatomic, strong) NSNumber *end;

@property (nonatomic, strong) NSDate *startDate;

@end

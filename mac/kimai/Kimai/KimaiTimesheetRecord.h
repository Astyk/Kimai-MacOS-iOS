//
//  KimaiTimesheetRecord.h
//  Kimai
//
//  Created by Vinzenz-Emanuel Weber on 28.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "JSONObject.h"
#import "KimaiTask.h"
#import "KimaiProject.h"


@interface KimaiTimesheetRecord : JSONObject {
    NSNumber *_start;
    NSNumber *_end;
}


@property (nonatomic, readonly) NSDictionary *dataDictionary;

@property (nonatomic, weak) KimaiProject *project;
@property (nonatomic, weak) KimaiTask *task;


// API attributes
@property (nonatomic, strong) NSNumber *timeEntryID;

@property (nonatomic, strong) NSNumber *userID;
@property (nonatomic, strong) NSString *userAlias;
@property (nonatomic, strong) NSString *userName;

@property (nonatomic, strong) NSNumber *customerID;
@property (nonatomic, strong) NSString *customerName;

@property (nonatomic, strong) NSNumber *projectID;
@property (nonatomic, strong) NSString *projectName;
@property (nonatomic, strong) NSString *projectComment;

@property (nonatomic, strong) NSNumber *activityID;
@property (nonatomic, strong) NSString *activityName;

@property (nonatomic, strong) NSNumber *approved;
@property (nonatomic, strong) NSNumber *billable;
@property (nonatomic, strong) NSNumber *budget;
@property (nonatomic, strong) NSNumber *cleared;
@property (nonatomic, strong) NSNumber *wage;
@property (nonatomic, strong) NSNumber *wage_decimal;
@property (nonatomic, strong) NSNumber *rate;
@property (nonatomic, strong) NSString *fixedRate;

@property (nonatomic, strong) NSString *comment;
@property (nonatomic, strong) NSNumber *commentType;

//@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSString *location;

@property (nonatomic, strong) NSNumber *start;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, strong) NSNumber *duration;
@property (nonatomic, strong) NSString *formattedDuration;
@property (nonatomic, strong) NSNumber *end;
@property (nonatomic, strong) NSDate *endDate;

@property (nonatomic, strong) NSNumber *statusID;
@property (nonatomic, strong) NSString *status;

@property (nonatomic, strong) NSNumber *trackingNumber;


@end

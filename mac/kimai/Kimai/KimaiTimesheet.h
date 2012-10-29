//
//  KimaiTimesheet.h
//  Kimai
//
//  Created by Vinzenz-Emanuel Weber on 28.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "KimaiObject.h"

@interface KimaiTimesheet : KimaiObject


@property (strong) NSNumber *activityID;
@property (strong) NSString *activityName;

@property (strong) NSNumber *approved;
@property (strong) NSNumber *billable;
@property (strong) NSNumber *budget;
@property (strong) NSNumber *cleared;
@property (strong) NSNumber *wage;
@property (strong) NSNumber *wage_decimal;
@property (strong) NSNumber *rate;

@property (strong) NSString *comment;
@property (strong) NSNumber *commentType;

@property (strong) NSNumber *customerID;
@property (strong) NSString *customerName;

//@property (strong) NSString *description;
@property (strong) NSString *location;

@property (strong) NSNumber *duration;
@property (strong) NSString *formattedDuration;

@property (strong) NSNumber *projectID;
@property (strong) NSString *projectName;
@property (strong) NSString *projectComment;

@property (strong) NSNumber *start;
@property (strong) NSNumber *end;

@property (strong) NSNumber *statusID;
@property (strong) NSString *status;

@property (strong) NSNumber *timeEntryID;
@property (strong) NSNumber *trackingNumber;

@property (strong) NSNumber *userID;
@property (strong) NSString *userAlias;
@property (strong) NSString *userName;

@end

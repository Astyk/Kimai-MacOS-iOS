//
//  Kimai.h
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 17.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KSReachability.h"

#import "KimaiProject.h"
#import "KimaiUser.h"
#import "KimaiTask.h"
#import "KimaiActiveRecording.h"
#import "KimaiTimesheetRecord.h"


typedef void (^KimaiSuccessHandler)(id response);
typedef void (^KimaiFailureHandler)(NSError *error);


@protocol KimaiDelegate <NSObject>

- (void)reachabilityChanged:(NSNumber *)isServiceReachable;

@end



@interface Kimai : NSObject

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSString *apiKey;

@property (nonatomic, strong) NSArray *users;
@property (nonatomic, strong) NSArray *projects;
@property (nonatomic, strong) NSArray *tasks;
@property (nonatomic, strong) NSArray *activeRecordings;
@property (nonatomic, strong) NSArray *timesheetRecords;

@property (nonatomic, strong) KSReachability *reachability;
@property (nonatomic, readonly) BOOL isServiceReachable;

@property (nonatomic, assign) id <KimaiDelegate> delegate;


- (id)initWithURL:(NSURL *)url;
- (void)authenticateWithUsername:(NSString *)username password:(NSString *)password success:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler;

- (void)logAllData;

- (void)reloadAllContent;
- (void)reloadAllContentWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler;
- (void)reloadUsersWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler;
- (void)reloadProjectsWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler;
- (void)reloadTasksWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler;
- (void)reloadActiveRecordingWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler;

- (void)reloadCurrentDayTimesheetWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler;
- (void)reloadTimesheetWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate limitStart:(NSNumber *)limitStart limitCount:(NSNumber *)limitCount success:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler;
- (void)getTimesheetRecordWithID:(NSNumber *)timesheetRecordID success:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler;
- (void)setTimesheetRecord:(KimaiTimesheetRecord *)record success:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler;

- (void)startProject:(KimaiProject *)project withTask:(KimaiTask *)task success:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler;
- (void)stopAllActivityRecordingsWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler;
- (void)stopActivityRecording:(KimaiActiveRecording *)activity success:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler;

@end

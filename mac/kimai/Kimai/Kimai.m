//
//  Kimai.m
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 17.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "Kimai.h"
#import "DSJSONRPC.h"

#define ERROR_DOMAIN @"org.kimai"


@interface Kimai() {
    DSJSONRPC *_jsonRPC;
    NSTimer *_reachabilityChangeTimeout;
    BOOL _previousReachable;
}

@end



@implementation Kimai



- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {

        self.url = url;
        
        // init service endpoint
        NSURL *jsonURL = [url URLByAppendingPathComponent:@"core/json.php"];
        _jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:jsonURL];
                
        // init Reachability
        _previousReachable = NO;
        _reachabilityChangeTimeout = nil;

        NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self
                               selector:@selector(onReachabilityChanged:)
                                   name:kDefaultNetworkReachabilityChangedNotification
                                 object:nil];

        self.reachability = [KSReachability reachabilityToHost:url.host];
        self.reachability.notificationName = kDefaultNetworkReachabilityChangedNotification;
        
        
    }
    return self;
}


#pragma mark - Reachability


- (void)onReachabilityChanged:(NSNotification*)notification {
    
    KSReachability* reachability = (KSReachability*)notification.object;

    // in case nothing changed, we don't need to do nothing
    if (_previousReachable == reachability.reachable) {
        return;
    }
    
    // unbounce reachability changes
    if (_reachabilityChangeTimeout != nil) {
        [_reachabilityChangeTimeout invalidate];
        _reachabilityChangeTimeout = nil;
    }
    
    // reschedule a timeout timer
    _reachabilityChangeTimeout = [NSTimer timerWithTimeInterval:2
                                                         target:self
                                                       selector:@selector(onReachabilityChangedTimeout:)
                                                       userInfo:reachability
                                                        repeats:NO];
    
    [[NSRunLoop currentRunLoop] addTimer:_reachabilityChangeTimeout
                                 forMode:NSDefaultRunLoopMode];

}


/*
 * Use a timer to detect REAL connection changes.
 * Switching from Wifi to Ethernet in software also creates reachability events in a timeframe of about one second.
 * 
 */
- (void)onReachabilityChangedTimeout:(NSTimer *)timer {

    KSReachability* reachability = (KSReachability*)timer.userInfo;

    _previousReachable = reachability.reachable;
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(reachabilityChanged:)]) {
        [self.delegate performSelector:@selector(reachabilityChanged:) withObject:[NSNumber numberWithBool:reachability.reachable]];
    }
    
    [_reachabilityChangeTimeout invalidate];
    _reachabilityChangeTimeout = nil;
    
}


- (BOOL)isServiceReachable {
    return self.reachability.reachable;
}



#pragma mark - API


- (void)logAllData {

    NSLog(@"PROJECTS:");

    for (KimaiProject *project in self.projects) {
        NSLog(@"%@", project);
    }

    NSLog(@"TASKS:");
    
    for (KimaiTask *task in self.tasks) {
        NSLog(@"%@", task);
    }
    
    NSLog(@"ACTIVITY:");
    
    for (KimaiActiveRecording *activity in self.activeRecordings) {
        NSLog(@"%@", activity);
    }

    NSLog(@"TIMESHEET:");
    
    for (KimaiTimesheetRecord *record in self.todayTimesheetRecords) {
        NSLog(@"%@", record);
    }

}


- (void)reloadAllContent {

    [self reloadAllContentWithSuccess:^(id response) {
        [self logAllData];
    } failure:^(NSError *error) {
        NSLog(@"ERROR: %@", error);
    }];
    
}


- (void)reloadAllContentWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
    
    NSLog(@"RELOAD ALL CONTENT");

    [self reloadProjectsWithSuccess:^(id response) {
       
        [self reloadTasksWithSuccess:^(id response) {

            [self reloadActiveRecordingWithSuccess:^(id response) {
                
                [self reloadCurrentDayTimesheetWithSuccess:successHandler failure:failureHandler];
                
            } failure:failureHandler];

        } failure:failureHandler];

    } failure:failureHandler];

}


#pragma mark authenticate


- (void)authenticateWithUsername:(NSString *)username password:(NSString *)password success:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
    
    [self _callMethod:@"authenticate"
       withParameters:@[username, password]
       successHandler:^(id response) {
           
           NSDictionary *items = (NSDictionary *)response;
           NSArray *apiKeyArray = [items valueForKey:@"apiKey"];
           NSString *apiKey = [apiKeyArray objectAtIndex:0];
           if (apiKey) {
               self.apiKey = apiKey;
               
               if (successHandler) {
                   successHandler(nil);
               }
           }

       }
       failureHandler:failureHandler];
    
}


#pragma mark getUsers


- (void)reloadUsersWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
    
    [self _mapMethod:@"getUsers"
             toClass:[KimaiUser class]
             success:^(id response) {
        
        self.users = response;
        
        if (successHandler) {
            successHandler(response);
        }
        
    } failure:failureHandler];
    
}


#pragma mark getProjects


- (void)reloadProjectsWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
   
    [self _mapMethod:@"getProjects"
             toClass:[KimaiProject class]
             success:^(id response) {
        
        self.projects = response;
        
        if (successHandler) {
            successHandler(response);
        }
        
    } failure:failureHandler];
    
}


#pragma mark getTasks


- (void)reloadTasksWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
 
    [self _mapMethod:@"getTasks"
             toClass:[KimaiTask class]
             success:^(id response) {

        self.tasks = response;
        
        if (successHandler) {
            successHandler(response);
        }
        
    } failure:failureHandler];
    
}


#pragma mark getActiveRecording


- (void)reloadActiveRecordingWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
    
    [self _mapMethod:@"getActiveRecording"
             toClass:[KimaiActiveRecording class]
             success:^(id response) {
        
        self.activeRecordings = response;
        
        if (successHandler) {
            successHandler(response);
        }
        
    } failure:^(NSError *error) {
        
        if ([[error.userInfo valueForKey:@"NSLocalizedDescriptionKey"] isEqualToString:@"No active recording."]) {
            
            self.activeRecordings = nil;

            if (successHandler) {
                successHandler(nil);
            }

        } else if (failureHandler) {
            failureHandler(error);
        }
        
    }];
    
}


#pragma mark startRecord


- (void)startProject:(KimaiProject *)project withTask:(KimaiTask *)task success:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
    
    [self stopAllActivityRecordingsWithSuccess:^(id response) {

        //NSNumber *timeIntervalSince1970 = [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]];
        
        [self _callMethod:@"startRecord"
           withParameters:@[self.apiKey, project.projectID, task.activityID] // timeIntervalSince1970
           successHandler:^(id response) {
               if (response && [response isKindOfClass:[NSArray class]]) {
                   if (successHandler) {
                       successHandler(nil);
                   }
               }
           }
           failureHandler:failureHandler];

    } failure:failureHandler];

}


#pragma mark stopRecord


- (void)stopAllActivityRecordingsWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
    if (self.activeRecordings.count > 0) {
        
        KimaiActiveRecording *activity = [self.activeRecordings objectAtIndex:0];
        
        [self stopActivityRecording:activity success:^(id response) {
            
            [self reloadActiveRecordingWithSuccess:^(id response) {
                [self stopAllActivityRecordingsWithSuccess:successHandler failure:failureHandler];
            } failure:failureHandler];
            
        } failure:^(NSError *error) {
            NSLog(@"%@", error);
            [self stopAllActivityRecordingsWithSuccess:successHandler failure:failureHandler];
        }];
        
    } else if (successHandler) {
        successHandler(nil);
    }
}


- (void)stopActivityRecording:(KimaiActiveRecording *)activity success:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
    
    [self _callMethod:@"stopRecord"
       withParameters:@[self.apiKey, activity.timeEntryID]
       successHandler:^(id response) {
           if (response && [response isKindOfClass:[NSArray class]]) {
               if (successHandler) {
                   successHandler(nil);
               }
           }
       }
       failureHandler:failureHandler];
    
}


#pragma mark getTimesheet


- (void)reloadCurrentDayTimesheetWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {

    // FROM TODAY 00:00 UNTIL NOW
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
                                          fromDate:[NSDate date]];
    NSDate *startDate = [cal dateFromComponents:components];
    NSDate *endDate = [NSDate date];
    
    [self reloadTimesheetWithStartDate:startDate
                               endDate:endDate
                            limitStart:[NSNumber numberWithInt:0]
                            limitCount:[NSNumber numberWithInt:100]
                               success:^(id response) {
                                   
                                   self.todayTimesheetRecords = response;
                                   
                                   if (successHandler) {
                                       successHandler(response);
                                   }
                                   
                               }
                               failure:failureHandler];
}


- (void)reloadTimesheetWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate limitStart:(NSNumber *)limitStart limitCount:(NSNumber *)limitCount success:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {

    NSNumber *cleared = [NSNumber numberWithInt:0]; // -1 no filtering, 0 uncleared only, 1 cleared only

    [self _mapMethod:@"getTimesheet"
      withParameters:@[self.apiKey, startDate.description, endDate.description, cleared, limitStart, limitCount]
             toClass:[KimaiTimesheetRecord class]
             success:successHandler
             failure:failureHandler];
    
}


- (void)getTimesheetRecordWithID:(NSNumber *)timesheetRecordID success:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
    
    [self _mapMethod:@"getTimesheetRecord"
      withParameters:@[self.apiKey, timesheetRecordID]
             toClass:[KimaiTimesheetRecord class]
             success:successHandler
             failure:failureHandler];
    
}


- (void)setTimesheetRecord:(KimaiTimesheetRecord *)record success:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
    
    [self _callMethod:@"setTimesheetRecord"
       withParameters:@[self.apiKey, record.dataDictionary]
       successHandler:^(id response) {
           
           NSDictionary *items = (NSDictionary *)response;
           NSNumber *timeEntryID = [[items valueForKey:@"id"] objectAtIndex:0];
           if (timeEntryID) {
               record.timeEntryID = timeEntryID;
               if (successHandler) {
                   successHandler(record);
               }
           }
           
       }
       failureHandler:failureHandler];
    
}


#pragma mark - Map ID to Object


- (KimaiTask *)taskWithID:(NSNumber *)activityID {
    
    if (self.tasks) {
        NSArray *filteredTasks = [self.projects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"activityID = %@", activityID]];
        if (filteredTasks && filteredTasks.count == 1) {
            return [filteredTasks objectAtIndex:0];
        }
    }
    
    return nil;
}


- (KimaiProject *)projectWithID:(NSNumber *)projectID {

    if (self.projects) {
        NSArray *filteredProjects = [self.projects filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"projectID = %@", projectID]];
        if (filteredProjects && filteredProjects.count == 1) {
            return [filteredProjects objectAtIndex:0];
        }
    }
    
    return nil;
}


#pragma mark - Private


- (void)_mapMethod:(NSString *)method toClass:(Class)kimaiObjectClass success:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
    
    if (self.apiKey == nil && failureHandler) {
        failureHandler([NSError errorWithDomain:ERROR_DOMAIN code:-1 userInfo:[NSDictionary dictionaryWithObject:@"Not authenticated yet!" forKey:@"NSLocalizedDescriptionKey"]]);
        return;
    }
    
    [self _mapMethod:method
      withParameters:@[self.apiKey]
             toClass:kimaiObjectClass
             success:successHandler
             failure:failureHandler];
}


- (void)_mapMethod:(NSString *)method withParameters:(id)methodParams toClass:(Class)kimaiObjectClass success:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
    
    [self _callMethod:method
       withParameters:methodParams
       successHandler:^(id response) {
           if (response && [response isKindOfClass:[NSArray class]]) {
               
               NSArray *responseArray = (NSArray *)response;
               NSMutableArray *responseObjects = [NSMutableArray arrayWithCapacity:responseArray.count];
               
               for (NSDictionary *objectDictionary in responseArray) {
                   id kimaiObject = [[kimaiObjectClass alloc] initWithDictionary:objectDictionary];
                   [responseObjects addObject:kimaiObject];
               }

               if (successHandler) {
                   successHandler(responseObjects);
               }
               
           } else if (failureHandler) {
               failureHandler([NSError errorWithDomain:ERROR_DOMAIN code:-1 userInfo:[NSDictionary dictionaryWithObject:@"No items in server response!" forKey:@"NSLocalizedDescriptionKey"]]);
           }
       }
       failureHandler:failureHandler];

}


- (void)_callMethod:(NSString *)methodName
          withParameters:(id)methodParams
          successHandler:(KimaiSuccessHandler)successHandler
          failureHandler:(KimaiFailureHandler)failureHandler {
    
    
    // check internet connection
    if (self.reachability.reachable == NO) {
        NSLog(@"Unable to call method %@, we are offline or Kimai is not reachable.", methodName);
        return;
    }
    
    
    // we need an API key for all API calls except "authenticate"
    if (![methodName isEqualToString:@"authenticate"]) {
        if (self.apiKey == nil) {
            if (failureHandler) {
                failureHandler([NSError errorWithDomain:ERROR_DOMAIN code:-1 userInfo:[NSDictionary dictionaryWithObject:@"API key is missing! Authenticate first!" forKey:@"NSLocalizedDescriptionKey"]]);
            }
            return;
        }
    }
    
    
    NSLog(@"Call method \"%@\"", methodName);
    
    [_jsonRPC callMethod:methodName
          withParameters:methodParams
            onCompletion:^(NSString *methodName, NSInteger callId, id methodResult, DSJSONRPCError *methodError, NSError *internalError) {
                
                if (methodError) {
                    
                    NSLog(@"\nMethod %@(%li) returned an error: %@\n\n", methodName, callId, methodError);

                    if (failureHandler) {
                        failureHandler([NSError errorWithDomain:ERROR_DOMAIN code:methodError.code userInfo:[NSDictionary dictionaryWithObject:methodError.message forKey:@"NSLocalizedDescriptionKey"]]);
                    }
                    
                } else if (internalError) {
                    
                    NSLog(@"\nMethod %@(%li) couldn't be sent with error: %@\n\n", methodName, callId, internalError);

                    if (failureHandler) {
                        failureHandler(internalError);
                    }
                    
                } else {
                    
                    NSDictionary *dict = (NSDictionary *)methodResult;
                    if (dict) {
                        
                        NSNumber *success = (NSNumber *)[dict valueForKey:@"success"];
                        if (success.boolValue) {

                            id items = [dict valueForKey:@"items"];
                            
                            if (successHandler) {
                                successHandler(items);
                            }
                            
                        } else if (failureHandler) {
                            
                            NSDictionary *error = (NSDictionary *)[dict valueForKey:@"error"];
                            NSString *msg = (NSString *)[error valueForKey:@"msg"];

                            failureHandler([NSError errorWithDomain:ERROR_DOMAIN code:-1 userInfo:[NSDictionary dictionaryWithObject:msg forKey:@"NSLocalizedDescriptionKey"]]);
                            
                        }
                        
                    } else if (failureHandler) {
                        
                        failureHandler([NSError errorWithDomain:ERROR_DOMAIN code:-1 userInfo:[NSDictionary dictionaryWithObject:@"No response from server!" forKey:@"NSLocalizedDescriptionKey"]]);
                        
                    }

                    
                }
            }];
}


#pragma mark - Memory


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end


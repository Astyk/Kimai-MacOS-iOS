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
}

@end



@implementation Kimai



- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        self.url = url;
        NSURL *jsonURL = [url URLByAppendingPathComponent:@"core/json.php"];
        _jsonRPC = [[DSJSONRPC alloc] initWithServiceEndpoint:jsonURL];
    }
    return self;
}


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

}



- (void)reloadAllContent {

    [self reloadAllContentWithSuccess:^(id response) {
        [self logAllData];
    } failure:^(NSError *error) {
        NSLog(@"ERROR: %@", error);
    }];
    
}


- (void)reloadAllContentWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
    
    [self reloadProjectsWithSuccess:^(id response) {
       
        [self reloadTasksWithSuccess:^(id response) {

         [self reloadActiveRecordingWithSuccess:successHandler failure:failureHandler];

        } failure:failureHandler];

    } failure:failureHandler];

}


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


- (void)reloadProjectsWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
   
    [self _mapMethod:@"getProjects" toClass:[KimaiProject class] success:^(id response) {
        
        self.projects = response;
        
        if (successHandler) {
            successHandler(response);
        }
        
    } failure:failureHandler];
    
}


- (void)reloadTasksWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
 
    [self _mapMethod:@"getTasks" toClass:[KimaiTask class] success:^(id response) {

        self.tasks = response;
        
        if (successHandler) {
            successHandler(response);
        }
        
    } failure:failureHandler];
    
}


- (void)reloadActiveRecordingWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
    
    [self _mapMethod:@"getActiveRecording" toClass:[KimaiActiveRecording class] success:^(id response) {
        
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


- (void)startProject:(KimaiProject *)project withTask:(KimaiTask *)task success:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
    
    [self stopAllActivityRecordingsWithSuccess:^(id response) {

        [self _callMethod:@"startRecord"
           withParameters:@[self.apiKey, project.projectID, task.activityID]
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


- (void)stopAllActivityRecordingsWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
    if (self.activeRecordings.count > 0) {
        
        KimaiActiveRecording *activity = [self.activeRecordings objectAtIndex:0];
        
        [self stopActivityRecording:activity success:^(id response) {
            
            [self reloadActiveRecordingWithSuccess:^(id response) {
                [self stopAllActivityRecordingsWithSuccess:successHandler failure:failureHandler];
            } failure:^(NSError *error) {
                [self stopAllActivityRecordingsWithSuccess:successHandler failure:failureHandler];
            }];
            
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


- (void)_mapMethod:(NSString *)method toClass:(Class)kimaiObjectClass success:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
    
    [self _callMethod:method
       withParameters:@[self.apiKey]
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
               
           }
       }
       failureHandler:failureHandler];

}


- (void)_callMethod:(NSString *)methodName
          withParameters:(id)methodParams
          successHandler:(KimaiSuccessHandler)successHandler
          failureHandler:(KimaiFailureHandler)failureHandler {
    
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
                        
                        BOOL success = (BOOL)[dict valueForKey:@"success"];
                        if (success) {

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


@end


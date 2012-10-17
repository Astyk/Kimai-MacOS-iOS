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



- (void)preloadAllContent {
    
    KimaiFailureHandler failureHandler = ^(NSError *error) {
        NSLog(@"%@", error);
    };
    
    
    [self reloadProjectsWithSuccess:^(id response) {
        
        for (KimaiProject *project in response) {
            NSLog(@"%@", project);
        }
        
        [self reloadTasksWithSuccess:^(id response) {
            
            for (KimaiTask *task in response) {
                NSLog(@"%@", task);
            }
            
        } failure:failureHandler];
        
    } failure:failureHandler];

}

/*
 function initRecorderPage()
 {
 setProjects(Kimai.getProjects());
 setTasks(Kimai.getTasks());
 setActiveTask(Kimai.getRunningTask());
 }
 */
//getActiveRecording

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
    
    [self _callMethod:@"getProjects"
       withParameters:@[self.apiKey]
       successHandler:^(id response) {
           if (response && [response isKindOfClass:[NSArray class]]) {
               
               NSArray *responseProjects = (NSArray *)response;
               NSMutableArray *projects = [NSMutableArray arrayWithCapacity:responseProjects.count];
               
               for (NSDictionary *project in responseProjects) {
                   KimaiProject *kimaiProject = [[KimaiProject alloc] initWithDictionary:project];
                   [projects addObject:kimaiProject];
               }
               
               self.projects = projects;
               
               if (successHandler) {
                   successHandler(self.projects);
               }
               
           }
       }
       failureHandler:failureHandler];
    
}


- (void)reloadTasksWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
    
    [self _callMethod:@"getTasks"
       withParameters:@[self.apiKey]
       successHandler:^(id response) {
           if (response && [response isKindOfClass:[NSArray class]]) {
               
               NSArray *responseTasks = (NSArray *)response;
               NSMutableArray *tasks = [NSMutableArray arrayWithCapacity:responseTasks.count];
               
               for (NSDictionary *task in responseTasks) {
                   KimaiTask *kimaiTask = [[KimaiTask alloc] initWithDictionary:task];
                   [tasks addObject:kimaiTask];
               }
               
               self.tasks = tasks;
               
               if (successHandler) {
                   successHandler(self.tasks);
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
                            failureHandler([NSError errorWithDomain:ERROR_DOMAIN code:-1 userInfo:[NSDictionary dictionaryWithObject:@"Unknown error" forKey:@"NSLocalizedDescriptionKey"]]);
                        }
                    }
                    
                }
            }];
}


@end


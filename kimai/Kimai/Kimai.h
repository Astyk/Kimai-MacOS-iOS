//
//  Kimai.h
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 17.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KimaiProject.h"
#import "KimaiTask.h"

typedef void (^KimaiSuccessHandler)(id response);
typedef void (^KimaiFailureHandler)(NSError *error);


@interface Kimai : NSObject

@property (strong) NSURL *url;
@property (strong) NSString *apiKey;
@property (strong) NSArray *projects;
@property (strong) NSArray *tasks;


- (id)initWithURL:(NSURL *)url;
- (void)preloadAllContent;
- (void)authenticateWithUsername:(NSString *)username password:(NSString *)password success:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler;
- (void)reloadProjectsWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler;
- (void)reloadTasksWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler;




@end

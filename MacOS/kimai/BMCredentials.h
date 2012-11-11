//
//  BMCredentials.h
//
//  Created by Vinzenz-Emanuel Weber on 11.11.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SSKeychain.h"


typedef void (^BMCredentialsLoadSuccessHandler)(NSString *username, NSString *password, NSString *serviceURL);
typedef void (^BMCredentialsStoreSuccessHandler)();
typedef void (^BMCredentialsFailureHandler)(NSError *error);


@interface BMCredentials : NSObject

+ (void)loadCredentialsWithServicename:(NSString *)servicename success:(BMCredentialsLoadSuccessHandler)successHandler failure:(BMCredentialsFailureHandler)failureHandler;

+ (void)storeServiceURL:(NSString *)serviceURL username:(NSString *)username password:(NSString *)password servicename:(NSString *)servicename success:(BMCredentialsStoreSuccessHandler)successHandler failure:(BMCredentialsFailureHandler)failureHandler;

@end

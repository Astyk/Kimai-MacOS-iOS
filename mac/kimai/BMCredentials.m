//
//  BMCredentials.m
//
//  Created by Vinzenz-Emanuel Weber on 11.11.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "BMCredentials.h"

@implementation BMCredentials


+ (void)loadCredentialsWithServicename:(NSString *)servicename success:(BMCredentialsLoadSuccessHandler)successHandler failure:(BMCredentialsFailureHandler)failureHandler {
        
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSError *error = nil;
    
    NSString *serviceURL = [standardUserDefaults stringForKey:@"BMCredentialsServiceURLKey"];
    NSString *username = nil;
    NSString *password = nil;
    
    NSArray *allAccounts = [SSKeychain accountsForService:servicename error:&error];
    if (allAccounts != nil && allAccounts.count > 0) {
        
        NSDictionary *account = [allAccounts objectAtIndex:0];
        
        // to be backwards compatible, should be removed in some future release
        NSString *kimaiURLOrNil = [account valueForKey:@"icmt"];
        if (serviceURL == nil && kimaiURLOrNil != nil && [NSURL URLWithString:kimaiURLOrNil] != nil) {
            serviceURL = kimaiURLOrNil;
        }
        
        username = [account valueForKey:@"acct"];
        if (username == nil) {
            NSLog(@"Could not get username from keychain!");
        } else {
            
            password = [SSKeychain passwordForService:servicename account:username error:&error];
            if (password == nil) {
                NSLog(@"Could not get password from keychain!");
            }
            
        }
        
    } else {
        NSLog(@"No credentials in keychain!");
    }
    
    if ((serviceURL == nil || username == nil || password == nil) && failureHandler) {
        failureHandler(error);
    } else if (successHandler) {
        successHandler(username, password, serviceURL);
    }
    
}


+ (void)storeServiceURL:(NSString *)serviceURL username:(NSString *)username password:(NSString *)password servicename:(NSString *)servicename success:(BMCredentialsStoreSuccessHandler)successHandler failure:(BMCredentialsFailureHandler)failureHandler {
    
    if (serviceURL) {
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        [standardUserDefaults setValue:serviceURL forKey:@"BMCredentialsServiceURLKey"];
    }
    
    
    
    NSError *error = nil;
    
    // remove all accounts first before storing another one
    NSArray *allAccounts = [SSKeychain accountsForService:servicename];
    for (NSDictionary *account in allAccounts) {
        error = nil;
        if (([SSKeychain deletePasswordForService:[account valueForKey:@"svce"] account:[account valueForKey:@"acct"] error:&error] == NO || error != nil) && failureHandler) {
            failureHandler(error);
        } else if (successHandler) {
            successHandler(nil);
        }
    }
    
    // set a new password
    error = nil;
    if (([SSKeychain setPassword:password forService:servicename account:username error:&error] == NO || error != nil) && failureHandler) {
        failureHandler(error);
    } else if (successHandler) {
        successHandler(nil);
    }
    
}


@end

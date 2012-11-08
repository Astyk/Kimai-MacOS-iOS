//
//  ViewController.m
//  Kimai
//
//  Created by Vinzenz-Emanuel Weber on 07.11.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "ViewController.h"
#import "KSReachability.h"
#import "SSKeychain.h"


@interface ViewController ()

typedef void (^KeychainSuccessHandler)(NSString *username, NSString *password, NSString *kimaiServerURL);
typedef void (^KeychainFailureHandler)(NSError *error);

@end

@implementation ViewController


static NSString *SERVICENAME = @"org.kimai.timetracker";


KimaiFailureHandler standardFailureHandler = ^(NSError *error) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
};


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self initKimai];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Credentials


- (void)getCredentialsWithSuccess:(KeychainSuccessHandler)successHandler failure:(KeychainFailureHandler)failureHandler {
        
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSError *error = nil;
    
    NSString *kimaiServerURL = [standardUserDefaults stringForKey:@"KimaiServerURLKey"];
    NSString *username = nil;
    NSString *password = nil;
    
    NSArray *allAccounts = [SSKeychain accountsForService:SERVICENAME error:&error];
    if (allAccounts != nil && allAccounts.count > 0) {
        
        NSString *username = [allAccounts objectAtIndex:0];
        if (username == nil) {
            NSLog(@"Could not get username from keychain!");
        } else {
            
            NSString *password = [SSKeychain passwordForService:SERVICENAME account:username error:&error];
            if (password == nil) {
                NSLog(@"Could not get password from keychain!");
            }
            
        }
        
    } else {
        NSLog(@"No credentials in keychain!");
    }

    if ((kimaiServerURL == nil || username == nil || password == nil) && failureHandler) {
        failureHandler(error);
    } else if (successHandler) {
        successHandler(username, password, kimaiServerURL);
    }

}


- (void)setKimaiServerURL:(NSString *)kimaiServerUrl username:(NSString *)username password:(NSString *)password {
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setValue:kimaiServerUrl forKey:@"KimaiServerURLKey"];
    
    NSError *error = nil;
    if ([SSKeychain setPassword:password forService:SERVICENAME account:username error:&error] == NO) {
        standardFailureHandler(error);
    }
    
}


#pragma mark - Kimai


- (void)initKimai {
    
    [self getCredentialsWithSuccess:^(NSString *username, NSString *password, NSString *kimaiServerURL) {

        self.kimai = [[Kimai alloc] initWithURL:[NSURL URLWithString:kimaiServerURL]];
        self.kimai.delegate = self;

    } failure:^(NSError *error) {

        NSLog(@"%@", error);
        // display login screen
    
    }];
    
}


- (void)reloadData {
    
    if (self.kimai.isServiceReachable == NO) {
        return;
    }
    
    [self.kimai reloadAllContentWithSuccess:^(id response) {
        [self.kimai logAllData];
    } failure:standardFailureHandler];
    
}


#pragma mark - KimaiDelegate


- (void)reachabilityChanged:(NSNumber *)isServiceReachable {
    
    NSLog(@"Reachability changed to %@", isServiceReachable.boolValue ? @"ONLINE" : @"OFFLINE");
    
    if (isServiceReachable.boolValue) {
        
        if (self.kimai.apiKey == nil) {
            
            [self getCredentialsWithSuccess:^(NSString *username, NSString *password, NSString *kimaiServerURL) {
                
                [self.kimai authenticateWithUsername:username password:password success:^(id response) {
                    [self reloadData];
                } failure:standardFailureHandler];
                
            } failure:^(NSError *error) {

                NSLog(@"%@", error);
                // display login screen
                
            }];

        } else {
            [self reloadData];
        }
        
    } else {
        NSLog(@"Offline");
    }
    
}


@end

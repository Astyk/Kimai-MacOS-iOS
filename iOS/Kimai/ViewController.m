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
#import "TasksViewController.h"


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


- (void)loadCredentialsWithSuccess:(KeychainSuccessHandler)successHandler failure:(KeychainFailureHandler)failureHandler {
    
    /*
     #if DEBUG
     if (successHandler) {
     successHandler(@"testuser1", @"test123", @"https://timetracker.blockhausmedien.at");
     }
     return;
     #endif
     */
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    NSError *error = nil;
    
    NSString *kimaiServerURL = [standardUserDefaults stringForKey:@"KimaiServerURLKey"];
    NSString *username = nil;
    NSString *password = nil;
    
    NSArray *allAccounts = [SSKeychain accountsForService:SERVICENAME error:&error];
    if (allAccounts != nil && allAccounts.count > 0) {
        
        NSDictionary *account = [allAccounts objectAtIndex:0];
        
        // to be backwards compatible, should be removed in some future release
        NSString *kimaiURLOrNil = [account valueForKey:@"icmt"];
        if (kimaiServerURL == nil && kimaiURLOrNil != nil && [NSURL URLWithString:kimaiURLOrNil] != nil) {
            kimaiServerURL = kimaiURLOrNil;
        }
        
        username = [account valueForKey:@"acct"];
        if (username == nil) {
            NSLog(@"Could not get username from keychain!");
        } else {
            
            password = [SSKeychain passwordForService:SERVICENAME account:username error:&error];
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


- (void)storeKimaiServerURL:(NSString *)kimaiServerUrl username:(NSString *)username password:(NSString *)password success:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
    
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    [standardUserDefaults setValue:kimaiServerUrl forKey:@"KimaiServerURLKey"];
    
    NSError *error = nil;
    if (([SSKeychain setPassword:password forService:SERVICENAME account:username error:&error] == NO || error != nil) && failureHandler) {
        failureHandler(error);
    } else if (successHandler) {
        successHandler(nil);
    }
    
}



#pragma mark - Kimai


- (void)initKimai {
    
    [self loadCredentialsWithSuccess:^(NSString *username, NSString *password, NSString *kimaiServerURL) {

        self.kimai = [[Kimai alloc] initWithURL:[NSURL URLWithString:kimaiServerURL]];
        self.kimai.delegate = self;

    } failure:^(NSError *error) {

        [self showLoginView];
        
    }];
    
}


- (void)reloadData {
    
    if (self.kimai.isServiceReachable == NO) {
        return;
    }
    
    [self.kimai reloadAllContentWithSuccess:^(id response) {

        [self.tableView reloadData];

    } failure:standardFailureHandler];
    
}


#pragma mark - KimaiDelegate


- (void)reachabilityChanged:(NSNumber *)isServiceReachable {
    
    NSLog(@"Reachability changed to %@", isServiceReachable.boolValue ? @"ONLINE" : @"OFFLINE");
    
    if (isServiceReachable.boolValue) {
        
        if (self.kimai.apiKey == nil) {
            
            [self loadCredentialsWithSuccess:^(NSString *username, NSString *password, NSString *kimaiServerURL) {
                
                [self.kimai authenticateWithUsername:username password:password success:^(id response) {
                    [self reloadData];
                } failure:standardFailureHandler];
                
            } failure:^(NSError *error) {

                [self showLoginView];
                
            }];

        } else {
            [self reloadData];
        }
        
    } else {
        NSLog(@"Offline");
    }
    
}


#pragma mark - Handle Login


- (void)showLoginView {
    if (self.credentialsView.superview == nil) {
        [self.view addSubview:self.credentialsView];
    }
}


- (void)dismissLoginView {
    if (self.credentialsView.superview == self.view) {
        [self.credentialsView removeFromSuperview];
    }
}


- (IBAction)loginClicked:(id)sender {
    
    [self storeKimaiServerURL:self.kimaiServerURLTextField.text username:self.usernameTextField.text password:self.passwordTextField.text success:^(id response) {
        
        [self initKimai];
        [self dismissLoginView];
        
    } failure:^(NSError *error) {
        NSLog(@"%@", error);
    }];
    
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.kimai.projects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    KimaiProject *project = [self.kimai.projects objectAtIndex:indexPath.row];
    cell.textLabel.text = project.name;
    
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    KimaiProject *project = [self.kimai.projects objectAtIndex:indexPath.row];
    TasksViewController *detailViewController = [[TasksViewController alloc] initWithKimai:self.kimai project:project];
    [self.navigationController pushViewController:detailViewController animated:YES];
}

@end

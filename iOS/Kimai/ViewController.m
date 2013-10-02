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
#import "BMCredentials.h"
#import "SVProgressHUD.h"
#import "BMTimeFormatter.h"


@interface ViewController ()

typedef void (^KeychainSuccessHandler)(NSString *username, NSString *password, NSString *kimaiServerURL);
typedef void (^KeychainFailureHandler)(NSError *error);

@end

@implementation ViewController


static NSString *SERVICENAME = @"org.kimai.timetracker";


KimaiFailureHandler standardFailureHandler = ^(NSError *error) {

    [SVProgressHUD dismiss];

    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:error.localizedDescription
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles: nil] show];
};


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Kimai";

    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(reloadData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    
    [self initKimai];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
    [self reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




#pragma mark - Kimai


- (void)initKimai {
    
    [BMCredentials loadCredentialsWithServicename:SERVICENAME success:^(NSString *username, NSString *password, NSString *serviceURL) {
    
        self.kimai = [[Kimai alloc] initWithURL:[NSURL URLWithString:serviceURL]];
        self.kimai.delegate = self;

    } failure:^(NSError *error) {
        
        [self showLoginView];

    }];
    
}


- (void)reloadData {
    
    if (self.kimai.isServiceReachable == NO) {
        return;
    }
    
    [self.refreshControl beginRefreshing];
    [SVProgressHUD showWithStatus:@"Loading ..."];

    [self.kimai reloadAllContentWithSuccess:^(id response) {

        [SVProgressHUD dismiss];
        [self.refreshControl endRefreshing];

        [self.tableView reloadData];

    } failure:standardFailureHandler];
    
}


- (void)stopAllActivities {
    
    [SVProgressHUD showWithStatus:@"Stopping task ..."];
    
    [self.kimai stopAllActivityRecordingsWithSuccess:^(id response) {
        [self reloadData];
    } failure:^(NSError *error) {
        standardFailureHandler(error);
        [self reloadData];
    }];
    
}


#pragma mark - KimaiDelegate


- (void)reachabilityChanged:(NSNumber *)isServiceReachable service:(id)service {
    
    NSString *status = (isServiceReachable.boolValue) ? @"ONLINE" : @"OFFLINE";
    
    //[SVProgressHUD showWithStatus:[NSString stringWithFormat:@"Kimai is %@", status]];

    NSLog(@"Reachability changed to %@", status);
    

    if (isServiceReachable.boolValue) {
        
        if (self.kimai.apiKey == nil) {
            
            [BMCredentials loadCredentialsWithServicename:SERVICENAME success:^(NSString *username, NSString *password, NSString *serviceURL) {
                
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
        self.navigationItem.leftBarButtonItem = nil;
    }
}


- (void)dismissLoginView {
    if (self.credentialsView.superview == self.view) {
        [self.credentialsView removeFromSuperview];
        
        UIBarButtonItem *loginNavigationItem = [[UIBarButtonItem alloc] initWithTitle:@"Settings"
                                                                                style:UIBarButtonItemStyleBordered
                                                                               target:self
                                                                               action:@selector(showLoginView)];
        self.navigationItem.leftBarButtonItem = loginNavigationItem;
        
    }
}


- (IBAction)loginClicked:(id)sender {
    
    [SVProgressHUD showWithStatus:@"Logging in ..."];
    
    [BMCredentials storeServiceURL:self.kimaiServerURLTextField.text username:self.usernameTextField.text password:self.passwordTextField.text servicename:SERVICENAME success:^{

        [self initKimai];
        [self dismissLoginView];

    } failure:^(NSError *error) {
        NSLog(@"%@", error);
        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }];

}

- (NSString *)statusBarTitleWithActivity:(KimaiActiveRecording *)activity {
    NSDate *now = [NSDate date];
    NSString *activityTime = [BMTimeFormatter formatedDurationStringFromDate:activity.startDate toDate:now];
    return [NSString stringWithFormat:@"%@ (%@) %@", activity.projectName, activity.activityName, activityTime];
}


#pragma mark - Table view data source
/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0: return @"Projects";
    }
    return @"";
}
*/
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    int sections = 0;
    
    sections += (self.kimai.activeRecordings != nil && self.kimai.activeRecordings.count > 0);
    sections += (self.kimai.projects != nil && self.kimai.projects.count > 0);
    
    return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    if (section == 0 && self.kimai.activeRecordings != nil && self.kimai.activeRecordings.count > 0) {
        return 1;
    }

    return self.kimai.projects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    if (indexPath.section == 0 && self.kimai.activeRecordings != nil && self.kimai.activeRecordings.count > 0) {
        
        KimaiActiveRecording *record = [self.kimai.activeRecordings objectAtIndex:0];
        cell.textLabel.text = [self statusBarTitleWithActivity:record];
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.imageView.image = [UIImage imageNamed:@"kimai_stop_selected.png"];
        
    } else {
        
        KimaiProject *project = [self.kimai.projects objectAtIndex:indexPath.row];
        cell.textLabel.text = project.name;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.imageView.image = nil;
        
    }
    
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

    if (indexPath.section == 0 && self.kimai.activeRecordings != nil && self.kimai.activeRecordings.count > 0) {
        
        [self stopAllActivities];
        
    } else {
        
        KimaiProject *project = [self.kimai.projects objectAtIndex:indexPath.row];
        TasksViewController *detailViewController = [[TasksViewController alloc] initWithKimai:self.kimai project:project];
        [self.navigationController pushViewController:detailViewController animated:YES];

    }
}

@end

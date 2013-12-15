//
//  AppDelegate.m
//  Kimai
//
//  Created by Vinzenz-Emanuel Weber on 07.11.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

#import "BMCustomer.h"
#import "BMProject.h"
#import "BMRegion.h"
#import "BMTimesheetRecord.h"
#import "BMTimesheetRecordComment.h"
#import "BMUser.h"


@implementation AppDelegate


- (void)initTestDatabase {
    
    NSArray *allCustomers = [BMCustomer findAll];
    if (allCustomers != 0 && allCustomers.count != 0) {
        return;
    }
    
    BMCustomer *customer = [BMCustomer createEntity];
    customer.name = @"Men's Health";
    
    BMProject *project = [BMProject createEntity];
    project.name = @"Personal Trainer I18N";
    project.customer = customer;
    
    BMRegion *region = [BMRegion createEntity];
    region.name = @"blockhaus office";
    region.identifier = @"blockhaus";
    region.latitude = [NSNumber numberWithFloat:48.202644];
    region.longitude = [NSNumber numberWithFloat:16.354472];
    region.radius = [NSNumber numberWithFloat:50];
    [region addProjectsObject:project];

    [[NSManagedObjectContext defaultContext] saveToPersistentStoreAndWait];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"BMTimesheetModel.sqlite"];
    [self initTestDatabase];
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
//    [_locationManager startMonitoringSignificantLocationChanges];

    if ([CLLocationManager isRangingAvailable]) {
        NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"76C7B1E4-7DCB-415B-BB68-89A99CC909F8"];
        [self registerBeaconRegionWithUUID:uuid andIdentifier:@"at.blockhausmedien.home"];
    }
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.viewController = [[ViewController alloc] init];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.viewController];
    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    //[self testCloseTimesheet];
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    //[self testAddTimesheetWithRegionIdentifier:@"blockhaus"];
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[NSManagedObjectContext defaultContext] saveToPersistentStoreAndWait];
}


#pragma mark - CLLocationManagerDelegate


- (void)registerBeaconRegionWithUUID:(NSUUID *)proximityUUID andIdentifier:(NSString*)identifier {
    
    NSLog(@"Register beacone with UUID %@ and identifier %@", proximityUUID, identifier);
    
    // Create the beacon region to be monitored.
    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc]
                                    initWithProximityUUID:proximityUUID
                                    identifier:identifier];
    
    // Register the beacon region with the location manager.
    [self.locationManager startMonitoringForRegion:beaconRegion];
}


- (void)postLocalPushNotificationWithText:(NSString *)text soundName:(NSString *)soundFileName {
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = text;

    if (soundFileName) {
        notification.soundName = soundFileName;
    }

    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}


- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region {
    
    for (CLBeacon *beacon in beacons) {
        switch (beacon.proximity) {
            case CLProximityNear:
                NSLog(@"Beacon is near!");
                break;
            case CLProximityImmediate:
                NSLog(@"Beacon is immediate!");
                break;
            case CLProximityFar:
                NSLog(@"Beacon is far!");
                break;
            case CLProximityUnknown:
                NSLog(@"Beacon proximity unknown!");
                break;
        }
    }

}


- (void)testAddTimesheetWithRegionIdentifier:(NSString *)identifier {

    BMRegion *bmregion = [BMRegion findFirstWithPredicate:[NSPredicate predicateWithFormat:@"identifier = %@", identifier]];
    if (bmregion != nil) {
        
        // find the project connected to this region for auto logging
        BMProject *project = nil;
        if (bmregion.projects != nil && bmregion.projects.count != 0) {
            project = [[bmregion.projects allObjects] firstObject];
        }
        
        BMTimesheetRecord *timesheetRecord = [BMTimesheetRecord createEntity];
        timesheetRecord.startDate = [NSDate date];
        timesheetRecord.project = project;
        
        for (int i = 0; i < 10; i++) {
            BMTimesheetRecordComment *comment = [BMTimesheetRecordComment createEntity];
            comment.text = [NSString stringWithFormat:@"Comment number %i!", i];
            [timesheetRecord addCommentsObject:comment];
        }
        
        [[NSManagedObjectContext defaultContext] saveToPersistentStoreAndWait];
    }

}


- (void)testCloseTimesheet {
    
    BMTimesheetRecord *activeTimesheetRecord = [BMTimesheetRecord findFirstWithPredicate:[NSPredicate predicateWithFormat:@"startDate != NULL && endDate = NULL"]];
    if (activeTimesheetRecord) {
        activeTimesheetRecord.endDate = [NSDate date];
        activeTimesheetRecord.duration = [NSNumber numberWithDouble:[activeTimesheetRecord.endDate timeIntervalSinceDate:activeTimesheetRecord.startDate]];
        [[NSManagedObjectContext defaultContext] saveToPersistentStoreAndWait];
    } else {
        NSLog(@"No active timesheet record found!");
    }
    
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"Did enter monitored region!");
    [self testAddTimesheetWithRegionIdentifier:region.identifier];
    [self postLocalPushNotificationWithText:[NSString stringWithFormat:@"You just arrived at %@!", region.identifier] soundName:@"trololo1.aiff"];

}


- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"Did exit monitored region!");
    [self testCloseTimesheet];
    [self postLocalPushNotificationWithText:[NSString stringWithFormat:@"You just left %@!", region.identifier] soundName:@"trololo1.aiff"];
}

@end

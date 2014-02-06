//
//  AppDelegate.h
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 15.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ServiceManagement/ServiceManagement.h>
#import "StartAtLoginController.h"
#import "KSReachability.h"
#import "Kimai.h"


static NSString *SERVICENAME = @"org.kimai.timetracker";



@interface BMAppDelegate : NSObject <NSApplicationDelegate, NSAlertDelegate, KimaiDelegate> {
    NSStatusItem *statusItem;
    NSWindowController *_preferencesWindowController;
}

@property (strong) Kimai *kimai;
@property (nonatomic, strong) KSReachability* reachability;
@property (strong) NSMutableArray *pastDaysTimesheetRecordsArray;

@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
- (void)saveDatabase;

@property (assign) IBOutlet NSWindow *timeTrackerWindow;
@property (assign) IBOutlet NSWindow *mainMenuWindow;
@property (nonatomic, readonly) NSWindowController *preferencesWindowController;

- (IBAction)pickActivityButtonClicked:(id)sender;
@property (weak) IBOutlet NSButton *pastButton;
@property (weak) IBOutlet NSButton *presentButton;
@property (weak) IBOutlet NSButton *futureButton;
@property (weak) IBOutlet NSTextField *leaveDateDayLabel;
@property (weak) IBOutlet NSTextField *leaveDateTimeLabel;


- (void)initKimai;
- (void)reloadMenu;
- (void)hidePreferences;
- (void)showAlertSheetWithError:(NSError *)error;

@property (weak) IBOutlet NSButton *homeButton;
- (IBAction)homeButtonClicked:(id)sender;
- (IBAction)timeTrackWindowOKClicked:(id)sender;

- (void)launchSupportWebsiteFromPreferences;
- (void)launchSupportWebsiteFromErrorMessage;
- (void)launchSupportWebsiteFromMenu;

@end
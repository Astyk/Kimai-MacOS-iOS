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

@property (assign) IBOutlet NSWindow *mainMenuWindow;
@property (nonatomic, readonly) NSWindowController *preferencesWindowController;


- (void)initKimai;
- (void)reloadMenu;
- (void)hidePreferences;
- (void)showAlertSheetWithError:(NSError *)error;


- (void)launchSupportWebsiteFromPreferences;
- (void)launchSupportWebsiteFromErrorMessage;
- (void)launchSupportWebsiteFromMenu;

@end

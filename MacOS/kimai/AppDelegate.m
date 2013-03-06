//
//  AppDelegate.m
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 15.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "AppDelegate.h"
#import <Sparkle/Sparkle.h>
#import "PFMoveApplication.h"
#import "SSKeychain.h"
#import "KimaiLocationManager.h"
#import "TransparentWindow.h"
#import "BMTimeFormatter.h"
#import "BMCredentials.h"
#import "MASPreferencesWindowController.h"
#import "GeneralPreferencesViewController.h"
#import "AccountPreferencesViewController.h"


@interface AppDelegate () {
    NSTimer *_updateUserInterfaceTimer;
    NSTimer *_reloadDataTimer;
    KimaiLocationManager *locationManager;
    
    NSArray *_timesheetRecordsForLastSevenDays;

}


@property (strong) NSMutableArray *transparentWindowArray;

@end



@implementation AppDelegate




#pragma mark - NSApplicationDelegate


- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    
    [self hidePreferences];
    [self hideTimeTrackerWindow];
    
#ifndef DEBUG
    
    // Offer to the move the Application if necessary.
	// Note that if the user chooses to move the application,
	// this call will never return. Therefore you can suppress
	// any first run UI by putting it after this call.
	PFMoveToApplicationsFolderIfNecessary();

    // check for other instances
    int runningInstances = 0;
    NSString *bundleIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
    NSArray *running = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication *app in running) {
        if ([[app bundleIdentifier] isEqualToString:bundleIdentifier]) {
            runningInstances++;
        }
    }

    if (runningInstances > 1) {
        NSLog(@"An instance of Kimai (%@) is already running!", bundleIdentifier);
        [NSApp terminate:nil];
    }

#endif
	
    
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    // https://github.com/shpakovski/Popup
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setView:statusItemView];
    [statusItem setHighlightMode:YES];
    [statusItem setTitle:@"Loading..."];
    [statusItem setEnabled:NO];

    
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Kimai Menu"];
    [statusItem setMenu:menu];

    [self initScreensaverNotificationObserver];
    
    //locationManager = [KimaiLocationManager sharedManager];

    [self initKimai];    
    [self startReloadDataTimer];

}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    return NSTerminateNow;
}


- (void)applicationWillTerminate:(NSNotification *)notification {
    [self removeScreensaverNotificationObserver];
}


#pragma mark - Screensaver/Sleep Notifications


- (void)initScreensaverNotificationObserver {
   
    
    NSDistributedNotificationCenter *distributedNotificationCenter = [NSDistributedNotificationCenter defaultCenter];
    
    [distributedNotificationCenter addObserver:self
                                      selector:@selector(screensaverStarted:)
                                          name:@"com.apple.screensaver.didstart"
                                        object:nil];
    
    [distributedNotificationCenter addObserver:self
                                      selector:@selector(screensaverStopped:)
                                          name:@"com.apple.screensaver.didstop"
                                        object:nil];
    
    [distributedNotificationCenter addObserver:self
                                      selector:@selector(screenLocked:)
                                          name:@"com.apple.screenIsLocked"
                                        object:nil];
    
    [distributedNotificationCenter addObserver:self
                                      selector:@selector(screenUnlocked:)
                                          name:@"com.apple.screenIsUnlocked"
                                        object:nil];

    
    NSNotificationCenter *workspaceNotificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
    
    [workspaceNotificationCenter addObserver:self
                                    selector:@selector(workspaceWillSleep:)
                                        name:NSWorkspaceWillSleepNotification
                                      object:nil];

    [workspaceNotificationCenter addObserver:self
                                    selector:@selector(workspaceDidWake:)
                                        name:NSWorkspaceDidWakeNotification
                                      object:nil];

}


- (void)removeScreensaverNotificationObserver {
    
    NSDistributedNotificationCenter *notificationCenter = [NSDistributedNotificationCenter defaultCenter];

    [notificationCenter removeObserver:self
                                  name:@"com.apple.screensaver.didstart"
                                object:nil];
    
    [notificationCenter removeObserver:self
                                  name:@"com.apple.screensaver.didstop"
                                object:nil];
    
    [notificationCenter removeObserver:self
                                  name:@"com.apple.screenIsLocked"
                                object:nil];
    
    [notificationCenter removeObserver:self
                                  name:@"com.apple.screenIsUnlocked"
                                object:nil];
    
    NSNotificationCenter *workspaceNotificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
    
    [workspaceNotificationCenter removeObserver:self
                                           name:NSWorkspaceWillSleepNotification
                                         object:nil];

    [workspaceNotificationCenter removeObserver:self
                                           name:NSWorkspaceDidWakeNotification
                                         object:nil];

}


- (void)workspaceWillSleep:(NSNotification *)notification {
    
    NSLog(@"workspaceWillSleep");

    // log date/time when system went to sleep
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSDate date] forKey:@"WorkspaceFellAsleepDateKey"];
    [defaults synchronize];

}


- (void)workspaceDidWake:(NSNotification *)notification {
   
    NSLog(@"workspaceDidWake");
    
    NSDate *workspaceFellAsleepDate = (NSDate *)[[NSUserDefaults standardUserDefaults] valueForKey:@"WorkspaceFellAsleepDateKey"];
    if (workspaceFellAsleepDate != nil) {
        
        NSDate *now = [NSDate date];
        NSTimeInterval workspaceAsleepDuration = [workspaceFellAsleepDate timeIntervalSinceDate:now];
        
        // if the user left his Mac for more than 5 minutes
        // ask what he did during the time
        if (workspaceAsleepDuration > 60 * 5) {
            [self performSelectorOnMainThread:@selector(showTimeTrackerWindowWithLeaveDate:) withObject:workspaceFellAsleepDate waitUntilDone:NO];
        }
    }

}


- (void)screensaverStarted:(NSNotification *)notification {
    
    NSLog(@"screensaverStarted");
    
    // log date/time when screensaver started for later reference
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:[NSDate date] forKey:@"ScreensaverStartedDateKey"];
    [defaults synchronize];
    
}


- (void)screensaverStopped:(NSNotification *)notification {
    
    NSLog(@"screensaverStopped");

    NSDate *screensaverStartedDate = [[NSUserDefaults standardUserDefaults] valueForKey:@"ScreensaverStartedDateKey"];
    if (screensaverStartedDate != nil) {
        
        NSDate *now = [NSDate date];
        NSTimeInterval screensaverActivateDuration = [screensaverStartedDate timeIntervalSinceDate:now];
        
        // if the user left his Mac for more than 5 minutes
        // ask what he did during the time
        if (screensaverActivateDuration > 60 * 5) {
            [self performSelectorOnMainThread:@selector(showTimeTrackerWindowWithLeaveDate:) withObject:screensaverStartedDate waitUntilDone:NO];
        }
    }
    
}


- (void)screenLocked:(NSNotification *)notification {
    NSLog(@"screenLocked");
}


- (void)screenUnlocked:(NSNotification *)notification {
    NSLog(@"screenUnlocked");
}


#pragma mark - Time Tracker Window


- (void)hideTimeTrackerWindow {
    
    if ([self.window isVisible]) {
        [self.window orderOut:self];
    }
    
    for (TransparentWindow *window in self.transparentWindowArray) {
        if ([window isVisible]) {
            [window orderOut:self];
        }
    }
    
    [self.transparentWindowArray removeAllObjects];
    self.transparentWindowArray = nil;
    
}


- (void)_showTimeTrackerWindow {
    [self showTimeTrackerWindowWithLeaveDate:[NSDate dateWithTimeInterval:-60*35 sinceDate:[NSDate date]]];
}


- (void)showTimeTrackerWindowWithLeaveDate:(NSDate *)leaveDate {
    
    NSDate *now = [NSDate date];
    NSString *durationString = [BMTimeFormatter formatedDurationStringFromDate:leaveDate toDate:now];
//    self.window.title = [NSString stringWithFormat:@"You were gone for %@", durationString];
    [self.presentButton setTitle:durationString];

    NSDateFormatter *dayFormat = [[NSDateFormatter alloc] init];
    [dayFormat setDateFormat:@"dd.MM.yyyy"];
    [self.leaveDateDayLabel setStringValue:[dayFormat stringFromDate:leaveDate]];

    NSDateFormatter *timeFormat = [[NSDateFormatter alloc] init];
    [timeFormat setDateFormat:@"HH:mm"];
    [self.leaveDateTimeLabel setStringValue:[timeFormat stringFromDate:leaveDate]];

    
/*
    [self.window setOpaque:NO];
    self.window.backgroundColor = [NSColor colorWithCalibratedWhite:1.0 alpha:0.0];
*/
    
    KimaiActiveRecording *activeRecordingOrNil = nil;
    if (self.kimai.activeRecordings) {
        activeRecordingOrNil = [self.kimai.activeRecordings objectAtIndex:0];
        if (activeRecordingOrNil) {
            NSString *activityTime = [BMTimeFormatter formatedWorkingDuration:0 withCurrentActivity:activeRecordingOrNil];
            self.pastButton.title = [NSString stringWithFormat:@"%@ (%@) %@", activeRecordingOrNil.projectName, activeRecordingOrNil.activityName, activityTime];
        }
    }
    
    
    
	NSArray *screens = [NSScreen screens];
    self.transparentWindowArray = [NSMutableArray arrayWithCapacity:screens.count];
    
	for (int i = 0; i < [screens count]; i++) {
        
		NSScreen *screen = [screens objectAtIndex:i];
        NSValue *screenSizeValue = [[screen deviceDescription] objectForKey:NSDeviceSize];
        CGSize screenSize = screenSizeValue.sizeValue;
        CGRect windowRect = CGRectMake(0, 0, screenSize.width, screenSize.height);
        
        TransparentWindow *transparentWindow = [[TransparentWindow alloc] initWithContentRect:windowRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreRetained defer:NO screen:screen];
        
#ifndef DEBUG
        transparentWindow.level = NSMainMenuWindowLevel + 1;
#endif
        
        if (i == 0) {
            [transparentWindow addChildWindow:self.window ordered:NSWindowAbove];
        } else {
            TransparentWindow *lastTransparentWindow = [self.transparentWindowArray lastObject];
            [lastTransparentWindow addChildWindow:transparentWindow ordered:NSWindowAbove];
        }
        
        [self.transparentWindowArray addObject:transparentWindow];
        [transparentWindow makeKeyAndOrderFront:self];
        transparentWindow.canHide = NO;
	}

    
    [self.window center];
    [self.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];

}


- (IBAction)timeTrackWindowOKClicked:(id)sender {
    [self hideTimeTrackerWindow];
}


- (IBAction)homeButtonClicked:(id)sender {

}

static NSString *PAST_BUTTON_TITLE = @"PAST";
static NSString *PRESENT_BUTTON_TITLE = @"PRESENT";
static NSString *FUTURE_BUTTON_TITLE = @"FUTURE";


- (IBAction)pickActivityButtonClicked:(id)sender {
    
    if (!self.kimai.isServiceReachable || self.kimai.apiKey == nil) {
        NSLog(@"Kimai is not initialized or reachable!");
        return;
    }
    
    
    NSString *menuTitle;
    NSButton *button = (NSButton *)sender;
    if (button == self.pastButton) {
        menuTitle = PAST_BUTTON_TITLE;
    } else if (button == self.presentButton) {
        menuTitle = PRESENT_BUTTON_TITLE;
    } else if (button == self.futureButton) {
        menuTitle = FUTURE_BUTTON_TITLE;
    }
    
    NSMenu *kimaiMenu = [[NSMenu alloc] initWithTitle:menuTitle];

    
    KimaiActiveRecording *activeRecordingOrNil = nil;
    if (self.kimai.activeRecordings) {
        activeRecordingOrNil = [self.kimai.activeRecordings objectAtIndex:0];
    }
    
    // TODAY
    [self addMenuItemTaskHistoryWithMenu:kimaiMenu
                                   title:@"Today"
                        timesheetRecords:self.kimai.timesheetRecordsToday
                         currentActivity:activeRecordingOrNil
                                  action:@selector(pickActivityWithMenuItem:)];
    
    // YESTERDAY
    [self addMenuItemTaskHistoryWithMenu:kimaiMenu
                                   title:@"Yesterday"
                        timesheetRecords:self.kimai.timesheetRecordsYesterday
                         currentActivity:nil
                                  action:@selector(pickActivityWithMenuItem:)];
    
    // TOTAL WORKING HOURS LAST WEEK Mon-Sun
    [self addMenuItemTaskHistoryWithMenu:kimaiMenu
                                   title:@"Last Week"
                        timesheetRecords:_timesheetRecordsForLastSevenDays
                         currentActivity:nil
                                  action:@selector(pickActivityWithMenuItem:)];
    
    // ALL PROJECTS
    NSMenuItem *allProjectsMenuItem = [[NSMenuItem alloc] initWithTitle:@"Projects" action:nil keyEquivalent:@""];
    [allProjectsMenuItem setSubmenu:[self projectsMenuWithAction:@selector(pickActivityWithMenuItem:)]];
    [kimaiMenu addItem:allProjectsMenuItem];
    

    
    // show the menu as a popover
    [kimaiMenu popUpMenuPositioningItem:nil atLocation:button.frame.origin inView:self.window.contentView];

}


- (void)pickActivityWithMenuItem:(id)sender {
    if ([sender isKindOfClass:[NSMenuItem class]]) {
        
        NSMenuItem *menuItem = (NSMenuItem *)sender;
        NSMenu *menu;
        
        KimaiTask *task;
        KimaiProject *project;
        
        if ([menuItem.representedObject isKindOfClass:[KimaiTimesheetRecord class]]) {
            
            menu = menuItem.menu;
            
            KimaiTimesheetRecord *record = menuItem.representedObject;
            record.project = [self.kimai projectWithID:record.projectID];
            record.task = [self.kimai taskWithID:record.activityID];
            project = record.project;
            task = record.task;
            
        } else if ([menuItem.representedObject isKindOfClass:[KimaiTask class]]) {
            
            menu = menuItem.parentItem.parentItem.menu;
            
            task = menuItem.representedObject;
            project = menuItem.parentItem.representedObject;
            
        }
        
        
        NSString *menuTitle = menu.title;
        NSString *taskTitle = [NSString stringWithFormat:@"%@ (%@)", project.name, task.name];
        if ([menuTitle isEqualToString:PAST_BUTTON_TITLE]) {
            [self.pastButton setTitle:taskTitle];
        } else if ([menuTitle isEqualToString:PRESENT_BUTTON_TITLE]) {
            [self.presentButton setTitle:taskTitle];
        } else if ([menuTitle isEqualToString:FUTURE_BUTTON_TITLE]) {
            [self.futureButton setTitle:taskTitle];
        }
        
    }

}


#pragma mark - Alert Sheet


- (void)showAlertSheetWithError:(NSError *)error {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:@"Error"];
    [alert setInformativeText:error.description];
    [alert setAlertStyle:NSWarningAlertStyle];
    [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:nil contextInfo:nil];
}


#pragma mark - Kimai


- (void)initKimai {
    
    [BMCredentials loadCredentialsWithServicename:SERVICENAME success:^(NSString *username, NSString *password, NSString *serviceURL) {
        
        self.kimai = [[Kimai alloc] initWithURL:[NSURL URLWithString:serviceURL]];
        self.kimai.delegate = self;
        
    } failure:^(NSError *error) {
        
        NSLog(@"%@", error);
        [self showPreferences];

    }];
    
}

/*
- (void)_testTimeSheets {
    
    KimaiTimesheetRecord *newRecord = [[KimaiTimesheetRecord alloc] init];
    newRecord.statusID = [NSNumber numberWithInt:1];
    newRecord.project = [self.kimai.projects objectAtIndex:0];
    newRecord.task = [self.kimai.tasks objectAtIndex:0];
    
    // FROM - TODAY 00:00
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSEraCalendarUnit | NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit)
                                          fromDate:[NSDate date]];
    newRecord.startDate = [cal dateFromComponents:components];
    newRecord.startDate = [newRecord.startDate dateByAddingTimeInterval:60*60]; // add one hour
    
    // TO - NOW
    newRecord.endDate = [NSDate date];
    
    
    [self.kimai setTimesheetRecord:newRecord success:^(id response) {
        
        [self.kimai getTimesheetRecordWithID:newRecord.timeEntryID success:^(id response) {
            for (KimaiTimesheetRecord *record in response) {
                NSLog(@"%@", record);
            }
        } failure:^(NSError *error) {
            NSLog(@"%@", error);
        }];
        
    } failure:^(NSError *error) {
        NSLog(@"%@", error);
    }];    

}
*/

- (void)reloadData {
    
    
    if (self.kimai.isServiceReachable == NO) {
        return;
    }
    
    
    [statusItem setTitle:@"Loading..."];
    [statusItem setEnabled:NO];
    
    
    KimaiFailureHandler failureHandler = ^(NSError *error) {
        [self showAlertSheetWithError:error];
        [self reloadMenu];
    };
    
    
    [self.kimai reloadAllContentWithSuccess:^(id response) {
        
#if DEBUG
        //[self.kimai logAllData];
        //[self _testTimeSheets];
#endif
        [self reloadMenu];

        [self reloadMostUsedProjectsAndTasksWithSuccess:^(id response) {
        
            [self reloadMenu];
            
#if DEBUG
            [self _showTimeTrackerWindow];
#endif


        } failure:failureHandler];

    } failure:failureHandler];
    
}



- (void)reloadMostUsedProjectsAndTasksWithSuccess:(KimaiSuccessHandler)successHandler failure:(KimaiFailureHandler)failureHandler {
        
    NSDate *now = [NSDate date];
    NSCalendar *cal = [NSCalendar currentCalendar];
    [cal setFirstWeekday:2]; // 1 == Sunday, 2 == Monday, 7 == Saturday
    
    NSDateComponents *nowComponents = [cal components:(NSYearCalendarUnit | NSWeekOfYearCalendarUnit | NSTimeZoneCalendarUnit) fromDate:now];
    
    NSDateComponents *lastWeekMondayComponents = [[NSDateComponents alloc] init];
    [lastWeekMondayComponents setTimeZone:nowComponents.timeZone];
    [lastWeekMondayComponents setYear:nowComponents.year];
    [lastWeekMondayComponents setWeekOfYear:nowComponents.weekOfYear-1];
    [lastWeekMondayComponents setWeekday:2];
    NSDate *startDate = [cal dateFromComponents:lastWeekMondayComponents];
    
    NSDateComponents *sevenDaysComponents = [[NSDateComponents alloc] init];
    [sevenDaysComponents setDay:+7];    
    NSDate *endDate = [cal dateByAddingComponents:sevenDaysComponents toDate:startDate options:1];

    NSLog(@"%@ - %@", startDate, endDate);
    
    [self.kimai getTimesheetWithStartDate:startDate
                                  endDate:endDate
                                  success:^(id response) {
                                      
                                      _timesheetRecordsForLastSevenDays = (NSArray *)response;
                                      
                                      if (successHandler) {
                                          successHandler(nil);
                                      }
                                      
                                  }
                                  failure:failureHandler];

}



#pragma mark - KimaiDelegate


- (void)reachabilityChanged:(NSNumber *)isServiceReachable {
    
    NSLog(@"Reachability changed to %@", isServiceReachable.boolValue ? @"ONLINE" : @"OFFLINE");
    
    if (isServiceReachable.boolValue) {
        
        if (self.kimai.apiKey == nil) {

            [BMCredentials loadCredentialsWithServicename:SERVICENAME success:^(NSString *username, NSString *password, NSString *serviceURL) {
                
                [self.kimai authenticateWithUsername:username password:password success:^(id response) {
                    [self reloadData];
                } failure:^(NSError *error) {
                    [self showAlertSheetWithError:error];
                    [self reloadMenu];
                }];

            } failure:^(NSError *error) {
                
                NSLog(@"%@", error);
                [self showPreferences];

            }];
                        
        } else {
            [self reloadData];
        }
        
    } else {
        [statusItem setTitle:@"Offline"];
    }
    
}


#pragma mark - KimaiTimesheetRecord Filter


- (NSMutableArray *)groupedTimesheetRecordsByProjectAndActivity:(NSArray *)timesheetRecords maxTimesheetRecords:(int)maxTimesheetRecords {
    
    NSMutableArray *groupedTimesheetRecords = [NSMutableArray array];
    NSMutableArray *mutableTimesheetRecords = [NSMutableArray arrayWithArray:timesheetRecords];
    while (mutableTimesheetRecords.count > 0) {
        
        // search for all records with the same projectID and activityID
        KimaiTimesheetRecord *record = [mutableTimesheetRecords objectAtIndex:0];
        
        NSPredicate *filterTimesheetRecordPredicate = [NSPredicate predicateWithFormat:@"projectID = %@ AND activityID = %@", record.projectID, record.activityID];
        
        NSArray *timesheetRecordsGroupedByProjectAndActivity = [mutableTimesheetRecords filteredArrayUsingPredicate:filterTimesheetRecordPredicate];
        
        // sum all durations
        NSNumber *totalDuration = [timesheetRecordsGroupedByProjectAndActivity valueForKeyPath:@"@sum.duration"];
        
        // filter out all remaining recods
        [mutableTimesheetRecords filterUsingPredicate:[NSCompoundPredicate notPredicateWithSubpredicate:filterTimesheetRecordPredicate]];
        
        // create a new record representing a whole group of records
        // if the duration is larger than 1 minute
        if (totalDuration.intValue > 59) {
            KimaiTimesheetRecord *groupedTimesheetRecord = [[KimaiTimesheetRecord alloc] init];
            groupedTimesheetRecord.projectID = record.projectID;
            groupedTimesheetRecord.projectName = record.projectName;
            groupedTimesheetRecord.activityID = record.activityID;
            groupedTimesheetRecord.activityName = record.activityName;
            groupedTimesheetRecord.duration = totalDuration;
            [groupedTimesheetRecords addObject:groupedTimesheetRecord];
        }
        
    }
    
    // sort the records by duration
    NSSortDescriptor *durationSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"duration" ascending:NO];
    [groupedTimesheetRecords sortUsingDescriptors:[NSArray arrayWithObject:durationSortDescriptor]];
    
    // remove objects to return a limited array
    if (maxTimesheetRecords > 0) {
        while (groupedTimesheetRecords.count > maxTimesheetRecords) {
            [groupedTimesheetRecords removeLastObject];
        }
    }

    return groupedTimesheetRecords;
}



#pragma mark - User Interface


- (NSMenu *)projectsMenuWithAction:(SEL)aSelector {
    
    // TASKS
    NSMenu *tasksMenu = [[NSMenu alloc] initWithTitle:@"Tasks"];
    for (KimaiTask *task in self.kimai.tasks) {
        if ([task.visible boolValue] == YES) {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:task.name action:aSelector keyEquivalent:@""];
            [menuItem setRepresentedObject:task];
            [menuItem setEnabled:YES];
            [tasksMenu addItem:menuItem];
        }
    }
    
    
    // PROJECTS
    NSMenu *projectsMenu = [[NSMenu alloc] initWithTitle:@"Projects"];
    for (KimaiProject *project in self.kimai.projects) {
        if ([project.visible boolValue] == YES) {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:project.name action:nil keyEquivalent:@""];
            [menuItem setRepresentedObject:project];
            [menuItem setEnabled:YES];
            [menuItem setSubmenu:[tasksMenu copy]];
            [projectsMenu addItem:menuItem];
        }
    }
    
    return projectsMenu;
}


- (void)reloadMenu {
    
    
    NSMenu *kimaiMenu = [[NSMenu alloc] initWithTitle:@"Kimai"];
    KimaiActiveRecording *activeRecordingOrNil = nil;
    NSString *title = @"Kimai";
    
    if (self.kimai.activeRecordings) {
        
        // STOP ALL ACTIVE TASKS
        NSMenuItem *stopMenuItem = [[NSMenuItem alloc] initWithTitle:@"Stop" action:@selector(stopAllActivities) keyEquivalent:@""];
        [kimaiMenu addItem:stopMenuItem];
        
        /////////////////////////////////////////////////////////////////////////////////
        [kimaiMenu addItem:[NSMenuItem separatorItem]];

        activeRecordingOrNil = [self.kimai.activeRecordings objectAtIndex:0];
        title = [self statusBarTitleWithActivity:activeRecordingOrNil];

        [self startTimer];
    } else {
        [self stopTimer];
    }
    [statusItem setTitle:title];
    
    
    
    // TODAY
    [self addMenuItemTaskHistoryWithMenu:kimaiMenu
                                   title:@"Today"
                        timesheetRecords:self.kimai.timesheetRecordsToday
                         currentActivity:activeRecordingOrNil
                                  action:@selector(startProjectWithMenuItem:)];


    // YESTERDAY
    [self addMenuItemTaskHistoryWithMenu:kimaiMenu
                                   title:@"Yesterday"
                        timesheetRecords:self.kimai.timesheetRecordsYesterday
                         currentActivity:nil
                                  action:@selector(startProjectWithMenuItem:)];
    
    
    // TOTAL WORKING HOURS LAST WEEK Mon-Sun
    [self addMenuItemTaskHistoryWithMenu:kimaiMenu
                                   title:@"Last Week"
                        timesheetRecords:_timesheetRecordsForLastSevenDays
                         currentActivity:nil
                                  action:@selector(startProjectWithMenuItem:)];


    // ALL PROJECTS
    NSMenuItem *allProjectsMenuItem = [[NSMenuItem alloc] initWithTitle:@"Projects" action:nil keyEquivalent:@""];
    [allProjectsMenuItem setSubmenu:[self projectsMenuWithAction:@selector(startProjectWithMenuItem:)]];
    [kimaiMenu addItem:allProjectsMenuItem];
    
    
    /////////////////////////////////////////////////////////////////////////////////
    [kimaiMenu addItem:[NSMenuItem separatorItem]];
    

    // RELOAD DATA
    NSMenuItem *reloadMenuItem = [[NSMenuItem alloc] initWithTitle:@"Reload Projects / Tasks" action:@selector(reloadData) keyEquivalent:@""];
    [reloadMenuItem setEnabled:self.kimai.apiKey != nil];
    [kimaiMenu addItem:reloadMenuItem];
    
    
    // OPEN WEBSITE
    if (self.kimai.url != nil) {
        NSMenuItem *launchWebsiteMenuItem = [[NSMenuItem alloc] initWithTitle:@"Launch Kimai Website" action:@selector(launchKimaiWebsite) keyEquivalent:@""];
        [kimaiMenu addItem:launchWebsiteMenuItem];
    }

    
    /////////////////////////////////////////////////////////////////////////////////
    [kimaiMenu addItem:[NSMenuItem separatorItem]];

    
    // SOFTWARE UPDATE
    NSMenuItem *checkUpdatesMenuItem = [[NSMenuItem alloc] initWithTitle:@"Software Update..." action:@selector(checkForUpdates:) keyEquivalent:@""];
    [checkUpdatesMenuItem setTarget:[SUUpdater sharedUpdater]];
    [kimaiMenu addItem:checkUpdatesMenuItem];

    
    // PREFERENCES
    NSMenuItem *preferencesMenuItem = [[NSMenuItem alloc] initWithTitle:@"Preferences..." action:@selector(showPreferences) keyEquivalent:@""];
    [kimaiMenu addItem:preferencesMenuItem];
    
    
    /////////////////////////////////////////////////////////////////////////////////
    [kimaiMenu addItem:[NSMenuItem separatorItem]];

#if DEBUG
    // SHOW TIME TRACKER WINDOW
    NSMenuItem *timetrackerMenuItem = [[NSMenuItem alloc] initWithTitle:@"Timetracker Window..." action:@selector(_showTimeTrackerWindow) keyEquivalent:@""];
    [kimaiMenu addItem:timetrackerMenuItem];
#endif
    
    // QUIT
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit Kimai" action:@selector(quitApplication) keyEquivalent:@""];
    [kimaiMenu addItem:quitMenuItem];
    
    
    [statusItem setMenu:kimaiMenu];
    [statusItem setEnabled:YES];
    
}


- (void)addMenuItemTaskHistoryWithMenu:(NSMenu *)menu title:(NSString *)title timesheetRecords:(NSArray *)timesheetRecords currentActivity:(KimaiActiveRecording *)activity action:(SEL)aSelector {
    
    if (timesheetRecords == nil) {
        return;
    }
    
    
    // recalculate total working duration
    NSNumber *totalWorkingHours = (timesheetRecords.count == 0) ? 0 :[timesheetRecords valueForKeyPath:@"@sum.duration"];
    NSString *totalWorkingHoursString = [BMTimeFormatter formatedWorkingDuration:totalWorkingHours.doubleValue withCurrentActivity:activity];
    
    NSMenuItem *titleMenuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"%@ %@", title, totalWorkingHoursString] action:nil keyEquivalent:@""];
    [titleMenuItem setEnabled:NO];
    [menu addItem:titleMenuItem];
    
    
    if (timesheetRecords.count != 0) {
        
        NSMutableArray *groupedTimesheetRecords = [self groupedTimesheetRecordsByProjectAndActivity:timesheetRecords maxTimesheetRecords:7];
        
        for (KimaiTimesheetRecord *record in groupedTimesheetRecords) {
            
            NSString *activityTime = [BMTimeFormatter formatedDurationStringFromTimeInterval:record.duration.doubleValue];
            NSString *title = [NSString stringWithFormat:@"%@ (%@) %@", record.projectName, record.activityName, activityTime];
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title action:aSelector keyEquivalent:@""];
            [menuItem setRepresentedObject:record];
            [menuItem setEnabled:YES];
            [menu addItem:menuItem];
            
        }
        
    }

    
    /////////////////////////////////////////////////////////////////////////////////
    [menu addItem:[NSMenuItem separatorItem]];
    
}


- (void)launchKimaiWebsite {
    [[NSWorkspace sharedWorkspace] openURL:self.kimai.url];
}


- (NSString *)statusBarTitleWithActivity:(KimaiActiveRecording *)activity {
    NSDate *now = [NSDate date];
    NSString *activityTime = [BMTimeFormatter formatedDurationStringFromDate:activity.startDate toDate:now];
    return [NSString stringWithFormat:@"%@ (%@) %@", activity.projectName, activity.activityName, activityTime];
}


- (void)startProjectWithMenuItem:(id)sender {
    if ([sender isKindOfClass:[NSMenuItem class]]) {
        
        NSMenuItem *menuItem = (NSMenuItem *)sender;

        KimaiTask *task;
        KimaiProject *project;

        if ([menuItem.representedObject isKindOfClass:[KimaiTimesheetRecord class]]) {
            
            KimaiTimesheetRecord *record = menuItem.representedObject;
            record.project = [self.kimai projectWithID:record.projectID];
            record.task = [self.kimai taskWithID:record.activityID];
            project = record.project;
            task = record.task;
            
        } else if ([menuItem.representedObject isKindOfClass:[KimaiTask class]]) {
            
            task = menuItem.representedObject;
            project = menuItem.parentItem.representedObject;
            
        }
        
        [self.kimai startProject:project withTask:task success:^(id response) {
            [self reloadData];
        } failure:^(NSError *error) {
            [self showAlertSheetWithError:error];
            [self reloadData];
        }];
        
    }
}


- (void)stopAllActivities {
    
    [self.kimai stopAllActivityRecordingsWithSuccess:^(id response) {
        [self reloadData];
    } failure:^(NSError *error) {
        [self showAlertSheetWithError:error];
        [self reloadData];
    }];
    
}


- (void)quitApplication {
    [NSApp terminate:self];
}



#pragma mark - Preferences

- (NSWindowController *)preferencesWindowController
{
    if (_preferencesWindowController == nil)
    {
        NSViewController *generalViewController = [[GeneralPreferencesViewController alloc] init];
        NSViewController *advancedViewController = [[AccountPreferencesViewController alloc] init];
        NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, advancedViewController, nil];
        
        // To add a flexible space between General and Advanced preference panes insert [NSNull null]:
        //     NSArray *controllers = [[NSArray alloc] initWithObjects:generalViewController, [NSNull null], advancedViewController, nil];
                
        NSString *title = NSLocalizedString(@"Preferences", @"Common title for Preferences window");
        _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:controllers title:title];
    }
    return _preferencesWindowController;
}


- (void)hidePreferences {
    
    [self.preferencesWindowController close];
/*
    if ([self.window isVisible]) {
        [self.window orderOut:self];
    }
 */
}


- (void)showPreferences {
    
    [self.preferencesWindowController showWindow:nil];

    /*
    [self.window center];
    [self.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
     */
}



#pragma mark - NSTimer


- (void)startReloadDataTimer {
    
    _reloadDataTimer = [NSTimer scheduledTimerWithTimeInterval:60*60*30 // 30 minutes
                                                        target:self
                                                      selector:@selector(reloadData)
                                                      userInfo:nil
                                                       repeats:YES];
    
    [[NSRunLoop mainRunLoop] addTimer:_reloadDataTimer forMode:NSRunLoopCommonModes];
}


- (void)startTimer {
    
    if (_updateUserInterfaceTimer != nil) {
        return;
    }
    
    [self timerUpdate];
    
    _updateUserInterfaceTimer = [NSTimer scheduledTimerWithTimeInterval:20.0
                                                      target:self
                                                    selector:@selector(timerUpdate)
                                                    userInfo:nil
                                                     repeats:YES];
    
    // enable UI updates also when scrollview is scrolling
    [[NSRunLoop mainRunLoop] addTimer:_updateUserInterfaceTimer forMode:NSRunLoopCommonModes];
    
}


- (void)stopTimer {
    [_updateUserInterfaceTimer invalidate];
    _updateUserInterfaceTimer = nil;
}


- (void)updateTime {
    
    if (self.kimai.activeRecordings.count == 0) {
        return;
    }
    
    KimaiActiveRecording *activity = [self.kimai.activeRecordings objectAtIndex:0];
    [statusItem setTitle:[self statusBarTitleWithActivity:activity]];

}


- (void)timerUpdate {
    [self performSelectorOnMainThread:@selector(updateTime) withObject:nil waitUntilDone:NO];
}


@end
    
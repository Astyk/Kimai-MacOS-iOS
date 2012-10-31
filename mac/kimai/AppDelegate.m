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
#import "RHKeychain.h"
#import "KimaiLocationManager.h"

@interface AppDelegate () {
    NSTimer *_updateUserInterfaceTimer;
    NSTimer *_reloadDataTimer;
    KimaiLocationManager *locationManager;
    NSDate *_screensaverStartedDate;
    NSTimeInterval _totalWorkingDurationToday;
}
@end



@implementation AppDelegate

static NSString *SERVICENAME = @"org.kimai.timetracker";


#pragma mark - NSApplicationDelegate


- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
	// Offer to the move the Application if necessary.
	// Note that if the user chooses to move the application,
	// this call will never return. Therefore you can suppress
	// any first run UI by putting it after this call.
	
    [self hidePreferences];

#ifndef DEBUG
	PFMoveToApplicationsFolderIfNecessary();
#endif
    
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
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


#pragma mark - Screensaver Notifications


- (void)initScreensaverNotificationObserver {
   
    NSDistributedNotificationCenter *notificationCenter = [NSDistributedNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector(screensaverStarted:)
                               name:@"com.apple.screensaver.didstart"
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(screensaverStopped:)
                               name:@"com.apple.screensaver.didstop"
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(screenLocked:)
                               name:@"com.apple.screenIsLocked"
                             object:nil];

    [notificationCenter addObserver:self
                           selector:@selector(screenUnlocked:)
                               name:@"com.apple.screenIsUnlocked"
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

}


- (void)screensaverStarted:(NSNotification *)notification {
    NSLog(@"screensaverStarted");
    
    // log date/time when screensaver started for later reference
    _screensaverStartedDate = [NSDate date];
}


- (void)screensaverStopped:(NSNotification *)notification {
    NSLog(@"screensaverStopped");
    
    if (_screensaverStartedDate != nil) {
        
        NSDate *now = [NSDate date];
        NSTimeInterval screensaverActivateDuration = [_screensaverStartedDate timeIntervalSinceDate:now];
        
        // if the user left his Mac for more than 10 minutes
        // ask what he did during the time
        if (screensaverActivateDuration > 60 * 10) {
             
        }
    }
    
}


- (void)screenLocked:(NSNotification *)notification {
    NSLog(@"screenLocked");
}


- (void)screenUnlocked:(NSNotification *)notification {
    NSLog(@"screenUnlocked");
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
    
    if (RHKeychainDoesGenericEntryExist(NULL, SERVICENAME)) {
        
#if DEBUG
        NSString *kimaiServerURL = @"http://localhost/kimai";
        NSString *username = @"testuser";
        NSString *password = @"test123";
#else
        NSString *kimaiServerURL = RHKeychainGetGenericComment(NULL, SERVICENAME);
        NSString *username = RHKeychainGetGenericUsername(NULL, SERVICENAME);
        NSString *password = RHKeychainGetGenericPassword(NULL, SERVICENAME);
#endif

        // init Kimai
        [self.kimaiURLTextField setStringValue:kimaiServerURL];
        [self.usernameTextField setStringValue:username];
        [self.passwordTextField setStringValue:password];
        
        self.kimai = [[Kimai alloc] initWithURL:[NSURL URLWithString:kimaiServerURL]];
        self.kimai.delegate = self;
        
    } else {
        [self showPreferences];
    }
    
}


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


-(void)recalculateTotalWorkingDurationToday {
    _totalWorkingDurationToday = 0;
    for (KimaiTimesheetRecord *record in self.kimai.timesheetRecords) {
        _totalWorkingDurationToday += record.duration.doubleValue;
    }
}


- (void)reloadData {
    
    
    if (self.kimai.isServiceReachable == NO) {
        return;
    }
    
    
    [statusItem setTitle:@"Loading..."];
    [statusItem setEnabled:NO];
    
    
    [self.kimai reloadAllContentWithSuccess:^(id response) {
        
#if DEBUG
        //[self.kimai logAllData];
        //[self _testTimeSheets];
#endif
        [self recalculateTotalWorkingDurationToday];
        [self reloadMenu];
        
    } failure:^(NSError *error) {
        [self showAlertSheetWithError:error];
        [self reloadMenu];
    }];
    
}


#pragma mark - KimaiDelegate


- (void)reachabilityChanged:(NSNumber *)isServiceReachable {
    
    NSLog(@"Reachability changed to %@", isServiceReachable.boolValue ? @"ONLINE" : @"OFFLINE");
    
    if (isServiceReachable.boolValue) {
        
        if (self.kimai.apiKey == nil) {
            
            if (RHKeychainDoesGenericEntryExist(NULL, SERVICENAME)) {
                
                
#if DEBUG
                NSString *username = @"testuser";
                NSString *password = @"test123";
#else
                NSString *username = RHKeychainGetGenericUsername(NULL, SERVICENAME);
                NSString *password = RHKeychainGetGenericPassword(NULL, SERVICENAME);
#endif
                
                
                [self.kimai authenticateWithUsername:username password:password success:^(id response) {
                    [self reloadData];
                } failure:^(NSError *error) {
                    [self showAlertSheetWithError:error];
                    [self reloadMenu];
                }];
                
            } else {
                [self showPreferences];
            }
            
        } else {
            [self reloadData];
        }
        
    } else {
        [statusItem setTitle:@"Offline"];
    }
    
}


#pragma mark - User Interface


- (void)reloadMenu {
    
    NSMenu *kimaiMenu = [[NSMenu alloc] initWithTitle:@"Kimai"];
    
    NSString *totalWorkingHoursToday = @"0m";
    
    NSString *title = @"Kimai";
    if (self.kimai.activeRecordings) {
        
        // STOP ALL ACTIVE TASKS
        NSMenuItem *stopMenuItem = [[NSMenuItem alloc] initWithTitle:@"Stop" action:@selector(stopAllActivities) keyEquivalent:@""];
        [kimaiMenu addItem:stopMenuItem];
        
        // SEPERATOR
        [kimaiMenu addItem:[NSMenuItem separatorItem]];

        KimaiActiveRecording *activeRecording = [self.kimai.activeRecordings objectAtIndex:0];
        title = [self statusBarTitleWithActivity:activeRecording];
        totalWorkingHoursToday = [self totalWorkingDurationTodayWithCurrentActivity:activeRecording];

        [self startTimer];
    } else {
        [self stopTimer];
    }
    [statusItem setTitle:title];
    
    
    
    // TASKS
    NSMenu *tasksMenu = [[NSMenu alloc] initWithTitle:@"Tasks"];
    for (KimaiTask *task in self.kimai.tasks) {
        if ([task.visible boolValue] == YES) {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:task.name action:@selector(clickedMenuItem:) keyEquivalent:@""];
            [menuItem setRepresentedObject:task];
            [menuItem setEnabled:YES];
            [tasksMenu addItem:menuItem];
        }
    }
    
    
    // PROJECTS
    for (KimaiProject *project in self.kimai.projects) {
        if ([project.visible boolValue] == YES) {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:project.name action:nil keyEquivalent:@""];
            [menuItem setRepresentedObject:project];
            [menuItem setEnabled:YES];
            [menuItem setSubmenu:[tasksMenu copy]];
            [kimaiMenu addItem:menuItem];
        }
    }
    
    
    // SEPERATOR
    [kimaiMenu addItem:[NSMenuItem separatorItem]];

    
    // TOTAL WORKING HOURS TODAY
    NSMenuItem *totalWorkingHoursMenuItem = [[NSMenuItem alloc] initWithTitle:[NSString stringWithFormat:@"Today %@", totalWorkingHoursToday] action:nil keyEquivalent:@""];
    [totalWorkingHoursMenuItem setEnabled:NO];
    [kimaiMenu addItem:totalWorkingHoursMenuItem];

    
    // TODAY TASK HISTORY
    if (self.kimai.timesheetRecords) {
        
        NSSortDescriptor *startDateSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:NO];
        NSArray *sortedTimesheetRecords = [self.kimai.timesheetRecords sortedArrayUsingDescriptors:[NSArray arrayWithObject:startDateSortDescriptor]];
        
        for (KimaiTimesheetRecord *record in sortedTimesheetRecords) {

            // is endDate AFTER startDate
            if ([record.endDate compare:record.startDate] == NSOrderedDescending) {
                NSString *activityTime = [self formattedDurationStringFromDate:record.startDate toDate:record.endDate];
                NSString *title = [NSString stringWithFormat:@"%@ - %@ - %@", record.projectName, record.activityName, activityTime];
                NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title action:nil keyEquivalent:@""];
                //[menuItem setRepresentedObject:project];
                [menuItem setEnabled:NO];
                //[menuItem setSubmenu:[tasksMenu copy]];
                [kimaiMenu addItem:menuItem];
            }
            
        }

        // SEPERATOR
        [kimaiMenu addItem:[NSMenuItem separatorItem]];
    }

    
    // RELOAD DATA
    NSMenuItem *reloadMenuItem = [[NSMenuItem alloc] initWithTitle:@"Reload Projects / Tasks" action:@selector(reloadData) keyEquivalent:@""];
    [reloadMenuItem setEnabled:self.kimai.apiKey != nil];
    [kimaiMenu addItem:reloadMenuItem];
    
    
    // OPEN WEBSITE
    if (self.kimai.url != nil) {
        NSMenuItem *launchWebsiteMenuItem = [[NSMenuItem alloc] initWithTitle:@"Launch Kimai Website" action:@selector(launchKimaiWebsite) keyEquivalent:@""];
        [kimaiMenu addItem:launchWebsiteMenuItem];
    }

    
    // SEPERATOR
    [kimaiMenu addItem:[NSMenuItem separatorItem]];

    
    // SOFTWARE UPDATE
    NSMenuItem *checkUpdatesMenuItem = [[NSMenuItem alloc] initWithTitle:@"Software Update..." action:@selector(checkForUpdates:) keyEquivalent:@""];
    [checkUpdatesMenuItem setTarget:[SUUpdater sharedUpdater]];
    [kimaiMenu addItem:checkUpdatesMenuItem];

    
    // PREFERENCES
    NSMenuItem *preferencesMenuItem = [[NSMenuItem alloc] initWithTitle:@"Preferences..." action:@selector(showPreferences) keyEquivalent:@""];
    [kimaiMenu addItem:preferencesMenuItem];
    
    
    // SEPERATOR
    [kimaiMenu addItem:[NSMenuItem separatorItem]];

    
    // QUIT
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit Kimai" action:@selector(quitApplication) keyEquivalent:@""];
    [kimaiMenu addItem:quitMenuItem];
    
    
    [statusItem setMenu:kimaiMenu];
    [statusItem setEnabled:YES];
    
}


- (void)launchKimaiWebsite {
    [[NSWorkspace sharedWorkspace] openURL:self.kimai.url];
}


- (IBAction)storePreferences:(id)sender {
    
    if (self.window.isVisible) {
        
        NSString *kimaiServerURL = [self.kimaiURLTextField stringValue];
        NSString *username = [self.usernameTextField stringValue];
        NSString *password = [self.passwordTextField stringValue];
        
        if (kimaiServerURL.length == 0 ||
            username.length == 0 ||
            password.length == 0) {
            return;
        }
        
        
        if (RHKeychainDoesGenericEntryExist(NULL, SERVICENAME) == NO) {
            RHKeychainAddGenericEntry(NULL, SERVICENAME);
        }
        
#ifndef DEBUG
        if (RHKeychainSetGenericUsername(NULL, SERVICENAME, username) &&
            RHKeychainSetGenericPassword(NULL, SERVICENAME, password) &&
            RHKeychainSetGenericComment(NULL, SERVICENAME, kimaiServerURL)) {
            [self hidePreferences];
            [self initKimai];
        }
#endif
        
    }
    
}


- (NSString *)formattedDurationStringFromDate:(NSDate *)fromDate toDate:(NSDate *)toDate {
    
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit
                                                                       fromDate:fromDate
                                                                         toDate:toDate
                                                                        options:0];
    NSInteger hours = [dateComponents hour];
    NSInteger minutes = [dateComponents minute];
    // NSInteger seconds = [dateComponents second];
    
    NSString *formattedTime = [NSString stringWithFormat:@"%lih %lim", hours, minutes];
    if (hours == 0) {
        formattedTime = [NSString stringWithFormat:@"%lim", minutes];
    }
    
    return formattedTime;
}


- (NSString *)totalWorkingDurationTodayWithCurrentActivity:(KimaiActiveRecording *)activity {
    
    NSDate *now = [NSDate date];
    NSTimeInterval activityDuration = [now timeIntervalSinceDate:activity.startDate];
    NSTimeInterval totalWorkingDurationToday = _totalWorkingDurationToday + activityDuration;
    NSDate *nowPlusDuration = [NSDate dateWithTimeInterval:totalWorkingDurationToday sinceDate:now];
    NSString *totalWorkingHoursToday = [self formattedDurationStringFromDate:now toDate:nowPlusDuration];

    return totalWorkingHoursToday;
}


- (NSString *)statusBarTitleWithActivity:(KimaiActiveRecording *)activity {

    NSDate *now = [NSDate date];
    NSString *activityTime = [self formattedDurationStringFromDate:activity.startDate toDate:now];
    //NSString *totalWorkingHoursToday = [self totalWorkingDurationTodayWithActivity:activity];

//    return [NSString stringWithFormat:@"%@ - %@ - %@ / %@", activity.projectName, activity.activityName, activityTime, totalWorkingHoursToday];
    return [NSString stringWithFormat:@"%@ - %@ - %@", activity.projectName, activity.activityName, activityTime];

}


- (void)clickedMenuItem:(id)sender {
    if ([sender isKindOfClass:[NSMenuItem class]]) {
        
        NSMenuItem *menuItem = (NSMenuItem *)sender;
        KimaiTask *task = menuItem.representedObject;
        KimaiProject *project = menuItem.parentItem.representedObject;
        
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


#pragma mark - NSWindow


- (void)hidePreferences {
    if ([self.window isVisible]) {
        [self.window orderOut:self];
    }
}


- (void)showPreferences {
    [self.window center];
    [self.window makeKeyAndOrderFront:self];
    [NSApp activateIgnoringOtherApps:YES];
}


#pragma mark - NSTimer


- (void)startReloadDataTimer {
    
    _reloadDataTimer = [NSTimer scheduledTimerWithTimeInterval:60*60*30 // 30 minutes
                                                        target:self
                                                      selector:@selector(reloadData)
                                                      userInfo:nil
                                                       repeats:YES];

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


- (NSString *)formatTimeComponent:(NSInteger)timeComponent {
    if (timeComponent < 10) {
        return [NSString stringWithFormat:@"0%li", timeComponent];
    }
    return [NSString stringWithFormat:@"%li", timeComponent];
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
    
//
//  AppDelegate.m
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 15.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "AppDelegate.h"
#import "PFMoveApplication.h"
#import "RHKeychain.h"
#import "KimaiLocationManager.h"

@interface AppDelegate () {
    NSTimer *_trainingTimer;
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
    [statusItem setTitle:@"Kimai"];

    
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Kimai Menu"];
    [statusItem setMenu:menu];

    [self initScreensaverNotificationObserver];
    
    //locationManager = [KimaiLocationManager sharedManager];

    [self initKimai];
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


- (NSString *)totalWorkingHoursTodayByAddingTimeInterval:(NSTimeInterval)additionalTimeInterval {
    
    NSTimeInterval totalWorkingDurationToday = _totalWorkingDurationToday + additionalTimeInterval;
    
    NSDate *now = [NSDate date];
    NSDate *nowPlusDuration = [NSDate dateWithTimeInterval:totalWorkingDurationToday sinceDate:now];
    
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSHourCalendarUnit | NSMinuteCalendarUnit
                                                                       fromDate:now
                                                                         toDate:nowPlusDuration
                                                                        options:0];
    NSInteger hours = [dateComponents hour];
    NSInteger minutes = [dateComponents minute];
    
    NSString *time = [NSString stringWithFormat:@"%lih %lim", hours, minutes];
    if (hours == 0) {
        time = [NSString stringWithFormat:@"%lim", minutes];
    }

    return time;
}


-(void)recalculateTotalWorkingDurationToday {
    _totalWorkingDurationToday = 0;
    for (KimaiTimesheetRecord *record in self.kimai.timesheetRecords) {
        _totalWorkingDurationToday += record.duration.doubleValue;
    }
}


- (void)reloadData {
    
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


- (NSString *)statusBarTitleWithActivity:(KimaiActiveRecording *)activity {
    
    NSDate *now = [NSDate date];
    
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit
                                                                       fromDate:activity.startDate
                                                                         toDate:now
                                                                        options:0];
    
    NSInteger hours = [dateComponents hour];
    NSInteger minutes = [dateComponents minute];
   // NSInteger seconds = [dateComponents second];
    
    NSString *activityTime = [NSString stringWithFormat:@"%lih %lim", hours, minutes];
    if (hours == 0) {
        activityTime = [NSString stringWithFormat:@"%lim", minutes];
    }
    
    // total working hours today
    NSTimeInterval activityDuration = [now timeIntervalSinceDate:activity.startDate];
    NSString *totalWorkingHoursToday = [self totalWorkingHoursTodayByAddingTimeInterval:activityDuration];
    
    return [NSString stringWithFormat:@"%@ - %@ - %@ / %@", activity.projectName, activity.activityName, activityTime, totalWorkingHoursToday];
}


- (void)reloadMenu {

    NSMenu *kimaiMenu = [[NSMenu alloc] initWithTitle:@"Kimai"];

    
    NSString *title = @"Kimai";
    if (self.kimai.activeRecordings) {
        
        NSMenuItem *stopMenuItem = [[NSMenuItem alloc] initWithTitle:@"Stop" action:@selector(stopAllActivities) keyEquivalent:@""];
        [kimaiMenu addItem:stopMenuItem];
        [kimaiMenu addItem:[NSMenuItem separatorItem]];

        KimaiActiveRecording *activeRecording = [self.kimai.activeRecordings objectAtIndex:0];
        title = [self statusBarTitleWithActivity:activeRecording];
        
        [self startTimer];
    } else {
        [self stopTimer];
    }
    [statusItem setTitle:title];
    
    
    
    NSMenu *tasksMenu = [[NSMenu alloc] initWithTitle:@"Tasks"];
    for (KimaiTask *task in self.kimai.tasks) {
        if ([task.visible boolValue] == YES) {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:task.name action:@selector(clickedMenuItem:) keyEquivalent:@""];
            [menuItem setRepresentedObject:task];
            [menuItem setEnabled:YES];
            [tasksMenu addItem:menuItem];
        }
    }
    

    
    for (KimaiProject *project in self.kimai.projects) {
        if ([project.visible boolValue] == YES) {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:project.name action:nil keyEquivalent:@""];
            [menuItem setRepresentedObject:project];
            [menuItem setEnabled:YES];
            [menuItem setSubmenu:[tasksMenu copy]];
            [kimaiMenu addItem:menuItem];
        }
    }


    [kimaiMenu addItem:[NSMenuItem separatorItem]];

    NSMenuItem *preferencesMenuItem = [[NSMenuItem alloc] initWithTitle:@"Preferences..." action:@selector(showPreferences) keyEquivalent:@""];
    [kimaiMenu addItem:preferencesMenuItem];

    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:@"Quit Kimai" action:@selector(quitApplication) keyEquivalent:@""];
    [kimaiMenu addItem:quitMenuItem];
    
    
    [statusItem setMenu:kimaiMenu];

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


- (void)startTimer {
    
    if (_trainingTimer != nil) {
        return;
    }
    
    [self timerUpdate];
    
    _trainingTimer = [NSTimer scheduledTimerWithTimeInterval:20.0
                                                      target:self
                                                    selector:@selector(timerUpdate)
                                                    userInfo:nil
                                                     repeats:YES];
    
    // enable UI updates also when scrollview is scrolling
    //[[NSRunLoop mainRunLoop] addTimer:_trainingTimer forMode:NSRunLoopCommonModes];
    
}


- (void)stopTimer {
    [_trainingTimer invalidate];
    _trainingTimer = nil;
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

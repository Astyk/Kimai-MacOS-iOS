//
//  AppDelegate.m
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 15.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "BMAppDelegate.h"
#import "SSKeychain.h"
#import "BMTimeFormatter.h"
#import "BMCredentials.h"
#import "MASPreferencesWindowController.h"
#import "GeneralPreferencesViewController.h"
#import "AccountPreferencesViewController.h"
#import <Carbon/Carbon.h>


@interface BMAppDelegate () {

    NSTimer *_updateUserInterfaceTimer;
    NSTimer *_reloadDataTimer;
    
    NSArray *_timesheetRecordsForLastSevenDays;

}


@property (strong) NSMutableArray *transparentWindowArray;

@end



@implementation BMAppDelegate



#pragma mark - NSApplicationDelegate


- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    
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

    
    [self hidePreferences];
    
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    // https://github.com/shpakovski/Popup
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setHighlightMode:YES];
    [statusItem setTitle:NSLocalizedString(@"Loading...", @"Displayed in the Menu Bar. Indicating that data is currently being loaded from the server")];
//    [statusItem setEnabled:NO];
    
    NSMenu *menu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Kimai Menu", @"The name of the menu")];
    [statusItem setMenu:menu];


    [self initKimai];
    [self startReloadDataTimer];
    
}


#pragma mark - Alert Sheet

- (void)showUserNotificationWithTitle:(NSString *)title text:(NSString *)text {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = title;
    notification.informativeText = text;
    notification.soundName = NSUserNotificationDefaultSoundName;
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
}


- (void)showAlertSheetWithError:(NSError *)error {

    //[self showUserNotificationWithTitle:@"Error" text:error.description];
    
    [self showPreferences];
    
    NSString *localizedDescription = nil;
    if (error.userInfo) {
        localizedDescription = [error.userInfo objectForKey:@"NSLocalizedDescriptionKey"];
    }

    NSAlert *alert = [NSAlert alertWithMessageText:NSLocalizedString(@"Error", @"Alert dialog title")
                                     defaultButton:NSLocalizedString(@"OK", @"Alert dialog OK button title")
                                   alternateButton:nil
                                       otherButton:nil
                         informativeTextWithFormat:@"%@", localizedDescription ? localizedDescription : error.localizedDescription];
    alert.delegate = self;
    alert.showsHelp = YES;
    alert.alertStyle = NSWarningAlertStyle;
    
    [alert beginSheetModalForWindow:self.preferencesWindowController.window
                      modalDelegate:self
                     didEndSelector:nil
                        contextInfo:nil];
    
}


- (BOOL)alertShowHelp:(NSAlert *)alert {
    [self launchSupportWebsiteFromErrorMessage];
    return YES;
}



#pragma mark - Kimai


- (void)initKimai {
    
    [BMCredentials loadCredentialsWithServicename:SERVICENAME success:^(NSString *username, NSString *password, NSString *serviceURL) {
        
        self.kimai = [[Kimai alloc] initWithURL:[NSURL URLWithString:serviceURL]];
        self.kimai.delegate = self;
        
    } failure:^(NSError *error) {
        
        NSLog(@"%@", error);
        [self showPreferences];
        [self reloadMenu];

    }];
    
}


- (void)reloadData {
    
    
    if (self.kimai.isServiceReachable == NO) {
        return;
    }
    
        
    
    [statusItem setTitle:NSLocalizedString(@"Loading...", nil)];
    [statusItem setEnabled:NO];
    
    
    KimaiFailureHandler failureHandler = ^(NSError *error) {
        [self showAlertSheetWithError:error];
        [self reloadMenu];
    };
    
    
    [self.kimai reloadAllContentWithSuccess:^(id response) {
        
        [self reloadMenu];

        [self reloadMostUsedProjectsAndTasksWithSuccess:^(id response) {
        
            [self reloadMenu];
            
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

- (void)reachabilityChanged:(NSNumber *)isServiceReachable service:(id)service {
    
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
        [statusItem setTitle:NSLocalizedString(@"Offline", @"The app is currently offline and can not reach the time tracker server via Internet")];
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
    NSMenu *tasksMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Tasks", @"The menu bar title for Tasks")];
    for (KimaiTask *task in self.kimai.tasks) {
        if ([task.visible boolValue] == YES) {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:task.name action:aSelector keyEquivalent:@""];
            [menuItem setRepresentedObject:task];
            [menuItem setEnabled:YES];
            [tasksMenu addItem:menuItem];
        }
    }
    
    
    // PROJECTS
    NSMenu *projectsMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"Projects", nil)];
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
    
    
    NSMenu *kimaiMenu = [[NSMenu alloc] initWithTitle:NSLocalizedString(@"TimeTracker", @"The menu bar title of the main menu in the menu bar")];
    KimaiActiveRecording *activeRecordingOrNil = nil;
    NSString *title = NSLocalizedString(@"TimeTracker", nil);
    
    if (self.kimai.activeRecordings) {
        
        // STOP ALL ACTIVE TASKS
        NSMenuItem *stopMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Stop", @"Stop tracking the current activity") action:@selector(stopAllActivities) keyEquivalent:@""];
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
                                   title:NSLocalizedString(@"Today", nil)
                        timesheetRecords:self.kimai.timesheetRecordsToday
                         currentActivity:activeRecordingOrNil
                                  action:@selector(startProjectWithMenuItem:)];


    // YESTERDAY
    [self addMenuItemTaskHistoryWithMenu:kimaiMenu
                                   title:NSLocalizedString(@"Yesterday", nil)
                        timesheetRecords:self.kimai.timesheetRecordsYesterday
                         currentActivity:nil
                                  action:@selector(startProjectWithMenuItem:)];
    
    
    // TOTAL WORKING HOURS LAST WEEK Mon-Sun
    [self addMenuItemTaskHistoryWithMenu:kimaiMenu
                                   title:NSLocalizedString(@"Last Week", nil)
                        timesheetRecords:_timesheetRecordsForLastSevenDays
                         currentActivity:nil
                                  action:@selector(startProjectWithMenuItem:)];


    // ALL PROJECTS
    NSMenuItem *allProjectsMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Projects", nil) action:nil keyEquivalent:@""];
    [allProjectsMenuItem setSubmenu:[self projectsMenuWithAction:@selector(startProjectWithMenuItem:)]];
    [kimaiMenu addItem:allProjectsMenuItem];
    
    
    /////////////////////////////////////////////////////////////////////////////////
    [kimaiMenu addItem:[NSMenuItem separatorItem]];
    

    // RELOAD DATA
    NSMenuItem *reloadMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Reload Projects / Tasks", @"Reload all projects and tasks from the web server") action:@selector(reloadData) keyEquivalent:@""];
    [reloadMenuItem setEnabled:self.kimai.apiKey != nil];
    [kimaiMenu addItem:reloadMenuItem];
    
    
    // OPEN WEBSITE
    if (self.kimai.url != nil) {
        NSMenuItem *launchWebsiteMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Launch Kimai Website", @"The default web browser is being openend with the user's Kimai website") action:@selector(launchKimaiWebsite) keyEquivalent:@""];
        [kimaiMenu addItem:launchWebsiteMenuItem];
    }

    
    /////////////////////////////////////////////////////////////////////////////////
    [kimaiMenu addItem:[NSMenuItem separatorItem]];

        
    // PREFERENCES
    NSMenuItem *preferencesMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Preferences...", @"Open the application preferences") action:@selector(showPreferences) keyEquivalent:@""];
    [kimaiMenu addItem:preferencesMenuItem];
    
    // SUPPORT
    NSMenuItem *supportMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Support...", @"Link to the uservoice.com support page") action:@selector(launchSupportWebsiteFromMenu) keyEquivalent:@""];
    [kimaiMenu addItem:supportMenuItem];
    

    /////////////////////////////////////////////////////////////////////////////////
    [kimaiMenu addItem:[NSMenuItem separatorItem]];
    
    // QUIT
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Quit TimeTracker", @"Quit and leave the application") action:@selector(quitApplication) keyEquivalent:@""];
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


#pragma mark - Support


- (void)launchSupportWebsiteFromPreferences {
    [self launchSupportWebsiteFromMedium:@"preferences"];
}


- (void)launchSupportWebsiteFromErrorMessage {
    [self launchSupportWebsiteFromMedium:@"errormessage"];
}


- (void)launchSupportWebsiteFromMenu {
    [self launchSupportWebsiteFromMedium:@"menu"];
}


- (void)launchSupportWebsiteFromMedium:(NSString *)medium {
    NSString *urlString = [NSString stringWithFormat:@"http://blockhaus-timetracker.uservoice.com/?utm_source=macapp&utm_medium=%@&utm_campaign=support", medium];
    NSURL *url = [NSURL URLWithString:urlString];
    [[NSWorkspace sharedWorkspace] openURL:url];
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

}


- (void)showPreferences {
    
    [self.preferencesWindowController.window setLevel:NSMainMenuWindowLevel];
    [self.preferencesWindowController.window center];
    [self.preferencesWindowController.window makeKeyAndOrderFront:self];
    [self.preferencesWindowController showWindow:nil];

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

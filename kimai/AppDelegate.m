//
//  AppDelegate.m
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 15.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "AppDelegate.h"
#import "RHKeychain.h"


@interface AppDelegate () {
    NSTimer *_trainingTimer;
}
@end



@implementation AppDelegate

static NSString *SERVICENAME = @"org.kimai.timetracker";


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

    [self hidePreferences];
    
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setView:statusItemView];
    [statusItem setHighlightMode:YES];
    [statusItem setTitle:@"Kimai"];

    
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Kimai Menu"];
    [statusItem setMenu:menu];


    [self initKimai];
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
        
        NSString *kimaiServerURL = RHKeychainGetGenericComment(NULL, SERVICENAME);
        NSString *username = RHKeychainGetGenericUsername(NULL, SERVICENAME);
        NSString *password = RHKeychainGetGenericPassword(NULL, SERVICENAME);
        
        [self.kimaiURLTextField setStringValue:kimaiServerURL];
        [self.usernameTextField setStringValue:username];
        [self.passwordTextField setStringValue:password];
        
        self.kimai = [[Kimai alloc] initWithURL:[NSURL URLWithString:kimaiServerURL]];
        [self.kimai authenticateWithUsername:username password:password success:^(id response) {
            
            [self reloadData];
            
        } failure:^(NSError *error) {
            
            [self showAlertSheetWithError:error];
            [self reloadMenu];
            
        }];
        
    } else {
        [self showPreferences];
    }
    
}


- (void)reloadData {
    
    [self.kimai reloadAllContentWithSuccess:^(id response) {
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
        
        if (RHKeychainSetGenericUsername(NULL, SERVICENAME, username) &&
            RHKeychainSetGenericPassword(NULL, SERVICENAME, password) &&
            RHKeychainSetGenericComment(NULL, SERVICENAME, kimaiServerURL)) {
            [self hidePreferences];
            [self initKimai];
        }
        
    }
    
}


- (NSString *)statusBarTitleWithActivity:(KimaiActiveRecording *)activity {
    
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit
                                                                       fromDate:activity.startDate
                                                                         toDate:[NSDate date]
                                                                        options:0];
    
    NSInteger hours = [dateComponents hour];
    NSInteger minutes = [dateComponents minute];
    NSInteger seconds = [dateComponents second];
    
    NSString *time;
    if (hours > 0) {
        time = [NSString stringWithFormat:@"%li:%@:%@", hours, [self formatTimeComponent:minutes], [self formatTimeComponent:seconds]];
    } else {
        time = [NSString stringWithFormat:@"%@:%@", [self formatTimeComponent:minutes], [self formatTimeComponent:seconds]];
    }
    
    return [NSString stringWithFormat:@"%@ - %@ - %@", activity.projectName, activity.activityName, time];
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
    
    _trainingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
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


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{

    return NSTerminateNow;
}

@end

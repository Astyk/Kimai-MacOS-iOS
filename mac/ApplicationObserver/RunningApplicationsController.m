//
//  RunningApplicationsController.m
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 19.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "RunningApplicationsController.h"
#import "BMAppDelegate.h"
#import "BMTimeFormatter.h"
#import "BMiCalExport.h"



@implementation RunningApplicationsController {
    int _switchCyclesCount;
}


- (id)init
{
    self = [super init];
    if (self) {
        
        _switchCyclesCount = 0;
        
/*
        //[self loggedApplications];
        BMAppDelegate *delegate = (BMAppDelegate *)[NSApplication sharedApplication].delegate;
        NSManagedObjectContext *moc = [delegate managedObjectContext];
        [BMiCalExport icalExportWithManagedObjectContext:moc];
        return self;
*/
 
        // add the window change observer for every running application
        for (NSRunningApplication *application in [NSWorkspace sharedWorkspace].runningApplications) {
            [self addObserverToApplication:application];
        }


        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                               selector:@selector(applicationDidBecomeActive:)
                                                                   name:NSWorkspaceDidActivateApplicationNotification object:nil];

        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                               selector:@selector(applicationDidLaunch:)
                                                                   name:NSWorkspaceDidLaunchApplicationNotification object:nil];

        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self
                                                               selector:@selector(applicationDidTerminate:)
                                                                   name:NSWorkspaceDidTerminateApplicationNotification object:nil];
        
    }
    return self;
}



#pragma mark - Core Data




- (NSArray *)loggedApplications {
    
    BMAppDelegate *delegate = (BMAppDelegate *)[NSApplication sharedApplication].delegate;
    
    NSManagedObjectContext *moc = [delegate managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BMApplication"
                                                         inManagedObjectContext:moc];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    

    int totalWorkingDuration = 0;
    
    NSError *error;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    for (BMApplication *application in array) {
        
        if ([application.bundleIdentifier isEqualToString:@"com.apple.loginwindow"] ||
            [application.bundleIdentifier isEqualToString:@"com.apple.ScreenSaver.Engine"]) {
            // do not track the login window or screensaver
            continue;
        }
        
        int totalAppDuration = 0;
        for (BMApplicationWindow *window in application.windows) {
            
            // cleanup unnecessary objects in database
            if (window.activeDuration.intValue == 0) {
                NSLog(@"Delete object: %@", window.title);
                [moc deleteObject:window];
                continue;
            }
            
            totalAppDuration += window.activeDuration.intValue;
        }

        if (totalAppDuration > 0) {
            totalWorkingDuration += totalAppDuration;
            NSLog(@"%@ %@", application.bundleIdentifier, [BMTimeFormatter formatedDurationStringFromTimeInterval:totalAppDuration]);
        }

    }
    
    NSLog(@"TOTAL  %@", [BMTimeFormatter formatedDurationStringFromTimeInterval:totalWorkingDuration]);
    
    [delegate saveDatabase];
    
    return array;
}


- (void)sumTimePerApplication {
    
    BMAppDelegate *delegate = (BMAppDelegate *)[NSApplication sharedApplication].delegate;
    
    NSManagedObjectContext *moc = [delegate managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BMApplicationWindow"
                                                         inManagedObjectContext:moc];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSError *error;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    for (BMApplicationWindow *window in array) {
        if (window.activateDate && window.deactivateDate) {
            int timeinterval = [window.deactivateDate timeIntervalSinceDate:window.activateDate];
            NSLog(@"%i", timeinterval);
            window.activeDuration = [NSNumber numberWithInt:timeinterval];
        }
    }
    
    // store the changes
    [delegate saveDatabase];
    
}


- (BMApplication *)applicationWithBundleIdentifier:(NSString *)bundleIdentifier {
    
    BMAppDelegate *delegate = (BMAppDelegate *)[NSApplication sharedApplication].delegate;
    
    NSManagedObjectContext *moc = [delegate managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BMApplication"
                                                         inManagedObjectContext:moc];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"bundleIdentifier = %@", bundleIdentifier];
    [request setPredicate:predicate];
        
    NSError *error;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    if (array == nil || array.count == 0) {
        // BMApplication not found
        return nil;
    }

    // return first fetch result object
    return [array objectAtIndex:0];
}


- (BMApplication *)applicationWithRunningApplication:(NSRunningApplication *)runningApplication {
    
    // return the current application if it matches the bundle identifier
    if (_currentApplication && [_currentApplication.bundleIdentifier isEqualToString:runningApplication.bundleIdentifier]) {
        return _currentApplication;
    }
    
    // return an existing one from the database
    BMApplication *application = [self applicationWithBundleIdentifier:runningApplication.bundleIdentifier];
    if (application) {
        _currentApplication = application;
        return application;
    }
    
    // or otherwise create a new database entity
    BMAppDelegate *delegate = (BMAppDelegate *)[NSApplication sharedApplication].delegate;
    application = (BMApplication *)[NSEntityDescription insertNewObjectForEntityForName:@"BMApplication"
                                                                  inManagedObjectContext:delegate.managedObjectContext];
    application.bundleIdentifier = runningApplication.bundleIdentifier;
    application.name = runningApplication.localizedName;
    

    // get the application icon
/*
    NSDictionary *applicationInfo = [[NSWorkspace sharedWorkspace] activeApplication];
    NSImage *iconImage = [[NSWorkspace sharedWorkspace] iconForFile:[applicationInfo valueForKey:@"NSApplicationPath"]];
    delegate.applicationIconImage.image = iconImage;
*/
    
    _currentApplication = application;
    return application;
}


- (BMApplicationWindow *)applicationWindowWithTitle:(NSString *)title {
    
    BMAppDelegate *delegate = (BMAppDelegate *)[NSApplication sharedApplication].delegate;
//    [delegate.applicationWindowTitle setStringValue:title];
    
    // save the current application window
    if (_currentApplicationWindow) {
        
        _currentApplicationWindow.deactivateDate = [NSDate date];
        
        // store database every other switch cycle
        if (++_switchCyclesCount >= 20) {
            _switchCyclesCount = 0;
            [delegate saveDatabase];
        }
        
    }
    
    // create a new instance
    _currentApplicationWindow = (BMApplicationWindow *)[NSEntityDescription insertNewObjectForEntityForName:@"BMApplicationWindow"
                                                                  inManagedObjectContext:delegate.managedObjectContext];
    _currentApplicationWindow.activateDate = [NSDate date];
    _currentApplicationWindow.title = title;
    
    return _currentApplicationWindow;
}


#pragma mark - Accessibility Observer


- (void)addObserverToApplication:(NSRunningApplication *)application {
    
    AXObserverRef observer = NULL;
    AXError err = AXObserverCreate( application.processIdentifier, MainWindowOrTitleChangedCallback, &observer );
    if ( err != kAXErrorSuccess ) {
        NSLog(@"Error creating application observer for %@", application.bundleIdentifier);
    } else if (observer != NULL) {
        
        AXUIElementRef app = AXUIElementCreateApplication(application.processIdentifier);
        
        err = AXObserverAddNotification( observer, app, kAXMainWindowChangedNotification, (__bridge void *)(self) );
        if ( err != kAXErrorSuccess ) {
            NSLog(@"Error adding window change notification observer");
        }
        
        err = AXObserverAddNotification( observer, app, kAXTitleChangedNotification, (__bridge void *)(self) );
        if ( err != kAXErrorSuccess ) {
            NSLog(@"Error adding title change notification observer");
        }
        
        //AXObserverAddNotification( observer, app, kAXApplicationHiddenNotification, (__bridge void *)(self) );
        //AXObserverAddNotification( observer, app, kAXApplicationShownNotification, (__bridge void *)(self) );
        CFRelease(app);
        
        CFRunLoopAddSource( [[NSRunLoop currentRunLoop] getCFRunLoop],
                           AXObserverGetRunLoopSource(observer),
                           kCFRunLoopDefaultMode );
        
        NSLog(@"DID ADD OBSERVER: %@", application.bundleIdentifier);

    }

}


- (void)removeObserverForApplication:(NSRunningApplication *)application {
    NSLog(@"UNOBSERVE: %@", application.bundleIdentifier);
}


#pragma mark - Notifications


- (void)applicationDidLaunch:(NSNotification *)notification {
    NSRunningApplication *application = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
    [self addObserverToApplication:application];
}


- (void)applicationDidTerminate:(NSNotification *)notification {
    NSRunningApplication *application = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
    [self removeObserverForApplication:application];
}


// the Accessibility observer callback
void MainWindowOrTitleChangedCallback( AXObserverRef observer, AXUIElementRef windowRef, CFStringRef notificationName, void * contextData ) {
    
    // the window or title of a window within an application changed
    RunningApplicationsController *controller = (__bridge RunningApplicationsController *)contextData;
    
    // create a new application entitiy
    BMApplicationWindow *applicationWindow = nil;
    
    // is this element really the currently active window
    CFStringRef titleValue = nil;
    AXUIElementCopyAttributeValue(windowRef, kAXTitleAttribute, (CFTypeRef*)&titleValue);
    if (titleValue) {
        applicationWindow = [controller applicationWindowWithTitle:(__bridge NSString *)(titleValue)];
        CFRelease(titleValue);
    }

    // add a new window entity with a title string
    if (applicationWindow) {
        [controller.currentApplication addWindowsObject:applicationWindow];
    }
}


// another application became active
- (void)applicationDidBecomeActive:(NSNotification *)notification {
    
    // get the application reference
    NSRunningApplication *runningApplication = [[notification userInfo] objectForKey:NSWorkspaceApplicationKey];
    
    // create a new application entitiy
    BMApplication *application = [self applicationWithRunningApplication:runningApplication];
    BMApplicationWindow *applicationWindow = nil;
    
    // create an application reference
    AXUIElementRef applicationRef = AXUIElementCreateApplication(runningApplication.processIdentifier);
    
    // try to fetch the application window title
    AXUIElementRef frontWindow = NULL;
    AXError err = AXUIElementCopyAttributeValue( applicationRef, kAXMainWindowAttribute, (CFTypeRef*)&frontWindow );
    if ( err == kAXErrorSuccess ) {

        CFStringRef titleValue = nil;
        AXUIElementCopyAttributeValue(frontWindow, kAXTitleAttribute, (CFTypeRef*)&titleValue);
        if (titleValue) {
            applicationWindow = [self applicationWindowWithTitle:(__bridge NSString *)(titleValue)];
            CFRelease(titleValue);
        }

    } else {
        applicationWindow = [self applicationWindowWithTitle:@"-"];
        NSLog(@"Error %i when calling AXUIElementCopyAttributeValue", err);
    }
    
    if (frontWindow) {
        CFRelease(frontWindow);
    }
    
    if (applicationRef) {
        CFRelease(applicationRef);
    }

    
    // finally add the newly created application window to its application object
    if (applicationWindow) {
        [application addWindowsObject:applicationWindow];
    }
}


@end

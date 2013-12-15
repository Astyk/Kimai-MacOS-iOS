//
//  AppDelegate.m
//  KimaiLoginHelper
//
//  Created by Vinzenz-Emanuel Weber on 31.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
    
    /*
    NSString *appPath = [[[[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
    // This string takes you from MyGreat.App/Contents/Library/LoginItems/MyHelper.app to MyGreat.App This is an obnoxious but dynamic way to do this since that specific Subpath is required
    NSString *binaryPath = [[NSBundle bundleWithPath:appPath] executablePath]; // This gets the binary executable within your main application
    [[NSWorkspace sharedWorkspace] launchApplication:binaryPath];
    [NSApp terminate:nil];
    
    */
    
    
    NSLog(@"KimaiLoginHelper app is about to try launching Kimai");
    
    
    // Check if main app is already running; if yes, do nothing and terminate helper app
    BOOL alreadyRunning = NO;
    NSArray *running = [[NSWorkspace sharedWorkspace] runningApplications];
    for (NSRunningApplication *app in running) {
        if ([[app bundleIdentifier] isEqualToString:@"com.blockhausmedia.timetracker"]) {
            NSLog(@"An instance of Kimai is already running!");
            alreadyRunning = YES;
        }
    }
    
    if (!alreadyRunning) {
        NSString *path = [[NSBundle mainBundle] bundlePath];
        NSArray *p = [path pathComponents];
        NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:p];
        [pathComponents removeLastObject];
        [pathComponents removeLastObject];
        [pathComponents removeLastObject];
        [pathComponents addObject:@"MacOS"];
        [pathComponents addObject:@"LaunchAtLoginApp"];
        NSString *newPath = [NSString pathWithComponents:pathComponents];

        NSLog(@"Trying to launch Kimai application binary at path %@", newPath);
        
        if ([[NSWorkspace sharedWorkspace] launchApplication:newPath]) {
            NSLog(@"Launching Kimai succeeded!");
        } else {
            NSLog(@"Launching Kimai failed!");            
        }
        
    }
    [NSApp terminate:nil];
}


@end

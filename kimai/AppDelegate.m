//
//  AppDelegate.m
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 15.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "AppDelegate.h"


@implementation AppDelegate


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{

    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setView:statusItemView];
    [statusItem setHighlightMode:YES];
    [statusItem setTitle:@"Kimai"];

    
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Kimai Menu"];
    [statusItem setMenu:menu];

    

    KimaiFailureHandler failureHandler = ^(NSError *error) {
        NSLog(@"ERROR: %@", error);
        [self reloadMenu];
    };
    
    self.kimai = [[Kimai alloc] initWithURL:[NSURL URLWithString:@"http://timetracker.blockhausmedien.at/"]];
    [self.kimai authenticateWithUsername:@"admin" password:@"test123" success:^(id response) {
        [self reloadData:nil];
    } failure:failureHandler];
    
}


- (IBAction)reloadData:(id)sender {
    [self.kimai reloadAllContentWithSuccess:^(id response) {
        [self reloadMenu];
    } failure:^(NSError *error) {
        NSLog(@"ERROR: %@", error);
        [self reloadMenu];
    }];
}


- (void)reloadMenu {
    
    NSString *title = @"Kimai";
    if (self.kimai.activeRecordings) {
        KimaiActiveRecording *activeRecording = [self.kimai.activeRecordings objectAtIndex:0];
        title = [NSString stringWithFormat:@"%@ - %@", activeRecording.projectName, activeRecording.activityName];
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
    
    NSMenu *kimaiMenu = [[NSMenu alloc] initWithTitle:@"Kimai"];

    for (KimaiProject *project in self.kimai.projects) {
        if ([project.visible boolValue] == YES) {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:project.name action:nil keyEquivalent:@""];
            [menuItem setRepresentedObject:project];
            [menuItem setEnabled:YES];
            [menuItem setSubmenu:[tasksMenu copy]];
            [kimaiMenu addItem:menuItem];
        }
    }

    [statusItem setMenu:kimaiMenu];

}


- (void)clickedMenuItem:(id)sender {
    if ([sender isKindOfClass:[NSMenuItem class]]) {
       
        NSMenuItem *menuItem = (NSMenuItem *)sender;
        KimaiTask *task = menuItem.representedObject;
        KimaiProject *project = menuItem.parentItem.representedObject;
        
        [self.kimai startProject:project withTask:task success:^(id response) {
            [self reloadData:nil];
        } failure:^(NSError *error) {
            NSLog(@"%@", error);
            [self reloadData:nil];
        }];
        
    }
}


- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{

    return NSTerminateNow;
}

@end

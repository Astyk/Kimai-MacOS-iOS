//
//  AppDelegate.h
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 15.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KSReachability.h"
#import "StatusItemView.h"
#import "Kimai.h"


static NSString *SERVICENAME = @"org.kimai.timetracker";


@interface AppDelegate : NSObject <NSApplicationDelegate, KimaiDelegate> {
    NSStatusItem *statusItem;
    StatusItemView *statusItemView;
    NSWindowController *_preferencesWindowController;
}

@property (strong) Kimai *kimai;
@property (nonatomic, strong) KSReachability* reachability;
@property (strong) NSMutableArray *pastDaysTimesheetRecordsArray;

@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, readonly) NSWindowController *preferencesWindowController;
@property (weak) IBOutlet NSView *timeTrackerQueryView;
@property (weak) IBOutlet NSPopUpButton *pastPopupButton;
@property (weak) IBOutlet NSPopUpButton *presentPopupButton;
@property (weak) IBOutlet NSPopUpButton *futurePopupButton;


- (void)initKimai;
- (void)reloadMenu;
- (void)hidePreferences;
- (void)showAlertSheetWithError:(NSError *)error;

- (IBAction)timeTrackWindowOKClicked:(id)sender;
@end

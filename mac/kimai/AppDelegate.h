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
static NSString *PODIO_SERVICENAME = @"com.podio";



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

- (IBAction)pickActivityButtonClicked:(id)sender;
@property (weak) IBOutlet NSButton *pastButton;
@property (weak) IBOutlet NSButton *presentButton;
@property (weak) IBOutlet NSButton *futureButton;
@property (weak) IBOutlet NSTextField *leaveDateDayLabel;
@property (weak) IBOutlet NSTextField *leaveDateTimeLabel;

- (void)initPodio;


- (void)initKimai;
- (void)reloadMenu;
- (void)hidePreferences;
- (void)showAlertSheetWithError:(NSError *)error;

@property (weak) IBOutlet NSButton *homeButton;
- (IBAction)homeButtonClicked:(id)sender;
- (IBAction)timeTrackWindowOKClicked:(id)sender;


@end

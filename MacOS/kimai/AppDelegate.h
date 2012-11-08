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


@interface AppDelegate : NSObject <NSApplicationDelegate, KimaiDelegate> {
    NSStatusItem *statusItem;
    StatusItemView *statusItemView;
}

@property (nonatomic, strong) KSReachability* reachability;

@property (assign) IBOutlet NSWindow *window;

@property (weak) IBOutlet NSTextField *kimaiURLTextField;
@property (weak) IBOutlet NSTextField *usernameTextField;
@property (weak) IBOutlet NSSecureTextField *passwordTextField;
@property (weak) IBOutlet NSButton *loginCheckButton;

@property (strong) Kimai *kimai;

- (IBAction)storePreferences:(id)sender;

@end
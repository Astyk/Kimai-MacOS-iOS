//
//  AppDelegate.h
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 15.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "StatusItemView.h"
#import "Kimai.h"

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSStatusItem *statusItem;
    StatusItemView *statusItemView;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSMenu *mainMenu;
@property (strong) Kimai *kimai;

- (IBAction)reloadData:(id)sender;

@end

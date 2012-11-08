//
//  StatusItemView.h
//  Quick2Go
//
//  Created by Vinzenz-Emanuel Weber on 03.02.12.
//  Copyright (c) 2012 Blockhaus Medienagentur. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface StatusItemView : NSView <NSMenuDelegate> {
    NSWindow *_mainWindow;
    NSStatusItem *statusItem;
    NSString *title;
    int _textWidth;
    BOOL isMenuVisible;
    BOOL isHighlighted;
    NSImage *_iconImage;
    NSImage *_selectedIconImage;
}

@property (assign, nonatomic) NSWindow *mainWindow;
@property (retain, nonatomic) NSStatusItem *statusItem;
@property (retain, nonatomic) NSString *title;

@end

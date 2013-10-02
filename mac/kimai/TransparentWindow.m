//
//  TransparentWindow.m
//  Kimai-MacOS
//
//  Created by Vinzenz-Emanuel Weber on 10.11.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "TransparentWindow.h"

@implementation TransparentWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag screen:(NSScreen *)screen {
    if (self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag screen:screen]) {
        [self setBackgroundColor: [NSColor blackColor]];
        [self setAlphaValue:0.7];
        [self setOpaque:NO];
    }
    return self;
}


@end

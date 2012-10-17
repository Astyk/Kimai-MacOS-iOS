//
//  StatusItemView.m
//  Quick2Go
//
//  Created by Vinzenz-Emanuel Weber on 03.02.12.
//  Copyright (c) 2012 Blockhaus Medienagentur. All rights reserved.
//

#import "StatusItemView.h"



#define StatusItemViewPaddingWidth  6
#define StatusItemViewPaddingHeight 3




@implementation StatusItemView

@synthesize mainWindow;
@synthesize statusItem;
@synthesize title;




- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _iconImage = [NSImage imageNamed:@"smart-icon.png"];
        _selectedIconImage = [NSImage imageNamed:@"smart-icon-selected.png"];
        statusItem = nil;
        title = @"";
        isMenuVisible = NO;
        isHighlighted = NO;
    }
    
    return self;
}



#pragma mark -
#pragma mark NSResponder


- (void)mouseDown:(NSEvent *)event {
    isHighlighted = YES;   
    [self setNeedsDisplay:YES];
}

- (void)rightMouseDown:(NSEvent *)event {
    [self mouseDown:event];
}

- (void)otherMouseDown:(NSEvent *)event {
    [self mouseDown:event];
}

- (void)mouseUp:(NSEvent *)event {
    
    if ([mainWindow isVisible]) {
        [mainWindow orderOut:self]; 
    } else {
        [mainWindow makeKeyAndOrderFront:self];
        [NSApp activateIgnoringOtherApps:YES];
    }

    isHighlighted = NO;
    [self setNeedsDisplay:YES];
}

- (void)rightMouseUp:(NSEvent *)event {
    [self mouseUp:event];
}

- (void)otherMouseUp:(NSEvent *)event {
    [self mouseUp:event];
}



#pragma mark -
#pragma mark NSMenuDelegate



- (void)menuWillOpen:(NSMenu *)menu {
    isMenuVisible = YES;
    [self setNeedsDisplay:YES];
}

- (void)menuDidClose:(NSMenu *)menu {
    isMenuVisible = NO;
    [menu setDelegate:nil];    
    [self setNeedsDisplay:YES];
}


#pragma mark -
#pragma mark Title calculations


- (NSColor *)titleForegroundColor {
    return [NSColor whiteColor];
    /*
    if (isHighlighted) {
        return [NSColor whiteColor];
    }
    else {
        return [NSColor blackColor];
    }
     */
}

- (NSDictionary *)titleAttributes {
    // Use default menu bar font size
    NSFont *font = [NSFont menuBarFontOfSize:0];
    
    NSColor *foregroundColor = [self titleForegroundColor];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            font,            NSFontAttributeName,
            foregroundColor, NSForegroundColorAttributeName,
            nil];
}

- (NSRect)titleBoundingRect {
    return [title boundingRectWithSize:NSMakeSize(1e100, 1e100)
                               options:0
                            attributes:[self titleAttributes]];
}

- (void)setTitle:(NSString *)newTitle {
    if (![title isEqual:newTitle]) {
       // [newTitle retain];
       // [title release];
        title = newTitle;
        
        // Update status item size (which will also update this view's bounds)
        NSRect titleBounds = [self titleBoundingRect];
        _textWidth = titleBounds.size.width + (2 * StatusItemViewPaddingWidth);
        int newWidth = titleBounds.size.width + (3 * StatusItemViewPaddingWidth) + _iconImage.size.width;
        [statusItem setLength:newWidth];
        
        [self setNeedsDisplay:YES];
    }
}

- (NSString *)title {
    return title;
}


- (void)drawRect:(NSRect)rect {

    
    // Draw status bar background, highlighted if menu is showing
    [statusItem drawStatusBarBackgroundInRect:[self bounds]
                                withHighlight:isHighlighted];
    
    // Draw icon
    NSPoint iconorigin = NSMakePoint(rect.size.width - _iconImage.size.width - StatusItemViewPaddingWidth,
                                     StatusItemViewPaddingHeight);
    
    if (isHighlighted) {
        [_selectedIconImage drawAtPoint:iconorigin fromRect:rect operation:NSCompositeHighlight fraction:1.0];
    }
    else {
        [_iconImage drawAtPoint:iconorigin fromRect:rect operation:NSCompositeHighlight fraction:1.0];
    }
    

    // Draw orange rectanlge with rounded corners
    NSRect backgroundRect = NSMakeRect([self bounds].origin.x + 2, [self bounds].origin.y + 3, _textWidth - 4, [self bounds].size.height - 5);
    
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:backgroundRect xRadius:8.0 yRadius:8.0];
    [path addClip];
    
    [[NSColor orangeColor] set];
    NSRectFill(rect);
    

    // Draw title string
    NSPoint textorigin = NSMakePoint(StatusItemViewPaddingWidth,StatusItemViewPaddingHeight);
    [title drawAtPoint:textorigin withAttributes:[self titleAttributes]];

    
}

@end


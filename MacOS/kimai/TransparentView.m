//
//  TransparentView.m
//  Kimai-MacOS
//
//  Created by Vinzenz-Emanuel Weber on 22.11.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "TransparentView.h"

@implementation TransparentView

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor clearColor] set];
//    NSRectFill(dirtyRect);
        NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);
}

@end

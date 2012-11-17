//
//  GeneralPreferencesViewController.m
//  Kimai-MacOS
//
//  Created by Vinzenz-Emanuel Weber on 17.11.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "GeneralPreferencesViewController.h"

@interface GeneralPreferencesViewController ()

@end

@implementation GeneralPreferencesViewController

- (id)init
{
    return [super initWithNibName:@"GeneralPreferencesViewController" bundle:nil];
}

#pragma mark - MASPreferencesViewController

- (NSString *)identifier
{
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:NSImageNamePreferencesGeneral];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"General", @"Toolbar item name for the General preference pane");
}

@end

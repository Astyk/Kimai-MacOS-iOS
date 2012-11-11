//
//  AppDelegate.h
//  Kimai
//
//  Created by Vinzenz-Emanuel Weber on 07.11.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ViewController *viewController;
@property (strong, nonatomic) UINavigationController *navigationController;

@end

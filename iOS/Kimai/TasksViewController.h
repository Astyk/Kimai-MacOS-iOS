//
//  TasksViewController.h
//  Kimai-iOS
//
//  Created by Vinzenz-Emanuel Weber on 11.11.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Kimai.h"

@interface TasksViewController : UITableViewController

@property (weak) Kimai *kimai;
@property (weak) KimaiProject *project;

- (id)initWithKimai:(Kimai *)kimai project:(KimaiProject *)project;

@end

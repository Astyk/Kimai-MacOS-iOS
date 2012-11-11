//
//  ViewController.h
//  Kimai
//
//  Created by Vinzenz-Emanuel Weber on 07.11.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Kimai.h"

@interface ViewController : UIViewController <KimaiDelegate, UITableViewDataSource, UITableViewDelegate>

@property (strong) Kimai *kimai;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIView *credentialsView;
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UITextField *kimaiServerURLTextField;

- (IBAction)loginClicked:(id)sender;

@end

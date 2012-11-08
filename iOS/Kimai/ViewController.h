//
//  ViewController.h
//  Kimai
//
//  Created by Vinzenz-Emanuel Weber on 07.11.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Kimai.h"

@interface ViewController : UIViewController <KimaiDelegate>

@property (strong) Kimai *kimai;

@end

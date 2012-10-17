//
//  KimaiProject.h
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 17.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KimaiObject.h"

@interface KimaiProject : KimaiObject

@property (strong) NSString *approved;
@property (strong) NSString *budget;
@property (strong) NSString *comment;
@property (strong) NSNumber *customerID;
@property (strong) NSString *customerName;
@property (strong) NSString *effort;
@property (strong) NSNumber *filter;
@property (strong) NSNumber *internal;
@property (strong) NSString *name;
@property (strong) NSNumber *projectID;
@property (strong) NSNumber *trash;
@property (strong) NSNumber *visible;

@end

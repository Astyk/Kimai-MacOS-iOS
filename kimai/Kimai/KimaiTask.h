//
//  KimaiTask.h
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 17.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "KimaiObject.h"

@interface KimaiTask : KimaiObject

@property (strong) NSNumber *activityID;
@property (strong) NSNumber *assignable;
@property (strong) NSString *name;
@property (strong) NSNumber *visible;

@end

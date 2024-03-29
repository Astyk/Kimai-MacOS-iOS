//
//  KimaiTask.h
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 17.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "JSONObject.h"

@interface KimaiTask : JSONObject

@property (nonatomic, strong) NSNumber *activityID;
@property (nonatomic, strong) NSNumber *assignable;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *visible;

@end

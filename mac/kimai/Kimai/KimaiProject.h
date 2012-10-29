//
//  KimaiProject.h
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 17.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "KimaiObject.h"

@interface KimaiProject : KimaiObject

@property (nonatomic, strong) NSString *approved;
@property (nonatomic, strong) NSString *budget;
@property (nonatomic, strong) NSString *comment;
@property (nonatomic, strong) NSNumber *customerID;
@property (nonatomic, strong) NSString *customerName;
@property (nonatomic, strong) NSString *effort;
@property (nonatomic, strong) NSNumber *filter;
@property (nonatomic, strong) NSNumber *internal;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *projectID;
@property (nonatomic, strong) NSNumber *trash;
@property (nonatomic, strong) NSNumber *visible;

@end

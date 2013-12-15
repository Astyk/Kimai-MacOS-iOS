//
//  BMCustomer.h
//  Kimai-iOS
//
//  Created by Vinzenz-Emanuel Weber on 14.10.13.
//  Copyright (c) 2013 blockhaus medienagentur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BMProject;

@interface BMCustomer : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *projects;
@end

@interface BMCustomer (CoreDataGeneratedAccessors)

- (void)addProjectsObject:(BMProject *)value;
- (void)removeProjectsObject:(BMProject *)value;
- (void)addProjects:(NSSet *)values;
- (void)removeProjects:(NSSet *)values;

@end

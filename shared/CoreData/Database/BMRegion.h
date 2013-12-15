//
//  BMRegion.h
//  Kimai-iOS
//
//  Created by Vinzenz-Emanuel Weber on 14.10.13.
//  Copyright (c) 2013 blockhaus medienagentur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BMProject, BMTimesheetRecord;

@interface BMRegion : NSManagedObject

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * radius;
@property (nonatomic, retain) NSSet *projects;
@property (nonatomic, retain) NSSet *timesheetRecords;
@end

@interface BMRegion (CoreDataGeneratedAccessors)

- (void)addProjectsObject:(BMProject *)value;
- (void)removeProjectsObject:(BMProject *)value;
- (void)addProjects:(NSSet *)values;
- (void)removeProjects:(NSSet *)values;

- (void)addTimesheetRecordsObject:(BMTimesheetRecord *)value;
- (void)removeTimesheetRecordsObject:(BMTimesheetRecord *)value;
- (void)addTimesheetRecords:(NSSet *)values;
- (void)removeTimesheetRecords:(NSSet *)values;

@end

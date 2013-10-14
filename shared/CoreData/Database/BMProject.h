//
//  BMProject.h
//  Kimai-iOS
//
//  Created by Vinzenz-Emanuel Weber on 14.10.13.
//  Copyright (c) 2013 blockhaus medienagentur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BMCustomer, BMRegion, BMTimesheetRecord;

@interface BMProject : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) BMCustomer *customer;
@property (nonatomic, retain) NSSet *regions;
@property (nonatomic, retain) NSSet *timesheetRecords;
@end

@interface BMProject (CoreDataGeneratedAccessors)

- (void)addRegionsObject:(BMRegion *)value;
- (void)removeRegionsObject:(BMRegion *)value;
- (void)addRegions:(NSSet *)values;
- (void)removeRegions:(NSSet *)values;

- (void)addTimesheetRecordsObject:(BMTimesheetRecord *)value;
- (void)removeTimesheetRecordsObject:(BMTimesheetRecord *)value;
- (void)addTimesheetRecords:(NSSet *)values;
- (void)removeTimesheetRecords:(NSSet *)values;

@end

//
//  BMTimesheetRecord.h
//  Kimai-iOS
//
//  Created by Vinzenz-Emanuel Weber on 14.10.13.
//  Copyright (c) 2013 blockhaus medienagentur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BMProject, BMRegion, BMTimesheetRecordComment;

@interface BMTimesheetRecord : NSManagedObject

@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) BMProject *project;
@property (nonatomic, retain) BMRegion *region;
@end

@interface BMTimesheetRecord (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(BMTimesheetRecordComment *)value;
- (void)removeCommentsObject:(BMTimesheetRecordComment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

@end

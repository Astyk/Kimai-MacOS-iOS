//
//  BMTimesheetRecordComment.h
//  Kimai-iOS
//
//  Created by Vinzenz-Emanuel Weber on 14.10.13.
//  Copyright (c) 2013 blockhaus medienagentur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BMTimesheetRecord;

@interface BMTimesheetRecordComment : NSManagedObject

@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) BMTimesheetRecord *timesheetRecord;

@end

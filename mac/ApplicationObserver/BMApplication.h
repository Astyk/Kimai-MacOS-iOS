//
//  BMApplication.h
//  RunningApplications
//
//  Created by Vinzenz-Emanuel Weber on 16.03.13.
//  Copyright (c) 2013 blockhaus medienagentur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BMApplicationWindow;

@interface BMApplication : NSManagedObject

@property (nonatomic, retain) NSString * bundleIdentifier;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *windows;
@end

@interface BMApplication (CoreDataGeneratedAccessors)

- (void)addWindowsObject:(BMApplicationWindow *)value;
- (void)removeWindowsObject:(BMApplicationWindow *)value;
- (void)addWindows:(NSSet *)values;
- (void)removeWindows:(NSSet *)values;

@end

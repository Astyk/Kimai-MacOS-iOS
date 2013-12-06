//
//  BMApplicationWindow.h
//  RunningApplications
//
//  Created by Vinzenz-Emanuel Weber on 20.03.13.
//  Copyright (c) 2013 blockhaus medienagentur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BMApplication;

@interface BMApplicationWindow : NSManagedObject

@property (nonatomic, retain) NSDate * activateDate;
@property (nonatomic, retain) NSDate * deactivateDate;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * activeDuration;
@property (nonatomic, retain) BMApplication *application;

@end

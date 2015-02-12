//
//  BMiCalExport.h
//  RunningApplications
//
//  Created by Vinzenz-Emanuel Weber on 24.04.13.
//  Copyright (c) 2013 blockhaus medienagentur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BMApplicationWindow.h"

@interface BMiCalExport : NSObject

+ (NSString *)icalExportWithManagedObjectContext:(NSManagedObjectContext *)moc;

@end

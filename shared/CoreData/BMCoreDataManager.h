//
//  BMCoreDataManager.h
//  TestCoreData
//
//  Created by Vinzenz-Emanuel Weber on 12.10.13.
//  Copyright (c) 2013 blockhaus medienagentur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CoreData+MagicalRecord.h"

@interface BMCoreDataManager : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (BMCoreDataManager *)sharedManager;
- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end

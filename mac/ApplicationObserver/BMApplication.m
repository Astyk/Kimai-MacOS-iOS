//
//  BMApplication.m
//  RunningApplications
//
//  Created by Vinzenz-Emanuel Weber on 16.03.13.
//  Copyright (c) 2013 blockhaus medienagentur. All rights reserved.
//

#import "BMApplication.h"
#import "BMApplicationWindow.h"


@implementation BMApplication

@dynamic bundleIdentifier;
@dynamic name;
@dynamic windows;

/*
- (NSNumber *)totalActiveDuration {
    
    NSNumber *totalActiveDuration = nil;
    
    // https://developer.apple.com/library/mac/#documentation/Cocoa/Reference/Foundation/Classes/NSExpression_Class/Reference/NSExpression.html#//apple_ref/occ/clm/NSExpression/expressionForFunction:arguments:
    NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:@"activeDuration"];
    NSExpression *totalActiveDurationExpression = [NSExpression expressionForFunction:@"sum:" arguments:[NSArray arrayWithObject:keyPathExpression]];
    NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
    [expressionDescription setName:@"activeDuration"];
    [expressionDescription setExpression:totalActiveDurationExpression];
    [expressionDescription setExpressionResultType:NSInteger32AttributeType];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"BMApplicationWindow"
                                                         inManagedObjectContext:moc];
    [request setEntity:entityDescription];
    [request setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];
    [request setResultType:NSDictionaryResultType];
    
    // Execute the fetch.
    NSError *error = nil;
    NSArray *objects = [[NSManagedObjectContext contextForCurrentThread] executeFetchRequest:request error:&error];
    if (objects == nil) {
        NSLog(@"%@", [error localizedDescription]);
    } else {
        if ([objects count] > 0) {
            totalActiveDuration = [[objects objectAtIndex:0] valueForKey:@"lastModified"];
        }
    }
    
    return totalActiveDuration;
}
*/

@end

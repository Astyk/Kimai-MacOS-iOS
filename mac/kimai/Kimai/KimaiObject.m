//
//  KimaiObject.m
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 17.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "KimaiObject.h"
#include <objc/runtime.h>

@implementation KimaiObject

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    self = [super init];
    if (self) {
        
        for (NSString *key in [dictionary allKeys]) {
            
            // watch out for "description" this is part of NSObject anyway
            if ([key isEqualToString:@"description"]) {
                continue;
            }
            
            id value = [dictionary valueForKey:key];
            
            if ([self respondsToSelector:NSSelectorFromString(key)]) {
                if (value != [NSNull null]) {
                    [self setValue:value forKey:key];
                }
            } else {
                NSLog(@"Does not respond to key '%@' of type %s", key, object_getClassName(value));
            }
            
        }
        
    }
    return self;
}


static const char *getPropertyType(objc_property_t property) {
    const char *attributes = property_getAttributes(property);
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char *state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {
        if (attribute[0] == 'T') {
            return (const char *)[[NSData dataWithBytes:(attribute + 3) length:strlen(attribute) - 4] bytes];
        }
    }
    return "@";
}


- (NSString *)description {
    unsigned int outCount, i;

    NSMutableString *description = [NSMutableString stringWithFormat:@"<"];

    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for(i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName) {
            const char *propType = getPropertyType(property);
            NSString *propertyName = [NSString stringWithUTF8String:propName];
            NSString *propertyType = [NSString stringWithUTF8String:propType];

            [description appendFormat:@"(%@ *)%@=%@ ", propertyType, propertyName, [self valueForKey:propertyName]];
        }
    }
    free(properties);
 
    [description appendFormat:@">"];
    return description;
}


@end

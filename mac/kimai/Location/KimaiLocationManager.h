//
//  KimaiLocationManager.h
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 25.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreWLAN/CoreWLAN.h>


@interface KimaiLocationManager : NSObject <CLLocationManagerDelegate> {
    CLLocationManager *_locationManager;
    CWInterface *_currentInterface;
}

@property (nonatomic, strong) CLLocationManager *locationManager;

+ (KimaiLocationManager *)sharedManager;

@end

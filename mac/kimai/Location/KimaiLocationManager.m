//
//  KimaiLocationManager.m
//  kimai
//
//  Created by Vinzenz-Emanuel Weber on 25.10.12.
//  Copyright (c) 2012 blockhaus medienagentur. All rights reserved.
//

#import "KimaiLocationManager.h"

@implementation KimaiLocationManager

@synthesize locationManager = _locationManager;


+ (KimaiLocationManager *)sharedManager {
    static KimaiLocationManager *INSTANCE = nil;
    if(INSTANCE == nil) {
        INSTANCE = [[KimaiLocationManager alloc] init];
    }
    return INSTANCE;
}


- (id)init
{
    self = [super init];
    if (self) {
        
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.purpose = @"Detect whenever you are at the office and start tracking your time automatically.";
        _locationManager.delegate = self;
        [_locationManager startUpdatingLocation];

        [self scanWifiList];
    }
    return self;
}


#pragma mark - CoreWLANWirelessManager


- (void)scanWifiList {
    
    for (NSString *interfaceName in [CWInterface interfaceNames]) {
        
        CWInterface *interface = [CWInterface interfaceWithName:interfaceName];
        
        NSError *error;
        NSSet *networks = [interface scanForNetworksWithName:nil error:&error];
        
        for (CWNetwork *network in networks) {
            NSLog(@"%@, %@", network.ssid, network.bssid);
        }
    }
    
#if 0
    InetAddress address = InetAddress.getLocalHost();
    // InetAddress address = InetAddress.getByName("192.168.46.53");
    
    /*
     * Get NetworkInterface for the current host and then read the
     * hardware address.
     */
    NetworkInterface ni = NetworkInterface.getByInetAddress(address);
    if (ni != null) {
        byte[] mac = ni.getHardwareAddress();
        if (mac != null) {
            /*
             * Extract each array of mac address and convert it to hexa with the
             * following format 08-00-27-DC-4A-9E.
             */
            for (int i = 0; i < mac.length; i++) {
                System.out.format("%02X%s", mac[i], (i < mac.length - 1) ? "-" : "");
            }
        } else {
            System.out.println("Address doesn't exist or is not accessible.");
        }
    } else {
        System.out.println("Network Interface for the specified address is not found.");
    }
#endif
}



#pragma mark - CLLocationManagerDelegate


- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    
	// Ignore updates where nothing we care about changed
	if (newLocation.coordinate.longitude == oldLocation.coordinate.longitude &&
		newLocation.coordinate.latitude == oldLocation.coordinate.latitude &&
		newLocation.horizontalAccuracy == oldLocation.horizontalAccuracy)
	{
		return;
	}
    
    NSLog(@"%f, %f, %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude, newLocation.horizontalAccuracy);
    
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"%@", error);
}


- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status  {
    NSLog(@"%i", status);
}



#pragma mark - CLRegion


- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    NSLog(@"didStartMonitoringForRegion %@", region);
}


- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"didEnterRegion %@", region);
}


- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"didExitRegion %@", region);
}


- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error  {
    NSLog(@"%@", error);
}



#pragma mark - Memory


- (void)dealloc
{
    [_locationManager stopUpdatingLocation];
}


@end

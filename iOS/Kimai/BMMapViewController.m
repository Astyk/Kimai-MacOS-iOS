//
//  BMMapViewController.m
//  Kimai-iOS
//
//  Created by Vinzenz-Emanuel Weber on 12.10.13.
//  Copyright (c) 2013 blockhaus medienagentur. All rights reserved.
//

#import "BMMapViewController.h"
#import "AppDelegate.h"


@interface BMMapViewController ()

@end

@implementation BMMapViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.mapView.delegate = self;
    
    
    // show all monitored regions in the map
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    for (CLRegion *region in delegate.locationManager.monitoredRegions) {
        NSLog(@"%@", region.identifier);
        MKCircle *circle = [MKCircle circleWithCenterCoordinate:region.center radius:region.radius];
        [self.mapView addOverlay:circle];
    }
    
    
    // make sure monitoring is available no this device
    if ([CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        
        UIBarButtonItem *regionMappingButton = [[UIBarButtonItem alloc] initWithTitle:@"Set Region"
                                                                                style:UIBarButtonItemStyleBordered
                                                                               target:self
                                                                               action:@selector(setRegionToMonitor)];
        self.navigationItem.rightBarButtonItem = regionMappingButton;
        
    }
}


- (void)setRegionToMonitor {
    
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
/*
    // If the overlay's radius is too large, registration fails automatically,
    // so clamp the radius to the max value.
    CLLocationDegrees radius = overlay.radius;
    if (radius > delegate.locationManager.maximumRegionMonitoringDistance) {
        radius = delegate.locationManager.maximumRegionMonitoringDistance;
    }
*/
    
    CLLocation *userLocation = self.mapView.userLocation.location;

    // Create the geographic region to be monitored.
    CLCircularRegion *geoRegion = [[CLCircularRegion alloc]
                                   initWithCenter:userLocation.coordinate
                                   radius:50
                                   identifier:@"blockhaus"];
    
    geoRegion.notifyOnEntry = YES;
    geoRegion.notifyOnExit = YES;
    
    
    [delegate.locationManager startMonitoringForRegion:geoRegion];
    
}


- (MKOverlayView *)mapView:(MKMapView *)map viewForOverlay:(id <MKOverlay>)overlay
{
    MKCircleView *circleView = [[MKCircleView alloc] initWithOverlay:overlay];
    circleView.strokeColor = [UIColor redColor];
    circleView.fillColor = [[UIColor redColor] colorWithAlphaComponent:0.4];
    return circleView;
}



#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)aMapView didUpdateUserLocation:(MKUserLocation *)aUserLocation {
    MKCoordinateRegion region;
    MKCoordinateSpan span;
    span.latitudeDelta = 0.005;
    span.longitudeDelta = 0.005;
    CLLocationCoordinate2D location;
    location.latitude = aUserLocation.coordinate.latitude;
    location.longitude = aUserLocation.coordinate.longitude;
    region.span = span;
    region.center = location;
    [aMapView setRegion:region animated:YES];
}


@end

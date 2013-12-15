//
//  BMMapViewController.h
//  Kimai-iOS
//
//  Created by Vinzenz-Emanuel Weber on 12.10.13.
//  Copyright (c) 2013 blockhaus medienagentur. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface BMMapViewController : UIViewController <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

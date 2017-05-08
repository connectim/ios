//
//  MapLocationViewController.h
//  Connect
//
//  Created by MoHuilin on 16/7/27.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "BaseViewController.h"
#import <MapKit/MapKit.h>

@interface MapLocationViewController : BaseViewController


- (instancetype)initWithComplete:(void (^)(NSDictionary *complete))complete cancel:(void (^)())cancel;

- (instancetype)initWithLocation:(CLLocationCoordinate2D)location;

- (instancetype)initWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude;

@end

//
//  MapLocationViewController.m
//  Connect
//
//  Created by MoHuilin on 16/7/27.
//  Copyright © 2016年 Connect.  All rights reserved.
//

#import "MapLocationViewController.h"
#import "LKAnnotation.h"
#import "UIView+ScreenShot.h"


@interface MapLocationViewController () <MKMapViewDelegate, CLLocationManagerDelegate> {
    MKCoordinateRegion myCurrentRegion;
}

@property(nonatomic, strong) MKMapView *mapView;
@property(nonatomic, strong) CLLocationManager *locationManager;
@property(nonatomic, strong) UIButton *myLocationButton;
@property(nonatomic, strong) UIImageView *annotationImageView;
@property(nonatomic, assign) CLLocationCoordinate2D location;
@property(nonatomic, strong) CLGeocoder *geocoder;
@property(nonatomic, assign) BOOL hasLocationMyLocation;
@property(nonatomic, copy) void (^PickLoctactiomComplete)(NSDictionary *complete);
@property(nonatomic, copy) void (^PickLoctactiomCancel)();
@property(nonatomic, assign) BOOL showLocation;

@end

@implementation MapLocationViewController

- (instancetype)initWithLocation:(CLLocationCoordinate2D)location {
    if (self = [super init]) {
        self.location = location;
    }

    return self;
}

- (instancetype)initWithLatitude:(CGFloat)latitude longitude:(CGFloat)longitude {
    if (self = [super init]) {

        self.location = CLLocationCoordinate2DMake(latitude, longitude);
        self.showLocation = YES;
    }

    return self;
}

- (instancetype)initWithComplete:(void (^)(NSDictionary *))complete cancel:(void (^)())cancel {
    if (self = [super init]) {
        self.PickLoctactiomComplete = complete;

        self.PickLoctactiomCancel = cancel;
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view addSubview:self.mapView];


    if (self.showLocation) {
        LKAnnotation *annotation = [[LKAnnotation alloc] init];
        annotation.coordinate = _location;
        annotation.title = LMLocalizedString(@"Chat Loc", nil);
        annotation.subtitle = [NSString stringWithFormat:LMLocalizedString(@"Chat latitude longitude", nil),
                                                         _location.latitude,
                                                         _location.longitude];
        [self.mapView addAnnotation:annotation];
        MKCoordinateRegion locationRegion = MKCoordinateRegionMakeWithDistance(_location, 250, 250);
        [self.mapView setRegion:locationRegion animated:YES];

    } else {
        [self setNavigationRightWithTitle:LMLocalizedString(@"Link Send", nil)];
        [self.view addSubview:self.annotationImageView];
        [_annotationImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.view);
            make.size.mas_equalTo(CGSizeMake(AUTO_WIDTH(20), AUTO_HEIGHT(37)));
        }];
    }
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    [_locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8) {
        [_locationManager requestAlwaysAuthorization];
    }
    [_locationManager startUpdatingLocation];

    self.navigationItem.leftBarButtonItems = nil;
    [self setNavigationLeftWithTitle:LMLocalizedString(@"Common Cancel", nil)];

    self.title = LMLocalizedString(@"Chat Loc", nil);


    [self.view addSubview:self.myLocationButton];
    [_myLocationButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.view).offset(-20);
        make.right.equalTo(self.view).offset(-20);
        make.size.mas_equalTo(CGSizeMake(50, 50));
    }];
}

- (void)doRight:(id)sender {
    CGFloat height = DEVICE_SIZE.height / 3;
    self.annotationImageView.hidden = YES;
    UIImage *image = [self.view screenShotWithFrame:CGRectMake(0, self.view.center.y - (height / 2), DEVICE_SIZE.width, height)];
    self.annotationImageView.hidden = NO;

    [MBProgressHUD showMessage:LMLocalizedString(@"Common Loading", nil) toView:self.view];

    __weak __typeof(&*self) weakSelf = self;
    CLLocation *clLocation = [[CLLocation alloc] initWithLatitude:_location.latitude longitude:_location.longitude];
    [self.geocoder reverseGeocodeLocation:clLocation completionHandler:^(NSArray<CLPlacemark *> *_Nullable placemarks, NSError *_Nullable error) {
        if (!error && [placemarks count] > 0) {
            NSDictionary *dict = [[placemarks objectAtIndexCheck:0] addressDictionary];
            NSString *street = nil;
            if ([dict.allKeys containsObject:@"Street"]) {
                street = [dict valueForKey:@"Street"];
            } else {
                street = [dict valueForKey:@"Name"];
            }

            if (GJCFStringIsNull(street)) {
                street = [dict valueForKey:@"Country"];
            }
            [GCDQueue executeInMainQueue:^{
                [MBProgressHUD hideHUDForView:weakSelf.view];

                if (weakSelf.PickLoctactiomComplete) {
                    weakSelf.PickLoctactiomComplete(@{@"image": image,
                            @"locationLatitude": @(_location.latitude),
                            @"locationLongitude": @(_location.longitude),
                            @"street": street});
                }

                [weakSelf dismissViewControllerAnimated:YES completion:nil];
            }];
        }
    }];
}

- (void)doLeft:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (MKMapView *)mapView {
    if (!_mapView) {
        _mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
        _mapView.delegate = self;
        [_mapView setShowsUserLocation:YES];
    }

    return _mapView;
}

- (UIButton *)myLocationButton {
    if (!_myLocationButton) {
        _myLocationButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_myLocationButton setImage:[UIImage imageNamed:@"map_location_mylocation"] forState:UIControlStateNormal];
        [_myLocationButton addTarget:self action:@selector(backToMyLocation) forControlEvents:UIControlEventTouchUpInside];
    }

    return _myLocationButton;
}

- (UIImageView *)annotationImageView {
    if (!_annotationImageView) {
        _annotationImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"map_location_annotation"]];
    }

    return _annotationImageView;
}

- (void)backToMyLocation {
    self.showLocation = NO;
    [self.mapView setRegion:myCurrentRegion animated:YES];
}

- (void)dealloc {
    self.mapView.delegate = nil;

    self.mapView = nil;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    // If it's a relatively recent event, turn off updates to save power.
    CLLocation *location = [locations lastObject];
    NSDate *eventDate = location.timestamp;
    NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
    if (ABS(howRecent) < 15.0) {
        // If the event is recent, do something with it.
        NSLog(@"latitude %+.6f, longitude %+.6f\n",
                location.coordinate.latitude,
                location.coordinate.longitude);
    }

}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {

}


#pragma mark - MKMapViewDelegate


- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    CLLocationCoordinate2D loc = [userLocation coordinate];

    self.location = loc;

    if (!self.geocoder) {
        self.geocoder = [[CLGeocoder alloc] init];
    }

    myCurrentRegion = MKCoordinateRegionMakeWithDistance(loc, 250, 250);

    if (self.showLocation) {
        return;
    }
    if (!self.hasLocationMyLocation) {
        [self.mapView setRegion:myCurrentRegion animated:YES];
        self.hasLocationMyLocation = YES;
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    CLLocationCoordinate2D location = [mapView convertPoint:self.annotationImageView.center toCoordinateFromView:self.view];
    self.location = location;

}

@end

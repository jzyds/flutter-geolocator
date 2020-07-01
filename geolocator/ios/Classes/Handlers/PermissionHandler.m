//
//  PermissionHandler.m
//  geolocator
//
//  Created by Maurits van Beusekom on 26/06/2020.
//

#import "PermissionHandler.h"
#import "../Constants/ErrorCodes.h"

@interface PermissionHandler() <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (copy, nonatomic) PermissionConfirmation confirmationHandler;
@property (copy, nonatomic) PermissionError errorHandler;

@end

@implementation PermissionHandler

+ (BOOL) hasPermission {
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            return YES;
        default:
            return NO;
    }
}

+ (BOOL) hasPermissionConfiguration {
    BOOL hasWhenInUseConfiguration = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"] != nil;
    BOOL hasAlwaysConfiguration = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"] != nil;
    
    return hasWhenInUseConfiguration || hasAlwaysConfiguration;
}

- (void) requestPermission:(PermissionConfirmation)confirmationHandler
              errorHandler:(PermissionError)errorHandler {
    // When we already have permission we don't have to request it again
    if ([PermissionHandler hasPermission]) {
        confirmationHandler([CLLocationManager authorizationStatus]);
        return;
    }
    
    if (self.confirmationHandler) {
        // Permission request is already running, return immediatly with error
        errorHandler(GeolocatorErrorPermissionRequestInProgress,
                     @"A request for location permissions is already running, please wait for it to finish before doing another request.");
        return;
    }
    
    self.confirmationHandler = confirmationHandler;
    self.errorHandler = errorHandler;
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationWhenInUseUsageDescription"] != nil) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    else if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSLocationAlwaysUsageDescription"] != nil) {
        [self.locationManager requestAlwaysAuthorization];
    }
    else {
        if (self.errorHandler) {
            self.errorHandler(GeolocatorErrorPermissionConfigMissing,
                              @"Permission definitions not found in the app's Info.plist. Please make sure to "
                               "add either NSLocationWhenInUseUsageDescription or "
                               "NSLocationAlwaysUsageDescription to the app's Info.plist file.");
        }
        
        [self cleanUp];
        return;
    }
}

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusNotDetermined) {
      return;
    }
    
    if (self.confirmationHandler) {
        self.confirmationHandler(status);
    }
    
    [self cleanUp];
}

- (void) cleanUp {
    self.locationManager = nil;
    self.errorHandler = nil;
    self.confirmationHandler = nil;
}
@end

#import "HealthHelper.h"

@implementation HealthHelper

/* Requests access for heart rate and steps */
-(void) getHealthPermissions{
    NSLog(@"Requesting health permissions...");
    
    if(NSClassFromString(@"HKHealthStore") && [HKHealthStore isHealthDataAvailable])
    {
        _healthStore = [[HKHealthStore alloc] init];
        
        NSSet *readObjectTypes  = [NSSet setWithObjects:
                                   [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate],
                                   [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount],
                                   nil];
        
        [_healthStore requestAuthorizationToShareTypes:nil
                                             readTypes:readObjectTypes
                                            completion:^(BOOL success, NSError *error) {
                                                
                                                if(success == YES)
                                                {
                                                    NSLog(@"Successfully got access.");
                                                }
                                                else
                                                {
                                                    NSLog(@"Unable to get authorization for health access.");
                                                }
                                            }];
    }

}


@end

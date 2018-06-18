#import <Foundation/Foundation.h>
@import HealthKit;

@interface HealthHelper : NSObject
@property HKHealthStore *healthStore;

-(void) getHealthPermissions;

@end

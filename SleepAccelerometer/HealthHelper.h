

#import <Foundation/Foundation.h>
@import HealthKit;

@protocol HealthHelperDelegate
- (void)returnQuery:(NSString*) vals;
@end

@interface HealthHelper : NSObject
@property HKHealthStore *healthStore;

-(void) getHealthPermissions;
@property(strong,nonatomic) NSString* values;
-(void) readAvailableDataFrom:(NSDate*) startDate to:(NSDate*)endDate withType:(HKSampleType*) sampleType;
-(void) readAvailableDataFrom:(NSDate*) startDate to:(NSDate*)endDate withType:(HKSampleType*) sampleType andAppendString:(NSMutableString*)tempValues;

@property (retain) id delegate;
@property(strong,nonatomic) NSMutableArray* rawHealthData;


@end

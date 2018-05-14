

#import "HealthHelper.h"

@implementation HealthHelper

-(void) getHealthPermissions{
    NSLog(@"Requesting health permissions...");
    
    if(NSClassFromString(@"HKHealthStore") && [HKHealthStore isHealthDataAvailable])
    {
        
        
        _healthStore = [[HKHealthStore alloc] init];
        
        NSSet *readObjectTypes  = [NSSet setWithObjects:
                                   [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate],
                                   [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount],
                                   nil];
        
        // Request access
        [_healthStore requestAuthorizationToShareTypes:nil
                                             readTypes:readObjectTypes
                                            completion:^(BOOL success, NSError *error) {
                                                
                                                if(success == YES)
                                                {
                                                    
                                                }
                                                else
                                                {

                                                }
                                                
                                            }];
    }
}


-(void) readAvailableDataFrom:(NSDate*) startDate to:(NSDate*)endDate withType:(HKSampleType*) sampleType andAppendString:(NSMutableString*)tempValues{
    
    _values = @"";
    _rawHealthData = [[NSMutableArray alloc] init];
    
    
    // HKSampleType *stepType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    // HKSampleType *heartRateType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    
    if(NSClassFromString(@"HKHealthStore") && [HKHealthStore isHealthDataAvailable])
    {
        _healthStore = [[HKHealthStore alloc] init];
        
        // Create a predicate to set start/end date bounds of the query
        NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
        
        // Create a sort descriptor for sorting by start date
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:YES];
        
        HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                                                     predicate:predicate
                                                                         limit:HKObjectQueryNoLimit
                                                               sortDescriptors:@[sortDescriptor]
                                                                resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                                                                    
                                                                    if(error){
                                                                        NSLog(@"%@,",error);
                                                                    }
                                                                    
                                                                    if(!error && results)
                                                                    {
                                                                        for(HKQuantitySample *samples in results)
                                                                        {
                                                                            NSArray *val = [samples.quantity.description componentsSeparatedByString:@" "];
                                                                            
                                                                            bool verbose = NO;
                                                                            if(verbose){
                                                                                [tempValues appendFormat:@"%@,%@,%@,%f,%f,%@,%@\n",samples.sampleType.description,samples.startDate.description,
                                                                                 samples.endDate.description,samples.startDate.timeIntervalSince1970,samples.endDate.timeIntervalSince1970,[val objectAtIndex:0],samples.device.model];
                                                                            }else{
                                                                                [tempValues appendFormat:@"%@,%f,%f,%@,%@\n",samples.sampleType.description,samples.startDate.timeIntervalSince1970,samples.endDate.timeIntervalSince1970,[val objectAtIndex:0],samples.device.model];
                                                                            }
                                                                        }
                                                                        
                                                                        if(sampleType ==  [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount]){
                                                                            [self readAvailableDataFrom:startDate to:endDate withType:[HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate] andAppendString:tempValues];
                                                                            
                                                                        }
                                                                        else{
                                                                            [self.delegate returnQuery:[NSString stringWithString:tempValues]];
                                                                            
                                                                        }
                                                                        
                                                                        
                                                                    }
                                                                    
                                                                }];
        
        
        // Execute the query
        [_healthStore executeQuery:sampleQuery];
        
    }
    
    
}


-(void) readAvailableDataFrom:(NSDate*) startDate to:(NSDate*)endDate withType:(HKSampleType*) sampleType{
    
    _values = @"";
    _rawHealthData = [[NSMutableArray alloc] init];
    
    
    if(NSClassFromString(@"HKHealthStore") && [HKHealthStore isHealthDataAvailable])
    {
        _healthStore = [[HKHealthStore alloc] init];
        
        // Create a predicate to set start/end date bounds of the query
        NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
        NSMutableString* tempValues = [[NSMutableString alloc] init];
        
        // Create a sort descriptor for sorting by start date
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:YES];
        
        HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                                                     predicate:predicate
                                                                         limit:HKObjectQueryNoLimit
                                                               sortDescriptors:@[sortDescriptor]
                                                                resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                                                                    
                                                                    if(error){
                                                                        NSLog(@"Error reading health data: %@,",error);
                                                                    }
                                                                    
                                                                    if(!error && results)
                                                                    {
                                                                        for(HKQuantitySample *samples in results)
                                                                        {
                                                                            NSArray *val = [samples.quantity.description componentsSeparatedByString:@" "];
                                                                            
                                                                            bool verbose = NO;
                                                                            if(verbose){
                                                                                [tempValues appendFormat:@"%@,%@,%@,%f,%f,%@,%@\n",samples.sampleType.description,samples.startDate.description,
                                                                                 samples.endDate.description,samples.startDate.timeIntervalSince1970,samples.endDate.timeIntervalSince1970,[val objectAtIndex:0],samples.device.model];
                                                                            }else{
                                                                                [tempValues appendFormat:@"%@,%f,%f,%@,%@\n",samples.sampleType.description,samples.startDate.timeIntervalSince1970,samples.endDate.timeIntervalSince1970,[val objectAtIndex:0],samples.device.model];
                                                                            }
                                                                            
                                                                            // type, start, end, value, model
                                                                            
                                                                        }
                                                                        
                                                                        
                                                                        [self.delegate returnQuery:[NSString stringWithString:tempValues]];
                                                                        
                                                                    }
                                                                    
                                                                }];
        
        
        // Execute the query
        [_healthStore executeQuery:sampleQuery];
        
    }
    
    
}


@end

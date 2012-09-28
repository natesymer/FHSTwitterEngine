//
//  NSMutableURLRequest+NSMutableURLRequest_sendSync.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 9/6/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "NSMutableURLRequest+NSMutableURLRequest_sendSync.h"

@implementation NSMutableURLRequest (NSMutableURLRequest_sendSync)

- (NSData *)sendSynchronousConnection {
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    
    NSData *responseData = [NSURLConnection sendSynchronousRequest:self returningResponse:&response error:&error];
    
    if (response == nil || responseData == nil || error != nil) {
        return nil;
    }
    
    return responseData;
}

@end

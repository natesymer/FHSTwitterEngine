//
//  NSURLRequest+FHSTE.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 7/24/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "NSURLRequest+FHSTE.h"
#import "FHSDefines.h"

@implementation NSURLRequest (FHSTE)

- (BOOL)isW3FormURLEncoded {
    if (![self.HTTPMethod isEqualToString:kPOST]) return NO;
    if (![self valueForHTTPHeaderField:@"Content-Type"]) return YES;
    if ([[self valueForHTTPHeaderField:@"Content-Type"]rangeOfString:kW3FormURLEncoded].location != NSNotFound) return YES;
    return NO;
}

- (NSDictionary *)postBodyDictionary {
    // Enforce content type
    if (![self isW3FormURLEncoded]) return @{};
    
    NSString *postBody = [[NSString alloc]initWithData:self.HTTPBody encoding:NSUTF8StringEncoding];
    NSArray *paramPairs = [postBody componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:paramPairs.count];
    
    for (NSString *param in paramPairs) {
        NSArray *parts = [param componentsSeparatedByString:@"="];
        if (parts.count < 2) continue;
        params[parts[0]] = parts[1];
    }
    
    return params;
}

@end

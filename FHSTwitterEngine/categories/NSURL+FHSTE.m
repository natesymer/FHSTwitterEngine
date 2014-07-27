//
//  NSURL+FHSTE.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/10/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "NSURL+FHSTE.h"

@implementation NSURL (FHSTwitterEngine)

- (NSURL *)URLWithoutQuery {
    return [[NSURL alloc]initWithScheme:self.scheme host:self.host path:self.path];
}

- (NSDictionary *)queryParameters {
    NSArray *paramPairs = [self.query componentsSeparatedByString:@"&"];
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:paramPairs.count];
    
    for (NSString *param in paramPairs) {
        NSArray *parts = [param componentsSeparatedByString:@"="];
        if (parts.count < 2) continue;
        params[parts[0]] = parts[1];
    }
    
    return params;
}

@end

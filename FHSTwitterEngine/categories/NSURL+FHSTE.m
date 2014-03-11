//
//  NSURL+FHSTE.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/10/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "NSURL+FHSTE.h"

@implementation NSURL (FHSTwitterEngine)

- (NSString *)absoluteStringWithoutParameters {
    if (self.absoluteString.length == 0) {
        return nil;
    }
    
    NSArray *parts = [self.absoluteString componentsSeparatedByString:@"?"];
    return (parts.count == 0)?nil:parts[0];
}

@end

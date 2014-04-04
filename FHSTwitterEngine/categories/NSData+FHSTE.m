//
//  NSData+FHSTE.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/10/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "NSData+FHSTE.h"

@implementation NSData (FHSTwitterEngine)

- (NSString *)appropriateFileExtension {
    uint8_t c;
    [self getBytes:&c length:1];
    
    switch (c) {
        case 0xFF:
            return @"jpeg";
        case 0x89:
            return @"png";
        case 0x47:
            return @"gif";
        case 0x49:
        case 0x4D:
            return @"tiff";
        default:
            return nil;
    }
}

- (NSString *)base64Encode {
    if ([self respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
        return [self base64EncodedStringWithOptions:0];
    } else {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
        return [self base64Encoding];
#pragma GCC diagnostic pop
    }
}

@end

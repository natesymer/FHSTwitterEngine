//
//  NSString+FHSTE.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/10/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "NSString+FHSTE.h"

@implementation NSString (FHSTwitterEngine)

- (NSString *)fhs_URLEncode {
    CFStringRef url = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)self, NULL, CFSTR("!*'();:@&=+$,/?%#[]"), kCFStringEncodingUTF8);
	return (__bridge_transfer NSString *)url;
}

- (NSString *)fhs_truncatedToLength:(int)length {
    return [self substringToIndex:MIN(length, self.length)];
}

- (NSString *)fhs_trimForTwitter {
    return [self fhs_truncatedToLength:140];
}

- (NSString *)fhs_stringWithRange:(NSRange)range {
    return [[self substringFromIndex:range.location]substringToIndex:range.length];
}

+ (NSString *)fhs_UUID {
    if ([[[UIDevice currentDevice]systemVersion]floatValue] >= 6.0f) {
        return [[NSUUID UUID]UUIDString];
    } else {
        CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
        CFStringRef string = CFUUIDCreateString(kCFAllocatorDefault, theUUID);
        CFRelease(theUUID);
        return [NSString stringWithString:(__bridge_transfer NSString *)string];
    }
}

- (BOOL)fhs_isNumeric {
	const char *raw = self.UTF8String;
    
    unsigned long length = strlen(raw);
    
	for (int i = 0; i < length; i++) {
        char current_char = raw[i];
		if (current_char < '0' || current_char > '9') {
            return NO;
        }
	}
	return YES;
}

@end

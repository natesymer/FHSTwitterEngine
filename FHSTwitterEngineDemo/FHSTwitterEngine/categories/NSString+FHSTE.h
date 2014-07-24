//
//  NSString+FHSTE.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/10/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (FHSTwitterEngine)
+ (NSString *)fhs_UUID;
- (NSString *)fhs_URLEncode;
- (NSString *)fhs_truncatedToLength:(int)length;
- (NSString *)fhs_stringWithRange:(NSRange)range;
- (BOOL)fhs_isNumeric;
@end

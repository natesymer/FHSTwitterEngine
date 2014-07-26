//
//  StreamParser.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 7/25/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StreamParser : NSObject

+ (BOOL)startsAbruptly:(NSData *)data;
+ (BOOL)endsAbruptly:(NSData *)data;

+ (NSArray *)parseStreamData:(NSData *)data;

@end

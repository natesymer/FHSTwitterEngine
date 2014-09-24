//
//  FHSStream+Parsing.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 9/24/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "FHSStream.h"

@interface FHSStream (Parsing)

+ (NSArray *)parseStreamData:(NSData *)data;
+ (NSArray *)parseStreamData:(NSData *)data leftoverData:(NSData **)leftoverData;
+ (NSArray *)parseStreamData:(char *)chars length:(size_t)length leftoverData:(char **)leftoverData leftoverSize:(size_t *)leftoverSize;

@end

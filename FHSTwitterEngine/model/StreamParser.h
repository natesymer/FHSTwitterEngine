//
//  StreamParser.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 7/25/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StreamParser : NSObject

+ (NSArray *)parseStreamData:(NSData *)data;

@end

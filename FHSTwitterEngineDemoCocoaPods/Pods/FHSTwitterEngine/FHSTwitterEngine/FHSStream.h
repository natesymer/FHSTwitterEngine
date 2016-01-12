//
//  FHSStream.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/9/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FHSTwitterEngine.h"

/** Stream. */
@interface FHSStream : NSObject

/**
 Stream block.
 */
@property (nonatomic, copy) StreamBlock block;

/**
 Stream with URL.
 @param url Stream URL.
 @param httpMethod HTTP method.
 @param params Parameters.
 @param timeout Time out value.
 @param block StreamBlock block.
 @return A stream instance.
 */
+ (FHSStream *)streamWithURL:(NSString *)url httpMethod:(NSString *)httpMethod parameters:(NSDictionary *)params timeout:(float)timeout block:(StreamBlock)block;

/**
 Start stream.
 */
- (void)stop;

/**
 Stop stream.
 */
- (void)start;

@end

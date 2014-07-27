//
//  FHSStream.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/9/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FHSTwitterEngine.h"

#define kFHSTwitterEngineRepairSplitMessages 1

@interface FHSStream : NSObject

@property (nonatomic, copy) StreamBlock block;

+ (FHSStream *)streamWithURL:(NSURL *)url httpMethod:(NSString *)httpMethod parameters:(NSDictionary *)params timeout:(float)timeout block:(StreamBlock)block;
- (instancetype)initWithURL:(NSURL *)url httpMethod:(NSString *)httpMethod parameters:(NSDictionary *)params timeout:(float)timeout block:(StreamBlock)block;

- (void)stop;
- (void)start;

// check out the streaming parameters here:
// https://dev.twitter.com/docs/streaming-apis/parameters

// This makes sure all track keywords are valid
+ (NSString *)sanitizeTrackParameter:(NSArray *)keywords;

@property (strong, readonly) NSURL *url;
@property (strong, readonly) NSString *HTTPMethod;
@property (strong, readonly) NSDictionary *parameters;
@property (readonly) float timeout;
@property (readonly) BOOL isActive;

@end

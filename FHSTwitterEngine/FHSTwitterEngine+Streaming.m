//
//  FHSTwitterEngine+Streaming.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 7/27/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "FHSTwitterEngine+Streaming.h"
#import "FHSStream.h"
#import <objc/runtime.h>

static char * const kActiveStreamsKey = "kActiveStreamsKey";

@implementation FHSTwitterEngine (Streaming)

- (NSMutableArray *)activeStreams {
    NSMutableArray *as = objc_getAssociatedObject(self, kActiveStreamsKey);
    if (!as) {
        as = [NSMutableArray array];
        objc_setAssociatedObject(self, kActiveStreamsKey, as, OBJC_ASSOCIATION_RETAIN);
    }
    return as;
}

- (void)setActiveStreams:(NSMutableArray *)as {
    objc_setAssociatedObject(self, kActiveStreamsKey, as, OBJC_ASSOCIATION_RETAIN);
}

- (void)streamURL:(NSURL *)url httpMethod:(NSString *)httpMethod params:(NSDictionary *)params block:(id)block {
    FHSStream *stream = [FHSStream streamWithURL:url httpMethod:kPOST parameters:params timeout:streamingTimeoutInterval block:block];
    [self.activeStreams addObject:stream];
    [stream start];
}

- (void)stopAllStreaming {
    [self.activeStreams makeObjectsPerformSelector:@selector(stop)];
    [self.activeStreams removeAllObjects];
}

@end

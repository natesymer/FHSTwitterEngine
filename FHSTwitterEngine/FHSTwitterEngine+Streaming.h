//
//  FHSTwitterEngine+Streaming.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 7/27/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "FHSTwitterEngine.h"

@interface FHSTwitterEngine (Streaming)

- (void)streamURL:(NSURL *)url httpMethod:(NSString *)httpMethod params:(NSDictionary *)params block:(id)block;
- (void)stopAllStreaming;

@end

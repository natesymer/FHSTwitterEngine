//
//  FHSStream.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/9/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FHSStream;

typedef void(^StreamBlock)(id result, BOOL *stop);

@interface FHSStream : NSObject

@property (nonatomic, assign) float timeout;
@property (nonatomic, copy) StreamBlock block;

+ (FHSStream *)streamWithURL:(NSString *)url httpMethod:(NSString *)httpMethod parameters:(NSDictionary *)params timeout:(float)timeout block:(StreamBlock)block;

- (void)stop;
- (void)start;

@end

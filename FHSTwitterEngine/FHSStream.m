//
//  FHSStream.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/9/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "FHSStream.h"
#import "FHSTwitterEngine.h"

@interface FHSTwitterEngine (Streaming)



@end

@interface FHSStream () <NSURLConnectionDelegate>

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableDictionary *params;
@property (nonatomic, strong) NSString *URL;

@end

@implementation FHSStream

+ (FHSStream *)streamWithURL:(NSString *)url httpMethod:(NSString *)httpMethod parameters:(NSDictionary *)params timeout:(float)timeout block:(StreamBlock)block {
    return [[[self class]alloc]initWithURL:url httpMethod:httpMethod parameters:params timeout:timeout block:block];
}

- (instancetype)initWithURL:(NSString *)url httpMethod:(NSString *)httpMethod parameters:(NSDictionary *)params timeout:(float)timeout block:(StreamBlock)block {
    self = [super init];
    if (self) {
        self.URL = url;
        self.params = params.mutableCopy;
        _params[@"delimited"] = @"length";
        self.block = block;
        id req = [[FHSTwitterEngine sharedEngine]streamingRequestForURL:[NSURL URLWithString:url] HTTPMethod:httpMethod parameters:params];
        
        if ([req isKindOfClass:[NSURLRequest class]]) {
            self.connection = [[NSURLConnection alloc]initWithRequest:req delegate:self startImmediately:NO];
        }
    }
    return self;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    _block(error, NO);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    int bytesExpected = 0;
    NSMutableString *message = nil;
    
    NSString *response = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    for (NSString *part in [response componentsSeparatedByString:@"\r\n"]) {
        int length = [part intValue];
        
        if (length > 0) {
            message = [NSMutableString string];
            bytesExpected = length;
        } else if (bytesExpected > 0 && message) {
            if (message.length < bytesExpected) {
                [message appendString:part];
                
                if (message.length < bytesExpected) {
                    [message appendString:@"\r\n"];
                }
                
                if (message.length == bytesExpected) {
                    NSError *jsonError = nil;
                    id json = [NSJSONSerialization JSONObjectWithData:[message dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&jsonError];
                    
                    BOOL stop = NO;
                    
                    if (!jsonError) {
                        _block(json, &stop);
                        [self keepAlive];
                    } else {
                        NSError *error = [NSError errorWithDomain:FHSErrorDomain code:406 userInfo:@{
                                                                                    NSUnderlyingErrorKey: jsonError,
                                                                                    NSLocalizedDescriptionKey: @"Invalid JSON was returned from Twitter",
                                                                                    @"json": json
                                                                                    }];
                        _block(error, &stop);
                    }
                    
                    if (stop) {
                        [self stop];
                    }

                    message = nil;
                    bytesExpected = 0;
                }
            }
        } else {
            [self keepAlive];
        }
    }
}

- (void)keepAlive {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stop) object:nil];
}

- (void)stop {
    [_connection cancel];
    [_connection unscheduleFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    self.connection = nil;
}

- (void)start {
    [_connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [_connection start];
    [self performSelector:@selector(stop) withObject:nil afterDelay:_timeout];
}

@end
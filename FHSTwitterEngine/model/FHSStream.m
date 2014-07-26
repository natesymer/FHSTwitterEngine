//
//  FHSStream.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/9/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "FHSStream.h"
#import "FHSTwitterEngine+Requests.h"
#import "NSError+FHSTE.h"
#import "StreamParser.h"

@interface FHSStream () <NSURLConnectionDelegate,NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *buffer;

@end

@implementation FHSStream

+ (instancetype)streamWithURL:(NSURL *)url httpMethod:(NSString *)httpMethod parameters:(NSDictionary *)params timeout:(float)timeout block:(StreamBlock)block {
    return [[[self class]alloc]initWithURL:url httpMethod:httpMethod parameters:params timeout:timeout block:block];
}

- (instancetype)initWithURL:(NSURL *)url httpMethod:(NSString *)httpMethod parameters:(NSDictionary *)params timeout:(float)timeout block:(StreamBlock)block {
    self = [super init];
    if (self) {
        _timeout = timeout;
        _url = url;
        _HTTPMethod = httpMethod;
        
        if (!params) {
            _parameters = @{
                            @"delimited": @"length", // This should never be changed.
                            @"stall_warnings": @"true"
                            };
        } else {
            _parameters = [NSDictionary dictionaryWithDictionary:params];
        }
        
        _block = block;
        _buffer = [NSMutableData data];
    }
    return self;
}

- (NSURLRequest *)request {
    NSMutableURLRequest *request = [FHSTwitterEngine.shared requestWithURL:_url HTTPMethod:_HTTPMethod params:_parameters];
    request.timeoutInterval = MAXFLOAT; // Disable timeout
    return request;
}

#pragma mark - NSURLConnection

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    
    BOOL stop = NO;
    
    if (_block) {
        _block(error, &stop);
    }
    
    if (stop) {
        [self stop];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
#if kFHSTwitterEngineRepairSplitMessages == 1
    
    NSData *saneData;
    
    if (_buffer.length > 0) {
        [_buffer appendData:data];
        saneData = _buffer;
    } else {
        saneData = data;
    }
#else
    NSData *saneData = data;
#endif
    
    NSData *leftover;
    NSArray *messages = [StreamParser parseStreamData:saneData leftoverData:&leftover];
    
#if kFHSTwitterEngineRepairSplitMessages == 1
    
    [_buffer setLength:0];
    
    if (leftover.length > 0) {
        [_buffer appendData:leftover];
    }

#endif
    
    for (NSData *message in messages) {
        BOOL stop = NO;
        
        id json = [NSJSONSerialization JSONObjectWithData:message options:NSJSONReadingMutableContainers error:0];
        if (_block) _block(json, &stop);
        
        if (stop) {
            [self stop];
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
    self.connection = [NSURLConnection connectionWithRequest:self.request delegate:self];
    [self performSelector:@selector(stop) withObject:nil afterDelay:_timeout];
}

+ (NSString *)sanitizeTrackParameter:(NSArray *)keywords {
    NSMutableArray *sanitized = [NSMutableArray arrayWithCapacity:keywords.count];
    
    for (NSString *string in keywords) {
        [sanitized addObject:[string fhs_truncatedToLength:60]];
    }
    
    return [sanitized componentsJoinedByString:@","];
}

@end

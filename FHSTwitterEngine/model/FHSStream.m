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

@interface FHSStream () <NSURLConnectionDelegate>

@property (nonatomic, strong) NSURLConnection *connection;

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
        
        self.block = block;
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
// Stream Format:
// <length>\n<length-1 characters>

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    NSArray *messages = [StreamParser parseStreamData:data];
    
    for (NSData *message in messages) {
        BOOL stop = NO;
        NSLog(@"message: %@",message);
        if (_block) _block([NSJSONSerialization JSONObjectWithData:message options:NSJSONReadingMutableContainers error:0], &stop);
        
        if (stop) {
            [self stop];
        }
    }
    
    /*int bytesExpected = 0;
    NSMutableString *message = nil;
    
    NSLog(@"%@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);

    NSString *response = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];

    for (NSString *part in [response componentsSeparatedByString:@"\r\n"]) {
        int length = [part intValue];

        if (length > 0) {
            message = [NSMutableString string];
            bytesExpected = length;
        }
        
        if (bytesExpected > 0 && message) {
            NSRange rangeOfCount = [message rangeOfString:@(bytesExpected).stringValue];
            if (rangeOfCount.location == 0) {
                message = [message substringFromIndex:rangeOfCount.length].mutableCopy;
            }
            
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
                        if (_block) {
                            _block(json, &stop);
                        }
                        [self keepAlive];
                    } else {
                        NSError *error = [NSError errorWithDomain:FHSErrorDomain code:406 userInfo:@{ NSUnderlyingErrorKey: jsonError, NSLocalizedDescriptionKey: @"Invalid JSON was returned from Twitter", @"json": json }];
                        if (_block) {
                            _block(error, &stop);
                        }
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
    }*/
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

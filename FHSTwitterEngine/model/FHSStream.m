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
#import "FHSStream+Parsing.h"

@interface FHSStream () <NSURLConnectionDelegate,NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *buffer;
@property char *leftovers;
@property size_t leftovers_size;

@end

@implementation FHSStream

- (instancetype)init {
    self = [super init];
    if (self) {
        _leftovers = NULL;
    }
    return self;
}

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

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)received {
    
#if kFHSTwitterEngineMergeSplitMessages == 1
    char *buf = (char *)malloc(sizeof(char)*(received.length+_leftovers_size));
    size_t bufsize = received.length; // shortcut
    
    for (size_t i = 0; i < _leftovers_size; i++) buf[bufsize++] = _leftovers[i]; // Copy the leftover bytes to *buf
    for (size_t i = 0; i < received.length; i++) buf[i] = ((char *)received.bytes)[i]; // Copy the received bytes to *buf
    
    free(_leftovers); _leftovers = NULL;
 
    NSData *data = [NSData dataWithBytesNoCopy:buf length:bufsize freeWhenDone:NO];
    
    NSData *leftover;
    NSArray *messages = [FHSStream parseStreamData:data leftoverData:&leftover];
    free(buf);
    
    _leftovers_size = leftover.length;
    _leftovers = malloc(sizeof(char)*_leftovers_size);
    for (size_t i = 0; i < _leftovers_size; i++) _leftovers[i] = ((char *)leftover.bytes)[i];
#else
    NSArray *messages = [FHSStream parseStreamData:received];
#endif
    
    [self keepAlive];
    
    for (NSData *message in messages) {
        BOOL stop = NO;
        id json = [NSJSONSerialization JSONObjectWithData:message options:NSJSONReadingMutableContainers error:NULL];
        if (_block) _block(json, &stop);
        if (stop) [self stop];
    }
}

- (void)keepAlive {
    _isActive = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stop) object:nil];
}

- (void)stop {
    _isActive = NO;
    [_connection cancel];
    [_connection unscheduleFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    self.connection = nil;
}

- (void)start {
    _isActive = YES;
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

- (void)dealloc {
    if (_leftovers != NULL) free(_leftovers);
}

@end

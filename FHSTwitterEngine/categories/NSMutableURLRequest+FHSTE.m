//
//  NSMutableURLRequest+FHSTE.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 7/25/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "NSMutableURLRequest+FHSTE.h"
#import "NSString+FHSTE.h"
#import "NSURL+FHSTE.h"

@implementation NSMutableURLRequest (FHSTE)

#pragma mark - Request Generation

+ (NSMutableURLRequest *)defaultRequestWithURL:(NSURL *)url {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPShouldHandleCookies = NO;
    request.cachePolicy = NSURLRequestReloadRevalidatingCacheData;
    request.timeoutInterval = 30.0f;
    return request;
}

+ (NSMutableURLRequest *)GETRequestWithURL:(NSURL *)url params:(NSDictionary *)params {
    NSMutableArray *paramPairs = [NSMutableArray arrayWithCapacity:params.count];
    
    [params enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        NSString *paramPair = [NSString stringWithFormat:@"%@=%@",key.fhs_URLEncode,obj.fhs_URLEncode];
        [paramPairs addObject:paramPair];
    }];
    
    NSURL *parameterizedURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",url.absoluteStringWithoutParameters, [paramPairs componentsJoinedByString:@"&"]]];
    
    return [self defaultRequestWithURL:parameterizedURL];
}

// application/x-www-form-urlencoded
+ (NSMutableURLRequest *)formURLEncodedPOSTRequestWithURL:(NSURL *)url params:(NSDictionary *)params {
    NSMutableURLRequest *request = [NSMutableURLRequest defaultRequestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    if (params.count > 0) {
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        
        NSMutableArray *pairs = [NSMutableArray arrayWithCapacity:params.count];
        
        [params enumerateKeysAndObjectsUsingBlock:^(NSString *k, NSString *v, BOOL *stop) {
            [pairs addObject:[NSString stringWithFormat:@"%@=%@",k,v]];
        }];
        
        request.HTTPBody = [[pairs componentsJoinedByString:@"&"]dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    return request;
}

+ (NSMutableURLRequest *)multipartPOSTRequestWithURL:(NSURL *)url params:(NSDictionary *)params {
    NSMutableURLRequest *r = [NSMutableURLRequest defaultRequestWithURL:url];
    [r setHTTPMethod:@"POST"];
    NSString *boundary = [NSString fhs_UUID];
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [r addValue:contentType forHTTPHeaderField:@"Content-Type"];
    
    r.HTTPBody = [self POSTBodyWithParams:params boundary:boundary];
    [r setValue:@(r.HTTPBody.length).stringValue forHTTPHeaderField:@"Content-Length"];
    
    return r;
}

#pragma mark - Multipart POST Body Generation

// It's O(n^2), but SUPER readable and maintainable.
+ (NSData *)POSTBodyWithParams:(NSDictionary *)params boundary:(NSString *)boundary {
    NSMutableArray *lines = [NSMutableArray array];
    
    //
    // Generate each line (NSData or NSString)
    //
    
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [lines addObject:[NSString stringWithFormat:@"--%@",boundary]];
        
        id payload = nil;
        
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dict = (NSDictionary *)obj;
            
            if ([dict[@"type"]isEqualToString:@"file"]) {
                [lines addObject:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"",key,dict[@"filename"]]];
                [lines addObject:[NSString stringWithFormat:@"Content-Type: %@",dict[@"mimetype"] ?: @"application/octet-stream"]];
                [lines addObject:@"Content-Transfer-Encoding: binary"];
                payload = dict[@"data"];
            }
        } else {
            [lines addObject:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"",key]];
            
            if ([obj isKindOfClass:[UIImage class]]) {
                [lines addObject:@"Content-Type: image/png"];
                payload = UIImagePNGRepresentation(obj);
            } else if ([obj isKindOfClass:[NSData class]]) {
                [lines addObject:@"Content-Type: application/octet-stream"];
                payload = (NSData *)obj;
            } else if ([obj isKindOfClass:[NSString class]]) {
                payload = (NSString *)obj;
            }
        }
        
        [lines addObject:@""];
        [lines addObject:payload];
    }];
    
    [lines addObject:[NSString stringWithFormat:@"--%@--",boundary]];
    [lines addObject:@""];
    
    //
    // Concat the lines into a giant NSData
    //
    
    NSData *crlf = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableData *d = [NSMutableData data];
    
    for (id obj in lines) {
        if ([obj isKindOfClass:[NSData class]]) {
            [d appendData:obj];
        } else if ([obj isKindOfClass:[NSString class]]) {
            [d appendData:[obj dataUsingEncoding:NSUTF8StringEncoding]];
        }
        [d appendData:crlf];
    }
    
    return d;
}

@end

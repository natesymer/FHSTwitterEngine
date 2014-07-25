//
//  FHSTwitterEngine+Requests.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/10/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "FHSTwitterEngine+Requests.h"
#import "NSMutableURLRequest+OAuth.h"

@implementation FHSTwitterEngine (Requests)

#pragma mark - Checks

- (NSError *)checkAuth {
    if (![self isAuthorized]) {
        [self loadAccessToken];
        if (![self isAuthorized]) {
            return [NSError errorWithDomain:FHSErrorDomain code:401 userInfo:@{NSLocalizedDescriptionKey:@"You are not authorized via OAuth."}];
        }
    }
    return nil;
}

- (NSError *)checkError:(id)json {
    if ([json isKindOfClass:[NSDictionary class]]) {
        NSArray *errors = json[@"errors"];
        if (errors.count > 0) return [NSError errorWithErrors:errors];
    }
    return nil;
}

#pragma mark - OAuth Signing

- (void)signRequest:(NSMutableURLRequest *)request {
    [self signRequest:request withToken:self.accessToken.key tokenSecret:self.accessToken.secret verifier:nil realm:nil];
}

- (void)signRequest:(NSMutableURLRequest *)request withToken:(NSString *)token tokenSecret:(NSString *)tokenSecret verifier:(NSString *)verifier realm:(NSString *)realm {
    [request signWithToken:self.accessToken.key tokenSecret:self.accessToken.secret verifier:verifier consumerKey:self.consumerKey consumerSecret:self.consumerSecret realm:realm];
}

#pragma mark - Request Generation

- (NSMutableURLRequest *)requestWithURL:(NSURL *)url HTTPMethod:(NSString *)httpMethod params:(NSDictionary *)params {
    NSMutableURLRequest *request = nil;
    
    if ([httpMethod isEqualToString:kPOST]) {
        
        __block BOOL requiresMultipart = NO;
        [params enumerateKeysAndObjectsUsingBlock:^(NSString *k, id v, BOOL *stop) {
            if (![v isKindOfClass:[NSString class]]) {
                requiresMultipart = YES;
                *stop = YES;
            }
        }];
        
        if (requiresMultipart) request = [NSMutableURLRequest multipartPOSTRequestWithURL:url params:params];
        else request = [NSMutableURLRequest formURLEncodedPOSTRequestWithURL:url params:params];
    } else if ([httpMethod isEqualToString:kGET]) {
        request = [NSMutableURLRequest GETRequestWithURL:url params:params];
    }
    
    [self signRequest:request];
    
    return request;
}

- (id)streamingRequestForURL:(NSURL *)url HTTPMethod:(NSString *)method parameters:(NSDictionary *)params {
    NSError *authError = [self checkAuth];
    if (authError) return authError;
    
    NSMutableURLRequest *request = [self requestWithURL:url HTTPMethod:method params:params];
    request.timeoutInterval = MAXFLOAT; // Disable timeout
    return request;
}

#pragma mark - Request Sending

- (id)sendRequestWithHTTPMethod:(NSString *)httpmethod URL:(NSURL *)url params:(NSDictionary *)params {
    NSError *authError = [self checkAuth];
    if (authError) return authError;
    
    NSMutableURLRequest *request = [self requestWithURL:url HTTPMethod:httpmethod params:params];
    
    id res = [self sendRequest:request];
    
    if (!res) return [NSError noDataError];
    if ([res isKindOfClass:[NSError class]]) return res;
    
    id parsed = [[NSJSONSerialization JSONObjectWithData:(NSData *)res options:NSJSONReadingMutableContainers error:nil]removeNull];
    
    NSError *error = [self checkError:parsed];
    if (error) return error;
    
    return parsed;
}

- (id)sendRequest:(NSURLRequest *)request {
    [self clearConsumerIfNecessary];
    
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (error) return error;
    if (!response) return error;
    if (response.statusCode >= 304) return error;
    if (data.length == 0) return error;
    
    return data;
}

@end

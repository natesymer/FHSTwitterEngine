//
//  FHSTwitterEngine+Auth.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/10/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "FHSTwitterEngine+Auth.h"
#import "NSError+FHSTE.h"
#import "FHSTwitterEngine+Requests.h"
#import "FHSTwitterEngine.m"

@implementation FHSTwitterEngine (Auth)

//
// OAuth
//

- (id)getRequestToken {
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    [request setHTTPMethod:@"POST"];
    [request setHTTPShouldHandleCookies:NO];
    [self signRequest:request withToken:nil tokenSecret:nil verifier:nil];
    
    id retobj = [self sendRequest:request];
    
    if ([retobj isKindOfClass:[NSData class]]) {
        return [[NSString alloc]initWithData:(NSData *)retobj encoding:NSUTF8StringEncoding];
    }
    
    return retobj;
}

- (BOOL)finishAuthWithRequestToken:(FHSToken *)reqToken {
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    [request setHTTPMethod:@"POST"];
    [request setHTTPShouldHandleCookies:NO];
    [self signRequest:request withToken:reqToken.key tokenSecret:reqToken.secret verifier:reqToken.verifier];
    
    if (_shouldClearConsumer) {
        self.shouldClearConsumer = NO;
        self.consumer = nil;
    }
    
    id retobj = [self sendRequest:request];
    
    if ([retobj isKindOfClass:[NSError class]]) {
        return NO;
    }
    
    NSString *response = [[NSString alloc]initWithData:(NSData *)retobj encoding:NSUTF8StringEncoding];
    
    if (response.length == 0) {
        return NO;
    }
    
    [self storeAccessToken:response];
    
    return YES;
}

//
// XAuth
//

- (NSError *)authenticateWithUsername:(NSString *)username password:(NSString *)password {
    if (password.length == 0) {
        return [NSError badRequestError];
    } else if (username.length == 0) {
        return [NSError badRequestError];
    }
    
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    [request setHTTPMethod:@"POST"];
    [request setHTTPShouldHandleCookies:NO];
    [self signRequest:request withToken:nil tokenSecret:nil verifier:nil];
    
    // generate the POST body...
    
    NSString *bodyString = [NSString stringWithFormat:@"x_auth_mode=client_auth&x_auth_username=%@&x_auth_password=%@",username,password];
    request.HTTPBody = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    
    if (_shouldClearConsumer) {
        self.shouldClearConsumer = NO;
        self.consumer = nil;
    }
    
    id ret = [self sendRequest:request];
    
    if ([ret isKindOfClass:[NSError class]]) {
        return ret;
    } else if ([ret isKindOfClass:[NSData class]]) {
        NSString *httpBody = [[NSString alloc]initWithData:(NSData *)ret encoding:NSUTF8StringEncoding];
        
        if (httpBody.length > 0) {
            [self storeAccessToken:httpBody];
        } else {
            return [NSError errorWithDomain:FHSErrorDomain code:422 userInfo:@{NSLocalizedDescriptionKey:@"The request was well-formed but was unable to be followed due to semantic errors.", @"request":request}];
        }
    }
    
    return nil;
}

@end

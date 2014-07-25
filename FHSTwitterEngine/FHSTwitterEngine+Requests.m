//
//  FHSTwitterEngine+Requests.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/10/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "FHSTwitterEngine+Requests.h"
#import <CommonCrypto/CommonHMAC.h>

@implementation FHSTwitterEngine (Requests)

#pragma mark - Checking

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

- (NSString *)OAuthHeaderForRequest:(NSURLRequest *)request token:(NSString *)token tokenSecret:(NSString *)tokenSecret verifier:(NSString *)verifier realm:(NSString *)realm {
    
    // OAuth Spec, Section 9.1.1 "Normalize Request Parameters"
    //
    // Build a query-style string containing the URL query, POST params
    // (if Content-Type is application/x-www-form-urlencoded), and OAuth header params.
    
    // Gather OAuth params
    NSMutableDictionary *oauth = @{
                                   @"oauth_consumer_key": self.consumerKey.fhs_URLEncode,
                                   @"oauth_signature_method": @"HMAC-SHA1",
                                   @"oauth_timestamp": @(time(nil)).stringValue,
                                   @"oauth_nonce": [NSString fhs_UUID],
                                   @"oauth_version": @"1.0a"
                                   }.mutableCopy;
    
    // Determine if this request is for a request token
    if (token.length > 0) {
        oauth[@"oauth_token"] = token.fhs_URLEncode;
        if (verifier.length > 0) oauth[@"oauth_verifier"] = verifier.fhs_URLEncode;
    } else {
        // The oauth_callback should only be set for a "Request Token" request.
        // Such requests shouldn't have a POST body.
        // If you have a better idea, contact us at @natesymer or @dkhamsing
        if (request.HTTPBody.length == 0) oauth[@"oauth_callback"] = @"oob";
    }
    
    // Put all params into one hash
    NSMutableDictionary *requestParameters = [NSMutableDictionary dictionary];
    [requestParameters addEntriesFromDictionary:oauth]; // OAuth headers
    if ([request.HTTPMethod isEqualToString:kGET]) [requestParameters addEntriesFromDictionary:request.URL.queryDictionary]; // GET query params (already encoded)
    if (request.isW3FormURLEncoded) [requestParameters addEntriesFromDictionary:request.postBodyDictionary]; // x-www-form-urlencoded POST params (already encoded)
    
    // Make parameter pairs
    NSMutableArray *paramPairs = [NSMutableArray arrayWithCapacity:requestParameters.count];
    
    [requestParameters enumerateKeysAndObjectsUsingBlock:^(NSString *k, NSString *v, BOOL *stop) {
        NSString *pair = [NSString stringWithFormat:@"%@=%@",k,v];
        [paramPairs addObject:pair];
    }];
    
    [paramPairs sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    NSString *normalizedRequestParameters = [paramPairs componentsJoinedByString:@"&"].fhs_URLEncode;
    
    // Realm isn't to be included in the Normalized Request Parameters
    // That's why it's down here
    if (realm.length > 0) oauth[@"oauth_realm"] = realm;
    
    
    // OAuth Spec, 9.1.2 "Construct Request URL"
    //
    // Remove parameters, lowercase, URLEncode
    NSString *requestURL = request.URL.absoluteStringWithoutParameters.lowercaseString.fhs_URLEncode;
    
    
    // OAuth Spec, Section 9.1.3 "Concatenate Request Elements"
    //
    // Sign request elements using HMAC-SHA1
    NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@",request.HTTPMethod,requestURL,normalizedRequestParameters];
    NSString *secret = [NSString stringWithFormat:@"%@&%@",self.consumerSecret.fhs_URLEncode,tokenSecret.fhs_URLEncode ?: @""];
    
    NSData *secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
    NSData *clearTextData = [signatureBaseString dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[20];
	CCHmac(kCCHmacAlgSHA1, secretData.bytes, secretData.length, clearTextData.bytes, clearTextData.length, result);
    
    oauth[@"oauth_signature"] = [[NSData dataWithBytes:result length:20]base64Encode];
    
    NSMutableArray *oauthPairs = [NSMutableArray arrayWithCapacity:oauth.count];
    
    [oauth enumerateKeysAndObjectsUsingBlock:^(NSString *k, NSString *v, BOOL *stop) {
        NSString *pair = [NSString stringWithFormat:@"%@=\"%@\"",k, v.fhs_URLEncode];
        [oauthPairs addObject:pair];
    }];
    
    [oauthPairs sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    return [NSString stringWithFormat:@"OAuth %@",[oauthPairs componentsJoinedByString:@","]];
}

- (void)signRequest:(NSMutableURLRequest *)request {
    [self signRequest:request withToken:self.accessToken.key tokenSecret:self.accessToken.secret verifier:nil realm:nil];
}

- (void)signRequest:(NSMutableURLRequest *)request withToken:(NSString *)token tokenSecret:(NSString *)tokenSecret verifier:(NSString *)verifier realm:(NSString *)realm {
    NSString *oauthHeader = [self OAuthHeaderForRequest:request token:token tokenSecret:tokenSecret verifier:verifier realm:realm];
    [request setValue:oauthHeader forHTTPHeaderField:@"Authorization"];
}

#pragma mark - Parameter Handling

- (void)appendGETParams:(NSDictionary *)params toURL:(NSURL **)url {
    if (params.count > 0) {
        NSMutableArray *paramPairs = [NSMutableArray arrayWithCapacity:params.count];
        
        [params enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
            NSString *paramPair = [NSString stringWithFormat:@"%@=%@",key.fhs_URLEncode,obj.fhs_URLEncode];
            [paramPairs addObject:paramPair];
        }];
        
        *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",(*url).absoluteStringWithoutParameters, [paramPairs componentsJoinedByString:@"&"]]];
    }
}

// It's O(n^2), but SUPER readable and maintainable.
- (NSData *)POSTBodyWithParams:(NSDictionary *)params boundary:(NSString *)boundary {
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

#pragma mark - Request Generation
// application/x-www-form-urlencoded
- (NSMutableURLRequest *)formURLEncodedPOSTRequestWithURL:(NSURL *)url params:(NSDictionary *)params {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:cachePolicy timeoutInterval:30.0f];
    [request setHTTPMethod:kPOST];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    
    NSMutableArray *pairs = [NSMutableArray arrayWithCapacity:params.count];
    
    [params enumerateKeysAndObjectsUsingBlock:^(NSString *k, NSString *v, BOOL *stop) {
        [pairs addObject:[NSString stringWithFormat:@"%@=%@",k,v]];
    }];
    
    request.HTTPBody = [[pairs componentsJoinedByString:@"&"]dataUsingEncoding:NSUTF8StringEncoding];
    return request;
}

- (NSMutableURLRequest *)requestWithURL:(NSURL *)url HTTPMethod:(NSString *)httpMethod params:(NSDictionary *)params {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:cachePolicy timeoutInterval:30.0f];
    [request setHTTPMethod:httpMethod];
    [request setHTTPShouldHandleCookies:NO];
    
    if ([httpMethod isEqualToString:kPOST]) {
        NSString *boundary = [NSString fhs_UUID];
        
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        
        request.HTTPBody = [self POSTBodyWithParams:params boundary:boundary];
        [request setValue:@(request.HTTPBody.length).stringValue forHTTPHeaderField:@"Content-Length"];
    } else if ([httpMethod isEqualToString:kGET]) {
        NSURL *paramURL = url.copy;
        [self appendGETParams:params toURL:&paramURL];
        request.URL = paramURL;
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

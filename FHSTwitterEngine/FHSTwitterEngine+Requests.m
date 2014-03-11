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

- (id)sendRequest:(NSURLRequest *)request {
    
    if (self.shouldClearConsumer) {
        self.shouldClearConsumer = NO;
        self.consumer = nil;
    }
    
    NSHTTPURLResponse *response = nil;
    NSError *error = nil;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (error) {
        return error;
    }
    
    if (response == nil) {
        return error;
    }
    
    if (response.statusCode >= 304) {
        return error;
    }
    
    if (data.length == 0) {
        return error;
    }
    
    return data;
}

//
// Write this out
//

- (NSString *)generateOAuthHeaderForRequest:(NSURLRequest *)request withToken:(NSString *)tokenString tokenSecret:(NSString *)tokenSecretString verifier:(NSString *)verifierString realm:(NSString *)realm {
    
    NSString *nonce = [NSString fhs_UUID];
    NSString *urlWithoutParams = request.URL.absoluteStringWithoutParameters.fhs_URLEncode;
    
    // OAuth Spec, Section 9.1.1 "Normalize Request Parameters"
    // build a sorted array of both request parameters and OAuth header parameters
    
    NSMutableDictionary *mutableParams = @{
                                           @"oauth_consumer_key": self.consumer.key.fhs_URLEncode,
                                           @"oauth_signature_method": @"HMAC-SHA1",
                                           @"oauth_timestamp": @(time(nil)).stringValue,
                                           @"oauth_nonce": nonce,
                                           @"oauth_version": @"1.0"
                                           }.mutableCopy;
    
    if (tokenString.length > 0) {
        mutableParams[@"oauth_token"] = [tokenString fhs_URLEncode];
        if (verifierString.length > 0) {
            mutableParams[@"oauth_verifier"] = [verifierString fhs_URLEncode];
        }
    } else {
        mutableParams[@"oauth_callback"] = @"oob";
    }
    
    NSMutableArray *paramPairs = [NSMutableArray arrayWithCapacity:mutableParams.count];
    
    [mutableParams enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        NSString *pair = [NSString stringWithFormat:@"%@=%@",key.fhs_URLEncode, obj.fhs_URLEncode];
        [paramPairs addObject:pair];
    }];
    
    NSMutableArray *oauthParamPairs = paramPairs.mutableCopy;
    
    if ([request.HTTPMethod isEqualToString:@"GET"]) {
        [paramPairs addObjectsFromArray:[request.URL.query componentsSeparatedByString:@"&"]];
    }
    
    [paramPairs sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    NSString *normalizedRequestParameters = [[paramPairs componentsJoinedByString:@"&"]fhs_URLEncode];
    
    // OAuth Spec, Section 9.1.2 "Concatenate Request Elements"
    // Sign request elements using HMAC-SHA1
    NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@",request.HTTPMethod,urlWithoutParams,normalizedRequestParameters];
    
    NSString *tokenSecretSantized = (tokenSecretString.length > 0)?tokenSecretString.fhs_URLEncode:@""; // this way a nil token won't make a bad signature
    
    NSString *secret = [NSString stringWithFormat:@"%@&%@",self.consumer.secret.fhs_URLEncode,tokenSecretSantized];
    
    NSData *secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
    NSData *clearTextData = [signatureBaseString dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[20];
	CCHmac(kCCHmacAlgSHA1, secretData.bytes, secretData.length, clearTextData.bytes, clearTextData.length, result);
    NSData *theData = [[[NSData dataWithBytes:result length:20]base64Encode]dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *signature = [[[NSString alloc]initWithData:theData encoding:NSUTF8StringEncoding]fhs_URLEncode];
    
	NSString *oauthToken = (tokenString.length > 0)?[NSString stringWithFormat:@"oauth_token=\"%@\", ",[tokenString fhs_URLEncode]]:@"oauth_callback=\"oob\", ";
    NSString *oauthVerifier = (verifierString.length > 0)?[NSString stringWithFormat:@"oauth_verifier=\"%@\", ",verifierString]:@"";
    

    //
    // now concat the params hash to generate the header
    //
    
    [mutableParams enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        
    }];
    
   // NSString *oauthHeader = [NSString stringWithFormat:@"OAuth oauth_consumer_key=\"%@\", %@%@oauth_signature_method=\"HMAC-SHA1\", oauth_signature=\"%@\", oauth_timestamp=\"%@\", oauth_nonce=\"%@\", oauth_version=\"1.0\"",consumerKey,oauthToken,oauthVerifier,signature,timestamp,nonce];
    
    /*NSString *nonce = [NSString fhs_UUID];
    NSString *timestamp = @(time(nil)).stringValue;
    
    NSMutableArray *parameterPairs = [NSMutableArray arrayWithCapacity:6];
    [parameterPairs addObject:[NSString stringWithFormat:@"oauth_consumer_key=%@",self.consumer.key.fhs_URLEncode]];
    [parameterPairs addObject:@"oauth_signature_method=HMAC-SHA1"];
    [parameterPairs addObject:[NSString stringWithFormat:@"oauth_nonce=%@",nonce.fhs_URLEncode]];
    [parameterPairs addObject:[NSString stringWithFormat:@"oauth_timestamp=%@",timestamp.fhs_URLEncode]];
    [parameterPairs addObject:@"oauth_version=1.0"];
    [parameterPairs addObject:[NSString stringWithFormat:@"oauth_token=%@",self.accessToken.key]];
    
    NSArray *sortedPairs = [parameterPairs sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    NSString *normalizedRequestParameters = [sortedPairs componentsJoinedByString:@"&"];
    
    NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@", @"GET", [@"https://api.twitter.com/1.1/account/verify_credentials.json" fhs_URLEncode],normalizedRequestParameters.fhs_URLEncode];
    
    NSString *secretForSigning = [NSString stringWithFormat:@"%@&%@", self.consumer.secret.fhs_URLEncode, self.accessToken.secret.fhs_URLEncode];
    
    NSData *secretData = [secretForSigning dataUsingEncoding:NSUTF8StringEncoding];
    NSData *clearTextData = [signatureBaseString dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[20];
	CCHmac(kCCHmacAlgSHA1, secretData.bytes, secretData.length, clearTextData.bytes, clearTextData.length, result);
    NSString *signature = [[NSData dataWithBytes:result length:20]base64Encode];
    
    return [NSString stringWithFormat:@"OAuth realm=\"%@\", oauth_consumer_key=\"%@\", oauth_token=\"%@\", oauth_signature_method=\"HMAC-SHA1\", oauth_signature=\"%@\", oauth_timestamp=\"%@\", oauth_nonce=\"%@\", oauth_version=\"1.0\"", @"http://api.twitter.com/".fhs_URLEncode, self.consumer.key.fhs_URLEncode, self.accessToken.key.fhs_URLEncode, signature.fhs_URLEncode, timestamp, nonce];*/
}

- (void)signRequest:(NSMutableURLRequest *)request {
    [self signRequest:request withToken:self.accessToken.key tokenSecret:self.accessToken.secret verifier:nil realm:nil];
}

- (void)signRequest:(NSMutableURLRequest *)request withToken:(NSString *)tokenString tokenSecret:(NSString *)tokenSecretString verifier:(NSString *)verifierString realm:(NSString *)realm {
    
    NSString *consumerKey = self.consumer.key.fhs_URLEncode;
    NSString *nonce = [NSString fhs_UUID];
    NSString *timestamp = @(time(nil)).stringValue;
    NSString *urlWithoutParams = request.URL.absoluteStringWithoutParameters.fhs_URLEncode;
    
    // OAuth Spec, Section 9.1.1 "Normalize Request Parameters"
    // build a sorted array of both request parameters and OAuth header parameters
    
    NSMutableDictionary *mutableParams = @{
                                           @"oauth_consumer_key": consumerKey,
                                           @"oauth_signature_method": @"HMAC-SHA1",
                                           @"oauth_timestamp": timestamp,
                                           @"oauth_nonce": nonce,
                                           @"oauth_version": @"1.0"
                                           }.mutableCopy;
    
    if (tokenString.length > 0) {
        mutableParams[@"oauth_token"] = [tokenString fhs_URLEncode];
        if (verifierString.length > 0) {
            mutableParams[@"oauth_verifier"] = [verifierString fhs_URLEncode];
        }
    } else {
        mutableParams[@"oauth_callback"] = @"oob";
    }
    
    NSMutableArray *paramPairs = [NSMutableArray arrayWithCapacity:mutableParams.count];
    
    for (NSString *key in mutableParams.allKeys) {
        [paramPairs addObject:[NSString stringWithFormat:@"%@=%@",key.fhs_URLEncode,[mutableParams[key] fhs_URLEncode]]];
    }
    
    if ([request.HTTPMethod isEqualToString:@"GET"]) {
        NSArray *halves = [request.URL.absoluteString componentsSeparatedByString:@"?"];
        
        if (halves.count > 1) {
            NSArray *parameters = [halves[1] componentsSeparatedByString:@"&"];
            
            if (parameters.count > 0) {
                [paramPairs addObjectsFromArray:parameters];
            }
        }
    }
    
    [paramPairs sortUsingSelector:@selector(compare:)];
    
    NSString *normalizedRequestParameters = [[paramPairs componentsJoinedByString:@"&"]fhs_URLEncode];
    
    // OAuth Spec, Section 9.1.2 "Concatenate Request Elements"
    // Sign request elements using HMAC-SHA1
    NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@",request.HTTPMethod,urlWithoutParams,normalizedRequestParameters];
    
    NSString *tokenSecretSantized = (tokenSecretString.length > 0)?tokenSecretString.fhs_URLEncode:@""; // this way a nil token won't make a bad signature
    
    NSString *secret = [NSString stringWithFormat:@"%@&%@",self.consumer.secret.fhs_URLEncode,tokenSecretSantized];
    
    NSData *secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
    NSData *clearTextData = [signatureBaseString dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[20];
	CCHmac(kCCHmacAlgSHA1, secretData.bytes, secretData.length, clearTextData.bytes, clearTextData.length, result);
    NSData *theData = [[[NSData dataWithBytes:result length:20]base64Encode]dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *signature = [[[NSString alloc]initWithData:theData encoding:NSUTF8StringEncoding]fhs_URLEncode];
    
	NSString *oauthToken = (tokenString.length > 0)?[NSString stringWithFormat:@"oauth_token=\"%@\", ",[tokenString fhs_URLEncode]]:@"oauth_callback=\"oob\", ";
    NSString *oauthVerifier = (verifierString.length > 0)?[NSString stringWithFormat:@"oauth_verifier=\"%@\", ",verifierString]:@"";
    
    NSString *oauthHeader = [NSString stringWithFormat:@"OAuth oauth_consumer_key=\"%@\", %@%@oauth_signature_method=\"HMAC-SHA1\", oauth_signature=\"%@\", oauth_timestamp=\"%@\", oauth_nonce=\"%@\", oauth_version=\"1.0\"",consumerKey,oauthToken,oauthVerifier,signature,timestamp,nonce];
    
    [request setValue:oauthHeader forHTTPHeaderField:@"Authorization"];
}

- (int)parameterLengthForURL:(NSString *)url params:(NSMutableDictionary *)params {
    int length = url.length;
    
    for (NSString *key in params) {
        length += [key fhs_URLEncode].length;
        length += [params[key] fhs_URLEncode].length;
        length += 1; // for the equal sign
    }
    
    return length;
}

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
        
        if (errors.count > 0) {
            return [NSError errorWithDomain:FHSErrorDomain code:418 userInfo:@{NSLocalizedDescriptionKey: @"Multiple Errors", @"errors": errors}];
        }
    }
    return nil;
}

- (void)appendGETParams:(NSDictionary *)params toURL:(NSURL **)url {
    if (params.count > 0) {
        NSMutableArray *paramPairs = [NSMutableArray arrayWithCapacity:params.count];
        
        for (NSString *key in params) {
            NSString *paramPair = [NSString stringWithFormat:@"%@=%@",key.fhs_URLEncode,[params[key] fhs_URLEncode]];
            [paramPairs addObject:paramPair];
        }
        
        *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",(*url).absoluteStringWithoutParameters, [paramPairs componentsJoinedByString:@"&"]]];
    }
}

- (NSData *)POSTBodyWithParams:(NSDictionary *)params boundary:(NSString *)boundary {
    NSMutableData *body = [NSMutableData dataWithLength:0];
    
    for (NSString *key in params.allKeys) {
        id obj = params[key];
        
        // start the parameter
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary]dataUsingEncoding:NSUTF8StringEncoding]];
        
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dict = [NSDictionary dictionaryWithDictionary:(NSDictionary *)obj];
            
            if ([dict[@"type"]isEqualToString:@"file"]) {
                [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"media\"; filename=\"%@\"\r\n",dict[@"filename"]] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n",dict[@"mimetype"]] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:dict[@"data"]];
            }
        } else {
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n",key] dataUsingEncoding:NSUTF8StringEncoding]];
            
            NSData *data = nil;
            
            if ([obj isKindOfClass:[NSData class]]) {
                [body appendData:[@"Content-Type: application/octet-stream\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                data = (NSData *)obj;
            } else if ([obj isKindOfClass:[NSString class]]) {
                data = [(NSString *)obj dataUsingEncoding:NSUTF8StringEncoding];
            }
            
            if (data.length > 0) {
                [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:data];
            }
        }

        // end the parameter
        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    return body;
}

- (NSError *)sendPOSTRequestForURL:(NSURL *)url andParams:(NSDictionary *)params {
    id obj = [self sendRequestWithHTTPMethod:@"POST" URL:url params:params];
    return [obj isKindOfClass:[NSError class]]?obj:nil;
}

- (id)sendGETRequestForURL:(NSURL *)url andParams:(NSDictionary *)params {
    return [self sendRequestWithHTTPMethod:@"GET" URL:url params:params];
}

- (id)sendRequestWithHTTPMethod:(NSString *)httpmethod URL:(NSURL *)url params:(NSDictionary *)params {
    NSError *authError = [self checkAuth];
    
    if (authError) {
        return authError;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30.0f];
    [request setHTTPMethod:httpmethod];
    [request setHTTPShouldHandleCookies:NO];
    
    if ([httpmethod isEqualToString:@"POST"]) {
        NSString *boundary = [NSString fhs_UUID];
        
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request setValue:contentType forHTTPHeaderField:@"Content-Type"];

        request.HTTPBody = [self POSTBodyWithParams:params boundary:boundary];
        [request setValue:@(request.HTTPBody.length).stringValue forHTTPHeaderField:@"Content-Length"];
    } else if ([httpmethod isEqualToString:@"GET"]) {
        [self appendGETParams:params toURL:&url];
    }
    
    [self signRequest:request];
    
    id retobj = [self sendRequest:request];
    
    if (!retobj) {
        return [NSError noDataError];
    } else if ([retobj isKindOfClass:[NSError class]]) {
        return retobj;
    }
    
    id parsed = [[NSJSONSerialization JSONObjectWithData:(NSData *)retobj options:NSJSONReadingMutableContainers error:nil]removeNull];
    
    NSError *error = [self checkError:parsed];
    
    if (error) {
        return error;
    }
    
    return parsed;
}

- (id)streamingRequestForURL:(NSURL *)url HTTPMethod:(NSString *)method parameters:(NSDictionary *)params {
    NSError *authError = [self checkAuth];
    
    if (authError) {
        return authError;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:cachePolicy timeoutInterval:MAXFLOAT]; // timeouts are handled manually
    [request setHTTPMethod:method];
    [request setHTTPShouldHandleCookies:NO];
    
    // Only POST and GET are relevant to the Twitter API
    
    if ([method isEqualToString:@"POST"]) {
        NSString *boundary = [NSString fhs_UUID];
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        request.HTTPBody = [self POSTBodyWithParams:params boundary:boundary];
        [request setValue:@(request.HTTPBody.length).stringValue forHTTPHeaderField:@"Content-Length"];
    } else if ([method isEqualToString:@"GET"]) {
        [self appendGETParams:params toURL:&url];
        request.URL = url;
    } else {
        return [NSError errorWithDomain:FHSErrorDomain code:-400 userInfo:@{NSLocalizedDescriptionKey: @"HTTP method not supported by FHSTwitterEngine."}];
    }
    
    [self signRequest:request];
    return request;
}

@end

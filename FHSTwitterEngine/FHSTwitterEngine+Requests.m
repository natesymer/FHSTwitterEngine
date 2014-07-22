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
    [self clearConsumerIfNecessary];
    
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

- (NSString *)generateOAuthHeaderForURL:(NSURL *)URL HTTPMethod:(NSString *)httpMethod withToken:(NSString *)tokenString tokenSecret:(NSString *)tokenSecretString verifier:(NSString *)verifierString realm:(NSString *)realm extraParameters:(NSDictionary *)extraParams {
    
    NSString *nonce = [NSString fhs_UUID];
    NSString *urlWithoutParams = URL.absoluteStringWithoutParameters.fhs_URLEncode;
    
    // OAuth Spec, Section 9.1.1 "Normalize Request Parameters"
    // build a sorted array of both request parameters and OAuth header parameters
    NSMutableDictionary *oauth = @{
                                   @"oauth_consumer_key": self.consumerKey.fhs_URLEncode,
                                   @"oauth_signature_method": @"HMAC-SHA1",
                                   @"oauth_timestamp": @(time(nil)).stringValue,
                                   @"oauth_nonce": nonce,
                                   @"oauth_version": @"1.0"
                                   }.mutableCopy;

    // Determine if this request is for a request token
    if (tokenString.length > 0) {
        oauth[@"oauth_token"] = tokenString.fhs_URLEncode;
        if (verifierString.length > 0) {
            oauth[@"oauth_verifier"] = verifierString.fhs_URLEncode;
        }
    } else {
        if (extraParams.count == 0) {
            oauth[@"oauth_callback"] = @"oob";
        }
    }
    
    NSMutableArray *paramPairs = [NSMutableArray arrayWithCapacity:oauth.count+extraParams.count];
    
    [oauth enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        NSString *pair = [NSString stringWithFormat:@"%@=%@",key, obj];
        [paramPairs addObject:pair];
    }];
    
    // Realm is not to be included in the Normalized request parameters
    if (realm.length > 0) {
        oauth[@"oauth_realm"] = realm;
    }
    
    if (extraParams.count > 0) {
        [extraParams enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
            NSString *pair = [NSString stringWithFormat:@"%@=%@",key, obj];
            [paramPairs addObject:pair];
        }];
    }
    
    [paramPairs sortUsingSelector:@selector(caseInsensitiveCompare:)]; // used to be compare:
    
    // Whew, that's over

    NSString *normalizedRequestParameters = [paramPairs componentsJoinedByString:@"&"].fhs_URLEncode;

    // OAuth Spec, Section 9.1.2 "Concatenate Request Elements"
    // Sign request elements using HMAC-SHA1
    NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@",httpMethod,urlWithoutParams,normalizedRequestParameters];
    
    // this way a nil token won't make a bad signature
    NSString *tokenSecretSantized = (tokenSecretString.length > 0)?tokenSecretString:@""; // This is precicely the way that works. Don't question it.
    
    NSString *secret = [NSString stringWithFormat:@"%@&%@",self.consumerSecret.fhs_URLEncode,tokenSecretSantized.fhs_URLEncode];
    
    NSData *secretData = [secret dataUsingEncoding:NSUTF8StringEncoding];
    NSData *clearTextData = [signatureBaseString dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char result[20];
	CCHmac(kCCHmacAlgSHA1, secretData.bytes, secretData.length, clearTextData.bytes, clearTextData.length, result);

    oauth[@"oauth_signature"] = [[NSData dataWithBytes:result length:20]base64Encode];
    
    NSMutableArray *oauthPairs = [NSMutableArray arrayWithCapacity:oauth.count];
    
    [oauth enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        NSString *pair = [NSString stringWithFormat:@"%@=\"%@\"",key.fhs_URLEncode, obj.fhs_URLEncode];
        [oauthPairs addObject:pair];
    }];
    
    [oauthPairs sortUsingSelector:@selector(caseInsensitiveCompare:)];
    
    return [NSString stringWithFormat:@"OAuth %@",[oauthPairs componentsJoinedByString:@", "]];
}

- (void)signRequest:(NSMutableURLRequest *)request {
    [self signRequest:request withToken:self.accessToken.key tokenSecret:self.accessToken.secret verifier:nil realm:nil extraParameters:nil];
}

- (void)signRequest:(NSMutableURLRequest *)request withToken:(NSString *)tokenString tokenSecret:(NSString *)tokenSecretString verifier:(NSString *)verifierString realm:(NSString *)realm extraParameters:(NSDictionary *)extraParams {
    NSString *oauthHeader = [self generateOAuthHeaderForURL:request.URL HTTPMethod:request.HTTPMethod withToken:tokenString tokenSecret:tokenSecretString verifier:verifierString realm:realm extraParameters:extraParams];
    [request setValue:oauthHeader forHTTPHeaderField:@"Authorization"];
}

- (int)parameterLengthForURL:(NSString *)url params:(NSMutableDictionary *)params {
    int length = url.length;
    
    for (NSString *key in params) {
        length += key.fhs_URLEncode.length;
        length += [params[key] fhs_URLEncode].length;
    }
    
    length += params.count*2; // accounts for equal sign & ampersands and the question mark
    
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
    
   // NSLog(@"%@",lines);
    
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
    
    if (d.length < 1000) NSLog(@"\n%@",[[NSString alloc]initWithData:d encoding:NSUTF8StringEncoding]);
    
    return d;
}

// Probably slightly faster
/*- (NSData *)POSTBodyWithParams:(NSDictionary *)params boundary:(NSString *)boundary {
    NSMutableData *body = [NSMutableData data];
    
    // setup commonly used data objects to save on processing
    NSData *cRetAndNlineData = [@"\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *boundaryData = [[NSString stringWithFormat:@"--%@\r\n",boundary]dataUsingEncoding:NSUTF8StringEncoding];
    NSData *cTypeOctetStreamData = [@"Content-Type: application/octet-stream\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *ctentXferEncData = [@"Content-Transfer-Encoding: binary\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding];
    
    [params enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        // start the parameter
        [body appendData:boundaryData];
        
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dict = [NSDictionary dictionaryWithDictionary:(NSDictionary *)obj];

            if ([dict[@"type"]isEqualToString:@"file"]) {
                [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n",key,dict[@"filename"]] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n",dict[@"mimetype"]] dataUsingEncoding:NSUTF8StringEncoding]];
                [body appendData:ctentXferEncData];
                [body appendData:dict[@"data"]];
            }
            
        } else {
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n",key] dataUsingEncoding:NSUTF8StringEncoding]];
            
            NSData *data = nil;
            
            if ([obj isKindOfClass:[NSData class]]) {
                [body appendData:cTypeOctetStreamData];
                data = (NSData *)obj;
            } else if ([obj isKindOfClass:[NSString class]]) {
                data = [(NSString *)obj dataUsingEncoding:NSUTF8StringEncoding];
            }
            
            if (data.length > 0) {
                [body appendData:cRetAndNlineData];
                [body appendData:data];
            }
        }
        
        // end the parameter
        [body appendData:cRetAndNlineData];
    }];
    
    [body appendData:[[NSString stringWithFormat:@"--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@"POSTing\n%@",[[NSString alloc]initWithData:body encoding:NSUTF8StringEncoding]);
    return body;
}*/

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


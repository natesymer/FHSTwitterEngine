//
//  NSMutableURLRequest+OAuth.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 7/25/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "NSMutableURLRequest+OAuth.h"
#import <CommonCrypto/CommonHMAC.h>
#import "NSString+FHSTE.h"
#import "NSURL+FHSTE.h"
#import "NSData+FHSTE.h"
#import "NSMutableURLRequest+FHSTE.h"

@implementation NSMutableURLRequest (OAuth)

#pragma mark - OAuth Header Generation

- (NSString *)OAuthHeaderWithToken:(NSString *)token
                       tokenSecret:(NSString *)tokenSecret
                          verifier:(NSString *)verifier
                       consumerKey:(NSString *)consumerKey
                    consumerSecret:(NSString *)consumerSecret
                             realm:(NSString *)realm {
    return [self OAuthHeaderWithToken:token
                          tokenSecret:tokenSecret
                             verifier:verifier
                          consumerKey:consumerKey
                       consumerSecret:consumerSecret
                                nonce:[NSString fhs_UUID]
                            timestamp:@(time(nil)).stringValue
                                realm:realm];
}

- (NSString *)OAuthHeaderWithToken:(NSString *)token
                       tokenSecret:(NSString *)tokenSecret
                          verifier:(NSString *)verifier
                       consumerKey:(NSString *)consumerKey
                    consumerSecret:(NSString *)consumerSecret
                             nonce:(NSString *)nonce
                         timestamp:(NSString *)timestamp
                             realm:(NSString *)realm {
    
    // OAuth Spec, Section 9.1.1 "Normalize Request Parameters"
    //
    // Build a query-style string containing the URL query, POST params
    // (if Content-Type is application/x-www-form-urlencoded), and OAuth header params.
    
    // Gather OAuth params
    NSMutableDictionary *oauth = @{
                                   @"oauth_consumer_key": consumerKey.fhs_URLEncode,
                                   @"oauth_signature_method": @"HMAC-SHA1",
                                   @"oauth_timestamp": timestamp.fhs_URLEncode,
                                   @"oauth_nonce": nonce.fhs_URLEncode,
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
        if (self.HTTPBody.length == 0) oauth[@"oauth_callback"] = @"oob";
    }
    
    // Put all params into one hash
    NSMutableDictionary *requestParameters = [NSMutableDictionary dictionary];
    [requestParameters addEntriesFromDictionary:oauth]; // OAuth headers
    if ([self.HTTPMethod isEqualToString:@"GET"]) [requestParameters addEntriesFromDictionary:self.getParameters]; // GET query params (already encoded)
    if (self.isW3FormURLEncoded) [requestParameters addEntriesFromDictionary:self.postParameters]; // x-www-form-urlencoded POST params (already encoded)
    
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
    NSString *requestURL = self.URL.URLWithoutQuery.absoluteString.lowercaseString.fhs_URLEncode;
    
    
    // OAuth Spec, Section 9.1.3 "Concatenate Request Elements"
    //
    // Sign request elements using HMAC-SHA1
    NSString *signatureBaseString = [NSString stringWithFormat:@"%@&%@&%@",self.HTTPMethod,requestURL,normalizedRequestParameters];
    NSString *secret = [NSString stringWithFormat:@"%@&%@",consumerSecret.fhs_URLEncode,tokenSecret.fhs_URLEncode ?: @""];
    
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

#pragma mark - OAuth Signing

- (void)signWithToken:(NSString *)token
          tokenSecret:(NSString *)tokenSecret
             verifier:(NSString *)verifier
          consumerKey:(NSString *)consumerKey
       consumerSecret:(NSString *)consumerSecret
                realm:(NSString *)realm {
    
    NSString *header = [self OAuthHeaderWithToken:token tokenSecret:tokenSecret verifier:verifier consumerKey:consumerKey consumerSecret:consumerSecret realm:realm];
    [self setValue:header forHTTPHeaderField:@"Authorization"];
}

@end

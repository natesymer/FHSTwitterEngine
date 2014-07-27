//
//  OAuth.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 7/26/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSMutableURLRequest+Oauth.h"
#import "NSMutableURLRequest+FHSTE.h"
#import "FHSTwitterEngine.h"
#import "FHSTwitterEngine+Requests.h"

static NSString * const kConsumerKey = @"aaaaaaaaaaaaaaaaaaaaaa";
static NSString * const kConsumerSecret = @"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";

static NSString * const kTokenKey = @"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
static NSString * const kTokenSecret = @"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";

static NSString * const kNonce = @"E43707B2-FA74-49AD-876C-193231CD5743";
static NSString * const kTimestamp = @"1406423565";

static NSString * const kVerifier = @"7065154";

@interface OAuth : XCTestCase

@end

//
// These tests were made when the OAuth code was working as intended.
//

@implementation OAuth

- (void)testXAuth {
    NSMutableURLRequest *r = [NSMutableURLRequest formURLEncodedPOSTRequestWithURL:[NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"] params:@{
                                                                                                                                                                @"x_auth_username": @"username",
                                                                                                                                                                @"x_auth_password": @"password",
                                                                                                                                                                @"x_auth_mode": @"client_auth"
                                                                                                                                                                }];
    
    NSString *generatedHeader = [r OAuthHeaderWithToken:nil tokenSecret:nil verifier:nil consumerKey:kConsumerKey consumerSecret:kConsumerSecret nonce:kNonce timestamp:kTimestamp realm:nil];
    NSString *expectedHeader = @"OAuth oauth_consumer_key=\"aaaaaaaaaaaaaaaaaaaaaa\",oauth_nonce=\"E43707B2-FA74-49AD-876C-193231CD5743\",oauth_signature=\"W2B33d09D9rp9a3dkAelfkoB33U%3D\",oauth_signature_method=\"HMAC-SHA1\",oauth_timestamp=\"1406423565\",oauth_version=\"1.0a\"";
    
    XCTAssert([generatedHeader isEqualToString:expectedHeader], @"The generated header must match the expected header.");
}

- (void)testRequestToken {
    NSMutableURLRequest *r = [NSMutableURLRequest defaultRequestWithURL:[NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"]];
    
    NSString *generatedHeader = [r OAuthHeaderWithToken:nil tokenSecret:nil verifier:nil consumerKey:kConsumerKey consumerSecret:kConsumerSecret nonce:kNonce timestamp:kTimestamp realm:nil];
    
    NSString *expectedHeader = @"OAuth oauth_callback=\"oob\",oauth_consumer_key=\"aaaaaaaaaaaaaaaaaaaaaa\",oauth_nonce=\"E43707B2-FA74-49AD-876C-193231CD5743\",oauth_signature=\"ZEMooPPJ%2Bl6cmtEKwnVFUssyjdM%3D\",oauth_signature_method=\"HMAC-SHA1\",oauth_timestamp=\"1406423565\",oauth_version=\"1.0a\"";
    
    XCTAssert([generatedHeader isEqualToString:expectedHeader], @"The generated header must match the expected header.");
}

- (void)testReverseAuthRequestToken {
    NSMutableURLRequest *r = [NSMutableURLRequest formURLEncodedPOSTRequestWithURL:[NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"] params:@{@"x_auth_mode": @"reverse_auth"}];
    
    NSString *generatedHeader = [r OAuthHeaderWithToken:nil tokenSecret:nil verifier:nil consumerKey:kConsumerKey consumerSecret:kConsumerSecret nonce:kNonce timestamp:kTimestamp realm:nil];
    NSString *expectedHeader = @"OAuth oauth_consumer_key=\"aaaaaaaaaaaaaaaaaaaaaa\",oauth_nonce=\"E43707B2-FA74-49AD-876C-193231CD5743\",oauth_signature=\"z%2FHnixPuwaGdp1HX70y0%2FnRwz1w%3D\",oauth_signature_method=\"HMAC-SHA1\",oauth_timestamp=\"1406423565\",oauth_version=\"1.0a\"";
    
    XCTAssert([generatedHeader isEqualToString:expectedHeader], @"The generated header must match the expected header.");
}

- (void)testOAuthTokenUpgrade {
    NSMutableURLRequest *r = [NSMutableURLRequest defaultRequestWithURL:[NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"]];
    r.HTTPMethod = @"POST";
    
    NSString *generatedHeader = [r OAuthHeaderWithToken:kTokenKey tokenSecret:kTokenSecret verifier:kVerifier consumerKey:kConsumerKey consumerSecret:kConsumerSecret nonce:kNonce timestamp:kTimestamp realm:nil];
    NSString *expectedHeader = @"OAuth oauth_consumer_key=\"aaaaaaaaaaaaaaaaaaaaaa\",oauth_nonce=\"E43707B2-FA74-49AD-876C-193231CD5743\",oauth_signature=\"fYkwBTwa68vXYEqpJcOGPOaRUeg%3D\",oauth_signature_method=\"HMAC-SHA1\",oauth_timestamp=\"1406423565\",oauth_token=\"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\",oauth_verifier=\"7065154\",oauth_version=\"1.0a\"";

    XCTAssert([generatedHeader isEqualToString:expectedHeader], @"The generated header must match the expected header.");
}

- (void)testOAuthGET {
    NSMutableURLRequest *r = [NSMutableURLRequest defaultRequestWithURL:[NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/mentions_timeline.json"]];
    r.HTTPMethod = @"GET";
    
    NSString *generatedHeader = [r OAuthHeaderWithToken:kTokenKey tokenSecret:kTokenSecret verifier:nil consumerKey:kConsumerKey consumerSecret:kConsumerSecret nonce:kNonce timestamp:kTimestamp realm:nil];
    NSString *expectedHeader = @"OAuth oauth_consumer_key=\"aaaaaaaaaaaaaaaaaaaaaa\",oauth_nonce=\"E43707B2-FA74-49AD-876C-193231CD5743\",oauth_signature=\"rVvSYiDDR5Bzkg2zrkKiQNwZ%2FyY%3D\",oauth_signature_method=\"HMAC-SHA1\",oauth_timestamp=\"1406423565\",oauth_token=\"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\",oauth_version=\"1.0a\"";
    
    XCTAssert([generatedHeader isEqualToString:expectedHeader], @"The generated header must match the expected header.");
}

- (void)testOAuthGETParams {
    NSMutableURLRequest *r = [NSMutableURLRequest GETRequestWithURL:[NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/mentions_timeline.json"] params:@{@"count": @"10"}];
    r.HTTPMethod = @"GET";
    
    NSString *generatedHeader = [r OAuthHeaderWithToken:kTokenKey tokenSecret:kTokenSecret verifier:nil consumerKey:kConsumerKey consumerSecret:kConsumerSecret nonce:kNonce timestamp:kTimestamp realm:nil];
    NSString *expectedHeader = @"OAuth oauth_consumer_key=\"aaaaaaaaaaaaaaaaaaaaaa\",oauth_nonce=\"E43707B2-FA74-49AD-876C-193231CD5743\",oauth_signature=\"tBRJuslpZ1V3fhXdM8LbUqTuho0%3D\",oauth_signature_method=\"HMAC-SHA1\",oauth_timestamp=\"1406423565\",oauth_token=\"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\",oauth_version=\"1.0a\"";
    
    XCTAssert([generatedHeader isEqualToString:expectedHeader], @"The generated header must match the expected header.");
}

- (void)testOAuthPOST {
    NSMutableURLRequest *r = [NSMutableURLRequest defaultRequestWithURL:[NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/retweet/467624447944691712.json"]];
    r.HTTPMethod = @"POST";

    NSString *generatedHeader = [r OAuthHeaderWithToken:kTokenKey tokenSecret:kTokenSecret verifier:nil consumerKey:kConsumerKey consumerSecret:kConsumerSecret nonce:kNonce timestamp:kTimestamp realm:nil];
    NSString *expectedHeader = @"OAuth oauth_consumer_key=\"aaaaaaaaaaaaaaaaaaaaaa\",oauth_nonce=\"E43707B2-FA74-49AD-876C-193231CD5743\",oauth_signature=\"PjniGHXHScF1274AvAtvCMwpXBw%3D\",oauth_signature_method=\"HMAC-SHA1\",oauth_timestamp=\"1406423565\",oauth_token=\"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\",oauth_version=\"1.0a\"";
    
    XCTAssert([generatedHeader isEqualToString:expectedHeader], @"The generated header must match the expected header.");
}

- (void)testOAuthPostMultipartParams {
    NSMutableURLRequest *r = [NSMutableURLRequest multipartPOSTRequestWithURL:[NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update.json"] params:@{@"status": @"Hey you, write tests now!"}];
    r.HTTPMethod = @"POST";
    
    NSString *generatedHeader = [r OAuthHeaderWithToken:kTokenKey tokenSecret:kTokenSecret verifier:nil consumerKey:kConsumerKey consumerSecret:kConsumerSecret nonce:kNonce timestamp:kTimestamp realm:nil];
    NSString *expectedHeader = @"OAuth oauth_consumer_key=\"aaaaaaaaaaaaaaaaaaaaaa\",oauth_nonce=\"E43707B2-FA74-49AD-876C-193231CD5743\",oauth_signature=\"bhwKWHsI4AsLPHl0zLeK2Shz1Uw%3D\",oauth_signature_method=\"HMAC-SHA1\",oauth_timestamp=\"1406423565\",oauth_token=\"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\",oauth_version=\"1.0a\"";
    
    XCTAssert([generatedHeader isEqualToString:expectedHeader], @"The generated header must match the expected header.");
}

@end

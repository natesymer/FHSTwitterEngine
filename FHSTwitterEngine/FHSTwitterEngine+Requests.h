//
//  FHSTwitterEngine+Requests.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/10/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "FHSTwitterEngine.h"

//
// NOTE
// You should never find yourself using this
// Category. (Unless you're implementing endpoints
// or doing something fancy and/or hacky)
//

@interface FHSTwitterEngine (Requests)

// send requests
- (id)sendRequest:(NSURLRequest *)request;

// The heart of FHSTwitterEngine
- (id)sendRequestWithHTTPMethod:(NSString *)httpmethod URL:(NSURL *)url params:(NSDictionary *)params;

// Generate streaming request used in FHSStream
- (id)streamingRequestForURL:(NSURL *)url HTTPMethod:(NSString *)method parameters:(NSDictionary *)params;

// Get an x-www-form-urlencoded POST-bodied request
- (NSMutableURLRequest *)formURLEncodedPOSTRequestWithURL:(NSURL *)url params:(NSDictionary *)params;

// Request signing
// Extra parameters that you want included in the OAuth signature
// No parameters are signed because they don't need to be. Makes everything quicker.
/*- (void)signRequest:(NSMutableURLRequest *)request;
- (void)signRequest:(NSMutableURLRequest *)request withToken:(NSString *)tokenString tokenSecret:(NSString *)tokenSecretString verifier:(NSString *)verifierString realm:(NSString *)realm extraParameters:(NSDictionary *)extraParams;
- (NSString *)generateOAuthHeaderForURL:(NSURL *)URL HTTPMethod:(NSString *)httpMethod withToken:(NSString *)tokenString tokenSecret:(NSString *)tokenSecretString verifier:(NSString *)verifierString realm:(NSString *)realm extraParameters:(NSDictionary *)extraParams;*/

// Request Signing
- (void)signRequest:(NSMutableURLRequest *)request;
- (void)signRequest:(NSMutableURLRequest *)request withToken:(NSString *)token tokenSecret:(NSString *)tokenSecret verifier:(NSString *)verifier realm:(NSString *)realm;
- (NSString *)OAuthHeaderForRequest:(NSURLRequest *)request token:(NSString *)token tokenSecret:(NSString *)tokenSecret verifier:(NSString *)verifier realm:(NSString *)realm;

// Generate a POST body from parameters. See implementation for details
- (NSData *)POSTBodyWithParams:(NSDictionary *)params boundary:(NSString *)boundary;

// Append GET params to a URL
- (void)appendGETParams:(NSDictionary *)params toURL:(NSURL **)url;

// DRY up auth & error checking
- (NSError *)checkAuth;
- (NSError *)checkError:(id)json;

@end
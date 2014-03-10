//
//  FHSTwitterEngine+RequestGeneration.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/10/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "FHSTwitterEngine.h"

@interface FHSTwitterEngine (Requests)

- (int)parameterLengthForURL:(NSString *)url params:(NSMutableDictionary *)params;

// send requests
- (id)sendRequest:(NSURLRequest *)request;

// Just here so I don't have to change a bunch of code
- (NSError *)sendPOSTRequestForURL:(NSURL *)url andParams:(NSDictionary *)params;
- (id)sendGETRequestForURL:(NSURL *)url andParams:(NSDictionary *)params;

// The heart of FHSTwitterEngine
- (id)sendRequestWithHTTPMethod:(NSString *)httpmethod URL:(NSURL *)url params:(NSDictionary *)params;

// Generate streaming request used in FHSStream
- (id)streamingRequestForURL:(NSURL *)url HTTPMethod:(NSString *)method parameters:(NSDictionary *)params;

// Request signing
- (void)signRequest:(NSMutableURLRequest *)request;
- (void)signRequest:(NSMutableURLRequest *)request withToken:(NSString *)tokenString tokenSecret:(NSString *)tokenSecretString verifier:(NSString *)verifierString;

@end

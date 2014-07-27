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

// Generate an OAuth signed request
- (NSMutableURLRequest *)requestWithURL:(NSURL *)url HTTPMethod:(NSString *)httpMethod params:(NSDictionary *)params;
- (NSMutableURLRequest *)requestWithURL:(NSURL *)url HTTPMethod:(NSString *)httpMethod params:(NSDictionary *)params sign:(BOOL)sign;

// DRY up auth & error checking
- (NSError *)checkAuth;
- (NSError *)checkError:(id)json;

@end
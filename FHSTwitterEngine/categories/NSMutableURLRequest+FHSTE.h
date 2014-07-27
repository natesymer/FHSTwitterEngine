//
//  NSMutableURLRequest+FHSTE.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 7/25/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableURLRequest (FHSTE)

- (BOOL)isW3FormURLEncoded;
- (NSDictionary *)postParameters;
- (NSDictionary *)getParameters;

+ (NSMutableURLRequest *)defaultRequestWithURL:(NSURL *)url;
+ (NSMutableURLRequest *)GETRequestWithURL:(NSURL *)url params:(NSDictionary *)params;
+ (NSMutableURLRequest *)formURLEncodedPOSTRequestWithURL:(NSURL *)url params:(NSDictionary *)params;
+ (NSMutableURLRequest *)multipartPOSTRequestWithURL:(NSURL *)url params:(NSDictionary *)params;

@end

//
//  NSMutableURLRequest+FHSTE.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 7/25/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableURLRequest (FHSTE)

+ (NSMutableURLRequest *)defaultRequestWithURL:(NSURL *)url;
+ (NSMutableURLRequest *)GETRequestWithURL:(NSURL *)url params:(NSDictionary *)params;
+ (NSMutableURLRequest *)formURLEncodedPOSTRequestWithURL:(NSURL *)url params:(NSDictionary *)params;
+ (NSMutableURLRequest *)multipartPOSTRequestWithURL:(NSURL *)url params:(NSDictionary *)params;
+ (NSData *)POSTBodyWithParams:(NSDictionary *)params boundary:(NSString *)boundary;

@end

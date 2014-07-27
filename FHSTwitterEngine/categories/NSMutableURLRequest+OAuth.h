//
//  NSMutableURLRequest+OAuth.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 7/25/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableURLRequest (OAuth)

// This one generates a timestamp and nonce for you.
// The nonce is a GUID and the timestamp is time(nil).
- (NSString *)OAuthHeaderWithToken:(NSString *)token
                       tokenSecret:(NSString *)tokenSecret
                          verifier:(NSString *)verifier
                       consumerKey:(NSString *)consumerKey
                    consumerSecret:(NSString *)consumerSecret
                             realm:(NSString *)realm;

- (NSString *)OAuthHeaderWithToken:(NSString *)token
                       tokenSecret:(NSString *)tokenSecret
                          verifier:(NSString *)verifier
                       consumerKey:(NSString *)consumerKey
                    consumerSecret:(NSString *)consumerSecret
                             nonce:(NSString *)nonce
                         timestamp:(NSString *)timestamp
                             realm:(NSString *)realm;

- (void)signWithToken:(NSString *)token
          tokenSecret:(NSString *)tokenSecret
             verifier:(NSString *)verifier
          consumerKey:(NSString *)consumerKey
       consumerSecret:(NSString *)consumerSecret
                realm:(NSString *)realm;

@end

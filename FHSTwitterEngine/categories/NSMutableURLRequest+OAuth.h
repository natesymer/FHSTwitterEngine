//
//  NSMutableURLRequest+OAuth.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 7/25/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMutableURLRequest (OAuth)

- (NSString *)OAuthHeaderWithToken:(NSString *)token
                       tokenSecret:(NSString *)tokenSecret
                          verifier:(NSString *)verifier
                       consumerKey:(NSString *)consumerKey
                    consumerSecret:(NSString *)consumerSecret
                             realm:(NSString *)realm;

- (void)signWithToken:(NSString *)token
          tokenSecret:(NSString *)tokenSecret
             verifier:(NSString *)verifier
          consumerKey:(NSString *)consumerKey
       consumerSecret:(NSString *)consumerSecret
                realm:(NSString *)realm;

@end

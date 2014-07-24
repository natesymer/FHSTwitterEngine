//
//  FHSTwitterEngine+iOS.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/12/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "FHSTwitterEngine+iOS.h"

@implementation FHSTwitterEngine (iOS)

- (void)authenticateWithAccount:(ACAccount *)account completion:(ReverseAuthCompletionBlock)completionBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            id res = [FHSTwitterEngine.sharedEngine getRequestTokenReverseAuth:YES];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                if ([res isKindOfClass:[NSString class]]) {
                    @autoreleasepool {
                        SLRequest *req = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                            requestMethod:SLRequestMethodPOST
                                                                      URL:[NSURL URLWithString:url_oauth_access_token]
                                                               parameters:@{
                                                                            @"x_reverse_auth_target": self.consumerKey,
                                                                            @"x_reverse_auth_parameters": (NSString *)res
                                                                            }
                                          ];
                        
                        req.account = account;
                        
                        [req performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                @autoreleasepool {
                                    if (error) {
                                        completionBlock(error);
                                    } else {
                                        NSString *httpBody = [[NSString alloc]initWithData:responseData encoding:NSUTF8StringEncoding];
                                        
                                        if (httpBody.length > 0) {
                                            [self storeAccessToken:httpBody];
                                            completionBlock(nil);
                                        } else {
                                            completionBlock([NSError noDataError]);
                                        }
                                    }
                                }
                            });
                        }];
                    }
                } else {
                    if ([res isKindOfClass:[NSError class]]) completionBlock(res);
                    else completionBlock([NSError errorWithDomain:kFHSErrorDomain code:-2002 userInfo:@{NSLocalizedDescriptionKey: @"FHSTwitterEngine's reverse auth code is broken, please let @natesymer or @dkhamsing know."}]);
                }
            });
        }
    });
}

@end

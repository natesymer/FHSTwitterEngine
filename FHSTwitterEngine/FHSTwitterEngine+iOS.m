//
//  FHSTwitterEngine+iOS.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/12/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "FHSTwitterEngine+iOS.h"

@implementation FHSTwitterEngine (iOS)

- (ACAccountStore *)accountStore {
    static ACAccountStore *accountStore = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        accountStore = [[ACAccountStore alloc]init];
    });
    return accountStore;
}

- (void)reverseAuthWithAccountSelectionBlock:(AccountSelectionBlock)accSelBlock completion:(ReverseAuthCompletionBlock)completionBlock {
    
    ACAccountType *twitterType = [self.accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [self.accountStore requestAccessToAccountsWithType:twitterType options:nil completion:^(BOOL granted, NSError *error) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            @autoreleasepool {
                
                if (error) {
                    completionBlock(error);
                } else if (!granted) {
                    completionBlock([NSError errorWithDomain:kFHSErrorDomain code:-2000 userInfo:@{ NSLocalizedDescriptionKey: @"Failed to gain access to local Twitter accounts." }]);
                } else {
                    NSArray *accounts = [self.accountStore accountsWithAccountType:twitterType];
                    
                    if (accounts.count == 0) {
                        completionBlock(NO);
                    } else {
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
                                            
                                            req.account = accSelBlock(accounts);
                                            
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
                                                                completionBlock([NSError errorWithDomain:kFHSErrorDomain code:-2001 userInfo:@{NSLocalizedDescriptionKey: @"A response with an empty body was returned."}]);
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
                }
            }
        });
    }];
}

@end

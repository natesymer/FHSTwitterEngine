//
//  FHSOAuthModel.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/10/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "FHSOAuthModel.h"

@implementation FHSConsumer

+ (FHSConsumer *)consumerWithKey:(NSString *)key secret:(NSString *)secret {
    return [[[self class]alloc]initWithKey:key secret:secret];
}

- (instancetype)initWithKey:(NSString *)key secret:(NSString *)secret {
    self = [super init];
    if (self) {
        self.key = key;
        self.secret = secret;
    }
    return self;
}

@end

@implementation FHSToken

+ (FHSToken *)tokenWithHTTPResponseBody:(NSString *)body {
    return [[[self class]alloc]initWithHTTPResponseBody:body];
}

- (instancetype)initWithHTTPResponseBody:(NSString *)body {
    self = [super init];
	if (self) {
        if (body.length > 0) {
            NSArray *pairs = [body componentsSeparatedByString:@"&"];
            
            for (NSString *pair in pairs) {
                NSArray *elements = [pair componentsSeparatedByString:@"="];
                
                if (elements.count > 1) {
                    NSString *field = elements[0];
                    NSString *value = elements[1];
                    
                    if ([field isEqualToString:@"oauth_token"]) {
                        self.key = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    } else if ([field isEqualToString:@"oauth_token_secret"]) {
                        self.secret = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    } else if ([field isEqualToString:@"screen_name"]) {
                        self.username = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    } else if ([field isEqualToString:@"user_id"]) {
                        self.user_id = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                    }
                }
            }
        }
	}
    
    return self;
}

@end
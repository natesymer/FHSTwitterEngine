//
//  lol.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/10/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FHSConsumer : NSObject

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *secret;

+ (FHSConsumer *)consumerWithKey:(NSString *)key secret:(NSString *)secret;

@end

@interface FHSToken : NSObject

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *secret;
@property (nonatomic, strong) NSString *verifier;

+ (FHSToken *)tokenWithHTTPResponseBody:(NSString *)body;

@end
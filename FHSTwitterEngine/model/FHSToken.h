//
//  FHSToken.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/14/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FHSToken : NSObject

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *secret;
@property (nonatomic, strong) NSString *verifier;

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *user_id;

+ (instancetype)tokenWithHTTPResponseBody:(NSString *)body;
- (instancetype)initWithHTTPResponseBody:(NSString *)body;

@end

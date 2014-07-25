//
//  NSURLRequest+FHSTE.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 7/24/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLRequest (FHSTE)

- (BOOL)isW3FormURLEncoded;
- (NSDictionary *)postBodyDictionary;

@end

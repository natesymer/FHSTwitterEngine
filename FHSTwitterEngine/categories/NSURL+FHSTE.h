//
//  NSURL+FHSTE.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/10/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (FHSTwitterEngine)

- (NSURL *)URLWithoutQuery;
- (NSDictionary *)queryParameters;

@end

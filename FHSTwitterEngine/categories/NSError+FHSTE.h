//
//  NSError+FHSTE.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/10/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const FHSErrorDomain;

@interface NSError (FHSTwitterEngine)

+ (NSError *)badRequestError;
+ (NSError *)noDataError;
+ (NSError *)imageTooLargeError;
+ (NSError *)errorWithErrors:(NSArray *)errors;

@end

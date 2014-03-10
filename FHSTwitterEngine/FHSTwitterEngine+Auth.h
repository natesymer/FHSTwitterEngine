//
//  FHSTwitterEngine+Auth.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/10/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "FHSTwitterEngine.h"

@interface FHSTwitterEngine (Auth)

- (id)getRequestToken;
- (BOOL)finishAuthWithRequestToken:(FHSToken *)reqToken;
- (NSError *)authenticateWithUsername:(NSString *)username password:(NSString *)password;

@end

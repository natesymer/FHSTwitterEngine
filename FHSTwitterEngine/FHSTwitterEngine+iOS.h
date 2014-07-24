//
//  FHSTwitterEngine+iOS.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/12/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import "FHSTwitterEngine.h"

#import <Social/Social.h>
#import <Accounts/Accounts.h>

typedef void(^AccountsFoundBlock)(NSArray *accounts, NSError *error);
typedef void(^ReverseAuthCompletionBlock)(NSError *error);

@interface FHSTwitterEngine (iOS)

- (void)authenticateWithAccount:(ACAccount *)account completion:(ReverseAuthCompletionBlock)completionBlock;

@end

//
//  FHSOAuthLoginController.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/10/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FHSToken;

typedef NS_ENUM(NSInteger, FHSTwitterEngineControllerResult) {
    FHSTwitterEngineControllerResultFailed,
    FHSTwitterEngineControllerResultSucceeded,
    FHSTwitterEngineControllerResultCancelled
};

typedef void(^LoginBlock)(BOOL cancelled, NSError *error);


/**
 `FHSOAuthLoginController` provides a view controller for `FHSTwitterEngine` to use OAuth.
 */

@interface FHSOAuthLoginController : UIViewController <UIWebViewDelegate>


/**
 The request token.
 */
//@property (nonatomic, strong) FHSToken *requestToken;


/**
 The `LoginBlock` block which returns a `BOOL` and an `NSError`.
 */
@property (nonatomic, copy) LoginBlock block;


/**
 Initializes `FHSTwitterEngineController` with a `LoginBlock` block.
 @param block Block of type `LoginBlock`
 @return An instance of `FHSTwitterEngineController`
 */
- (instancetype)initWithCompletionBlock:(LoginBlock)block;


/**
 Gets an instance of `FHSTwitterEngineController` with an `LoginBlock` block.
 @param block Block of type `LoginBlock`
 */
+ (instancetype)controllerWithCompletionBlock:(LoginBlock)block;

@end


#pragma mark - Constants
/// @name Constants

/**
 ## FHSTwitterEngineControllerResult
 
 The following constants are provided by `FHSTwitterEngineController` as possible result.
 
 enum {
 FHSTwitterEngineControllerResultFailed,
 FHSTwitterEngineControllerResultSucceeded,
 FHSTwitterEngineControllerResultCancelled
 }
 
 `FHSTwitterEngineControllerResultFailed`
 Failed authentication.
 
 `FHSTwitterEngineControllerResultSucceeded`
 Succeeded authentication.
 
 `FHSTwitterEngineControllerResultCancelled`
 Cancelled authentication.
 */

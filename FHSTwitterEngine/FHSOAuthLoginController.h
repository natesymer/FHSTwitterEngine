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

typedef void(^LoginControllerBlock)(FHSTwitterEngineControllerResult result);


/**
 `FHSOAuthLoginController` provides a view controller for `FHSTwitterEngine` to use OAuth.
 */

@interface FHSOAuthLoginController : UIViewController <UIWebViewDelegate>

/**
 The controller navigation bar.
 */
@property (nonatomic, strong) UINavigationBar *navBar;


/**
 The controller web view.
 */
@property (nonatomic, strong) UIWebView *theWebView;


/**
 The label with the loading text. The default is set to "Please Wait...".
 */
@property (nonatomic, strong) UILabel *loadingText;


/**
 The loading spinner used with `loadingText`.
 */
@property (nonatomic, strong) UIActivityIndicatorView *spinner;


/**
 The request token.
 */
@property (nonatomic, strong) FHSToken *requestToken;


/**
 The `LoginControllerBlock` block which returns a `FHSTwitterEngineControllerResult`.
 */
@property (nonatomic, copy) LoginControllerBlock block;


/**
 Initializes `FHSTwitterEngineController` with `LoginControllerBlock` block.
 @param block Block of type `LoginControllerBlock`
 @return An instance of `FHSTwitterEngineController`
 */
- (instancetype)initWithCompletionBlock:(LoginControllerBlock)block;


/**
 Gets an instance of `FHSTwitterEngineController` with `LoginControllerBlock` block.
 @param block Block of type `LoginControllerBlock`
 */
+ (FHSOAuthLoginController *)controllerWithCompletionBlock:(LoginControllerBlock)block;

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

//
//  FHSTwitterEngineController.h
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
 `FHSTwitterEngineController` provides a view controller for `FHSTwitterEngine` to use OAuth.
 */

@interface FHSTwitterEngineController : UIViewController <UIWebViewDelegate>

@property (nonatomic, strong) UINavigationBar *navBar;
@property (nonatomic, strong) UIWebView *theWebView;
@property (nonatomic, strong) UILabel *loadingText;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) FHSToken *requestToken;
@property (nonatomic, copy) LoginControllerBlock block;

/**
 Initializes `FHSTwitterEngineController.h` with `LoginControllerBlock` block.
 @param block Block of type `LoginControllerBlock`
 @return An instance of `FHSTwitterEngineController`
 */
- (instancetype)initWithCompletionBlock:(LoginControllerBlock)block;

/**
 TODO:
 */
+ (FHSTwitterEngineController *)controllerWithCompletionBlock:(LoginControllerBlock)block;

@end


///----------------
/// @name Constants
///----------------

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

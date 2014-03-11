//
//  FHSOAuthLoginController.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/10/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FHSOAuthModel.h"

typedef enum {
    FHSTwitterEngineControllerResultFailed,
    FHSTwitterEngineControllerResultSucceeded,
    FHSTwitterEngineControllerResultCancelled
} FHSTwitterEngineControllerResult;

typedef void(^LoginControllerBlock)(FHSTwitterEngineControllerResult result);

@interface FHSTwitterEngineController : UIViewController <UIWebViewDelegate>

@property (nonatomic, strong) UINavigationBar *navBar;
@property (nonatomic, strong) UIWebView *theWebView;
@property (nonatomic, strong) UILabel *loadingText;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) FHSToken *requestToken;
@property (nonatomic, copy) LoginControllerBlock block;

- (instancetype)initWithCompletionBlock:(LoginControllerBlock)block;
+ (FHSTwitterEngineController *)controllerWithCompletionBlock:(LoginControllerBlock)block;

@end
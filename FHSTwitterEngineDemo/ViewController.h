//
//  ViewController.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 8/22/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FHSTwitterEngine;

@interface ViewController : UIViewController {
    IBOutlet UITextField *passwordField;
    IBOutlet UITextField *usernameField;
    IBOutlet UITextField *tweetField;
    IBOutlet UILabel *loggedInUserLabel;
}

@property (nonatomic, strong) FHSTwitterEngine *engine;

@property (nonatomic, strong) IBOutlet UITextField *passwordField;
@property (nonatomic, strong) IBOutlet UITextField *usernameField;
@property (nonatomic, strong) IBOutlet UITextField *tweetField;
@property (nonatomic, strong) IBOutlet UILabel *loggedInUserLabel;

@end

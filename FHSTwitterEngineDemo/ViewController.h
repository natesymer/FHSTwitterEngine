//
//  ViewController.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 8/22/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FHSTwitterEngine.h"


@interface ViewController : UIViewController <FHSTwitterEngineAccessTokenDelegate, UIAlertViewDelegate> {
    IBOutlet UITextField *tweetField;
    IBOutlet UILabel *loggedInUserLabel;
}

@property (nonatomic, strong) FHSTwitterEngine *engine;

@property (nonatomic, strong) IBOutlet UITextField *tweetField;
@property (nonatomic, strong) IBOutlet UILabel *loggedInUserLabel;

@end

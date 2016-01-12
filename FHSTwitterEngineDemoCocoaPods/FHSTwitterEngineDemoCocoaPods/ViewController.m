//
//  ViewController.m
//  FHSTwitterEngineDemoCocoaPods
//
//  Created by Daniel Khamsing on 12/8/15.
//  Copyright © 2015 Daniel Khamsing. All rights reserved.
//

#import "ViewController.h"
#import "FHSTwitterEngine.h"

@interface ViewController () <FHSTwitterEngineAccessTokenDelegate>

@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@property (weak, nonatomic) IBOutlet UIButton *getTweetsButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[FHSTwitterEngine sharedEngine]permanentlySetConsumerKey:@"8EfOoU20N2kmrdKH3JXNw" andSecret:@"k5yXQiJghM1bdlLhgKlfDVarAiyX8hsQREyQhLpsMw8"];
    [[FHSTwitterEngine sharedEngine]setDelegate:self];
}

- (IBAction)loginAction:(id)sender {
    UIViewController *loginController = [[FHSTwitterEngine sharedEngine]loginControllerWithCompletionHandler:^(BOOL success) {
        NSLog(success?@"L0L success":@"O noes!!! Loggen faylur!!!");
        
        self.loginButton.userInteractionEnabled = NO;
        [self.loginButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [self.loginButton setTitle:@"Logged in :-)" forState:UIControlStateNormal];
    }];
    [self presentViewController:loginController animated:YES completion:nil];
}

- (IBAction)getTweetsAction:(id)sender {
    if (![FHSTwitterEngine sharedEngine].isAuthorized) {
        [self alertWithTitle:@"Please login first" message:nil];
        return;
    }
    
    NSLog(@"%@",[[FHSTwitterEngine sharedEngine]getTimelineForUser:[[FHSTwitterEngine sharedEngine]authenticatedID] isID:YES count:10]);
    
    [self alertWithTitle:@"Success" message:@"Check your console for latest tweets"];
}

#pragma mark - Private

- (void)alertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil];
    [controller addAction:action];
    
    
    [self presentViewController:controller animated:YES completion:nil];
}

# pragma mark - FHSTwitterEngine

- (void)storeAccessToken:(NSString *)accessToken {
    [[NSUserDefaults standardUserDefaults]setObject:accessToken forKey:@"SavedAccessHTTPBody"];
}

- (NSString *)loadAccessToken {
    return [[NSUserDefaults standardUserDefaults]objectForKey:@"SavedAccessHTTPBody"];
}


@end

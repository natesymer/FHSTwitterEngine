//
//  ViewController.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 8/22/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "ViewController.h"
#import "FHSTwitterEngine.h"

@interface ViewController () <FHSTwitterEngineAccessTokenDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) IBOutlet UITextField *tweetField;
@property (nonatomic, strong) IBOutlet UILabel *loggedInUserLabel;

@end

@implementation ViewController

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSString *username = [alertView textFieldAtIndex:0].text;
        NSString *password = [alertView textFieldAtIndex:1].text;
        
        dispatch_async(GCDBackgroundThread, ^{
            @autoreleasepool {
                [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
                NSError *returnCode = [[FHSTwitterEngine sharedEngine]getXAuthAccessTokenForUsername:username password:password];
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;

                dispatch_sync(GCDMainThread, ^{
                    @autoreleasepool {
                        NSString *title = nil;
                        NSString *message = nil;
                        
                        if (returnCode) {
                            title = [NSString stringWithFormat:@"Error %d",returnCode.code];
                            message = returnCode.domain;
                        } else {
                            title = @"Success";
                            message = @"You have successfully logged in via XAuth";
                            NSString *username = [[FHSTwitterEngine sharedEngine]loggedInUsername]; //self.engine.loggedInUsername;
                            if (username.length > 0) {
                                _loggedInUserLabel.text = [NSString stringWithFormat:@"Logged in as %@.",username];
                            } else {
                                _loggedInUserLabel.text = @"You are not logged in.";
                            }
                        }
                        UIAlertView *av = [[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [av show];
                    }
                });
            }
        });
    }
}

- (void)storeAccessToken:(NSString *)accessToken {
    [[NSUserDefaults standardUserDefaults]setObject:accessToken forKey:@"SavedAccessHTTPBody"];
}

- (NSString *)loadAccessToken {
    return [[NSUserDefaults standardUserDefaults]objectForKey:@"SavedAccessHTTPBody"];
}

- (IBAction)showLoginWindow:(id)sender {
    UIViewController *loginController = [[FHSTwitterEngine sharedEngine]loginControllerWithCompletionHandler:^(BOOL success) {
        NSLog(success?@"L0L success":@"O noes!!! Loggen faylur!!!");
    }];
    [self presentViewController:loginController animated:YES completion:nil];
}

- (IBAction)logout:(id)sender {
    [_tweetField resignFirstResponder];
    _loggedInUserLabel.text = @"You are not logged in.";
    [[FHSTwitterEngine sharedEngine]clearAccessToken];
}

- (IBAction)loginXAuth:(id)sender {
    UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"xAuth Login" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Login", nil];
    [av setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
    [[av textFieldAtIndex:0]setPlaceholder:@"Username"];
    [[av textFieldAtIndex:1]setPlaceholder:@"Password"];
    [av show];
}

- (IBAction)listFriends:(id)sender {
    [_tweetField resignFirstResponder];
    dispatch_async(GCDBackgroundThread, ^{
        @autoreleasepool {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            NSLog(@"Friends' IDs: %@",[[FHSTwitterEngine sharedEngine]getFriendsIDs]);
            
            dispatch_sync(GCDMainThread, ^{
                @autoreleasepool {
                    [[[UIAlertView alloc]initWithTitle:@"Complete" message:@"Your list of followers has been fetched..." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]show];
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                }
            });
        }
    });
}

- (IBAction)postTweet:(id)sender {

    [_tweetField resignFirstResponder];
    
    dispatch_async(GCDBackgroundThread, ^{
        @autoreleasepool {
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            NSError *returnCode = [[FHSTwitterEngine sharedEngine]postTweet:self.tweetField.text];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            NSString *title = nil;
            NSString *message = nil;
            
            if (returnCode) {
                title = [NSString stringWithFormat:@"Error %d",returnCode.code];
                message = returnCode.localizedDescription;
            } else {
                title = @"Tweet Posted";
                message = _tweetField.text;
            }
            
            dispatch_sync(GCDMainThread, ^{
                @autoreleasepool {
                    UIAlertView *av = [[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [av show];
                }
            });
        }
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[FHSTwitterEngine sharedEngine]permanentlySetConsumerKey:@"Xg3ACDprWAH8loEPjMzRg" andSecret:@"9LwYDxw1iTc6D9ebHdrYCZrJP4lJhQv5uf4ueiPHvJ0"];
    [[FHSTwitterEngine sharedEngine]setDelegate:self];
    [self.tweetField addTarget:self action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
}

- (void)viewWillAppear:(BOOL)animated {
    [[FHSTwitterEngine sharedEngine]loadAccessToken];
    NSString *username = [[FHSTwitterEngine sharedEngine]loggedInUsername];// self.engine.loggedInUsername;
    if (username.length > 0) {
        _loggedInUserLabel.text = [NSString stringWithFormat:@"Logged in as %@",username];
    } else {
        _loggedInUserLabel.text = @"You are not logged in.";
    }
}

@end

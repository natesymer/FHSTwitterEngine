//
//  ViewController.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 8/22/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "ViewController.h"
#import "FHSTwitterEngine.h"

@implementation ViewController

@synthesize engine, tweetField, loggedInUserLabel;

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        NSString *username = [alertView textFieldAtIndex:0].text;
        NSString *password = [alertView textFieldAtIndex:1].text;
        
        dispatch_async(GCDBackgroundThread, ^{
            @autoreleasepool {
                [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
                NSError *returnCode = [self.engine getXAuthAccessTokenForUsername:username password:password];
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
                            NSString *username = self.engine.loggedInUsername;
                            if (username.length > 0) {
                                loggedInUserLabel.text = [NSString stringWithFormat:@"Logged in as %@.",username];
                            } else {
                                loggedInUserLabel.text = @"You are not logged in.";
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
    [self presentModalViewController:[self.engine OAuthLoginWindow] animated:YES];
}

- (IBAction)logout:(id)sender {
    [tweetField resignFirstResponder];
    [self.engine clearAccessToken];
    loggedInUserLabel.text = @"You are not logged in.";
}

- (IBAction)loginXAuth:(id)sender {
    UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"xAuth Login" message:@"" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Login", nil];
    [av setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
    [[av textFieldAtIndex:0]setPlaceholder:@"Username"];
    [[av textFieldAtIndex:1]setPlaceholder:@"Password"];
    [av show];
}

- (IBAction)listFriends:(id)sender {
    [tweetField resignFirstResponder];
    dispatch_async(GCDBackgroundThread, ^{
        @autoreleasepool {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            
            NSLog(@"%@",[self.engine getUserInformationForUsers:[NSArray arrayWithObjects:@"fhsjaagshs", @"twitter", nil] areUsers:YES]);
            
            NSLog(@"followers:\n%@",[self.engine getFollowers]);
            
            dispatch_sync(GCDMainThread, ^{
                @autoreleasepool {
                    UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Complete!" message:@"Your list of followers has been fetched" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [av show];
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                }
            });
        }
    });
}

- (IBAction)postTweet:(id)sender {

    [tweetField resignFirstResponder];
    
    dispatch_async(GCDBackgroundThread, ^{
        @autoreleasepool {
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            NSError *returnCode = [self.engine postTweet:tweetField.text];
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            NSString *title = nil;
            NSString *message = nil;
            
            if (returnCode) {
                title = [NSString stringWithFormat:@"Error %d",returnCode.code];
                message = returnCode.domain;
            } else {
                title = @"Tweet Posted";
                message = tweetField.text;
            }
            
            dispatch_sync(GCDMainThread, ^{
                UIAlertView *av = [[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [av show];
            });
        }
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.engine = [[FHSTwitterEngine alloc]initWithConsumerKey:@"" andSecret:@""];
    [tweetField addTarget:self action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.engine loadAccessToken];
    NSString *username = self.engine.loggedInUsername;
    if (username.length > 0) {
        loggedInUserLabel.text = [NSString stringWithFormat:@"Logged in as %@",username];
    } else {
        loggedInUserLabel.text = @"You are not logged in.";
    }
}

@end

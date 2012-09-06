//
//  ViewController.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 8/22/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "ViewController.h"
#import "FHSTwitterEngine.h"
#import "OAAsynchronousDataFetcher.h"

@implementation ViewController

@synthesize engine, tweetField, passwordField, usernameField, loggedInUserLabel;

- (IBAction)showLoginWindow:(id)sender {
    [self presentModalViewController:[self.engine OAuthLoginWindow] animated:YES];
}

- (IBAction)logout:(id)sender {
    [self.engine clearAccessToken];
    NSString *username = self.engine.loggedInUsername;
    if (username.length > 0) {
        loggedInUserLabel.text = [NSString stringWithFormat:@"Logged in as %@.",username];
    } else {
        loggedInUserLabel.text = @"You are not logged in.";
    }
}

- (IBAction)loginXAuth:(id)sender {
    dispatch_async(GCDBackgroundThread, ^{
        int returnCode = [self.engine getXAuthAccessTokenForUsername:usernameField.text password:passwordField.text];
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
        
        if (returnCode == 0) {
            [dict setObject:@"Success" forKey:@"title"];
            [dict setObject:@"You have successfully logged in via XAuth" forKey:@"message"];
        }
        
        if (returnCode > 0) {
            dict = [[NSMutableDictionary alloc]initWithDictionary:[self.engine lookupErrorCode:returnCode]];
        }
        
        dispatch_sync(GCDMainThread, ^{
            UIAlertView *av = [[UIAlertView alloc]initWithTitle:[dict objectForKey:@"title"] message:[dict objectForKey:@"message"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [av show];
        });
    });
}

- (IBAction)listFriends:(id)sender {
    dispatch_async(GCDBackgroundThread, ^{
        NSLog(@"Friends: %@",[self.engine getFriends]);
        NSLog(@"Privacy Policy: %@",[self.engine getPrivacyPolicy]);
    });
    
    OAMutableURLRequest *req = [[OAMutableURLRequest alloc]initWithURL:nil consumer:nil token:nil realm:nil signatureProvider:nil];
    [req parameters];
}

- (IBAction)postTweet:(id)sender {
    dispatch_async(GCDBackgroundThread, ^{
        int returnCode = [self.engine postTweet:tweetField.text];
        
        NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
        
        if (returnCode == 0) {
            [dict setObject:@"Tweet Posted" forKey:@"title"];
            [dict setObject:tweetField.text forKey:@"message"];
        }
        
        if (returnCode > 0) {
            dict = [[NSMutableDictionary alloc]initWithDictionary:[self.engine lookupErrorCode:returnCode]];
        }
        
        dispatch_sync(GCDMainThread, ^{
            UIAlertView *av = [[UIAlertView alloc]initWithTitle:[dict objectForKey:@"title"] message:[dict objectForKey:@"message"] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [av show];
        });
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.engine = [[FHSTwitterEngine alloc]initWithConsumerKey:@"Xg3ACDprWAH8loEPjMzRg" andSecret:@"9LwYDxw1iTc6D9ebHdrYCZrJP4lJhQv5uf4ueiPHvJ0"];
    [passwordField addTarget:self action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
    [usernameField addTarget:self action:@selector(resignFirstResponder) forControlEvents:UIControlEventEditingDidEndOnExit];
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

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end

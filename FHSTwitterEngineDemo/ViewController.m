//
//  ViewController.m
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 8/22/12.
//  Copyright (c) 2012 Nathaniel Symer. All rights reserved.
//

#import "ViewController.h"
#import "FHSTwitterEngine.h"
#import "FHSOAuthLoginController.h"
#import "FHSTwitterEngine+Requests.h"
#import "FHSTwitterEngine+iOS.h"

static NSString * const TwitPicAPIKey = @"dc85de02fa89e78ecc41804617a5b171";

@interface ViewController () <UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>

@property (nonatomic, strong) UITableView *theTableView;
@property (nonatomic, assign) BOOL isStreaming;

@end

@implementation ViewController

- (void)loadView {
    [super loadView];
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    self.theTableView = [[UITableView alloc]initWithFrame:UIScreen.mainScreen.bounds style:UITableViewStylePlain];
    _theTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _theTableView.dataSource = self;
    _theTableView.delegate = self;
    _theTableView.contentInset = UIEdgeInsetsMake(20+44, 0, 0, 0);
    _theTableView.scrollIndicatorInsets = _theTableView.contentInset;
    [self.view addSubview:_theTableView];
    
    UINavigationBar *bar = [[UINavigationBar alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, (UIDevice.currentDevice.systemVersion.floatValue >= 7.0f)?64:44)];
    bar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    UINavigationItem *navItem = [[UINavigationItem alloc]initWithTitle:@"FHSTwitterEngine"];
	
    navItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Auth" style:UIBarButtonItemStylePlain target:self action:@selector(auth)];
    
    [bar pushNavigationItem:navItem animated:NO];
    [self.view addSubview:bar];
    
    // This is if you want to use xAuth
    // It uses the keys from Feathers (by Naklab) without the developer's permission.
    [[FHSTwitterEngine shared]permanentlySetConsumerKey:@"iD3JmMTXZ36MlISkfmkFvg" andSecret:@"B7HLYGJpwnyZr8fJeUGidW129i3cpgI2WsyGsHM2s"];
    
 //   [[FHSTwitterEngine sharedEngine]permanentlySetConsumerKey:@"Xg3ACDprWAH8loEPjMzRg" andSecret:@"9LwYDxw1iTc6D9ebHdrYCZrJP4lJhQv5uf4ueiPHvJ0"];
    [[FHSTwitterEngine shared]loadAccessToken];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"Created by @natesymer and @dkhamsing";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return FHSTwitterEngine.shared.isAuthorized?5:3;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.row) {
        case 0:
            [self postTweet];
            break;
        case 1:
            [self logTimeline];
            break;
        case 2:
            [self toggleStreaming];
            break;
        case 3:
            [self logout];
            break;
        case 4: {
            NSLog(@"Demo - Posting tweet with multiple upload ");

            NSArray *imageArray = @[[UIImage imageNamed:@"image1"], [UIImage imageNamed:@"image2"]];
            
            NSString *tweet = [NSString stringWithFormat:@"Multiple images %@", @(arc4random()%100)];
            NSLog(@"Posting Multiple Images (Response):\n%@",[FHSTwitterEngine.shared postTweet:tweet withImages:imageArray]);
        }
            break;
        default:
            break;
    }
    
    [_theTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellID = @"CellID";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellID];
    }
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Post Tweet";
            cell.detailTextLabel.text = nil;
            break;
        case 1:
            cell.textLabel.text = @"Log Timeline";
            cell.detailTextLabel.text = nil;
            break;
        case 2:
            cell.textLabel.text = @"Log Stream";
            cell.detailTextLabel.text = nil;
            break;
        case 3:
            cell.textLabel.text = @"Logout";
            cell.detailTextLabel.text = FHSTwitterEngine.shared.accessToken.username;
            break;
            
        case 4:
            cell.textLabel.text = @"Post Tweet With Multiple Images";
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self loginOAuth];
            break;
            
        case 1:
            [self loginReverseAuth];
            break;
            
        case 2:
            [self loginXAuth];
            break;
            
        default:
            break;
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:@"Tweet"]) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @autoreleasepool {
                NSString *tweet = [alertView textFieldAtIndex:0].text;
                id returned = [[FHSTwitterEngine shared]postTweet:tweet];
                [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                
                NSString *title = nil;
                NSString *message = nil;
                
                if ([returned isKindOfClass:[NSError class]]) {
                    NSError *error = (NSError *)returned;
                    title = [NSString stringWithFormat:@"Error %ld",(long)error.code];
                    message = error.localizedDescription;
                } else {
                    NSLog(@"%@",returned);
                    title = @"Tweet Posted";
                    message = tweet;
                }
                
                dispatch_sync(dispatch_get_main_queue(), ^{
                    @autoreleasepool {
                        UIAlertView *av = [[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                        [av show];
                    }
                });
            }
        });
    } else {
        if (buttonIndex == 1) {
            NSString *username = [alertView textFieldAtIndex:0].text;
            NSString *password = [alertView textFieldAtIndex:1].text;
            
            [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                @autoreleasepool {
                    // getXAuthAccessTokenForUsername:password: returns an NSError, not id.
                    NSError *returnValue = [[FHSTwitterEngine shared]authenticateWithUsername:username password:password];
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                    
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        @autoreleasepool {
                            NSString *title = returnValue?[NSString stringWithFormat:@"Error %ld",(long)returnValue.code]:@"Success";
                            NSString *message = returnValue?returnValue.localizedDescription:@"You have successfully logged in via XAuth";
                            UIAlertView *av = [[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                            [av show];
                            [_theTableView reloadData];
                        }
                    });
                }
            });
        }
    }
}

- (void)storeAccessToken:(NSString *)accessToken {
    [[NSUserDefaults standardUserDefaults]setObject:accessToken forKey:@"SavedAccessHTTPBody"];
}

- (NSString *)loadAccessToken {
    return [[NSUserDefaults standardUserDefaults]objectForKey:@"SavedAccessHTTPBody"];
}


- (void)auth {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"FHSTwitterEngine Auth Methods" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil  otherButtonTitles:@"OAuth", @"Reverse Auth", @"XAuth", nil];
    [sheet showInView:self.view];
}

//
// A note about reverse Auth:
// Account picking is not simplified or wrapped
// It's up to YOU to get a suitable ACAccount. Then
// you can pass it to FHSTwitterEngine and go from there.
//

- (void)loginReverseAuth {
    // Check if user has set up Twitter
    if (![SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        [[[UIAlertView alloc]initWithTitle:@"Oops" message:@"Twitter is no setup on this device, change this in Settings." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil]show];
        return;
    }
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    ACAccountStore *accountStore = [[ACAccountStore alloc]init];
    ACAccountType *twitterType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:twitterType options:nil completion:^(BOOL granted, NSError *error) {
        UIAlertView *a = [[UIAlertView alloc]initWithTitle:@"Auth Error" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        if (error) {
            a.message = error.localizedDescription;
        } else if (!granted) {
            a.message = @"Failed to gain access to local Twitter accounts.";
        } else {
            NSArray *accounts = [accountStore accountsWithAccountType:twitterType];
            
            if (accounts.count > 0) {
                // I'm being lazy and just saying 'Pick the first one'
                // You should probably pop a UIActionSheet or something
                ACAccount *twitterAccount = accounts.firstObject;
                
                //
                // Actual FHSTwitterEngine call is here.
                //
                
                [[FHSTwitterEngine shared]authenticateWithAccount:twitterAccount completion:^(NSError *error) {
                    NSLog(@"Reverse auth %@",!error?@"succeeded":@"failed");
                    [_theTableView reloadData];
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                }];
            } else {
                a.message = @"No available twitter accounts.";
            }
        }
        if (a.message.length > 0) {
            [a show];
        }
    }];
}

- (void)loginOAuth {
    FHSOAuthLoginController *c = [FHSOAuthLoginController controllerWithCompletionBlock:^(BOOL cancelled, NSError *error) {
        if (cancelled) {
            NSLog(@"Login Controller Cancelled");
            return;
        } else {
            if (error) {
                NSLog(@"Login Controller Failed: %@",error);
            } else {
                NSLog(@"Login Controller Succeeded");
            }
        }
        [_theTableView reloadData];
    }];
    
    [self presentViewController:c animated:YES completion:nil];
}

- (void)loginXAuth {
    UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"xAuth Login" message:@"Enter your Twitter login credentials:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Login", nil];
    [av setAlertViewStyle:UIAlertViewStyleLoginAndPasswordInput];
    [[av textFieldAtIndex:0]setPlaceholder:@"Username"];
    [[av textFieldAtIndex:1]setPlaceholder:@"Password"];
    [av show];
}

- (void)logout {
    [[FHSTwitterEngine shared]clearAccessToken];
    [_theTableView reloadData];
}

- (void)logTimeline {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @autoreleasepool {
            NSLog(@"%@",[[FHSTwitterEngine shared]getTimelineForUser:FHSTwitterEngine.shared.accessToken.user_id isID:YES count:10]);
           // NSLog(@"%@",[FHSTwitterEngine.shared getConfiguration]);
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                @autoreleasepool {
                    [[[UIAlertView alloc]initWithTitle:@"Complete" message:@"Your list of followers has been fetched. Check your debugger." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]show];
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                }
            });
        }
    });
}

- (void)postTweet {
    UIAlertView *av = [[UIAlertView alloc]initWithTitle:@"Tweet" message:@"Write a tweet below. Make sure you're using a testing account." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Tweet", nil];
    [av setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [[av textFieldAtIndex:0]setPlaceholder:@"Write a tweet here..."];
    [av show];
}

- (void)toggleStreaming {
    if (!_isStreaming) {
        self.isStreaming = YES;
        [[FHSTwitterEngine shared]streamSampleStatusesWithBlock:^(id result, BOOL *stop) {
            //NSLog(@"%@",result);
            if (_isStreaming == NO) {
                *stop = YES;
            }
        }];
    } else {
        self.isStreaming = NO;
    }
}

@end

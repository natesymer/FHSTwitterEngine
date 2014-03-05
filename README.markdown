FHSTwitterEngine
================

***Twitter API for Cocoa developers***

Created by [Nathaniel Symer](mailto:nate@natesymer.com), aka [@natesymer](http://twitter.com/natesymer) 

`FHSTwitterEngine` can:

- Authenicate using OAuth and/or xAuth.
- Make a request to just about every API endpoint.

Why you should use `FHSTwitterEngine`:

- Single .h/.m pair
- No dependencies
- Shared instance
- Scientific

Where did OAuthConsumer go? It's gone :) because there were a number of issues with it:

1. It had too much compatibility code
2. It concatenated and signed POST params
3. It could not take raw data as post params by design (see #2)
4. It duplicated functionality I already implemented.

**Setup**

1. Add `FHSTwitterEngine.h` and `FHSTwitterEngine.m` to your project
2. `#import "FHSTwitterEngine.h"` where necessary
3. Link against `SystemConfiguration.framework`
4. Enable ARC for both files if applicable

**Usage:**

> Set up `FHSTwitterEngine`

    [[FHSTwitterEngine sharedEngine]permanentlySetConsumerKey:@"<consumer_key>" andSecret:@"<consumer_secret>"];
> Or with a temporary consumer that gets cleared after each request
 
    [[FHSTwitterEngine sharedEngine]temporarilySetConsumerKey:@"<consumer_key>" andSecret:@"<consumer_secret>"];
         
> Set access token delegate (see header)

    [[FHSTwitterEngine sharedEngine]setDelegate:myDelegate]; 
    
> Login via OAuth:
    
    UIViewController *loginController = [[FHSTwitterEngine sharedEngine]loginControllerWithCompletionHandler:^(BOOL success) {
        NSLog(success?@"L0L success":@"O noes!!! Loggen faylur!!!");
    }];
    [self presentViewController:loginController animated:YES completion:nil];
    
> Login via XAuth:
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    	@autoreleasepool {
    		NSError *error = [[FHSTwitterEngine sharedEngine]getXAuthAccessTokenForUsername:@"<username>" password:@"<password>"];
        	// Handle error
        	dispatch_sync(dispatch_get_main_queue(), ^{
    			@autoreleasepool {
        			// Update UI
        		}
       		});
    	}
    });
    
> Clear the current consumer key

	[[FHSTwitterEngine sharedEngine]clearConsumer];
	
> Load a saved access_token (called when API calls are made):

    [[FHSTwitterEngine sharedEngine]loadAccessToken];

> Clear your access token:

    [[FHSTwitterEngine sharedEngine]clearAccessToken];

> Check if a session is valid:

    [[FHSTwitterEngine sharedEngine]isAuthorized];
    
> Do an API call (POST and GET):

    dispatch_async((dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    	@autoreleasepool {
    		id twitterData = [[FHSTwitterEngine sharedEngine]postTweet:@"Hi!"];
    		// Handle twitterData (see "About GET Requests")
    		dispatch_sync(dispatch_get_main_queue(), ^{
    			@autoreleasepool {
        			// Update UI
        		}
       		});
    	}
    });

**The "Singleton" Pattern**

The singleton pattern allows the programmer to use the library across scopes without having to manually keep a reference to the FHSTwitterEngine object. When the app is killed, any memory used by FHSTwitterEngine is freed.

**Threading**

While you can use any threading technology for threading, I recommend Grand Central Dispatch (GCD).

**General Comments**

`FHSTwitterEngine` will attempt to preemptively detect errors in your requests, before they are actually sent. This includes missing parameters, and a lack of authorization. If FHSTwitterEngine detects that a user is not logged in, it will attempt to load an access token using its delegate. This process is designed to prevent bad requests from being needlessly sent.

**About requests**

Most methods return `id`. The returned object can be a(n):

- `NSMutableDictionary`
- `NSMutableArray`
- `UIImage`
- `NSString`
- `NSError`
- `nil`

**For the future/To Do**

You can [email](mailto:nate@natesymer.com) me with suggestions or open an [issue](https://github.com/fhsjaagshs/FHSTwitterEngine/issues).

- OS X OAuth login window
- Custom objects for profile settings
- Tag releases
- Tests
- Add license
- Create a CocoaPod
- Make demo universal

**Debugging 101 for outsource developers**

Before emailing me, spend an hour trying to fix the problem yourself. Don't go wild and try to change everything, just trace back your steps, and look closely at details. Don't program by permutation.

One common issue appears to be an `#import` loop. This happens when class *a* imports class *b* which, in turn, imports class *a*. Usually, the compiler will give you a warning that should look like: *"multiple declarations of class x"*. However, this warning/error can appear from multiple declarations of class x, so be careful.

If after an hour, you have no solution and your problem is in your code, I don't want to hear it. I'm not getting paid to do your job (that you should be capable of doing yourself). 

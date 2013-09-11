FHSTwitterEngine
================

***Twitter API for Cocoa developers***

Created by [Nathaniel Symer](mailto:nate@natesymer.com), aka [@natesymer](http://twitter.com/natesymer) 

`FHSTwitterEngine` can:

- Authenicate using OAuth and/or xAuth.
- Make a request to just about every API endpoint.

Why you should use `FHSTwitterEngine`:

- Single header/implementation pair
- No dependencies
- Shared instance
- Clean, high level API

Where did OAuthConsumer go? A separate repository. There were a number of issues with it:

1. It had features beyond the scope of the Twitter API
2. It concatenated and signed POST parameters
3. It could not take raw data as parameters (see #2)
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
    
    [[FHSTwitterEngine sharedEngine]showOAuthLoginControllerFromViewController:self withCompletion:^(BOOL success) {
        // handle success
    }];
    
> Login via XAuth:
    
    dispatch_async(GCDBackgroundThread, ^{
    	@autoreleasepool {
    		NSError *error = [[FHSTwitterEngine sharedEngine] getXAuthAccessTokenForUsername:@"<username>" password:@"<password>"];
        	// Handle error
        	dispatch_sync(GCDMainThread, ^{
    			@autoreleasepool {
        			// Update UI
        		}
       		});
    	}
    });
    
> Clear the current consumer key

	[[FHSTwitterEngine sharedEngine]clearConsumer];
	
> Reload a saved access_token:

    [[FHSTwitterEngine sharedEngine]loadAccessToken];

> End a session:

    [[FHSTwitterEngine sharedEngine]clearAccessToken];

> Check if a session is valid:

    [[FHSTwitterEngine sharedEngine]isAuthorized];
    
> Do an API call (POST):

    dispatch_async(GCDBackgroundThread, ^{
    	@autoreleasepool {
    		NSError *error = [[FHSTwitterEngine sharedEngine]twitterAPIMethod]; 
    		// Handle error
    		dispatch_sync(GCDMainThread, ^{
    			@autoreleasepool {
        			// Update UI
        		}
       		});
    	}
    });

> Do an API call (GET):

    dispatch_async(GCDBackgroundThread, ^{
    	@autoreleasepool {
    		id twitterData = [[FHSTwitterEngine sharedEngine]twitterAPIMethod];
    		// Handle twitterData (see "About GET Requests")
    		dispatch_sync(GCDMainThread, ^{
    			@autoreleasepool {
        			// Update UI
        		}
       		});
    	}
    });
<br />
**The "Singleton" Pattern**

The singleton pattern allows the programmer to use the library across scopes without having to manually keep a reference to the FHSTwitterEngine object. When the app is killed, any memory used by FHSTwitterEngine is freed.

**Grand Central Dispatch**

*So what are those `GCDBackgroundThread` and `GCDMainThread` defines?<br />*
The defines are macros for `dispatch_async()` and `dispatch_sync()`. You could use any form of threading for FHSTwitterEngine, but GCD is the recommended technology.

**General Comments**

`FHSTwitterEngine` will attempt to preëmtively detect errors in your requests, before they are actually sent. This includes missing parameters, and a lack of authorization. If FHSTwitterEngine detects that a user is not logged in, it will attempt to load an access token using its delegate. This process is designed to prevent bad requests from being needlessly sent.

**About POST Requests**

All methods that send POST requests, including the xAuth login method, return `NSError`. If there is no error, they should return `nil`. The `NSError` is either an HTTP error or an error returned by the Twitter API.

**About GET requests**

GET methods return `id`. There returned object class can be one of the following:

- `NSMutableDictionary`
- `NSMutableArray`
- `UIImage`
- `NSString`
- `NSError`
- `nil`

**For the future/To Do**

You should probably [email](mailto:nate@natesymer.com) me with suggestions.

- OS X OAuth login window
- Add custom objects for profile settings
- Have the OAuth method not require a view controller to be passed
- POST requests returning data like GET requests

**Don't Email Me Saying It Doesn't Work**

The first thing you should do is spend an hour trying to fix the problem yourself. Don't go wild and try to change everything, just trace back your steps, and look closely at details. Don't program by permutation.

A common issue seems to be an `#import` loop. This is usually solved by, you guessed it, tracing back your steps. The `#import` loop happens when file A imports file B which imports file A. The loop is given away by a compile error, multiple declarations of class X.

If after an hour, you have no solution and your problem is in your code, I don't want to hear it. I'm not getting paid to do the job you should be capable of doing.
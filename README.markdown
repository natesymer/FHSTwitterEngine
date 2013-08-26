FHSTwitterEngine
================

***The synchronous Twitter engine that doesn't suck!!***

Created by [Nathaniel Symer](mailto:nate@natesymer.com), aka [@natesymer](http://twitter.com/natesymer) 

Feel free to <a href="http://natesymer.com/donate/" alt="Buy me a coffee or graphics card">buy me a coffee</a> (donation).


`FHSTwitterEngine` can:

- Login through xAuth.
- Login through oAuth. Login UI based on [SA_OAuthTwitterEngineController](https://github.com/bengottlieb/Twitter-OAuth-iPhone)
- Make a request to most available API endpoints. Yes, even the stupid ones.


Why `FHSTwitterEngine` is better than `MGTwitterEngine`:

- Lack of annoying delegates
- Does not send you to Dependency Hell over a JSON parser
- Less setup
- Synchronous allowing for easier implementation (see Usage)
- More implemented API endpoints
- Uses a fixed version of OAuthConsumer (mine)
- **Less crufty**

Why `FHSTwitterEngine` is better than `STTwitter`:

- FHSTwitterEngine uses the singleton pattern
- FHSTwitterEngine avoids nested blocks
- FHSTwitterEngine is **less crufty**
- FHSTwitterEngine is dead easy to add to your project
- FHSTwitterEngine is simple

Notice a common theme?

**Setup**

1. Add the folder "FHSTwitterEngine" to your project and `#import "FHSTwitterEngine.h"` (I recommend `Prefix.pch`)
2. Link against `SystemConfiguration.framework`
3. If your project is using ARC, you must disable ARC for any `OA` prefixed files and `FHSTwitterEngine.{h,m}`.
4. Profit!!!!

**Usage:**

--> Set up `FHSTwitterEngine`:

    [[FHSTwitterEngine sharedEngine]permanentlySetConsumerKey:@"<consumer_key>" andSecret:@"<consumer_secret>"];
    
    // Or, if you want to assign your consumer key on a per-use basis:
    [[FHSTwitterEngine sharedEngine]temporarilySetConsumerKey:@"<consumer_key>" andSecret:@"<consumer_secret>"];
    
    // Then set the delegate. It is used for access token management, and is not required.
    // If a delegate is not provided, FHSTwitterEngine will save ONE access token in NSUserDefaults.
    [[FHSTwitterEngine sharedEngine]setDelegate:myDelegate]; 
    
--> Login via OAuth:
    
    [[FHSTwitterEngine sharedEngine]showOAuthLoginControllerFromViewController:self withCompletion:^(BOOL success) {
        if (success) {
            NSLog(@"L0L success");
        } else {
            NSLog(@"O noes!!! Logen falyur!!!");
        }
    }];
    
--> Login via XAuth:
    
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
    
--> Set up your consumer manually and temorarily
	
	// your keys will be cleared after the next request is prepared, before it is sent.
	[[FHSTwitterEngine sharedEngine]temporarilySetConsumerKey:@"<consumer_key>" andSecret:@"<consumer_secret>"];
	
	// if you're really paranoid, use this to clear the keys
	[[FHSTwitterEngine sharedEngine]clearConsumer];
	
--> Reload a saved access_token:

    [[FHSTwitterEngine sharedEngine]loadAccessToken];

--> End a session:

    [[FHSTwitterEngine sharedEngine]clearAccessToken];

--> Check if a session is valid:

    [[FHSTwitterEngine sharedEngine]isAuthorized];
    
--> Do an API call (POST):

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

--> Do an API call (GET):

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
    
    
**The "singleton" pattern**
The singleton pattern allows the programmer to drop all of the object management code, and allow faster and easier access to FHSTwitterEngine. The singleton pattern works by holding an FHSTwitterEngine in memory for the lifetime of the app by overriding the methods that would take it out of memory. Don't worry, it's not a leak and when the app is killed, the singleton instance will also be killed. It's really not that much different from what FHSTwitterEngine was before.

**Grand Central Dispatch**

So what are those `GCDBackgroundThread` and `GCDMainThread` defines?<br />
The defines are macros for `dispatch_async()` and `dispatch_sync()`, respectively. Instead of writing out a sometimes lengthy dispatch* call, you can punch in an easy macro. Plus, they help make your code more readable. By using GCD, the programmer can use FHSTwitterEngine procedurally.

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

In the case of `authenticatedUserIsBlocking:isID:` and `testService`, an NSString will be returned. It will be `@"YES"` to indicate YES and `@"NO"` to indicate NO. Additionally, it will return an `NSError` if it fails. How else could I prevent false negatives?

**For the future/To Do**

Feel free to [email](mailto:nate@natesymer.com) me for suggestions.

- Mac support (Whomever wants to do this for me, **go ahead**)
- Add custom objects for profile settings
- Replace OAuthConsumer with my own HTTP OAuth code

**IMPORTANT**

`FHSTwitterEngine` contains an overhauled version of `OAuthConsumer`. The changes are:

- Removed `OADataFetcher` and `OAAsynchronousDataFetcher`
- Added `+[OAMutableURLRequest fetchDataForRequest:withCompletionHandler:]` to manually send requests.
- Fixed string comparisons
- Fixed memory leaks
- Fixed bugs
- Added compatibility with alternative versions of OAuthConsumer

**I'm from New Jersey, so pardon my sarcastic comments, capisce?**

**Fixes for some common problems** (and best practices)

The first thing you should do is spend an hour trying to fix the problem yourself. Don't go wild and try to change everything, just trace back your steps, and look closely at details.

A common issue seems to be an `#import` loop. This is usually solved by, you guessed it, tracing back your steps. The `#import` loop happens when file A imports file B which imports file A. The loop is given away by a compile error, multiple declarations of class X.

kthxbye



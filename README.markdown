FHSTwitterEngine
================

***The synchronous Twitter engine that doesn't suck!!***

Created by [Nathaniel Symer](mailto:nate@natesymer.com), aka [@natesymer](http://twitter.com/natesymer)

Buy me a coffee or graphics card or a graphics card:
<html>
<form action="https://www.paypal.com/cgi-bin/webscr" method="post" target="_top">
<input type="hidden" name="cmd" value="_s-xclick">
<input type="hidden" name="encrypted" value="-----BEGIN PKCS7-----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-----END PKCS7-----
">
<input type="image" src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif" border="0" name="submit" alt="PayPal - The safer, easier way to pay online!">
<img alt="" border="0" src="https://www.paypalobjects.com/en_US/i/scr/pixel.gif" width="1" height="1">
</form>
</html>

<br>
`FHSTwitterEngine` can:

- Login through xAuth.
- Login through oAuth. Login UI based on [SA_OAuthTwitterEngineController](https://github.com/bengottlieb/Twitter-OAuth-iPhone)
- Make a request to every available API endpoints. Yes, even the legal ones.


Why `FHSTwitterEngine` is better than `MGTwitterEngine`:

- Lack of annoying delegates
- Does not send you to Dependency Hell over a JSON parser
- Less setup
- Synchronous allowing for easier implementation (see Usage)
- More implemented API endpoints
- Uses a fixed version of OAuthConsumer (mine)
- **Less crufty**


**Setup**

1. Add the folder "FHSTwitterEngine" to your project and `#import "FHSTwitterEngine.h"` (I recommend `Prefix.pch`)
2. Link against `SystemConfiguration.framework`
3. In **Compile Sources** in the **Build Phases** tab of your target (e.g. MyCoolApp.app with the target icon next to it), add the `-fno-objc-arc` compiler flag to all files starting with `OA` (In other words, the `OAuthConsumer` library, *nothing* else)
4. Profit!!!!

**Usage:**

--> Create `FHSTwitterEngine` object:

    FHSTwitterEngine *engine = [[FHSTwitterEngine alloc]initWithConsumerKey:@"<consumer_key>" andSecret:@"<consumer_secret>"];
    
    // or 
    
    FHSTwitterEngine *engine = [[FHSTwitterEngine alloc]init]; // If you plan to set your keys on a per-request basis
    
--> Login via OAuth:
    
    [engine showOAuthLoginControllerFromViewController:self];
    
--> Login via XAuth:
    
    dispatch_async(GCDBackgroundThread, ^{
    	@autoreleasepool {
    		NSError *error = [engine getXAuthAccessTokenForUsername:@"<username>" password:@"<password>"];
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
	[engine temporarilySetConsumerKey:@"<consumer_key>" andSecret:@"<consumer_secret>"];
	
	// if you are really paranoid, use this
	[engine clearConsumer];
	
    
--> Reload a saved access_token:

    [engine loadAccessToken];

--> End a session:

    [engine clearAccessToken];

--> Check if a session is valid:

    [engine isAuthorized];
    
--> Do an API call (POST):

    dispatch_async(GCDBackgroundThread, ^{
    	@autoreleasepool {
    		NSError *error = [engine twitterAPIMethod]; 
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
    		id twitterData = [engine twitterAPIMethod];
    		// Handle twitterData (see "About GET REquests")
    		dispatch_sync(GCDMainThread, ^{
    			@autoreleasepool {
        			// Update UI
        		}
       		});
    	}
    });

**Grand Central Dispatch**

So what are those `GCDBackgroundThread` and `GCDMainThread`?<br />
They are macros for `dispatch_async()` and `dispatch_sync()`, respectively. They make using GCD much easier. Yes, GCD is the designated way of adding async functionality to FHSTwitterEngine without losing the procedural paradigm.

**About POST requests**

All methods that send POST requests, including the xAuth login method, return `NSError`. If there is no error, they should return `nil`.

**General networking comments**

`FHSTwitterEngine` will attempt to preëmtively detect errors in your requests. This is designed to prevent flawed requests from being needlessly sent. This helps with rate limiting and networking turnover times.

**About GET requests**

GET methods return id. There returned object can be a member of one of the following classes:

- `NSDictionary`
- `NSArray`
- `UIImage`
- `NSString`
- `NSError`
- `nil`

In the case of `authenticatedUserIsBlocking:isID:`, an NSString will be returned. It will be `@"YES"` to indicate YES and `@"NO"` to indicate NO. Additionally, it will return an NSError if it fails. How else could I prevent false negatives?

**For the future**

Feel free to [email](mailto:nate@natesymer.com) me for suggestions.

- Specify AppID and Secret for each request for added security
- Mac support

**IMPORTANT**

`FHSTwitterEngine` contains an overhauled version of OAuthConsumer. The changes are:
- Removed `OADataFetcher`
- `OAAsynchronousDataFetcher` is now just a class method that takes arguments of a request and a block.
- Fixed string comparisons
- Fixed memory leaks
- Fixed bugs
- Compatibility with alternative versions of OAuthConsumer

**I'm from New Jersey, so pardon my sarcastic comments, mkay?**

**Fixes for some common problems** (and best practices)

- If you have any errors concerning multiple declarations for any class, check to make sure that any class is not importing another class which is importing the first class (aka `#import` loop - A imports B which imports A which imports B...)

kthxbye



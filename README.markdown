FHSTwitterEngine
================


***The synchronous Twitter engine that doesn't suck!!***

Created by [Nathaniel Symer](mailto:nate@natesymer.com), aka [fhsjaagshs](http://twitter.com/fhsjaagshs)


FHSTwitterEngine can:

- Login through XAuth.
- Login through OAuth. Login UI based on [SA_OAuthTwitterEngineController](https://github.com/bengottlieb/Twitter-OAuth-iPhone)
- Make a request to every available API endpoints. Yes, even the legal ones.


Why FHSTwitterEngine is better than MGTwitterEngine:

- Lack of annoying delegates
- Does not send you to Dependency Hell over a JSON parser
- Less setup
- Synchronous allowing for easier implementation (See usage)
- More implemented API endpoints
- Uses a fixed version of OAuthConsumer (mine)
- **Less crufty**



**Setup**

Add the folder "FHSTwitterEngine" to your project and #import "FHSTwitterEngine.h"

You will have to set OAuthConsumer and TouchJSON to use `-fno-objc-arc` if you are using ARC.

You also need to link against SystemConfiguration.framework

**Usage:**

-> Create FHSTwitterEngine object:

    FHSTwitterEngine *engine = [[FHSTwitterEngine alloc]initWithConsumerKey:@"<consumer key>" andSecret:@"<consumer secret>"];
    
-> Login via OAuth:
    
    [engine showOAuthLoginControllerFromViewController:self];
    
-> Login via XAuth:
    
    dispatch_async(GCDBackgroundThread, ^{
    	@autoreleasepool {
    		int resturnCode = [engine getXAuthAccessTokenForUsername:usernameField.text password:passwordField.text];
        	// Handle returnCode 
        	dispatch_sync(GCDMainThread, ^{
    			@autoreleasepool {
        			// Update UI
        		}
       		});
    	}
    });
    
-> Reload a saved access_token:

    [engine loadAccessToken];

-> End a session:

    [engine clearAccessToken];

-> Check if a session is valid:

    [engine isAuthorized];
    
-> Do an API call (POST)\*:

    dispatch_async(GCDBackgroundThread, ^{
    	@autoreleasepool {
    		int returnCode = [engine twitterAPIMethod]; // POST
    		// Handle returnCode
    		dispatch_sync(GCDMainThread, ^{
    			@autoreleasepool {
        			// Update UI
        		}
       		});
    	}
    });

-> Do an API call (GET)\*\*:

    dispatch_async(GCDBackgroundThread, ^{
    	@autoreleasepool {
    		id returnValue = [engine twitterAPIMethod]; // GET
    		// Handle returnValue
    		dispatch_sync(GCDMainThread, ^{
    			@autoreleasepool {
        			// Update UI
        		}
       		});
    	}
    });


\* POST methods return int. These are called *return codes*. See below for more.<br />
\*\* GET methods return id. This can be either an NSDictionary, NSArray, NSString, UIImage or nil. See below for errors

So what are those `GCDBackgroundThread` and `GCDMainThread`?<br />
They are macros for dispatch_async()/dispatch_sync(). 


<br />
**About Return Codes**<br />
(These apply to any method that returns an int)<br />

0 - Success <br />
1 - API Error (Params are invalid - It's my fault if whole (name and value) params are missing) <br />
2 - Insufficient input (missing a parameter, your fault)<br />
3 - Image too large (bigger than 700KB. Again, your fault)<br />
4 - User unauthorized <br />
304 to 504 - HTTP/Twitter response code. Check them out [here](https://dev.twitter.com/docs/error-codes-responses). (My favorite is Error 420 - Enhance Your Calm)

(You can look them up using the lookupErrorCode: method)

*Return codes 2 & 3 are your fault*


**About GET request return codes**

There are three keys:

- FHSTwitterEngineBOOLKeyYES<br />
- FHSTwitterEngineBOOLKeyNO<br />
- FHSTwitterEngineBOOLKeyERROR<br />

Check to see if the returned object is both an NSString and equal to one of these values.



**For the future**

Nothing for now... feel free to [email](mailto:nate@natesymer.com) me for suggestions.

**IMPORTANT**

Some of the libraries included are (heavily) modified:

- OAuthConsumer - Removed OADataFetcher and rewrote OAAsynchronousDataFetcher to use blocks. Condensed classes and fixed memory leaks.
- TouchJSON - Fixed some boolean comparison of NSData and condense to one header/implementation pair.

You should use the included versions instead of other version of the libraries because the included versions are *considerably* better.



**Fixes for some common problems** (and best practices)

- If you have any errors concerning multiple declarations for any class, check to make sure that any class is not importing another class which is importing the first class (AKA `#import` loop)




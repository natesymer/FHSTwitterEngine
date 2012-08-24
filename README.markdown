FHSTwitterEngine
================


***The synchronous Twitter engine that doesn't suck!!***

Created by Nathaniel Symer, aka [fhsjaagshs](mailto:fhsjaagshs@fhsjaagshs.com)


FHSTwitterEngine can:

- Login through XAuth.
- Login through OAuth. Implementation based on [SA_OAuthTwitterEngineController](https://github.com/bengottlieb/Twitter-OAuth-iPhone)
- Make a request to most API endpoints (I implemented them ad nauseam)

Why FHSTwitterEngine is better than MGTwitterEngine:

- Lack of annoying delegates
- Does not send you to Dependency Hell over a JSON parser
- Synchronous allowing for easier implementation (See usage)
- More implemented API endpoints
- **Less crufty**


List of implemented API endpoints: All of them. Yes, even the legal/xyz ones.

**Setup**

Add the folder "FHSTwitterEngine" to your project and import "FHSTwitterEngine.h"

**Usage:**

-> Create FHSTwitterEngine object:

    FHSTwitterEngine *engine = [[FHSTwitterEngine alloc]initWithConsumerKey:@"<consumer key>" andSecret:@"<consumer secret>"];
    
-> Login via OAuth:
    
    [self.engine showOAuthLoginControllerFromViewController:self];
    
-> Login via XAuth:
    
    dispatch_async(GCDBackgroundThread, ^{
        int resturnCode = [self.engine getXAuthAccessTokenForUsername:usernameField.text password:passwordField.text];
        /* Handle returnCode */
        dispatch_sync(GCDMainThread, ^{
        	/* Update UI */
        });
    });
    
-> Reload a saved access_token:

    [self.engine loadAccessToken];

-> End a session:

    [self.engine clearAccessToken]; /* notice that it's not account/end_session */

-> Check if a session is valid:

    [self.engine isAuthorized];
    
-> Do an API call:

    dispatch_async(GCDBackgroundThread, ^{
    	int returnCode = [self.engine doYourBloodyAPICall];
    	/* Handle returnCode */
    	dispatch_sync(GCDMainThread, ^{
        	/* Update UI */
        });
    });



<br />
**About Return Codes**<br />
(These apply to any method that returns an int)<br />

0 - Success<br />
1 - API Error (Params are invalid - missing params here are my fault)<br />
2 - Insufficient input (missing a parameter, your fault)<br />
3 - Image too large (bigger than 700KB. Again, your fault)<br />
4 - User unauthorized <br />
304 to 504 - HTTP/Twitter response code. Look these up [here](https://dev.twitter.com/docs/error-codes-responses). (My favorite is Error 420 - Enhance Your Calm)

(You can look them up using the lookupErrorCode: method)

*Return codes 2 & 3 are your fault*

<br />

**Note to contributors**

If you could help me implement the rest of the endpoints, I would really appreciate it. 

There is an excellent JSON parser *INCLUDED* in the iOS SDK called NSJSONSerialization. Please use it for the sake of my (our) users.



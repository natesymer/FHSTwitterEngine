**Changelog**
===

FHSTwitterEngine
===

Bear in mind that I didn't exactly start this until recently, and FHSTwitterEngine used to be 100% undocumented.

**Initial Commits**

- Added more endpoints
- Fixed a variety of bugs

**Version 1.0**

- Finished endpoints
- FHSTwitterEngine now uses Twitter API v1.1
- Changed the return of errors (now returns NSError, see readme.markdown for more)

**Version 1.1**

- Fixed a TON of bugs
- Cut dependency on TouchJSON

**Version 1.2**

- Fixed the postTweet:withImageData:inReplyTo: method.
- Added Search API stuffs

**Version 1.3**

- Added self.includeEntities to turn on or off the inclusion of entities. Defaults to NO.

**Version 1.3.1**

- Fixed some potential problems in base64EncodingWithLineLength:

**Version 1.3.2**

- Fixed an issue with the date format from twitter, thanks to Jason Hsu.
- Added the ability to set your consumer key and secret on a per-request basis.

**Version 1.3.3**

- since_id is now optional for - [FHSTwitterEngine getHomeTimelineSinceID:count:]

**Version 1.4**

- Fixed misspelling of "Destroy" (was destory) in a method name (I think it was destoryTweet:). Thanks to Conrad Kramer ([@conradev](http://twitter.com/conradev)) for pointing this out.
- Added completion block to OAuth login method
- Fixed lag with the date parsing method by not lazily allocating the NSDateFormatter. A 200ms delay is now gone. *And there was much rejoycing*.

**Version 1.5**

- Rewrote whole methods
- Removed deprecated methods/endpoints
- Moved all URLs to static constants
- Adapted code to be more easily refactored to non ARC (MRC)
- Added methods for `account/update_profile_image` and `account/update_profile_background_image` that accept an NSData argument
- Added direct methods for `friends/ids` and `followers/ids`
- Fixed incorrect key in `updateProfileColorsWithDictionary:`
- Added keys for profile settings

**Version 1.5.1**

- Cleaned up error messages
- Streamlined the sending of requests
- Fixed handling of users string with the methods that take an NSArray of users as a param

**Version 1.5.2**

- Cleaned up the OAuth login controller and the base64 encoding methods.

**Version 1.6**

- MOVE AWAY FROM ARC
- Fix bug with parsing nil JSON data

**Version 1.6.1**

- Sorry I forgot about the changelog!
- Fixed a bunch of bugs... You should be good to go.
- More optimization and reengineering

**Version 1.6.3**

- Added followers/list and friends/list
- Replaced -getFriends and -getFollowers with the methods for the above
- Exposed -generateRequestStringsFromArray:

**Version 1.6.3.1**

- Found an issue with the mass listing method - cursors
- Adapted code for cursors, no more -getFriends and -getFollowers. You'll just have to pass your logged in username… Boo hoo.

**Version 1.6.4**

- Moved all batch lookup methods to use 100 instead of 99

**Version 1.6.5**

- Fixed issue in -generateRequestStringsFromArray method where some ids were ignored (the remainder of a modulo division operation)

**Version 1.7**

- FHSTwitterEngine now uses the singleton pattern
- Cleaned up the -isAuthorized check in `-sendGETRequest:` and `-sendPOSTRequest:` to attempt to load saved access tokens if unauthorized.
- Cleaned up login controller
- Updated Demo app

**Version 1.8**

- Added streaming

OAuthConsumer
===
*Version numbers below are for **\_my\_** version of OAuthConsumer. I modified OAuthConsumer almost beyond recognition...*

**Pre-1.0 Versions**

- Condense code
- Weed out useless stuff

**Version 1.0**

- Fix some memory leaks

**Version 1.1**

- Fix most remaining memory leaks
- Add better support the pin/verifier property in `OAToken` (The version of `OAuthConsumer` in `SA_OAuthTwitterEngine` uses the `pin` property)

**Version 1.2**

- Fix some potential memory leaks

**Version 1.2.1**

- Add convenience init methods to `OAMutableURLRequest`, `OAToken`, and `OAConsumer`
- Moved `fetchDataForRequest:` to OAMutableURLRequest.m, removed `OAAsynchronousDataFetcher`

**Version 1.2.2**

- Just restructure and remove @synthesizes


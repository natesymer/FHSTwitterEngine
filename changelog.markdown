# **FHSTwitterEngine Changelog**

Changes are by **Nate Symer** unless otherwise noted (you can also see the changelog archive for [OAuthConsumer](.github/oauthconsumer.md)).

**Version 2.0.5** by [@brightsider](https://github.com/brightsider)

- [Fix streaming](https://github.com/fhsjaagshs/FHSTwitterEngine/pull/124)

**Version 2.0.4** by [Daniel Khamsing](https://github.com/dkhamsing)

- Fix missing `list_id` in `- removeUsersFromListWithID:users`

**Version 2.0.3** by [Daniel Khamsing](https://github.com/dkhamsing)

- Fix missing `list_id` in `- addUsersToListWithID:users`

**Version 2.0.2** by [Daniel Khamsing](https://github.com/dkhamsing)

- Update Podspec `platform`, `social_media_url`
- Update CocoaPods demo
- Update Twitter demo app keys

**Version 2.0.1** by [Daniel Khamsing](https://github.com/dkhamsing)

- Version change to accommodate CocoaPods
- Update documentation

**Version 1.8.2** by [Daniel Khamsing](https://github.com/dkhamsing)

- Add support for CocoaPods
- Add documentation

**Version 1.8.1**

- Add support for media/upload API by [SalahAldin Ghanim](https://github.com/salah-ghanim)
- Add preliminary support for CocoaPods by [SalahAldin Ghanim](https://github.com/salah-ghanim)
- Swift demo by [Daniel Khamsing](https://github.com/dkhamsing)
- Fix (standardize) parameter names by [Cam Clendenin](https://github.com/camclendenin)
- Fix bug with body request body parameters by [SalahAldin Ghanim](https://github.com/salah-ghanim)
- Fix demo crash by [Alex Ling](https://github.com/hkalexling)

**Version 1.8**

- Added streaming

**Version 1.7**

- `FHSTwitterEngine` now uses the singleton pattern
- Cleaned up the -isAuthorized check in `-sendGETRequest:` and `-sendPOSTRequest:` to attempt to load saved access tokens if unauthorized.
- Cleaned up login controller
- Updated Demo app

**Version 1.6.5**

- Fixed issue in `-generateRequestStringsFromArray` method where some ids were ignored (the remainder of a modulo division operation)

**Version 1.6.4**

- Moved all batch lookup methods to use `100` instead of `99`

**Version 1.6.3.1**

- Found an issue with the mass listing method - cursors
- Adapted code for cursors, no more `-getFriends` and `-getFollowers`. You'll just have to pass your logged in username… Boo hoo.

**Version 1.6.3**

- Added `followers/list` and `friends/list`
- Replaced `-getFriends` and `-getFollowers` with the methods for the above
- Exposed `-generateRequestStringsFromArray:`

**Version 1.6.1**

- Sorry I forgot about the changelog!
- Fixed a bunch of bugs... You should be good to go.
- More optimization and reengineering

**Version 1.6**

- MOVE AWAY FROM ARC
- Fix bug with parsing nil JSON data

**Version 1.5.2**

- Cleaned up the OAuth login controller and the base64 encoding methods.

**Version 1.5.1**

- Cleaned up error messages
- Streamlined the sending of requests
- Fixed handling of users string with the methods that take an `NSArray` of users as a param

**Version 1.5**

- Rewrote whole methods
- Removed deprecated methods/endpoints
- Moved all URLs to static constants
- Adapted code to be more easily refactored to non ARC (MRC)
- Added methods for `account/update_profile_image` and `account/update_profile_background_image` that accept an NSData argument
- Added direct methods for `friends/ids` and `followers/ids`
- Fixed incorrect key in `updateProfileColorsWithDictionary:`
- Added keys for profile settings

**Version 1.4**

- Fixed misspelling of "Destroy" in a method name (I think it was `destoryTweet:`). Thanks to [Conrad Kramer](http://twitter.com/conradev) for pointing this out.
- Added completion block to OAuth login method
- Fixed lag with the date parsing method by not lazily allocating the `NSDateFormatter`. A 200ms delay is now gone. *And there was much rejoicing*.

**Version 1.3.3**

- `since_id` is now optional for `getHomeTimelineSinceID:count:`

**Version 1.3.2**

- Fixed an issue with the date format from Twitter, thanks to Jason Hsu.
- Added the ability to set your consumer key and secret on a per-request basis.

**Version 1.3.1**

- Fixed some potential problems in `base64EncodingWithLineLength:`

**Version 1.3**

- Added `self.includeEntities` to turn on or off the inclusion of entities. Defaults to NO.

**Version 1.2**

- Fixed the `postTweet:withImageData:inReplyTo:` method.
- Added Search API stuffs

**Version 1.1**

- Fixed a TON of bugs
- Cut dependency on `TouchJSON`

**Version 1.0**

- Finished endpoints
- `FHSTwitterEngine` now uses Twitter API v1.1
- Changed the return of errors (now returns `NSError`, see README for more)

**Initial Commits**

- Added more endpoints
- Fixed a variety of bugs

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

**Version 1.3.1**

- since_id is now optional for - [FHSTwitterEngine getHomeTimelineSinceID:count:]



OAuthConsumer
===
*Version numbers below refer to FHSTwitterEngine versions*

**Initial Commits**

- Condense

**Version 1.0**

- Fix some memory leaks

**Version 1.1**

- Fix most remaining memory leaks
- Add better support the pin/verifier property in OAToken (The version of OAuthConsumer in SA_OAuthTwitterEngine uses the pin property)

**Version 1.2**

- Fix some potential memory leaks


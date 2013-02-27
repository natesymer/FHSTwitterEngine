**Changelog**
===

FHSTwitterEngine
===

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


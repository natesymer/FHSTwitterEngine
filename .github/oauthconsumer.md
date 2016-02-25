OAuthConsumer Changelog
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

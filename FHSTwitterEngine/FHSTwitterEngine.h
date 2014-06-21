//
//  FHSTwitterEngine.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 8/22/12.
//  Copyright (C) 2012 Nathaniel Symer.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

//
// FHSTwitterEngine
// The synchronous Twitter engine that doesn’t suck!!
//

// Frameworks
#import <Foundation/Foundation.h>
#import "FHSDefines.h"
#import "FHSToken.h"

// Categories
#import "NSError+FHSTE.h"
#import "NSData+FHSTE.h"
#import "NSString+FHSTE.h"
#import "NSObject+FHSTE.h"
#import "NSURL+FHSTE.h"

/**
 Use `FHSTwitterEngine` to authenticate with Twitter and make a request to just about every Twitter API endpoint.
 */
@interface FHSTwitterEngine : NSObject

/**
 A Boolean value indicating whether FHSTwitterEngine should include Entities. See Twitter's documentation for more information:
 https://dev.twitter.com/docs/entities
 */
@property (nonatomic, assign) BOOL includeEntities;


/**
 A `FHSToken` object representing the access token.
 */
@property (nonatomic, strong) FHSToken *accessToken;


/**
 String representing the consumer key.
 */
@property (nonatomic, strong) NSString *consumerKey;


/**
 String representing the consumer secret.
 */
@property (nonatomic, strong) NSString *consumerSecret;


#pragma mark Blocks

/**
 Block to store the access token.
 */
@property (nonatomic, copy) StoreAccessTokenBlock storeAccessTokenBlock;


/**
 Block to load the access token.
 */
@property (nonatomic, copy) LoadAccessTokenBlock loadAccessTokenBlock;


#pragma mark - REST API v1.1

/**
 See Twitter's documentation for more information:
 https://dev.twitter.com/docs/api/1.1
 */


#pragma mark - Timelines
/// @name Timelines

/**
 Gets the most recent mentions (Tweets containing a users's @screen_name) for the authenticating user. API endpoint: GET statuses/mentions_timeline.
 @param count Number of Tweets to retrieve.
 @return A list of Tweets.
 */
- (id)getMentionsTimelineWithCount:(int)count;


/**
 Gets the most recent mentions (Tweets containing a users's @screen_name) for the authenticating user. API endpoint: GET statuses/mentions_timeline.
 @param count Number of Tweets to retrieve.
 @param sinceID Returns results with an ID greater than (that is, more recent than) the specified ID.
 @param maxID Returns results with an ID less than (that is, older than) or equal to the specified ID.
 @return A list of Tweets.
 */
- (id)getMentionsTimelineWithCount:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;


/**
 Gets the timeline for a given user. API endpoint: GET statuses/user_timeline.
 @param user The user ID or screen name.
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @param count Number of Tweets to get.
 @return A list of Tweets.
 */
- (id)getTimelineForUser:(NSString *)user isID:(BOOL)isID count:(int)count;


/**
 Gets the timeline for a given user. API endpoint: GET statuses/user_timeline.
 @param user The user ID or screen name.
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @param count Number of Tweets to get.
 @param sinceID Returns results with an ID greater than (that is, more recent than) the specified ID.
 @param maxID Returns results with an ID less than (that is, older than) or equal to the specified ID.
 @return A list of Tweets.
 */
- (id)getTimelineForUser:(NSString *)user isID:(BOOL)isID count:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;


/**
 Gets the home timeline for the authenticated user (list of the most recent Tweets and retweets posted by the authenticating user and the users they follow). API endpoint: GET statuses/home_timeline.
 @param sinceID Timeline will return Tweets with ID greater than this value (optional, set `sinceID` to `@""` if you do not wish to use this parameter).
 @param count Number of Tweets to retrieve (needs to be greater than zero).
 @return A list of Tweets.
 */
- (id)getHomeTimelineSinceID:(NSString *)sinceID count:(int)count;


/**
 Gets the most recent tweets authored by the authenticating user that have been retweeted by others. API endpoint: GET statuses/retweets_of_me.
 @param count Number of Tweets to get.
 @return A list of Tweets.
 */
- (id)getRetweetedTimelineWithCount:(int)count;


/**
 Gets the most recent tweets authored by the authenticating user that have been retweeted by others. API endpoint: GET statuses/retweets_of_me.
 @param count Number of Tweets to get.
 @param sinceID Returns results with an ID greater than (that is, more recent than) the specified ID.
 @param maxID Returns results with an ID less than (that is, older than) or equal to the specified ID.
 @return A list of Tweets.
 */
- (id)getRetweetedTimelineWithCount:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;


#pragma mark - Tweets
/// @name Tweets

/**
 Gets the most recent retweets of the tweet specified by the Tweet ID. API endpoint: GET statuses/retweets.
 @param identifier Tweet ID.
 @param count Number of Tweets to get.
 @return A list of Tweets.
 */
- (id)getRetweetsForTweet:(NSString *)identifier count:(int)count;


/**
 Gets a single Tweet with the given Tweet ID. API endpoint: GET statuses/show.
 @param identifier Tweet ID.
 @return Detail for the Tweet.
 */
- (id)getDetailsForTweet:(NSString *)identifier;


/**
 Destroys (deletes) the status specified by the Tweet ID. The authenticating user must be the author of the specified status. API endpoint: POST statuses/destroy.
 @param identifier Tweet ID.
 @return The response from the Twitter API.
 */
- (id)destroyTweet:(NSString *)identifier;


/**
 Posts a Tweet. To upload an image, use `postTweet:withImageData:`. API endpoint: POST statuses/update.
 @param tweetString Tweet to post.
 @return The response from the Twitter API.
 */
- (id)postTweet:(NSString *)tweetString;


/**
 Posts a reply to a Tweet. API endpoint: POST statuses/update.
 @param tweetString Reply.
 @param inReplyToString Tweet ID to reply to.
 @return The response from the Twitter API.
 */
- (id)postTweet:(NSString *)tweetString inReplyTo:(NSString *)inReplyToString;


/**
 Retweets a Tweet with the given Tweet ID. API endpoint: POST statuses/retweet.
 @param identifier Tweet ID.
 @return The response from the Twitter API.
 */
- (id)retweet:(NSString *)identifier;


/*
 Posts a Tweet with an image. API endpoint: POST statuses/update_with_media.
 @param tweetString Tweet to post.
 @param theData Image data.
 @return The response from the Twitter API.
 */
- (id)postTweet:(NSString *)tweetString withImageData:(NSData *)theData;


/*
 Posts a Tweet with an image. API endpoint: POST statuses/update_with_media.
 @param tweetString Tweet to post.
 @param theData Image data.
 @param inReplyToString Tweet ID to reply to.
 @return The response from the Twitter API.
 */
- (id)postTweet:(NSString *)tweetString withImageData:(NSData *)theData inReplyTo:(NSString *)irt;


/**
 Posts a tweet with multiple images. API endpoint: POST statuses/update.
 @param tweetString Tweet to post.
 @param listOfImageData List of images (image data).
 @return The response from the Twitter API.
 */
- (id)postTweet:(NSString *)tweetString withListOfImageData:(NSArray*)listOfImageData;


/**
 Posts a reply to a tweet with multiple images. API endpoint: POST statuses/update.
 @param tweetString Tweet to post.
 @param listOfImageData List of images (image data).
 @param inReplyToString Tweet ID to reply to.
 @return The response from the Twitter API.
 */
- (id)postTweet:(NSString *)tweetString withListOfImageData:(NSArray*)listOfImageData inReplyTo:(NSString *)irt;


/**
 Returns information allowing the creation of an embedded representation of a Tweet on third party sites. See the oEmbed specification for information about the response format. API endpoint: GET statuses/oembed.
*/
//TODO: GET statuses/oembed


/**
 Returns a collection of up to 100 user IDs belonging to users who have retweeted the tweet specified by the id parameter. This method offers similar data to GET statuses/retweets/:id and replaces API v1's GET statuses/:id/retweeted_by/ids method. API endpoint: GET statuses/retweeters/ids.
 */
//TODO: GET statuses/retweeters/ids


#pragma mark - Search
/// @name Search

/**
 Search for relevant Tweets matching a specified query. API endpoint: GET search/tweets.
 @param q Search query.
 @param count Number of Tweets to get, must be greater than 0.
 @param resultType Use enum for mixed, recent or popular
 @param untilDate Returns tweets generated before the given date. Date should be formatted as YYYY-MM-DD.
 @param sinceID Returns results with an ID greater than (that is, more recent than) the specified ID.
 @param maxID Returns results with an ID less than (that is, older than) or equal to the specified ID.
 @return A list of Tweets.
 */
//TODO: rename unil to until
//TODO: rename q to query (one letter is too short)
- (id)searchTweetsWithQuery:(NSString *)q count:(int)count resultType:(FHSTwitterEngineResultType)resultType unil:(NSDate *)untilDate sinceID:(NSString *)sinceID maxID:(NSString *)maxID;


#pragma mark - Streaming
/// @name Streaming

/**
 Returns public statuses that match one or more filter predicates (`follow`, `track`, `locations`). API endpoint: POST statuses/filter.
 @param users List of users, at least one is required (`follow`).
 @param keywords List of keywords, at least one is required (`track`).
 @param locBox A comma-separated list of longitude, latitude pairs (must be exactly four) specifying a location bounding box to filter Tweets by (`locations`).
 @param block Stream block: it contains a return stream and a *stop Boolean.
 */
- (void)streamPublicStatusesForUsers:(NSArray *)users keywords:(NSArray *)keywords locationBox:(NSArray *)locBox block:(StreamBlock)block;


/**
 Returns a small random sample of all public statuses. API endpoint: GET statuses/sample.
 @param block Stream block: it contains a return stream and a *stop Boolean.
 */
- (void)streamSampleStatusesWithBlock:(StreamBlock)block;


/**
 Returns all public statuses. This endpoint requires special permission to access. API endpoint: GET statuses/firehose.
 @param block Stream block: it contains a return stream and a *stop Boolean.
 */
- (void)streamFirehoseWithBlock:(StreamBlock)block;


/**
 Streams messages for users. API endpoint: GET user.
 @param with List of users the authenticated user is following (optional).
 @param replies A Boolean to determine whether the stream includes replies (this is not implemented at the moment).
 @param keywords List of keywords of additional Tweets to stream (optional).
 @param locBox A comma-separated list of longitude, latitude pairs specifying a location bounding box to filter Tweets by (optional).
 @param block Stream block: it contains a return stream and a *stop Boolean.
 */
- (void)streamUserMessagesWith:(NSArray *)with replies:(BOOL)replies keywords:(NSArray *)keywords locationBox:(NSArray *)locBox block:(StreamBlock)block;


/**
 Streams messages for a set of users, as described in Site streams. See https://dev.twitter.com/docs/streaming-apis/streams/site for more information. API endpoint: GET site.
 */
// TODO: GET site


#pragma mark - Direct Messages
/// @name Direct Messages (DMs)

/**
 Gets the most recent direct messages sent to the authenticating user. This method requires an access token with RWD. API endpoint: // GET direct_messages.
 @param count Number of Messages to get, must be greater than 0 and less than 200.
 */
- (id)getDirectMessages:(int)count;


/**
 Gets the most recent direct messages sent by the authenticating user. This method requires an access token with RWD. API endpoint: GET direct_messages/sent,
 @param count Number of Messages to get, must be greater than 0 and less than 200.
 */
- (id)getSentDirectMessages:(int)count;


/**
 Shows a single direct message, specified by an id parameter. This method requires an access token with RWD. API endpoint: GET direct_messages/show.
 @param messageID ID of message.
 */
- (id)showDirectMessage:(NSString *)messageID;


/**
 Destroys (deletes) the direct message specified in the required ID parameter. The authenticating user must be the recipient of the specified direct message. This method requires an access token with RWD. API endpoint: POST direct_messages/destroy.
 @param messageID ID of message.
 @return The response from the Twitter API.
 */
- (id)deleteDirectMessage:(NSString *)messageID;


/**
 Sends a new direct message to the specified user from the authenticating user. API endpoint: POST direct_messages/new.
 @param body Message body (required).
 @param user Message recipient (required).
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @return The response from the Twitter API.
 */
- (id)sendDirectMessage:(NSString *)body toUser:(NSString *)user isID:(BOOL)isID;


#pragma mark - Friends & Followers
/// @name Friends & Followers

/**
 Gets user IDs that the currently authenticated user does not want to receive retweets from. Use `enableRetweets:andDeviceNotifs:forUser:isID` to set the "no retweets" status for a given user account on behalf of the current user. API endpoint: GET friendships/no_retweets/ids.
 @return List of user IDs.
 */
- (id)getNoRetweetIDs;


/**
 Gets a list of user IDs the authenticated user is following. API endpoint: GET friends/ids.
 @return List of user IDs.
 */
- (id)getFriendsIDs;


/**
 Gets a list of user IDs following the authenticated user. API endpoint: GET followers/ids.
 @return List of user IDs.
 */
- (id)getFollowersIDs;


/**
 Gets a list of user IDs for every user who has a pending request to follow the authenticating user. API endpoint: GET friendships/incoming.
 @return List of user IDs.
 */
- (id)getPendingIncomingFollowers;


/**
 Gets a list of user IDs for every protected user for whom the authenticating user has a pending follow request. API endpoint: GET friendships/outgoing.
 @return List of user IDs.
 */
- (id)getPendingOutgoingFollowers;


/**
 Follows the specified user. API endpoint: POST friendships/create.
 @param user The user ID or screen name.
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @return The response from the Twitter API.
 */
- (id)followUser:(NSString *)user isID:(BOOL)isID;


/**
 Unfollows the specified user. API endpoint: POST friendships/destroy.
 @param user The user ID or screen name.
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @return The response from the Twitter API.
 */
- (id)unfollowUser:(NSString *)user isID:(BOOL)isID;


/**
 Allows one to enable or disable retweets and device notifications from the specified user. API endpoint: POST friendships/update.
 @param enableRTs A Boolean value to determine whether to enable or disable retweets.
 @param devNotifs A Boolean value to determine whether to enable or disable device notifications.
 @param user The user ID or screen name.
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @return The response from the Twitter API.
 */
- (id)enableRetweets:(BOOL)enableRTs andDeviceNotifs:(BOOL)devNotifs forUser:(NSString *)user isID:(BOOL)isID;


/**
 Returns detailed information about the relationship between two arbitrary users. API endpoint: GET friendships/show.
 */
//TODO: GET friendships/show


/**
 Gets a friends list for an user. API endpoint: GET friends/list.
 @param user The user ID or screen name.
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @param cursor Cursor position of the list.
 @return A list of user IDs.
 */
- (id)listFriendsForUser:(NSString *)user isID:(BOOL)isID withCursor:(NSString *)cursor;


/**
 Gets a list of followers for an user. API endpoint: GET followers/list.
 @param user The user ID or screen name.
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @param cursor Cursor position of the list.
 @return A list of user IDs.
 */
- (id)listFollowersForUser:(NSString *)user isID:(BOOL)isID withCursor:(NSString *)cursor;


/**
 Gets the relationships of the authenticating user to the comma-separated list of up to 100 screen_names or user_ids provided. Values for connections can be: following, following_requested, followed_by, none, blocking. API endpoint: GET friendships/lookup.
 @param users List of users.
 @param areIDs A Boolean that determines if `users` are screen names or user IDs.
 */
- (id)lookupFriendshipStatusForUsers:(NSArray *)users areIDs:(BOOL)areIDs;


#pragma mark - Users
/// @name Users

/**
 Gets settings (including current trend, geo and sleep time information) for the authenticating user. API endpoint: GET account/settings.
 */
- (id)getUserSettings;


/**
 Use this method to test if supplied user credentials are valid. API endpoint: GET account/verify_credentials.
 @return Returns an HTTP 200 OK response code and a representation of the requesting user if authentication was successful; returns a 401 status code and an error message if not.
 */
- (id)verifyCredentials;


/**
 Updates the authenticating user's settings. API endpoint: POST account/settings.
 @param settings Dictionary with the following keys (values are strings):
 `sleep_time_enabled`: true/false,
 `sleep_time_enabled`: true/false,
 `start_sleep_time`: UTC time,
 `end_sleep_time`: UTC time,
 `time_zone`: Europe/Copenhagen, Pacific/Tongatapu,
 `lang`: en, it, es.
 @return The response from the Twitter API.
 */
- (id)updateSettingsWithDictionary:(NSDictionary *)settings;


/**
 Sets which device Twitter delivers updates to for the authenticating user. Sending none as the device parameter will disable SMS updates. API endpoint:POST account/update_delivery_device.
 */
// TODO: POST account/update_delivery_device


/**
 Updates the profile for the authenticated user. API endpoint: POST account/update_profile.
 @param settings Dictionary with the following keys (values are strings):
 `name` (20 characters maximum),
 `url` (100 characters maximum),
 `location` (30 characters maximum),
 `description` (160 characters maximum).
 @return The response from the Twitter API.
 */
- (id)updateUserProfileWithDictionary:(NSDictionary *)settings;


/**
 Sets the authenticated user's profile background image with an image. API endpoint: POST account/update_profile_background_image.
 @param data Image data.
 @param isTiled A Boolean value that determines if the image is tiled. If `YES`, the image is tiled.
 @return The response from the Twitter API.
 */
- (id)setProfileBackgroundImageWithImageData:(NSData *)data tiled:(BOOL)isTiled;


/**
 Sets the authenticated user's profile background image with an image. API endpoint: POST account/update_profile_background_image.
 @param file File path of image.
 @param isTiled A Boolean value that determines if the image is tiled. If `YES`, the image is tiled.
 @return The response from the Twitter API.
 */
- (id)setProfileBackgroundImageWithImageAtPath:(NSString *)file tiled:(BOOL)isTiled;


/**
 Sets the profile colors for the authenticated user. API endpoint: POST account/update_profile_colors.
 @param dictionary Dictionary with the following keys (values are hex colors in string format, either three or six characters):
 `profile_background_color`,
 `profile_link_color`,
 `profile_sidebar_border_color`,
 `profile_sidebar_fill_color`,
 `profile_text_color`.
 If the dictionary is nil, FHSTwitterEngine resets the values.
 @return The response from the Twitter API.
 */
- (id)updateProfileColorsWithDictionary:(NSDictionary *)dictionary;


/**
 Sets the profile image with an image file path. API endpoint: POST account/update_profile_image.
 @param file File path of image.
 @return The response from the Twitter API.
 */
- (id)setProfileImageWithImageAtPath:(NSString *)file;


/**
 Sets the profile image with an image. API endpoint: POST account/update_profile_image.
 @param data Image data.
 @return The response from the Twitter API.
 */
- (id)setProfileImageWithImageData:(NSData *)data;


/**
 Sets whether the profile uses a background image. API endpoint: POST account/update_profile_image.
 @param shouldUseProfileBackgroundImage A Boolean value that determines if whether the profile uses a background image.
 @return The response from the Twitter API.
 */
- (id)setUseProfileBackgroundImage:(BOOL)shouldUseProfileBackgroundImage;


/**
 Returns a collection of users that the authenticating user is blocking. API endpoint: GET blocks/list.
 */
- (id)listBlockedIDs;


/**
 Returns a collection of IDs that the authenticating user is blocking. API endpoint: GET blocks/ids.
 */
- (id)listBlockedUsers;


/**
 Blocks the specified user from following the authenticating user. In addition the blocked user will not show in the authenticating users mentions or timeline (unless retweeted by another user). If a follow or friend relationship exists it is destroyed. API endpoint: POST blocks/create.
 @param username Screen name of user to block.
 @return The response from the Twitter API.
 */
- (id)block:(NSString *)username;


/**
 Un-blocks the user specified user for the authenticating user. If relationships existed before the block was instated, they will not be restored. API endpoint: POST blocks/destroy.
 @param username Screen name of user to block.
 @return The response from the Twitter API.
 */
- (id)unblock:(NSString *)username;


/**
 Returns if the authenticating user is blocking a target user. API endpoint: GET blocks/exists.
 @param user The user ID or screen name.
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (id)authenticatedUserIsBlocking:(NSString *)user isID:(BOOL)isID;



/**
 Looks up users (up to 100 users). API endpoint: GET users/lookup.
 @param users List of users to look up.
 @param areIDs A Boolean value that determines whether the list is of screen names or user IDs. If `YES`, `users` is a list of user IDs.
 */
- (id)lookupUsers:(NSArray *)users areIDs:(BOOL)areIDs;


/**
 Returns a variety of information about the user specified by the required user_id or screen_name parameter. The author's most recent Tweet will be returned inline when possible. GET users/lookup is used to retrieve a bulk collection of user objects. API endpoint: GET users/show.
 */
// TODO: GET users/show


/**
 Searches users with the given query. API endpoint: GET users/search.
 @param q Query of search.
 @param count Count of query.
 */
- (id)searchUsersWithQuery:(NSString *)q andCount:(int)count;


/**
 Returns a collection of users that the specified user can "contribute" to. API endpoint: GET users/contributees.
*/
// TODO: GET users/contributees


/**
 Returns a collection of users who can contribute to the specified account. API endpoint: GET users/contributors.
 */
// TODO: GET users/contributors


/**
 Removes the uploaded profile banner for the authenticating user. Returns HTTP 200 upon success. API endpoint: POST account/remove_profile_banner.
 */
//TODO: POST account/remove_profile_banner


/**
 Uploads a profile banner on behalf of the authenticating user.  API endpoint: POST account/update_profile_banner.
 */
//TODO: POST account/update_profile_banner


/**
 Mutes the user specified in the ID parameter for the authenticating user. API endpoint: POST mutes/users/create
 @param user The user ID or screen name.
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @return Returns the muted user in the requested format when successful. Returns a string describing the failure condition when unsuccessful.
 */
- (id)muteUser:(NSString *)user isID:(BOOL)isID;


/**
 Un-mutes the user specified in the ID parameter for the authenticating user. API endpoint: POST mutes/users/destroy
 @param user The user ID or screen name.
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @return Returns the unmuted user in the requested format when successful. Returns a string describing the failure condition when unsuccessful.
 */
- (id)unmuteUser:(NSString *)user isID:(BOOL)isID;


/**
 Get list of user IDs the authenticating user has muted. API endpoint: GET mutes/users/ids
 @return Returns an array of numeric user ids the authenticating user has muted. API endpoint: GET mutes/users/ids
 */
- (id)getMutedIds;


/** 
 Get list of users the authenticating user has muted. API endpoint: GET mutes/users/list
 @return Returns an array of user objects the authenticating user has muted.
 */
- (id)getMutedUsers;


/**
 Returns a map of the available size variations of the specified user's profile banner. If the user has not uploaded a profile banner, a HTTP 404 will be served instead.  API endpoint: GET users/profile_banner.
 */
//TODO: GET users/profile_banner


#pragma mark - Suggested Users
/// @name Suggested Users

/**
 Access the users in a given category of the Twitter suggested user list. It is recommended that applications cache this data for no more than one hour. API endpoint: GET users/suggestions/:slug.
 */
// TODO: GET users/suggestions/:slug

/**
 Access to Twitter's suggested user list. This returns the list of suggested user categories. The category can be used in GET users/suggestions/:slug to get the users in that category. API endpoint: GET users/suggestions.
 */
// TODO: GET users/suggestions
 
/**
 Access the users in a given category of the Twitter suggested user list and return their most recent status if they are not a protected user. API endpoint: GET users/suggestions/:slug/members.
 */
// TODO: GET users/suggestions/:slug/members


#pragma mark - Favorites
/// @name Favorites

/**
 Gets the favorite Tweets for a given user. API endpoint: GET favorites/list.
 @param user The user ID or screen name.
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @param count Number of Tweets to get.
 @return A list of Tweets favorited by the user.
 */
- (id)getFavoritesForUser:(NSString *)user isID:(BOOL)isID andCount:(int)count;


/**
 Gets the favorite Tweets for a given user. API endpoint: // GET favorites/list.
 @param user The user ID or screen name.
 @param isID A Boolean that determines of `user` is a screen name or a user ID.
 @param count Specifies the number of records to retrieve. Must be less than or equal to 200. Defaults to 20.
 @param sinceID Returns results with an ID greater than (that is, more recent than) the specified ID.
 @param maxID Returns results with an ID less than (that is, older than) or equal to the specified ID.
 @return A list of Tweets.
 */
- (id)getFavoritesForUser:(NSString *)user isID:(BOOL)isID andCount:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;


/**
 Marks or unmarks Tweet as favorite for the authenticating user. API endpoints: POST favorites/destroy, POST favorites/create.
 @param tweetID ID of Tweet to mark or unmark as favorite.
 @param flag A Boolean value that determines if the Tweet is to be marked or unmarked as favorite. If `YES`, the Tweet is marked as favorite.
 @return The response from the Twitter API.
 */
- (id)markTweet:(NSString *)tweetID asFavorite:(BOOL)flag;

// TODO: separate methods to favorite/destroy?


#pragma mark - Lists
/// @name Lists

/**
 Gets all lists the specified user subscribes to, including their own.  API endpoint: GET lists/list.
 @param user The user ID or screen name.
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @return Twitter lists.
 */
- (id)getListsForUser:(NSString *)user isID:(BOOL)isID;


/**
 Returns a timeline of tweets authored by members of the specified list. API endpoint: GET lists/statuses.
 @param listID The list ID.
 @param count Number of Tweets to get.
 @return A list of Tweets.
 */
- (id)getTimelineForListWithID:(NSString *)listID count:(int)count;


/**
 Returns a timeline of tweets authored by members of the specified list. API endpoint: GET lists/statuses.
 @param listID The list ID.
 @param count Number of Tweets to get.
 @param sinceID Returns results with an ID greater than (that is, more recent than) the specified ID.
 @param maxID Returns results with an ID less than (that is, older than) or equal to the specified ID.
 @return A list of Tweets.
 */
- (id)getTimelineForListWithID:(NSString *)listID count:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;


/**
 Returns a timeline of tweets authored by members of the specified list. API endpoint: GET lists/statuses.
 @param listID The list ID.
 @param count Number of Tweets to get.
 @param excludeRetweets A Boolean that specifies whether to return retweets.
 @param excludeReplies A Boolean that specifies whether to return replies.
 @return A list of Tweets.
 */
- (id)getTimelineForListWithID:(NSString *)listID count:(int)count excludeRetweets:(BOOL)excludeRetweets excludeReplies:(BOOL)excludeReplies;


/**
 Returns a timeline of tweets authored by members of the specified list. API endpoint: GET lists/statuses.
 @param listID The list ID.
 @param count Number of Tweets to get.
 @param sinceID Returns results with an ID greater than (that is, more recent than) the specified ID.
 @param maxID Returns results with an ID less than (that is, older than) or equal to the specified ID.
 @param excludeRetweets A Boolean that specifies whether to return retweets.
 @param excludeReplies A Boolean that specifies whether to return replies.
 @return A list of Tweets.
 */
- (id)getTimelineForListWithID:(NSString *)listID count:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID excludeRetweets:(BOOL)excludeRetweets excludeReplies:(BOOL)excludeReplies;


/**
 Removes the specified member from the list. The authenticated user must be the list's owner to remove members from the list. API endpoint: POST lists/members/destroy.
 */
// TODO: POST lists/members/destroy


/**
 Returns the lists the specified user has been added to. If user_id or screen_name are not provided the memberships for the authenticating user are returned. API endpoint: GET lists/memberships.
 */
// TODO: GET lists/memberships


/**
 Returns the subscribers of the specified list. Private list subscribers will only be shown if the authenticated user owns the specified list. API endpoint: TODO: GET lists/subscribers.
 */
// TODO: GET lists/subscribers


/**
 Subscribes the authenticated user to the specified list. API endpoint: POST lists/subscribers/create.
 */
// TODO: POST lists/subscribers/create


/**
 Check if the specified user is a subscriber of the specified list. Returns the user if they are subscriber. API endpoint: GET lists/subscribers/show.
 */
// TODO: GET lists/subscribers/show


/**
 Unsubscribes the authenticated user from the specified list. API endpoint: POST lists/subscribers/destroy.
 */
// TODO: POST lists/subscribers/destroy


/**
 Adds multiple members to a list, by specifying a comma-separated list of member ids or screen names. The authenticated user must own the list to be able to add members to it. Note that lists can't have more than 5,000 members. API endpoint: POST lists/members/create_all.
 @param listID The ID of the list.
 @param users List of user screen names (at least 1 user, maximum of 100 users).
 @return The response from the Twitter API.
 */
- (id)addUsersToListWithID:(NSString *)listID users:(NSArray *)users;


/**
 Check if the specified user is a member of the specified list. API endpoint: GET lists/members/show.
 */
// TODO: GET lists/members/show


/**
 Returns the members of the specified list. Private list members will only be shown if the authenticated user owns the specified list. API endpoint: GET lists/members.
 @param listID The ID of the list.
 @return A list of users.
 */
- (id)listUsersInListWithID:(NSString *)listID;


/**
 Add a member to a list. The authenticated user must own the list to be able to add members to it. Note that lists cannot have more than 5,000 members. API endpoint: POST lists/members/create.
 */
// TODO: POST lists/members/create


/**
 Deletes the specified list. The authenticated user must own the list to be able to destroy it. API endpoint: POST lists/destroy.
 */
// TODO: POST lists/destroy


/**
 Updates the name of specified list. The authenticated user must own the list to be able to update it. API endpoint: POST lists/update.
 @param listID The ID of the list.
 @param name The name of the list (cannot be empty).
 @return The response from the Twitter API.
 */
- (id)updateListWithID:(NSString *)listID name:(NSString *)name;


/**
 Updates the description of specified list. The authenticated user must own the list to be able to update it. API endpoint: POST lists/update.
 @param listID The ID of the list.
 @param description The description of the list.
 @return The response from the Twitter API.
 */
- (id)updateListWithID:(NSString *)listID description:(NSString *)description;


/**
 Updates the privacy of specified list. The authenticated user must own the list to be able to update it. API endpoint: POST lists/update.
 @param listID The ID of the list.
 @param isPrivate A Boolean that specifies if the list is private.
 @return The response from the Twitter API.
 */
- (id)updateListWithID:(NSString *)listID mode:(BOOL)isPrivate;


/**
 Updates the privacy of specified list. The authenticated user must own the list to be able to update it. API endpoint: POST lists/update.
 @param listID The ID of the list.
 @param name The name of the list (cannot be empty).
 @param description The description of the list.
 @param isPrivate A Boolean that specifies if the list is private.
 @return The response from the Twitter API.
 */
- (id)updateListWithID:(NSString *)listID name:(NSString *)name description:(NSString *)description mode:(BOOL)isPrivate;


/**
 Creates a new list for the authenticated user. Note that you can't create more than 20 lists per account. API endpoint: POST lists/create.
 @param name The name of the list (cannot be empty).
 @param isPrivate A Boolean that specifies if the list is private.
 @param description The description of the list (optional).
 @return The response from the Twitter API.
 */
- (id)createListWithName:(NSString *)name isPrivate:(BOOL)isPrivate description:(NSString *)description;


/**
 Returns the specified list. Private lists will only be shown if the authenticated user owns the specified list. API endpoint: GET lists/show.
 @param listID The ID of the list.
 @return A list with its attributes (name, created_at, see https://dev.twitter.com/docs/api/1.1/get/lists/show for more info).
 */
- (id)getListWithID:(NSString *)listID;


/**
 Obtain a collection of the lists the specified user is subscribed to, 20 lists per page by default. Does not include the user's own lists. API endpoint: GET lists/subscriptions.
 */
// TODO: GET lists/subscriptions


/**
 Removes multiple members from a list, by specifying a comma-separated list of  screen names. The authenticated user must own the list to be able to remove members from it. API endpoint: POST lists/members/destroy_all.
 @param listID The ID of the list.
 @param users List of user screen names (at least 1 user, maximum of 100 users).
 @return The response from the Twitter API.
 */
- (id)removeUsersFromListWithID:(NSString *)listID users:(NSArray *)users;


/**
 Returns the lists owned by the specified Twitter user. Private lists will only be shown if the authenticated user is also the owner of the lists. API endpoint: GET lists/ownerships.
 */
// TODO: GET lists/ownerships


#pragma mark - Saved Searches
/// @name Saved Searches

/**
 Returns the authenticated user's saved search queries. API endpoint: GET saved_searches/list.
 */
// TODO: GET saved_searches/list


/**
 Retrieve the information for the saved search represented by the given id. The authenticating user must be the owner of saved search ID being requested. API endpoint: GET saved_searches/show/:id.
 */
// TODO: GET saved_searches/show/:id


/**
Create a new saved search for the authenticated user. A user may only have 25 saved searches. API endpoint:POST saved_searches/create.
 */
// TODO: POST saved_searches/create


/**
 Destroys a saved search for the authenticating user. The authenticating user must be the owner of saved search id being destroyed. API endpoint: POST saved_searches/destroy/:id.
 */
// TODO: POST saved_searches/destroy/:id


#pragma mark - Trends
/// @name Trends

/**
Returns the top 10 trending topics for a specific WOEID, if trending information is available for it. API endpoint: GET trends/place.
 */
// TODO: GET trends/place


/**
 Returns the locations that Twitter has trending topic information for. The response is an array of "locations" that encode the location's WOEID and some other human-readable information such as a canonical name and country the location belongs in. A WOEID is a Yahoo! Where On Earth ID. API endpoint: GET trends/available.
 */
// TODO: GET trends/available


/**
 Returns the locations that Twitter has trending topic information for, closest to a specified location. The response is an array of "locations" that encode the location's WOEID and some other human-readable information such as a canonical name and country the location belongs in.  API endpoint: GET trends/closest.
 */
// TODO: GET trends/closest


#pragma mark - Spam Reporting
/// @name Spam Reporting

/**
 Reports the specified user as a spam account to Twitter (additionally blocks the user). API endpoint: POST users/report_spam.
 @param user The user ID or screen name.
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @return The response from the Twitter API.
 */
- (id)reportUserAsSpam:(NSString *)user isID:(BOOL)isID;


#pragma mark - OAuth
/// @name OAuth

/**
 Allows a Consumer application to use an OAuth request_token to request user authorization. This method is a replacement of Section 6.2 of the OAuth 1.0 authentication flow for applications using the callback authentication flow.  API endpoint: GET oauth/authenticate.
 */
// TODO: GET oauth/authenticate


/**
 Allows a Consumer application to use an OAuth Request Token to request user authorization. This method fulfills Section 6.2 of the OAuth 1.0 authentication flow. Desktop applications must use this method (and cannot use GET oauth/authenticate). Please use HTTPS for this method. API endpoint: GET oauth/authorize.
 */
// TODO: GET oauth/authorize


/**
 Allows a Consumer application to exchange the OAuth Request Token for an OAuth Access Token. This method fulfills Section 6.3 of the OAuth 1.0 authentication flow. The OAuth access token may also be used for xAuth operations. Please use HTTPS for this method. API endpoint: POST oauth/access_token.
 */
// TODO: POST oauth/access_token


/**
 Allows a Consumer application to obtain an OAuth Request Token to request user authorization. API endpoint: POST oauth/request_token.
 */
- (id)getRequestToken;
- (id)getRequestTokenReverseAuth:(BOOL)reverseAuth; // for use with the iOS integrated twitter accounts

/**
 Allows a registered application to obtain an OAuth 2 Bearer Token, which can be used to make API requests on an application's own behalf, without a user context. This is called Application-only authentication. A Bearer Token may be invalidated using oauth2/invalidate_token. API endpoint: POST oauth2/token.
 */
// TODO: POST oauth2/token

/**
 Allows a registered application to revoke an issued OAuth 2 Bearer Token by presenting its client credentials. Once a Bearer Token has been invalidated, new creation attempts will yield a different Bearer Token and usage of the invalidated token will no longer be allowed. API endpoint: oauth2/invalidate_token.
 */
// TODO: POST oauth2/invalidate_token


#pragma mark - Help
/// @name Help

/**
 Returns the current configuration used by Twitter including twitter.com slugs which are not usernames, maximum photo resolutions, and t.co URL lengths. It is recommended applications request this endpoint when they are loaded, but no more than once a day. API endpoint: GET help/configuration.
 */
- (id)getConfiguration;


/**
 Returns the list of languages supported by Twitter along with their ISO 639-1 code. The ISO 639-1 code is the two letter value to use if you include lang with any of your requests. API endpoint: GET help/languages.
 */
- (id)getLanguages;


/**
 Returns Twitter's Privacy Policy. API endpoint: GET help/privacy.
 */
- (id)getPrivacyPolicy;


/**
 Returns the Twitter Terms of Service. API endpoint: GET help/tos.
 */
- (id)getTermsOfService;


/**
 Gets the rate limit status. See https://dev.twitter.com/docs/api/1.1/get/application/rate_limit_status for more information. API endpoint: GET application/rate_limit_status.
 */
- (id)getRateLimitStatus;


#pragma mark - Non-API
/// @name Non-API


#pragma mark Test
/**
 Tests the Twitter service. API endpoint: help/test.
 */
- (id)testService;

#pragma mark TwitPic (photo upload)

/**
 Posts a Tweet with an image using TwitPic.
 @param image Image to post.
 @param message Message to post (optional).
 @param twitPicAPIKey TwitPic API key.
 */
- (id)uploadImageToTwitPic:(UIImage *)image withMessage:(NSString *)message twitPicAPIKey:(NSString *)twitPicAPIKey;


/**
 Posts a Tweet with an image using TwitPic.
 @param imageData Image data of image to post.
 @param message Message to post (optional).
 @param twitPicAPIKey TwitPic API key.
 */
- (id)uploadImageDataToTwitPic:(NSData *)imageData withMessage:(NSString *)message twitPicAPIKey:(NSString *)twitPicAPIKey;


#pragma mark Login and Auth

/**
 OAuth.
 @param reqToken Request token `FHSToken`.
 @return A Boolean that specifies whether the request was successful.
 */
- (BOOL)finishAuthWithRequestToken:(FHSToken *)reqToken;


/**
 Authenticates using xAuth.
 @param username Username for xAuth.
 @param password Password for xAuth.
 */
- (NSError *)authenticateWithUsername:(NSString *)username password:(NSString *)password;


#pragma mark Access Token Management

/**
 Clears the access token.
 */
- (void)clearAccessToken;


/**
 Loads the access token.
 */
- (void)loadAccessToken;


/**
 Returns whether the library is authorized with Twitter.
 */
- (BOOL)isAuthorized;
- (void)storeAccessToken:(NSString *)accessTokenZ; // store your own HTTP body


#pragma mark API Key Management

/**
 Clears the consumer.
 */
- (void)clearConsumer;
- (void)clearConsumerIfNecessary;


/**
 Uses the consumer key pair for one request.
 @param consumerKey Consumer key.
 @param consumerSecret Consumer secret.
 */
- (void)temporarilySetConsumerKey:(NSString *)consumerKey andSecret:(NSString *)consumerSecret;


/**
 Uses the consumer key pair indefinitely.
 @param consumerKey Consumer key.
 @param consumerSecret Consumer secret.
 */
- (void)permanentlySetConsumerKey:(NSString *)consumerKey andSecret:(NSString *)consumerSecret;


#pragma mark Misc.

/**
 Initializes `FHSTwitterEngine`.
 Never call -[FHSTwitterEngine init] directly.
 */
+ (FHSTwitterEngine *)sharedEngine;


/**
 Singleton for a date formatter that is configured to parse Twitter's dates.
 */
+ (NSDateFormatter *)dateFormatter;


/**
 Checks whether the client is connected to the internet.
 */
+ (BOOL)isConnectedToInternet;


@end

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

// Models
#import "FHSOAuthModel.h"

// Constants
#import "FHSDefines.h"

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
 A Boolean value indicating whether FHSTwitterEngine should clear the consumer key.
 */
@property (assign, nonatomic) BOOL shouldClearConsumer;


/**
 A Boolean value indicating wheather FHSTwitterEngine should include Entities. See Twitter's documentation for more information:
 https://dev.twitter.com/docs/entities
 */
@property (nonatomic, assign) BOOL includeEntities;


/**
 A `FHSToken` object representing the access token.
 */
@property (nonatomic, strong) FHSToken *accessToken;


/**
 A `FHSConsumer` object representing the consumer.
 */
@property (strong, nonatomic) FHSConsumer *consumer;


#pragma mark Blocks

/**
 Blocks to store the access token.
 */
@property (nonatomic, copy) StoreAccessTokenBlock storeAccessTokenBlock;


/**
 Blocks to load the access token.
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
 Gets the most recent mentions (Tweets containing a users's @screen_name) for the authenticating user.
 @param count Number of Tweets to retrieve.
 @return A list of Tweets.
 */
// GET statuses/mentions_timeline
- (id)getMentionsTimelineWithCount:(int)count;


/**
 Gets the most recent mentions (Tweets containing a users's @screen_name) for the authenticating user.
 @param count Number of Tweets to retrieve.
 @param sinceID Returns results with an ID greater than (that is, more recent than) the specified ID.
 @param maxID Returns results with an ID less than (that is, older than) or equal to the specified ID.
 @return A list of Tweets.
 */
// GET statuses/mentions_timeline
- (id)getMentionsTimelineWithCount:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;


/**
 Gets the home timeline for the authenticated user (list of the most recent Tweets and retweets posted by the authenticating user and the users they follow).
 @param sinceID Timeline will return Tweets with ID greater than this value (optional, set `sinceID` to `@""` if you do not wish to use this parameter).
 @param count Number of Tweets to retrieve (needs to be greater than zero).
 @return A list of Tweets.
 */
// GET statuses/home_timeline
- (id)getHomeTimelineSinceID:(NSString *)sinceID count:(int)count;


/**
 Gets the timeline for a given user.
 @param user The user ID or screen name.
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @param count Number of Tweets to get.
 @return A list of Tweets.
 */
// GET statuses/user_timeline
- (id)getTimelineForUser:(NSString *)user isID:(BOOL)isID count:(int)count;


/**
 Gets the timeline for a given user.
 @param user The user ID or screen name.
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @param count Number of Tweets to get.
 @param sinceID Returns results with an ID greater than (that is, more recent than) the specified ID.
 @param maxID Returns results with an ID less than (that is, older than) or equal to the specified ID.
 @return A list of Tweets.
 */
// GET statuses/user_timeline
- (id)getTimelineForUser:(NSString *)user isID:(BOOL)isID count:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;


/**
 Gets the most recent tweets authored by the authenticating user that have been retweeted by others.
 @param count Number of Tweets to get.
 @return A list of Tweets.
 */
// GET statuses/retweets_of_me
- (id)getRetweetedTimelineWithCount:(int)count;


/**
 Gets the most recent tweets authored by the authenticating user that have been retweeted by others.
 @param count Number of Tweets to get.
 @param sinceID Returns results with an ID greater than (that is, more recent than) the specified ID.
 @param maxID Returns results with an ID less than (that is, older than) or equal to the specified ID.
 @return A list of Tweets.
 */
// GET statuses/retweets_of_me
- (id)getRetweetedTimelineWithCount:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;


#pragma mark - Tweets
/// @name Tweets

/**
 Gets the most recent retweets of the tweet specified by the Tweet ID.
 @param identifier Tweet ID.
 @param count Number of Tweets to get.
 @return A list of Tweets.
 */
// GET statuses/retweets
- (id)getRetweetsForTweet:(NSString *)identifier count:(int)count;


/**
 Gets a single Tweet with the given Tweet ID.
 @param identifier Tweet ID.
 @return Detail for the Tweet.
 */
// GET statuses/show
- (id)getDetailsForTweet:(NSString *)identifier;


/**
 Destroys (deletes) the status specified by the Tweet ID. The authenticating user must be the author of the specified status.
 @param identifier Tweet ID.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
// POST statuses/destroy
- (NSError *)destroyTweet:(NSString *)identifier;


/**
 Posts a Tweet. To upload an image, use `postTweet:withImageData:`.
 @param tweetString Tweet to post.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
// POST statuses/update
- (NSError *)postTweet:(NSString *)tweetString;


/**
 Posts a reply to a Tweet.
 @param tweetString Reply.
 @param inReplyToString Tweet ID to reply to.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
// POST statuses/update
- (NSError *)postTweet:(NSString *)tweetString inReplyTo:(NSString *)inReplyToString;


/**
 Retweets a Tweet with the given Tweet ID.
 @param identifier Tweet ID.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
// POST statuses/retweet
- (NSError *)retweet:(NSString *)identifier;


/*
 Posts a Tweet with an image.
 @param tweetString Tweet to post.
 @param theData Image data.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
// POST statuses/update_with_media
- (NSError *)postTweet:(NSString *)tweetString withImageData:(NSData *)theData;


/*
 Posts a Tweet with an image.
 @param tweetString Tweet to post.
 @param theData Image data.
 @param inReplyToString Tweet ID to reply to.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
// POST statuses/update_with_media

- (NSError *)postTweet:(NSString *)tweetString withImageData:(NSData *)theData inReplyTo:(NSString *)irt;


//TODO: GET statuses/oembed
//TODO: GET statuses/retweeters/ids


#pragma mark - Search
/// @name Search

/**
 Search for relevant Tweets matching a specified query.
 @param q Search query.
 @param count Number of Tweets to get, must be greater than 0.
 @param resultType Use enum for mixed, recent or popular
 @param unil Returns tweets generated before the given date. Date should be formatted as YYYY-MM-DD.
 @param sinceID Returns results with an ID greater than (that is, more recent than) the specified ID.
 @param maxID Returns results with an ID less than (that is, older than) or equal to the specified ID.
 @return A list of Tweets.
 */
// GET search/tweets
//TODO: rename unil to until
- (id)searchTweetsWithQuery:(NSString *)q count:(int)count resultType:(FHSTwitterEngineResultType)resultType unil:(NSDate *)untilDate sinceID:(NSString *)sinceID maxID:(NSString *)maxID;


#pragma mark - Streaming
/// @name Streaming

/**
 Returns public statuses that match one or more filter predicates (`follow`, `track`, `locations`).
 @param users List of users, at least one is required (`follow`).
 @param keywords List of keywords, at least one is required (`track`).
 @param locBox A comma-separated list of longitude, latitude pairs (must be exactly four) specifying a location bounding box to filter Tweets by (`locations`).
 @param block Stream block: it contains a return stream and a *stop Boolean.
 */
// POST statuses/filter
- (void)streamPublicStatusesForUsers:(NSArray *)users keywords:(NSArray *)keywords locationBox:(NSArray *)locBox block:(StreamBlock)block;


/**
 Returns a small random sample of all public statuses.
 @param block Stream block: it contains a return stream and a *stop Boolean.
 */
// GET statuses/sample
- (void)streamSampleStatusesWithBlock:(StreamBlock)block;


/**
 Returns all public statuses. This endpoint requires special permission to access.
 @param block Stream block: it contains a return stream and a *stop Boolean.
 */
// GET statuses/firehose
- (void)streamFirehoseWithBlock:(StreamBlock)block;


/**
 Streams messages for users.
 @param with List of users the authenticated user is following (optional).
 @param replies A Boolean to determine whether the stream includes replies (this is not implemented at the moment).
 @param keywords List of keywords of additional Tweets to stream (optional).
 @param locBox A comma-separated list of longitude, latitude pairs specifying a location bounding box to filter Tweets by (optional).
 @param block Stream block: it contains a return stream and a *stop Boolean.
 */
// GET user
- (void)streamUserMessagesWith:(NSArray *)with replies:(BOOL)replies keywords:(NSArray *)keywords locationBox:(NSArray *)locBox block:(StreamBlock)block;


// TODO: GET site


#pragma mark - Direct Messages
/// @name Direct Messages (DMs)

/**
 Gets the most recent direct messages sent to the authenticating user. This method requires an access token with RWD.
 @param count Number of Messages to get, must be greater than 0 and less than 200.
 */
// GET direct_messages
- (id)getDirectMessages:(int)count;


/**
 Gets the most recent direct messages sent by the authenticating user. This method requires an access token with RWD.
 @param count Number of Messages to get, must be greater than 0 and less than 200.
 */
// GET direct_messages/sent
- (id)getSentDirectMessages:(int)count;


/**
 Shows a single direct message, specified by an id parameter. This method requires an access token with RWD (read, write...
 @param messageID ID of message.
 */
//GET direct_messages/show
- (id)showDirectMessage:(NSString *)messageID;


/**
 Destroys (deletes) the direct message specified in the required ID parameter. The authenticating user must be the recipient of the specified direct message. This method requires an access token with RWD.
 @param messageID ID of message.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
// POST direct_messages/destroy
- (NSError *)deleteDirectMessage:(NSString *)messageID;


/**
 Sends a new direct message to the specified user from the authenticating user.
 @param body Message body (required).
 @param user Message recipient (required).
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
// POST direct_messages/new
- (NSError *)sendDirectMessage:(NSString *)body toUser:(NSString *)user isID:(BOOL)isID;


#pragma mark - Friends & Followers
/// @name Friends & Followers

/**
 Gets user IDs that the currently authenticated user does not want to receive retweets from. Use `enableRetweets:andDeviceNotifs:forUser:isID` to set the "no retweets" status for a given user account on behalf of the current user.
 @return List of user IDs.
 */
// GET friendships/no_retweets/ids
- (id)getNoRetweetIDs;


/**
 Gets a list of user IDs the authenticated user is following.
 @return List of user IDs.
 */
// GET friends/ids
- (id)getFriendsIDs;


/**
 Gets a list of user IDs following the authenticated user.
 @return List of user IDs.
 */
// GET followers/ids
- (id)getFollowersIDs;


/**
 Gets a list of user IDs for every user who has a pending request to follow the authenticating user.
 @return List of user IDs.
 */
// GET friendships/incoming
- (id)getPendingIncomingFollowers;


/**
 Gets a list of user IDs for every protected user for whom the authenticating user has a pending follow request.
 @return List of user IDs.
 */
// GET friendships/outgoing
- (id)getPendingOutgoingFollowers;


/**
 Follows the specified user.
 @param user The user ID or screen name.
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
// POST friendships/create
- (NSError *)followUser:(NSString *)user isID:(BOOL)isID;


/**
 Unfollows the specified user.
 @param user The user ID or screen name.
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
// POST friendships/destroy
- (NSError *)unfollowUser:(NSString *)user isID:(BOOL)isID;


/**
 Allows one to enable or disable retweets and device notifications from the specified user.
 @param enableRTs A Boolean value to determine whether to enable or disable retweets.
 @param devNotifs A Boolean value to determine whether to enable or disable device notifications.
 @param user The user ID or screen name.
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
// POST friendships/update
- (NSError *)enableRetweets:(BOOL)enableRTs andDeviceNotifs:(BOOL)devNotifs forUser:(NSString *)user isID:(BOOL)isID;


/**
 Returns detailed information about the relationship between two arbitrary users.
 */
//TODO: GET friendships/show


/**
 Gets a friends list for an user.
 of user IDs following a specified user.
 @param user The user ID or screen name.
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @param cursor Cursor position of the list.
 @return A list of user IDs.
 */
// GET friends/list
- (id)listFriendsForUser:(NSString *)user isID:(BOOL)isID withCursor:(NSString *)cursor;


/**
 Gets a list of followers for an user.
 Returns a cursored collection of user objects for users following the specified user. At this time, results are ordered with the most recent following first — however, this ordering is subject to unannounced change and eventual consistency issues. Results are given in groups of 20 users and...
 @param user The user ID or screen name.
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @param cursor Cursor position of the list.
 @return A list of user IDs.
 */
// GET followers/list
- (id)listFollowersForUser:(NSString *)user isID:(BOOL)isID withCursor:(NSString *)cursor;


/**
 Gets the relationships of the authenticating user to the comma-separated list of up to 100 screen_names or user_ids provided. Values for connections can be: following, following_requested, followed_by, none, blocking.
 @param users List of users.
 @param isID A Boolean that determines if `users` are screen names or user IDs.
 */
// GET friendships/lookup
- (id)lookupFriendshipStatusForUsers:(NSArray *)users areIDs:(BOOL)areIDs;



//TODO: below

#pragma mark - Users
#pragma mark - Suggested Users
#pragma mark - Favorites
#pragma mark - Lists
#pragma mark - Saved Searches
#pragma mark - Trends
#pragma mark - Spam Reporting
#pragma mark - OAuth
#pragma mark - Help



#pragma mark - Statuses






#pragma mark Retweet




#pragma mark Misc.


#pragma mark - Blocking

/**
 Blocks the user with the given screen name.
 blocks/create
 @param username Screen name of user to block.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)block:(NSString *)username;


/**
 Unblocks the user with the given screen name.
 nlocks/destroy
 @param username Screen name of user to block.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)unblock:(NSString *)username;


// blocks/blocking/ids
- (id)listBlockedIDs;

// blocks/blocking
- (id)listBlockedUsers;

// blocks/exists
- (id)authenticatedUserIsBlocking:(NSString *)user isID:(BOOL)isID;


#pragma mark - Search

/**
 Looks up users.
 users/lookup
 @param users List of users to look up.
 @param areIDs A Boolean value that determines whether the list is of screen names or user IDs. If `YES`, `users` is a list of user IDs.
 */
- (id)lookupUsers:(NSArray *)users areIDs:(BOOL)areIDs;


/**
 Searches users with the given query.
 users/search
 @param q Query of search.
 @param count Count of query.
 */
- (id)searchUsersWithQuery:(NSString *)q andCount:(int)count;




#pragma mark - Account
#pragma mark Account/update_profile_image

/**
 Sets the profile image with an image file path.
 @param file File path of image.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)setProfileImageWithImageAtPath:(NSString *)file;


/**
 Sets the profile image with an image.
 @param data Image data.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)setProfileImageWithImageData:(NSData *)data;


#pragma mark Account/settings GET and POST

/**
 Gets the authenticated user settings.
 */
- (id)getUserSettings;


/**
 Sets the authenticated user settings.
 @param settings Dictionary with the following keys (values are strings):
 `sleep_time_enabled`: true/false,
 `sleep_time_enabled`: true/false,
 `start_sleep_time`: UTC time,
 `end_sleep_time`: UTC time,
 `time_zone`: Europe/Copenhagen, Pacific/Tongatapu,
 `lang`: en, it, es.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)updateSettingsWithDictionary:(NSDictionary *)settings;


#pragma mark Account/update_profile

/**
 Updates the profile for the authenticated user.
 @param settings Dictionary with the following keys (values are strings):
 `name` (20 characters maximum),
 `url` (100 characters maximum),
 `location` (30 characters maximum),
 `description` (160 characters maximum).
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)updateUserProfileWithDictionary:(NSDictionary *)settings;


#pragma mark Account/update_profile_background_image

/**
 Sets the profile background image with an image.
 @param data Image data.
 @param tiled A Boolean value that determines if the image is tiled. If `YES`, the image is tiled.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)setProfileBackgroundImageWithImageData:(NSData *)data tiled:(BOOL)isTiled;


/**
 Sets the profile background image with an image file path.
 @param file File path of image.
 @param tiled A Boolean value that determines if the image is tiled. If `YES`, the image is tiled.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)setProfileBackgroundImageWithImageAtPath:(NSString *)file tiled:(BOOL)isTiled;


/**
 Sets whether the profile uses a background image.
 @param shouldUseProfileBackgroundImage A Boolean value that determines if whether the profile uses a background image.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)setUseProfileBackgroundImage:(BOOL)shouldUseProfileBackgroundImage;


#pragma mark Account/update_profile_colors

/**
 Sets the profile colors for the authenticated user.
 @param dictionary Dictionary with the following keys (values are hex colors in string format):
 `profile_background_color`,
 `profile_link_color`,
 `profile_sidebar_border_color`,
 `profile_sidebar_fill_color`,
 `profile_text_color`.
 If the dictionary is nil, FHSTwitterEngine resets the values.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)updateProfileColorsWithDictionary:(NSDictionary *)dictionary;


#pragma mark Account/verify_credentials

/**
 Verifies credentials.
 */
- (id)verifyCredentials;


#pragma mark - Application/rate_limit_status

/**
 Gets the rate limit status.
 */
- (id)getRateLimitStatus;


#pragma mark - Favorites
#pragma mark Favorites/create, favorites/destroy

/**
 Marks or unmarks Tweet as favorite.
 @param tweetID ID of Tweet to mark or unmark as favorite.
 @param flag A Boolean value that determines if the Tweet is to be marked or unmarked as favorite. If `YES`, the Tweet is marked as favorite.
 */
- (NSError *)markTweet:(NSString *)tweetID asFavorite:(BOOL)flag;


#pragma mark Favorites/list

/**
 Gets the favorite Tweets for a given user.
 @param user Screen name of user ID.
 @param isID A Boolean that determines if `user` is a screen name or a user ID.
 @param count Number of Tweets to get.
 @return A list of Tweets favorited by the user.
 */
- (id)getFavoritesForUser:(NSString *)user isID:(BOOL)isID andCount:(int)count;


/**
 Gets the Tweets favorited by a given user.
 @param user Screen name of user ID.
 @param isID A Boolean that determines of `user` is a screen name or a user ID.
 @param count Specifies the number of records to retrieve. Must be less than or equal to 200. Defaults to 20.
 @param sinceID Returns results with an ID greater than (that is, more recent than) the specified ID.
 @param maxID Returns results with an ID less than (that is, older than) or equal to the specified ID.
 @return A list of Tweets.
 */
- (id)getFavoritesForUser:(NSString *)user isID:(BOOL)isID andCount:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;





#pragma mark - Help

/**
 Tests the Twitter service.
 help/test
 */
- (id)testService;

// help/tos
- (id)getTermsOfService;

// help/privacy
- (id)getPrivacyPolicy;

// help/configuration
- (id)getConfiguration;

// help/languages
- (id)getLanguages;


#pragma mark - Report spam
// users/report_spam
- (NSError *)reportUserAsSpam:(NSString *)user isID:(BOOL)isID;



// users/profile_image
- (id)getProfileImageForUsername:(NSString *)username andSize:(FHSTwitterEngineImageSize)size;
- (id)getProfileImageURLStringForUsername:(NSString *)username andSize:(FHSTwitterEngineImageSize)size;


#pragma mark - Lists

// lists/list
- (id)getListsForUser:(NSString *)user isID:(BOOL)isID;

// lists/statuses
- (id)getTimelineForListWithID:(NSString *)listID count:(int)count;
- (id)getTimelineForListWithID:(NSString *)listID count:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;
- (id)getTimelineForListWithID:(NSString *)listID count:(int)count excludeRetweets:(BOOL)excludeRetweets excludeReplies:(BOOL)excludeReplies;
- (id)getTimelineForListWithID:(NSString *)listID count:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID excludeRetweets:(BOOL)excludeRetweets excludeReplies:(BOOL)excludeReplies;

// lists/members/create_all
- (NSError *)addUsersToListWithID:(NSString *)listID users:(NSArray *)users;

// lists/members/destroy_all
- (NSError *)removeUsersFromListWithID:(NSString *)listID users:(NSArray *)users;

// lists/members
- (id)listUsersInListWithID:(NSString *)listID;

// lists/update
- (NSError *)updateListWithID:(NSString *)listID name:(NSString *)name;
- (NSError *)updateListWithID:(NSString *)listID description:(NSString *)description;
- (NSError *)updateListWithID:(NSString *)listID mode:(BOOL)isPrivate;
- (NSError *)updateListWithID:(NSString *)listID name:(NSString *)name description:(NSString *)description mode:(BOOL)isPrivate;

// lists/show
- (id)getListWithID:(NSString *)listID;

// lists/create
- (NSError *)createListWithName:(NSString *)name isPrivate:(BOOL)isPrivate description:(NSString *)description;




#pragma mark - TwitPic (photo upload)

- (id)uploadImageToTwitPic:(UIImage *)image withMessage:(NSString *)message twitPicAPIKey:(NSString *)twitPicAPIKey;
- (id)uploadImageDataToTwitPic:(NSData *)imageData withMessage:(NSString *)message twitPicAPIKey:(NSString *)twitPicAPIKey;





#pragma mark - Login and Auth
//
// Login and Auth
//

// OAuth
- (id)getRequestToken;
- (BOOL)finishAuthWithRequestToken:(FHSToken *)reqToken;

// xAuth
- (NSError *)authenticateWithUsername:(NSString *)username password:(NSString *)password;


#pragma mark - Access Token Management

- (void)clearAccessToken;
- (void)loadAccessToken;
- (BOOL)isAuthorized;


#pragma mark - API Key Management

- (void)clearConsumer;
- (void)temporarilySetConsumerKey:(NSString *)consumerKey andSecret:(NSString *)consumerSecret; // key pair is used for one request
- (void)permanentlySetConsumerKey:(NSString *)consumerKey andSecret:(NSString *)consumerSecret; // key pair is used indefinitely


#pragma mark - Misc.

/**
 Generates a request string:
 id/username concatenator - returns an array of concatenated id/username lists
 100 ids/usernames per concatenated string
 */
- (NSArray *)generateRequestStringsFromArray:(NSArray *)array;


/**
 Initializes `FHSTwitterEngine`.
 @warning Never call -[FHSTwitterEngine init] directly.
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

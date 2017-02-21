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
// See https://dev.twitter.com/rest/public for Twitter REST APIs.
// See https://dev.twitter.com/streaming/userstreams for Streaming APIs.
//

#import <UIKit/UIKit.h>

/**
 Image sizes.
 */
typedef enum {
    FHSTwitterEngineImageSizeMini, // 24px by 24px
    FHSTwitterEngineImageSizeNormal, // 48x48
    FHSTwitterEngineImageSizeBigger, // 73x73
    FHSTwitterEngineImageSizeOriginal // original size of image
} FHSTwitterEngineImageSize;

/**
 Result types.
 */
typedef enum {
    FHSTwitterEngineResultTypeMixed,
    FHSTwitterEngineResultTypeRecent,
    FHSTwitterEngineResultTypePopular
} FHSTwitterEngineResultType;

/**
 Stream block.
 */
typedef void(^StreamBlock)(id result, BOOL *stop);

/**
 Remove NSNulls from NSDictionary and NSArray.
 Credit: Conrad Kramer https://github.com/conradev
 */
id removeNull(id rootObject);

// Profile
extern NSString * const FHSProfileBackgroundColorKey;
extern NSString * const FHSProfileLinkColorKey;
extern NSString * const FHSProfileSidebarBorderColorKey;
extern NSString * const FHSProfileSidebarFillColorKey;
extern NSString * const FHSProfileTextColorKey;

extern NSString * const FHSProfileNameKey;
extern NSString * const FHSProfileURLKey;
extern NSString * const FHSProfileLocationKey;
extern NSString * const FHSProfileDescriptionKey;

// Error
extern NSString * const FHSErrorDomain;

/** FHSTwitterEngine token object. */
@interface FHSToken : NSObject

/**
 Token key.
 */
@property (nonatomic, strong) NSString *key;

/**
 Token secret.
 */
@property (nonatomic, strong) NSString *secret;

/**
 Token verifier.
 */
@property (nonatomic, strong) NSString *verifier;

/**
 Get token.
 @param body HTTP response body.
 @return FHSToken.
 */
+ (FHSToken *)tokenWithHTTPResponseBody:(NSString *)body;

@end

/** Access token delegate. */
@protocol FHSTwitterEngineAccessTokenDelegate <NSObject>

/**
 Load access token.
 */
- (NSString *)loadAccessToken;

/**
 Store access token
 */
- (void)storeAccessToken:(NSString *)accessToken;

@optional

/**
 Login was cancelled.
 */
- (void)twitterEngineControllerDidCancel;

@end

/** FHSTwitterEngine, Twitter API for Cocoa developers. */

@interface FHSTwitterEngine : NSObject

#pragma mark - REST API

/// @name REST API

/**
 Post tweet.
 @param tweetString Tweet.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)postTweet:(NSString *)tweetString;


/**
 Post tweet reply.
 @param tweetString Tweet.
 @param inReplyToString Tweet id to reply to.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)postTweet:(NSString *)tweetString inReplyTo:(NSString *)inReplyToString;

/**
 Post tweet with media.
 @param tweetString Tweet.
 @param mediaIDs List of media ids.
 @return If an error occurs, returns an NSError object that describes the problem.
 */

- (NSError *)postTweet:(NSString *)tweetString withMediaIDs:(NSArray *)mediaIDs ;

/**
 Upload media with data.
 @param imageData Image data.
 @param completionBlock Block to be called on completion.
 */
- (void)uploadMediaWithData:(NSData *)imageData withCompletionBlock:(void (^)(NSError *error, id response))completionBlock;

/**
 Get timeline of tweets.
 @param sinceID Start tweet id.
 @param count Number of tweets.
 @return List of tweets.
 */
- (id)getHomeTimelineSinceID:(NSString *)sinceID count:(int)count;

/**
 Test service.
 */
- (id)testService;

/**
 Block a user.
 @param username Username.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)block:(NSString *)username;

/**
 Unblock a user.
 @param username Username.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)unblock:(NSString *)username;

// users/lookup

/**
 Lookup users
 @param users List of users.
 @param areIDs Boolean whether the list is user ids.
 @return User information.
 */
- (id)lookupUsers:(NSArray *)users areIDs:(BOOL)areIDs;

/**
 Search users.
 @param q Search query.
 @param count Number of results.
 @return User information.
 */
- (id)searchUsersWithQuery:(NSString *)q andCount:(int)count;

/**
 Set profile image with file path.
 @param file Image path.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)setProfileImageWithImageAtPath:(NSString *)file;

/**
 Set profile image with image.
 @param data Image data.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)setProfileImageWithImageData:(NSData *)data;

/**
 Get user settings.
 @return User settings.
 */
- (id)getUserSettings;

/**
 Update user settings. See FHSTwitterEngine.m for details.
 @param settings Dictionary of settings.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)updateSettingsWithDictionary:(NSDictionary *)settings;

/**
 Update user profile. See FHSTwitterEngine.m for details.
 @param settings Dictionary of settings.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)updateUserProfileWithDictionary:(NSDictionary *)settings;

/**
 Set profile background with image.
 @param data Image data.
 @param isTiled Boolean whether the image is tiled.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)setProfileBackgroundImageWithImageData:(NSData *)data tiled:(BOOL)isTiled;

/**
 Set profile background with file path.
 @param file Image path.
 @param isTiled Boolean whether the image is tiled.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)setProfileBackgroundImageWithImageAtPath:(NSString *)file tiled:(BOOL)isTiled;

/**
 Enable the profile background image.
 @param shouldUseProfileBackgroundImage Boolean whether to enable the profile background image.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)setUseProfileBackgroundImage:(BOOL)shouldUseProfileBackgroundImage;

/**
 Update profile colors. See FHSTwitterEngine.m for details.
 @param dictionary Dictionary of settings. If the dictionary is nil, FHSTwitterEngine resets the values.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)updateProfileColorsWithDictionary:(NSDictionary *)dictionary;

/**
 Get rate limit status.
 @return Rate limit status.
 */
- (id)getRateLimitStatus;

/**
 Like a tweet.
 @param tweetID Tweet id.
 @param flag Boolean whether the tweet is liked.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)markTweet:(NSString *)tweetID asFavorite:(BOOL)flag;

/**
 Get tweets liked for a user.
 @param user User.
 @param isID Boolean whether the user is a user id.
 @param count Number of likes.
 @return Tweets liked.
 */
- (id)getFavoritesForUser:(NSString *)user isID:(BOOL)isID andCount:(int)count;

/**
 Get tweets liked for a user.
 @param user User.
 @param isID Boolean whether the user is a user id.
 @param sinceID Beginning tweet.
 @param maxID End tweet.
 @return Tweets liked.
 */
- (id)getFavoritesForUser:(NSString *)user isID:(BOOL)isID andCount:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;

/**
 Verify credentials.
 @return User information for authenticated user if authentication was successful.
 */
- (id)verifyCredentials;

/**
 Follow a user.
 @param user User.
 @param isID Boolean whether the user is a user id.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)followUser:(NSString *)user isID:(BOOL)isID;

/**
 Unfollow a user.
 @param user User.
 @param isID Boolean whether the user is a user id.
 @return If an error occurs, returns an NSError object that describes the problem.
 */

- (NSError *)unfollowUser:(NSString *)user isID:(BOOL)isID;

/**
 Get follow status.
 @param users Users.
 @param areIDs Boolean whether the users are user ids.
 @return Follow statuses.
 */
- (id)lookupFriendshipStatusForUsers:(NSArray *)users areIDs:(BOOL)areIDs;

/**
 Get pending requests to follow authenticated user.
 @return Pending requests.
 */
- (id)getPendingIncomingFollowers;

/**
 Get ids of protected users for whom the authenticated user has a pending follow request.
 */
- (id)getPendingOutgoingFollowers;

/**
 Update user follow settings.
 @param enableRTs Boolean whether to receive retweets.
 @param devNotifs Boolean whether to receive device notifications.
 @param user User
 @param isID Boolean whether the user is a user id.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)enableRetweets:(BOOL)enableRTs andDeviceNotifs:(BOOL)devNotifs forUser:(NSString *)user isID:(BOOL)isID;

/**
 Get list of users that authenticated user does not want to receive retweets from.
 @return List of users.
 */
- (id)getNoRetweetIDs;

/**
 Get terms of service.
 @return Terms of service.
 */
- (id)getTermsOfService;

/**
 Get privacy policy.
 @return Privacy Policy.
 */
- (id)getPrivacyPolicy;

/**
 Get direct messages (DMs).
 @param count Number of DMs.
 @return DMs.
 */
- (id)getDirectMessages:(int)count;

/**
 Delete a direct message.
 @param messageID Message id.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)deleteDirectMessage:(NSString *)messageID;

/**
 Get sent direct messages (DMs).
 @param count Number of DMs.
 @return DMs.
 */
- (id)getSentDirectMessages:(int)count;

/**
 Send a direct message (DM).
 @param body Message body.
 @param user Recipient.
 @param isID Boolean whether the user is a user id.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)sendDirectMessage:(NSString *)body toUser:(NSString *)user isID:(BOOL)isID;

/**
 Show a direct message (DM).
 @param messageID Message id.
 @return DM.
 */
- (id)showDirectMessage:(NSString *)messageID;

/**
 Report user as spam.
 @param user User.
 @param isID Boolean whether the user is a user id.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)reportUserAsSpam:(NSString *)user isID:(BOOL)isID;

/**
 Get configuration.
 @return Configuration.
 */
- (id)getConfiguration;

/**
 Get languages.
 @return Languages.
 */
- (id)getLanguages;

/**
 Get list of blocked user ids.
 @return List of blocked user ids.
 */
- (id)listBlockedIDs;

/**
 Get list of blocked users.
 @return List of blocked users.
 */
- (id)listBlockedUsers;

/**
 Get block status for a user.
 @param user User.
 @param isID Boolean whether the user is a user id.
 @return Whether the user is blocked.
 */
- (id)authenticatedUserIsBlocking:(NSString *)user isID:(BOOL)isID;

/**
 Get profile image for a user.
 @param username User.
 @param size FHSTwitterEngineImageSize size.
 @return Profile image.
 */
- (id)getProfileImageForUsername:(NSString *)username andSize:(FHSTwitterEngineImageSize)size;

/**
 Get profile image URL for a user.
 @param username User.
 @param size FHSTwitterEngineImageSize size.
 @return Profile image URL String.
 */
- (id)getProfileImageURLStringForUsername:(NSString *)username andSize:(FHSTwitterEngineImageSize)size;

/**
 Get timeline for a user.
 @param user User.
 @param isID Boolean whether the user is a user id.
 @param count Number of tweets.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (id)getTimelineForUser:(NSString *)user isID:(BOOL)isID count:(int)count;

/**
 Get timeline for a user.
 @param user User.
 @param isID Boolean whether the user is a user id.
 @param count Number of tweets.
 @param sinceID First tweet to retrieve.
 @param maxID Last tweet to retrieve.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (id)getTimelineForUser:(NSString *)user isID:(BOOL)isID count:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;

/**
 Retweet a tweet.
 @param identifier Tweet id.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)retweet:(NSString *)identifier;

/**
 Get tweet details.
 @param identifier Tweet id.
 @return Tweet details.
 */
- (id)getDetailsForTweet:(NSString *)identifier;

/**
 Deleta a tweet.
 @param identifier Tweet id.
 @return Tweet details.
 */
- (NSError *)destroyTweet:(NSString *)identifier;

/**
 Post tweet with an image.
 @param theData Image data.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)postTweet:(NSString *)tweetString withImageData:(NSData *)theData;

/**
 Post tweet reply with an image.
 @param theData Image data.
 @param tweetID Tweet id to reply to.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)postTweet:(NSString *)tweetString withImageData:(NSData *)theData inReplyTo:(NSString *)tweetID;

/**
 Get mentions.
 @param count Number of tweets.
 @return Mentions.
 */
- (id)getMentionsTimelineWithCount:(int)count;

/**
 Get mentions.
 @param count Number of tweets.
 @param sinceID First tweet to retrieve.
 @param maxID Last tweet to retrieve.
 @return Mentions.
 */
- (id)getMentionsTimelineWithCount:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;

/**
 Get tweets of the authenticated user that were retweeted.
 @param count Number of tweets.
 @return List of tweets.
 */
- (id)getRetweetedTimelineWithCount:(int)count;

/**
 Get tweets of the authenticated user that were retweeted.
 @param count Number of tweets.
 @param sinceID First tweet to retrieve.
 @param maxID Last tweet to retrieve.
 @return List of tweets.
 */
- (id)getRetweetedTimelineWithCount:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;

/**
 Get retweets for a tweet.
 @param identifier Tweet id.
 @param count Number of retweets.
 */
- (id)getRetweetsForTweet:(NSString *)identifier count:(int)count;

/**
 Get lists for a user.
 @param user User.
 @param isID Boolean whether the user is a user id.
 @return Lists.
 */
- (id)getListsForUser:(NSString *)user isID:(BOOL)isID;

/**
 Get list timeline.
 @param listID List id.
 @param count Number of tweets.
 @return Tweets.
 */
- (id)getTimelineForListWithID:(NSString *)listID count:(int)count;

/**
 Get list timeline.
 @param listID List id.
 @param count Number of tweets.
 @param sinceID First tweet to retrieve.
 @param maxID Last tweet to retrieve.
 @return Tweets.
 */
- (id)getTimelineForListWithID:(NSString *)listID count:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;

/**
 Get list timeline.
 @param listID List id.
 @param count Number of tweets.
 @param excludeRetweets Boolean whether to exclude retweets.
 @param excludeReplies Boolean whether to exclude replies.
 @return Tweets.
 */
- (id)getTimelineForListWithID:(NSString *)listID count:(int)count excludeRetweets:(BOOL)excludeRetweets excludeReplies:(BOOL)excludeReplies;

/**
 Get list timeline.
 @param listID List id.
 @param count Number of tweets.
 @param sinceID First tweet to retrieve.
 @param maxID Last tweet to retrieve.
 @param excludeRetweets Boolean whether to exclude retweets.
 @param excludeReplies Boolean whether to exclude replies.
 @return Tweets.
 */
- (id)getTimelineForListWithID:(NSString *)listID count:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID excludeRetweets:(BOOL)excludeRetweets excludeReplies:(BOOL)excludeReplies;

/**
 Add users to a list.
 @param listID List id.
 @param users List of users.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)addUsersToListWithID:(NSString *)listID users:(NSArray *)users;

/**
 Remove users from a list.
 @param listID List id.
 @param users List of users.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)removeUsersFromListWithID:(NSString *)listID users:(NSArray *)users;

/**
 List users in a list.
 @param listID List id.
 @return Users.
 */
- (id)listUsersInListWithID:(NSString *)listID;

/**
 Update list name.
 @param listID List id.
 @param name List name.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)updateListWithID:(NSString *)listID name:(NSString *)name;

/**
 Update list description.
 @param listID List id.
 @param description List description.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)updateListWithID:(NSString *)listID description:(NSString *)description;

/**
 Set list privacy.
 @param isPrivate Boolean whether the list is private.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)updateListWithID:(NSString *)listID mode:(BOOL)isPrivate;

/**
 Update list settings.
 @param listID List id.
 @param name List name.
 @param description List description.
 @param isPrivate Boolean whether the list is private.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)updateListWithID:(NSString *)listID name:(NSString *)name description:(NSString *)description mode:(BOOL)isPrivate;

/**
 Get list information.
 @param listID List id.
 @return List information.
 */
- (id)getListWithID:(NSString *)listID;

/**
 Create a list
 @param name List name.
 @param isPrivate Boolean whether the list is private.
 @param description List description.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)createListWithName:(NSString *)name isPrivate:(BOOL)isPrivate description:(NSString *)description;

/**
 Seach tweets.
 @param resultType FHSTwitterEngineResultType type.
 @param untilDate Until date.
 @param sinceID First tweet to retrieve.
 @param maxID Last tweet to retrieve.
 @result Search results.
 */
- (id)searchTweetsWithQuery:(NSString *)q count:(int)count resultType:(FHSTwitterEngineResultType)resultType unil:(NSDate *)untilDate sinceID:(NSString *)sinceID maxID:(NSString *)maxID;

/**
 Get followers ids.
 @return List of follower ids.
 */
- (id)getFollowersIDs;

/**
 Get followers for a user.
 @param user User.
 @param isID Boolean whether the user is a user id.
 @param cursor Cursor.
 @return Users.
 */
- (id)listFollowersForUser:(NSString *)user isID:(BOOL)isID withCursor:(NSString *)cursor;

/**
 Get list of users the authenticated user is following.
 @return Users.
 */
- (id)getFriendsIDs;

/**
 Get list of users a given user is following.
 @param user User.
 @param isID Boolean whether the user is a user id.
 @param cursor Cursor.
 @return Users.
 */
- (id)listFriendsForUser:(NSString *)user isID:(BOOL)isID withCursor:(NSString *)cursor;

/**
 Upload an image to TwitPic.
 @param imageData Image data.
 @param message Message.
 @param twitPicAPIKey TwitPic API key.
 @return Upload image.
 */
- (id)uploadImageToTwitPic:(NSData *)imageData withMessage:(NSString *)message twitPicAPIKey:(NSString *)twitPicAPIKey;

#pragma mark - Streaming

/// @name Streaming

/**
 Stream user messages.
 @param with List of users to stream.
 @param replies Boolean whether to include replies.
 @param keywords Keywords.
 @param locBox Location
 @param block Stream block.
 */
- (void)streamUserMessagesWith:(NSArray *)with replies:(BOOL)replies keywords:(NSArray *)keywords locationBox:(NSArray *)locBox block:(StreamBlock)block;

/**
 Stream public tweets.
 @param users Users
 @param keywords Keywords.
 @param locBox Location
 @param block Stream block.
 */
- (void)streamPublicStatusesForUsers:(NSArray *)users keywords:(NSArray *)keywords locationBox:(NSArray *)locBox block:(StreamBlock)block;

/**
 Stream sample tweets.
 @param block Stream block.
 */
- (void)streamSampleStatusesWithBlock:(StreamBlock)block;

/**
 Stream firehose.
 @param block Stream block.
 */
- (void)streamFirehoseWithBlock:(StreamBlock)block;

/**
 Stream request generator
 @param url Stream URL.
 @param method HTTP method.
 @param params Parameters.
 @return Stream request.
 */
- (id)streamingRequestForURL:(NSURL *)url HTTPMethod:(NSString *)method parameters:(NSDictionary *)params;

#pragma mark - XAuth

/// @name XAuth

/**
 Get XAuth access token.
 @param username Username.
 @param password Password.
 @return If an error occurs, returns an NSError object that describes the problem.
 */
- (NSError *)getXAuthAccessTokenForUsername:(NSString *)username password:(NSString *)password;

#pragma mark - OAuth

/// @name OAuth

/**
 Login view controller.
 @return Instance of login view controller.
 */
- (UIViewController *)loginController;

/**
 Login view controller.
 @param block Completion block.
 @return Instance of login view controller.
 */
- (UIViewController *)loginControllerWithCompletionHandler:(void(^)(BOOL success))block;

#pragma mark - Access Token

/// @name Access Token

/**
 Clear access token.
 */
- (void)clearAccessToken;

/**
 Load access token.
 */
- (void)loadAccessToken;

/**
 Boolean that specifies whether the user is authenticated.
 @return Whether the user is authenticated.
 */
- (BOOL)isAuthorized;

#pragma mark - API Key

/// @name API Key

/**
 Clear consumer.
 */
- (void)clearConsumer;

/**
 Temporarily set consumer key and secret (used for one request).
 @param consumerKey Consumer key.
 @param consumerSecret Consumer secret.
 */
- (void)temporarilySetConsumerKey:(NSString *)consumerKey andSecret:(NSString *)consumerSecret;


/**
 Permanently set consumer key and secret (used indefinitely).
 @param consumerKey Consumer key.
 @param consumerSecret Consumer secret.
 */
- (void)permanentlySetConsumerKey:(NSString *)consumerKey andSecret:(NSString *)consumerSecret;

/**
 Generate request strings.
 id/username concatenator - returns an array of concatenated id/username lists
 100 ids/usernames per concatenated string
 @param array List.
 @return Request strings.
 */
- (NSArray *)generateRequestStringsFromArray:(NSArray *)array;

/**
 Shared instance of FHSTwitterEngine.
 @warning Never call -[FHSTwitterEngine init] directly.
 */
+ (FHSTwitterEngine *)sharedEngine;

/**
 Check network connection.
 @return Whether there is a network connection.
 */
+ (BOOL)isConnectedToInternet;

/**
 Boolean whether to include entities.
 */
@property (nonatomic, assign) BOOL includeEntities;

/**
 Username for authenticated user.
 */
@property (nonatomic, strong) NSString *authenticatedUsername;


/**
 User id for authenticated user.
 */
@property (nonatomic, strong) NSString *authenticatedID;

/**
 Access token.
 */
@property (nonatomic, strong) FHSToken *accessToken;

/**
 Date formatter.
 */
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

// Delegate, called to retrieve or save access tokens
@property (nonatomic, weak) id<FHSTwitterEngineAccessTokenDelegate> delegate;

@end

/** FHSTwitterEngine data interface. */
@interface NSData (FHSTwitterEngine)

/**
 Image file extension.
 @return Image file extension.
 */
- (NSString *)appropriateFileExtension;

/**
 Base 64 encoded string.
 @return Base 64 encoded string.
 */
- (NSString *)base64Encode;
@end

/** FHSTwitterEngine String interface. */
@interface NSString (FHSTwitterEngine)

/**
 URL encoded String.
 @return URL encoded String.
 */
- (NSString *)fhs_URLEncode;

/**
 Truncate String.
 @param length Length to truncate to.
 @return Truncated String.
 */
- (NSString *)fhs_truncatedToLength:(int)length;

/**
 Truncate String for Tweet.
 @return Truncated String for Tweet.
 */
- (NSString *)fhs_trimForTwitter;

/**
 Truncate String with range.
 @return Truncated String with range.
 */
- (NSString *)fhs_stringWithRange:(NSRange)range;

/**
 UUID.
 @return UUID.
 */
+ (NSString *)fhs_UUID;

/**
 String is numeric.
 @return Whether a string is numeric.
 */
- (BOOL)fhs_isNumeric;

@end

/** FHSTwitterEngine errors. */
@interface NSError (FHSTwitterEngine)

/**
 Bad request error.
 */
+ (NSError *)badRequestError;

/**
 No data error.
 */
+ (NSError *)noDataError;

/**
 Image is too large error.
 */
+ (NSError *)imageTooLargeError;

@end

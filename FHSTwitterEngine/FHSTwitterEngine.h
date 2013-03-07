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
//
// //// Version 1.3.1 ////
// FHSTwitterEngine //OAuthConsumer// Version 1.2
//
//


//
// FHSTwitterEngine
// The synchronous Twitter engine that doesn’t suck!!
//

// FHSTwitterEngine is Synchronous
// That means you will have to thread. Boo Hoo.

// Setup
// Just add the FHSTwitterEngine folder to you project.

// USAGE
// See README.markdown

//
// NOTE TO CONTRIBUTORS
// Use NSJSONSerialization with removeNull(). Life is easy that way.
//


#import <Foundation/Foundation.h>

// These are for the dispatch_async() calls that you use to get around the synchronous-ness
#define GCDBackgroundThread dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#define GCDMainThread dispatch_get_main_queue()

// oEmbed align modes
typedef enum {
    FHSTwitterEngineAlignModeLeft,
    FHSTwitterEngineAlignModeRight,
    FHSTwitterEngineAlignModeCenter,
    FHSTwitterEngineAlignModeNone
} FHSTwitterEngineAlignMode;

// Image sizes
typedef enum {
    FHSTwitterEngineImageSizeMini, // 24px by 24px
    FHSTwitterEngineImageSizeNormal, // 48x48
    FHSTwitterEngineImageSizeBigger, // 73x73
    FHSTwitterEngineImageSizeOriginal // original size of image
} FHSTwitterEngineImageSize;

typedef enum {
    FHSTwitterEngineResultTypeMixed,
    FHSTwitterEngineResultTypeRecent,
    FHSTwitterEngineResultTypePopular
} FHSTwitterEngineResultType;

// Remove NSNulls from NSDictionary and NSArray
// Credit for this function goes to Conrad Kramer
id removeNull(id rootObject);

@protocol FHSTwitterEngineAccessTokenDelegate <NSObject>

- (void)storeAccessToken:(NSString *)accessToken;
- (NSString *)loadAccessToken;

@end

@class OAToken;
@class OAConsumer;
@class OAMutableURLRequest;

@interface FHSTwitterEngine : NSObject <UIWebViewDelegate>

//
// REST API
//

//
// Custom REST API methods
// (The second method is called once for every 99 id's) - can be expensive CACHE CACHE CACHE
//

- (NSArray *)getFollowers; // followers/ids & users/lookup
- (NSArray *)getFriends; // friends/ids & users/lookup

//
// Standard REST API methods
//

// statuses/update
- (NSError *)postTweet:(NSString *)tweetString inReplyTo:(NSString *)inReplyToString;
- (NSError *)postTweet:(NSString *)tweetString;

// statuses/home_timeline
- (id)getHomeTimelineSinceID:(NSString *)sinceID count:(int)count;

// help/test
- (BOOL)testService;

// blocks/create
- (NSError *)block:(NSString *)username;

// blocks/destroy
- (NSError *)unblock:(NSString *)username;

// users/lookup
- (id)getUserInformationForUsers:(NSArray *)users areUsers:(BOOL)flag;

// users/search
- (id)searchUsersWithQuery:(NSString *)q andCount:(int)count;

// notifications/follow & notifications/leave
- (NSError *)disableNotificationsForID:(NSString *)identifier;
- (NSError *)disableNotificationsForUsername:(NSString *)username;
- (NSError *)enableNotificationsForID:(NSString *)identifier;
- (NSError *)enableNotificationsForUsername:(NSString *)identifier;

// account/totals
- (id)getTotals;

// account/update_profile_image
- (NSError *)setProfileImageWithImageAtPath:(NSString *)file;

// account/settings POST & GET
// See FHSTwitterEngine.m For details
- (NSError *)updateSettingsWithDictionary:(NSDictionary *)settings;
- (id)getUserSettings;

// account/update_profile
// See FHSTwitterEngine.m for details
- (NSError *)updateUserProfileWithDictionary:(NSDictionary *)settings;

// account/update_profile_background_image
- (NSError *)setProfileBackgroundImageWithImageAtPath:(NSString *)file tiled:(BOOL)flag;
- (NSError *)setUseProfileBackgroundImage:(BOOL)shouldUseProfileBackgroundImage;

// account/update_profile_colors
// See FHSTwitterEngine.m for details
// If the dictionary is nil, FHSTwitterEngine resets the values
- (NSError *)updateProfileColorsWithDictionary:(NSDictionary *)dictionary;

// account/rate_limit_status
- (id)getRateLimitStatus;

// favorites/create, favorites/destroy
- (NSError *)markTweet:(NSString *)tweetID asFavorite:(BOOL)flag;

// favorites
- (id)getFavoritesForUser:(NSString *)user isID:(BOOL)isID andCount:(int)count;

// account/verify_credentials
- (id)verifyCredentials;

// friendships/exists
- (id)user:(NSString *)user followsUser:(NSString *)userTwo areUsernames:(BOOL)areUsernames;

// friendships/create
- (NSError *)followUser:(NSString *)user isID:(BOOL)isID;

// friendships/destroy
- (NSError *)unfollowUser:(NSString *)user isID:(BOOL)isID;

// friendships/lookup
- (id)lookupFriends:(NSArray *)users areIDs:(BOOL)areIDs;

// friendships/incoming
- (id)getPendingIncomingFollowers;

// friendships/outgoing
- (id)getPendingOutgoingFollowers;

// friendships/update
- (NSError *)enableRetweets:(BOOL)enableRTs andDeviceNotifs:(BOOL)devNotifs forUser:(NSString *)user isID:(BOOL)isID;

// friendships/no_retweet_ids
- (id)getNoRetweetIDs;

// legal/tos
- (id)getTermsOfService;

// legal/privacy
- (id)getPrivacyPolicy;

// direct_messages
- (id)getDirectMessages:(int)count;

// direct_messages/destroy
- (NSError *)deleteDirectMessage:(NSString *)messageID;

// direct_messages/sent
- (id)getSentDirectMessages:(int)count;

// direct_messages/new
- (NSError *)sendDirectMessage:(NSString *)body toUser:(NSString *)user isID:(BOOL)isID;

// direct_messages/show
- (id)showDirectMessage:(NSString *)messageID;

// report_spam
- (NSError *)reportUserAsSpam:(NSString *)user isID:(BOOL)isID;

// help/configuration
- (id)getConfiguration;

// help/languages
- (id)getLanguages;

// blocks/blocking/ids
- (id)listBlockedIDs;

// blocks/blocking
- (id)listBlockedUsers;

// blocks/exists
- (id)authenticatedUserIsBlocking:(NSString *)user isID:(BOOL)isID;

// users/profile_image
- (id)getProfileImageForUsername:(NSString *)username andSize:(FHSTwitterEngineImageSize)size;

// trends/daily
- (id)getDailyTrends;

// trends/weekly
- (id)getWeeklyTrends;

// statuses/user_timeline
- (id)getTimelineForUser:(NSString *)user isID:(BOOL)isID count:(int)count;
- (id)getTimelineForUser:(NSString *)user isID:(BOOL)isID count:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;

// statuses/retweet
- (NSError *)retweet:(NSString *)identifier;

// statuses/oembed
- (id)oembedTweet:(NSString *)identifier maxWidth:(float)maxWidth alignmentMode:(FHSTwitterEngineAlignMode)alignmentMode;

// statuses/show
- (id)getDetailsForTweet:(NSString *)identifier;

// statuses/destory
- (NSError *)destoryTweet:(NSString *)identifier;

// statuses/update_with_media
- (NSError *)postTweet:(NSString *)tweetString withImageData:(NSData *)theData;
- (NSError *)postTweet:(NSString *)tweetString withImageData:(NSData *)theData inReplyTo:(NSString *)irt;

// statuses/mentions_timeline
- (id)getMentionsTimelineWithCount:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;
- (id)getMentionsTimelineWithCount:(int)count;

// statuses/retweets_of_me
- (id)getRetweetedTimelineWithCount:(int)count;
- (id)getRetweetedTimelineWithCount:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;

// statuses/retweets
- (id)getRetweetsForTweet:(NSString *)identifier count:(int)count;

// lists/list
- (id)getListsForUser:(NSString *)user isID:(BOOL)isID;

// lists/statuses
- (id)getTimelineForListWithID:(NSString *)listID count:(int)count sinceID:(NSString *)sinceID maxID:(NSString *)maxID;
- (id)getTimelineForListWithID:(NSString *)listID count:(int)count;

// lists/members/create_all
- (NSError *)addUsersToListWithID:(NSString *)listID users:(NSArray *)users;

// lists/members/destroy_all
- (NSError *)removeUsersFromListWithID:(NSString *)listID users:(NSArray *)users;

// lists/members
- (id)listUsersInListWithID:(NSString *)listID;

// lists/memberships
- (id)getListsThatUserIsMemberOf:(NSString *)user;

// lists/update
- (NSError *)setModeOfListWithID:(NSString *)listID toPrivate:(BOOL)isPrivate;
- (NSError *)changeNameOfListWithID:(NSString *)listID toName:(NSString *)newName;
- (NSError *)changeDescriptionOfListWithID:(NSString *)listID toDescription:(NSString *)newName;

// lists/show
- (id)getListWithID:(NSString *)listID;

// lists/create
- (NSError *)createListWithName:(NSString *)name isPrivate:(BOOL)isPrivate description:(NSString *)description;

// search
- (id)searchTweetsWithQuery:(NSString *)q count:(int)count resultType:(FHSTwitterEngineResultType)resultType unil:(NSDate *)untilDate sinceID:(NSString *)sinceID maxID:(NSString *)maxID;

//
// Login and Auth
//

// XAuth login
- (NSError *)getXAuthAccessTokenForUsername:(NSString *)username password:(NSString *)password;

// OAuth login
- (UIViewController *)OAuthLoginWindow; // You want to use it with something other than presentModalViewController:animated:
- (void)showOAuthLoginControllerFromViewController:(UIViewController *)sender; // just one less line of code

// Access Token Mangement
- (void)clearAccessToken;
- (void)loadAccessToken;
- (BOOL)isAuthorized;

// sendRequest methods, use these for every request
- (NSError *)sendPOSTRequest:(OAMutableURLRequest *)request withParameters:(NSArray *)params;
- (id)sendGETRequest:(OAMutableURLRequest *)request withParameters:(NSArray *)params;

//
// Misc Methods
//

// Date parser
- (NSDate *)getDateFromTwitterCreatedAt:(NSString *)twitterDate;

// init method
- (id)initWithConsumerKey:(NSString *)consumerKey andSecret:(NSString *)consumerSecret;

// Determines your internet status
+ (BOOL)isConnectedToInternet;

// Determines if entities should be included
@property (nonatomic, assign) BOOL includeEntities;

// Logged in user's username
@property (nonatomic, strong) NSString *loggedInUsername;

// Logged in user's Twitter ID
@property (nonatomic, strong) NSString *loggedInID;

// Will be called to store the accesstoken
@property (nonatomic, strong) id<FHSTwitterEngineAccessTokenDelegate> delegate;

// Access Token
@property (nonatomic, strong) OAToken *accessToken;

@end

@interface NSData (Base64)
+ (NSData *)dataWithBase64EncodedString:(NSString *)string;
- (id)initWithBase64EncodedString:(NSString *)string;
- (NSString *)base64EncodingWithLineLength:(unsigned int)lineLength;
@end

@interface NSString (FHSTwitterEngine)
- (NSString *)trimForTwitter;
- (BOOL)isNumeric;
@end

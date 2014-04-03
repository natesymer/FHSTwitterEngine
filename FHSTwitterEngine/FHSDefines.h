//
//  FHSDefines.h
//  FHSTwitterEngine
//
//  Created by Nathaniel Symer on 3/10/14.
//  Copyright (c) 2014 Nathaniel Symer. All rights reserved.
//

/**
 Constant definitions.
 */

// Image sizes
typedef NS_ENUM(NSInteger, FHSTwitterEngineImageSize) {
    FHSTwitterEngineImageSizeMini, // 24px by 24px
    FHSTwitterEngineImageSizeNormal, // 48x48
    FHSTwitterEngineImageSizeBigger, // 73x73
    FHSTwitterEngineImageSizeOriginal // original size of image
};

typedef NS_ENUM(NSInteger, FHSTwitterEngineResultType) {
    FHSTwitterEngineResultTypeMixed,
    FHSTwitterEngineResultTypeRecent,
    FHSTwitterEngineResultTypePopular
};

typedef void(^StreamBlock)(id result, BOOL *stop);
typedef NSString *(^LoadAccessTokenBlock)(void);
typedef void(^StoreAccessTokenBlock)(NSString *accessToken);

static NSURLRequestCachePolicy const cachePolicy = NSURLRequestReloadRevalidatingCacheData;

static float const streamingTimeoutInterval = 30.0f;

static NSString * const FHSProfileBackgroundColorKey = @"profile_background_color";
static NSString * const FHSProfileLinkColorKey = @"profile_link_color";
static NSString * const FHSProfileSidebarBorderColorKey = @"profile_sidebar_border_color";
static NSString * const FHSProfileSidebarFillColorKey = @"profile_sidebar_fill_color";
static NSString * const FHSProfileTextColorKey = @"profile_text_color";

static NSString * const FHSProfileNameKey = @"name";
static NSString * const FHSProfileURLKey = @"url";
static NSString * const FHSProfileLocationKey = @"location";
static NSString * const FHSProfileDescriptionKey = @"description";


//
// URL constants
//

static NSString * const url_oauth_access_token = @"https://api.twitter.com/oauth/access_token";
static NSString * const url_oauth_request_token = @"https://api.twitter.com/oauth/request_token";

static NSString * const url_search_tweets = @"https://api.twitter.com/1.1/search/tweets.json";

static NSString * const url_users_search = @"https://api.twitter.com/1.1/users/search.json";
static NSString * const url_users_show = @"https://api.twitter.com/1.1/users/show.json";
static NSString * const url_users_report_spam = @"https://api.twitter.com/1.1/users/report_spam.json";
static NSString * const url_users_lookup = @"https://api.twitter.com/1.1/users/lookup.json";

static NSString * const url_lists_create = @"https://api.twitter.com/1.1/lists/create.json";
static NSString * const url_lists_show = @"https://api.twitter.com/1.1/lists/show.json";
static NSString * const url_lists_update = @"https://api.twitter.com/1.1/lists/update.json";
static NSString * const url_lists_members = @"https://api.twitter.com/1.1/lists/members.json";
static NSString * const url_lists_members_destroy_all = @"https://api.twitter.com/1.1/lists/members/destroy_all.json";
static NSString * const url_lists_members_create_all = @"https://api.twitter.com/1.1/lists/members/create_all.json";
static NSString * const url_lists_statuses = @"https://api.twitter.com/1.1/lists/statuses.json";
static NSString * const url_lists_list = @"https://api.twitter.com/1.1/lists/list.json";

static NSString * const url_statuses_home_timeline = @"https://api.twitter.com/1.1/statuses/home_timeline.json";
static NSString * const url_statuses_update = @"https://api.twitter.com/1.1/statuses/update.json";
static NSString * const url_statuses_retweets_of_me = @"https://api.twitter.com/1.1/statuses/retweets_of_me.json";
static NSString * const url_statuses_user_timeline = @"https://api.twitter.com/1.1/statuses/user_timeline.json";
static NSString * const url_statuses_metions_timeline = @"https://api.twitter.com/1.1/statuses/mentions_timeline.json";
static NSString * const url_statuses_update_with_media = @"https://api.twitter.com/1.1/statuses/update_with_media.json";
static NSString * const url_statuses_destroy = @"https://api.twitter.com/1.1/statuses/destroy.json";
static NSString * const url_statuses_show = @"https://api.twitter.com/1.1/statuses/show.json";

static NSString * const url_blocks_exists = @"https://api.twitter.com/1.1/blocks/exists.json";
static NSString * const url_blocks_blocking = @"https://api.twitter.com/1.1/blocks/blocking.json";
static NSString * const url_blocks_blocking_ids = @"https://api.twitter.com/1.1/blocks/blocking/ids.json";
static NSString * const url_blocks_destroy = @"https://api.twitter.com/1.1/blocks/destroy.json";
static NSString * const url_blocks_create = @"https://api.twitter.com/1.1/blocks/create.json";

static NSString * const url_help_languages = @"https://api.twitter.com/1.1/help/languages.json";
static NSString * const url_help_configuration = @"https://api.twitter.com/1.1/help/configuration.json";
static NSString * const url_help_privacy = @"https://api.twitter.com/1.1/help/privacy.json";
static NSString * const url_help_tos = @"https://api.twitter.com/1.1/help/tos.json";
static NSString * const url_help_test = @"https://api.twitter.com/1.1/help/test.json";

static NSString * const url_direct_messages_show = @"https://api.twitter.com/1.1/direct_messages/show.json";
static NSString * const url_direct_messages_new = @"https://api.twitter.com/1.1/direct_messages/new.json";
static NSString * const url_direct_messages_sent = @"https://api.twitter.com/1.1/direct_messages/sent.json";
static NSString * const url_direct_messages_destroy = @"https://api.twitter.com/1.1/direct_messages/destroy.json";
static NSString * const url_direct_messages = @"https://api.twitter.com/1.1/direct_messages.json";

static NSString * const url_friendships_no_retweets_ids = @"https://api.twitter.com/1.1/friendships/no_retweets/ids.json";
static NSString * const url_friendships_update = @"https://api.twitter.com/1.1/friendships/update.json";
static NSString * const url_friendships_outgoing = @"https://api.twitter.com/1.1/friendships/outgoing.json";
static NSString * const url_friendships_incoming = @"https://api.twitter.com/1.1/friendships/incoming.json";
static NSString * const url_friendships_lookup = @"https://api.twitter.com/1.1/friendships/lookup.json";
static NSString * const url_friendships_destroy = @"https://api.twitter.com/1.1/friendships/destroy.json";
static NSString * const url_friendships_create = @"https://api.twitter.com/1.1/friendships/create.json";

static NSString * const url_account_verify_credentials = @"https://api.twitter.com/1.1/account/verify_credentials.json";
static NSString * const url_account_update_profile_colors = @"https://api.twitter.com/1.1/account/update_profile_colors.json";
static NSString * const url_account_update_profile_background_image = @"https://api.twitter.com/1.1/account/update_profile_background_image.json";
static NSString * const url_account_update_profile_image = @"https://api.twitter.com/1.1/account/update_profile_image.json";
static NSString * const url_account_settings = @"https://api.twitter.com/1.1/account/settings.json";
static NSString * const url_account_update_profile = @"https://api.twitter.com/1.1/account/update_profile.json";

static NSString * const url_favorites_list = @"https://api.twitter.com/1.1/favorites/list.json";
static NSString * const url_favorites_create = @"https://api.twitter.com/1.1/favorites/create.json";
static NSString * const url_favorites_destroy = @"https://api.twitter.com/1.1/favorites/destroy.json";

static NSString * const url_application_rate_limit_status = @"https://api.twitter.com/1.1/application/rate_limit_status.json";

static NSString * const url_followers_ids = @"https://api.twitter.com/1.1/followers/ids.json";
static NSString * const url_followers_list = @"https://api.twitter.com/1.1/followers/list.json";

static NSString * const url_friends_ids = @"https://api.twitter.com/1.1/friends/ids.json";
static NSString * const url_friends_list = @"https://api.twitter.com/1.1/friends/list.json";

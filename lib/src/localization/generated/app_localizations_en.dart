// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Wreadom';

  @override
  String get login => 'Login';

  @override
  String get home => 'Home';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get hindi => 'Hindi';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get profile => 'Profile';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get logout => 'Logout';

  @override
  String get help => 'Help';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get submitError => 'Report an issue';

  @override
  String get followers => 'Followers';

  @override
  String get following => 'Following';

  @override
  String get works => 'Works';

  @override
  String get about => 'About';

  @override
  String get posts => 'Posts';

  @override
  String get history => 'Read Content';

  @override
  String get saved => 'Saved';

  @override
  String get downloaded => 'Downloaded';

  @override
  String get profileSettings => 'Profile Settings';

  @override
  String get displayName => 'Display Name';

  @override
  String get penName => 'Pen Name';

  @override
  String get bio => 'Bio';

  @override
  String get privacy => 'Privacy';

  @override
  String get public => 'Public';

  @override
  String get followersOnly => 'Followers Only';

  @override
  String get private => 'Private';

  @override
  String get saveSettings => 'Save Settings';

  @override
  String get pleaseSignIn => 'Please Sign In';

  @override
  String get welcomeBack => 'Welcome Back!';

  @override
  String get createAccount => 'Create Account';

  @override
  String get signInToContinue => 'Sign in to continue reading';

  @override
  String get joinCommunity => 'Join our community of readers';

  @override
  String get username => 'Username';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get password => 'Password';

  @override
  String get requiredField => 'Required';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get minChars => 'Min 6 chars';

  @override
  String get loginBtn => 'LOGIN';

  @override
  String get signupBtn => 'SIGN UP';

  @override
  String get orDivider => 'OR';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get enterEmailFirst => 'Enter your email first';

  @override
  String get passwordResetSent => 'Password reset email sent';

  @override
  String get dontHaveAccount => 'Don\'t have an account? ';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get signUpLink => 'Sign Up';

  @override
  String get loginLink => 'Login';

  @override
  String get feed => 'Feed';

  @override
  String get notifications => 'Notifications';

  @override
  String get searchBooks => 'Search content';

  @override
  String get mine => 'Mine';

  @override
  String get noFollowingPosts => 'No posts from people you follow yet';

  @override
  String get noPosts => 'No posts yet';

  @override
  String get beFirstToPost => 'Be the first to post something!';

  @override
  String get createAPost => 'Create a Post';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get post => 'Post';

  @override
  String get discover => 'Discover';

  @override
  String get searchBooksAuthors => 'Search content and authors';

  @override
  String get searchHint => 'Search content, authors...';

  @override
  String get suggestedBooks => 'Suggested Content';

  @override
  String get noSuggestedBooks => 'No suggested content found.';

  @override
  String noBooksFoundIn(String genre) {
    return 'No content found in $genre.';
  }

  @override
  String noResultsFor(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get originalBooks => 'Original Content';

  @override
  String get moreBooks => 'More Content';

  @override
  String get profiles => 'Profiles';

  @override
  String get unknownAuthor => 'Unknown Author';

  @override
  String get internetArchive => 'Internet Archive';

  @override
  String get bookNotFound => 'Content not found';

  @override
  String get editBook => 'Edit content';

  @override
  String get reportBook => 'Report content';

  @override
  String shareBookMessage(String title, String link) {
    return 'Read \"$title\" on Wreadom: $link';
  }

  @override
  String readsStat(String count) {
    return '$count reads';
  }

  @override
  String chaptersStat(String count) {
    return '$count chapters';
  }

  @override
  String get continueReading => 'Continue Reading';

  @override
  String get startReading => 'Start Reading';

  @override
  String get aboutThisBook => 'About this content';

  @override
  String defaultShareMessage(String title) {
    return 'I\'m reading \"$title\" on Wreadom. Check it out.';
  }

  @override
  String get shareToFeed => 'Share to feed';

  @override
  String get signInToShare => 'Sign in to share this content.';

  @override
  String get sendToChat => 'Send to chat';

  @override
  String get noRecentConversations => 'No recent conversations yet.';

  @override
  String get conversation => 'Conversation';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get sentYouABook => 'sent you content.';

  @override
  String sentBookSnack(String title) {
    return 'Sent \"$title\".';
  }

  @override
  String get sharedToFeed => 'Shared to feed.';

  @override
  String get latestDiscussion => 'Latest discussion';

  @override
  String get showMore => 'Show more';

  @override
  String failedToLoadChats(String error) {
    return 'Failed to load chats: $error';
  }

  @override
  String get fetchingPublicDomain => 'Fetching public-domain text...';

  @override
  String get chaptersTitle => 'Chapters';

  @override
  String get viewChapterComments => 'View chapter comments';

  @override
  String get nextChapter => 'Next Chapter';

  @override
  String get shareChapter => 'Share Chapter';

  @override
  String get closeReader => 'Close Reader';

  @override
  String get internetArchivePreparation =>
      'Internet Archive content can take a moment to prepare.';

  @override
  String get viewPdf => 'View PDF';

  @override
  String get upvote => 'Upvote';

  @override
  String get downvote => 'Downvote';

  @override
  String get offline => 'Offline';

  @override
  String get readAloud => 'Read aloud';

  @override
  String get stop => 'Stop';

  @override
  String get stopReadingAloud => 'Stop reading aloud';

  @override
  String get readerSettings => 'Reader Settings';

  @override
  String get shareQuote => 'Share Quote';

  @override
  String get quoteAndComment => 'Quote & Comment';

  @override
  String get genreFantasy => 'Fantasy';

  @override
  String get genreRomance => 'Romance';

  @override
  String get genreSciFi => 'Science Fiction';

  @override
  String get genreMystery => 'Mystery';

  @override
  String get genreHorror => 'Horror';

  @override
  String get genreHistorical => 'Historical';

  @override
  String get genreAdventure => 'Adventure';

  @override
  String get genrePoetry => 'Poetry';

  @override
  String get genreClassic => 'Classic';

  @override
  String get genreSocial => 'Social';

  @override
  String get genreHistory => 'History';

  @override
  String get genreStories => 'Stories';

  @override
  String get genreCompetition => 'Wreadom Competition #1';

  @override
  String get genreOther => 'Other';

  @override
  String get genreBiography => 'Biography';

  @override
  String get genrePhilosophy => 'Philosophy';

  @override
  String get writer => 'Writer';

  @override
  String get messages => 'Messages';

  @override
  String get shelfCommunityClassics => 'Community Classics';

  @override
  String get shelfOriginals => 'Wreadom Originals';

  @override
  String get shelfTrending => 'Trending Works';

  @override
  String get shelfPopular => 'Popular Now';

  @override
  String get shelfRecentlyAdded => 'Recently Added';

  @override
  String get keepReading => 'Keep Reading';

  @override
  String get heroBannerSubtitle =>
      'Thousands of free content and original stories, curated for you.';

  @override
  String get exploreNow => 'Explore Now';

  @override
  String get dailyTopic => 'Daily Topic';

  @override
  String get readMore => 'Read More';

  @override
  String get yourShelf => 'Your Shelf';

  @override
  String percentComplete(int percent) {
    return '$percent% complete';
  }

  @override
  String get readyToResume => 'Ready to resume';

  @override
  String chapterNumber(int number) {
    return 'Chapter $number';
  }

  @override
  String errorWithDetails(String message) {
    return 'Error: $message';
  }

  @override
  String get seeAll => 'See All';

  @override
  String get authorsToFollow => 'Authors to Follow';

  @override
  String get topRatedAuthors => 'Top Rated Authors';

  @override
  String get mostReadAuthors => 'Most Read Authors';

  @override
  String get mostPublishedAuthors => 'Most Published Authors';

  @override
  String get featuredWreadomAuthor => 'Featured Wreadom author.';

  @override
  String get authorSpotlight => 'Author Spotlight';

  @override
  String authorBooks(String author) {
    return '$author\'s content';
  }

  @override
  String couldNotLoad(String title) {
    return 'Could not load $title.';
  }

  @override
  String bookByAuthor(String title, String author) {
    return '$title by $author';
  }

  @override
  String failedToLoadWithError(String error) {
    return 'Failed to load: $error';
  }

  @override
  String get writeSomethingFirst => 'Please write something first';

  @override
  String get loginToPost => 'Please log in to post';

  @override
  String get postShared => 'Post shared';

  @override
  String get shareAnUpdate => 'Share an update';

  @override
  String get close => 'Close';

  @override
  String get postBtn => 'Post';

  @override
  String get postHint => 'What are you reading, thinking, or building?';

  @override
  String get removeImage => 'Remove image';

  @override
  String get addImage => 'Add image';

  @override
  String get likedYourPost => 'liked your post.';

  @override
  String get deletePostTitle => 'Delete post?';

  @override
  String get deletePostContent => 'This will remove the post and its comments.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get postDeleted => 'Post deleted';

  @override
  String couldNotDeletePost(String error) {
    return 'Could not delete post: $error';
  }

  @override
  String get editPost => 'Edit post';

  @override
  String get updateYourPost => 'Update your post';

  @override
  String get replaceImage => 'Replace image';

  @override
  String get save => 'Save';

  @override
  String get reportPost => 'Report Post';

  @override
  String get regarding => 'Regarding';

  @override
  String get unlikePost => 'Unlike post';

  @override
  String get likePost => 'Like post';

  @override
  String get showComments => 'Show comments';

  @override
  String get sharePost => 'Share post';

  @override
  String checkOutPostOnWreadom(String link) {
    return 'Check out this post on Wreadom: $link';
  }

  @override
  String get wreadomPost => 'Wreadom Post';

  @override
  String get repliedToYourComment => 'replied to your comment.';

  @override
  String get commentedOnYourPost => 'commented on your post.';

  @override
  String errorSubmittingComment(String error) {
    return 'Error submitting comment: $error';
  }

  @override
  String commentsCount(int count) {
    return 'Comments ($count)';
  }

  @override
  String get comments => 'Comments';

  @override
  String get commentsLoading => 'Comments...';

  @override
  String get noCommentsYet => 'No comments yet. Be the first!';

  @override
  String errorLoadingComments(String error) {
    return 'Error loading comments: $error';
  }

  @override
  String replyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String get addAReply => 'Add a reply...';

  @override
  String get addAComment => 'Add a comment...';

  @override
  String get editComment => 'Edit comment';

  @override
  String get editReply => 'Edit reply';

  @override
  String editFailed(String error) {
    return 'Edit failed: $error';
  }

  @override
  String get deleteCommentTitle => 'Delete Comment?';

  @override
  String get deleteReplyTitle => 'Delete Reply?';

  @override
  String get deleteActionUndone => 'This action cannot be undone.';

  @override
  String deleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get pin => 'Pin';

  @override
  String get unpin => 'Unpin';

  @override
  String get edit => 'Edit';

  @override
  String get report => 'Report';

  @override
  String get reply => 'Reply';

  @override
  String get writeYourUpdate => 'Write your update';

  @override
  String get justNow => 'Just now';

  @override
  String daysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String hoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String minutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String get shareProfile => 'Share profile';

  @override
  String get menu => 'Menu';

  @override
  String readWithUserOnWreadom(String name, String link) {
    return 'Read with $name on Wreadom\n$link';
  }

  @override
  String get noBioYet => 'No bio yet.';

  @override
  String get averageRating => 'Average rating';

  @override
  String get totalReads => 'Total reads';

  @override
  String get booksPublished => 'Books published';

  @override
  String get dateJoined => 'Joined';

  @override
  String get activity => 'Activity';

  @override
  String get loadMore => 'Load more';

  @override
  String get themeDialogTitle => 'Theme';

  @override
  String get errorType => 'Issue type';

  @override
  String get whatWentWrong => 'What went wrong?';

  @override
  String get describeIssueHint => 'Describe the issue and what you were doing.';

  @override
  String get deviceLogsIncluded =>
      'Device info and recent app logs will be included.';

  @override
  String get viewCollectedLogs => 'View collected logs';

  @override
  String get submit => 'Submit';

  @override
  String get collectedLogs => 'Collected logs';

  @override
  String get noAppLogsYet => 'No app logs have been collected yet.';

  @override
  String get pleaseDescribeIssue => 'Please describe the issue.';

  @override
  String get mustBeLoggedInToSubmitIssues =>
      'You must be logged in to submit issues.';

  @override
  String get issueReportSubmitted => 'Issue report submitted.';

  @override
  String failedToSubmitIssueReport(String error) {
    return 'Failed to submit issue report: $error';
  }

  @override
  String get userNotFound => 'User not found';

  @override
  String penNameValue(String name) {
    return 'Pen name: $name';
  }

  @override
  String get privateAccountNotice =>
      'This account is private. Only basic profile info is visible.';

  @override
  String get followToSeeFullProfile =>
      'Follow this account to see their full profile.';

  @override
  String get books => 'Content';

  @override
  String get noPublishedBooksYet => 'No published content yet.';

  @override
  String failedToLoadBooks(String error) {
    return 'Failed to load content: $error';
  }

  @override
  String failedToLoadPosts(String error) {
    return 'Failed to load posts: $error';
  }

  @override
  String get noReadingHistoryYet => 'No reading history yet.';

  @override
  String errorLoadingHistory(String error) {
    return 'Error loading history: $error';
  }

  @override
  String get wreadomCreator => 'WREADOM CREATOR';

  @override
  String get officialLiteraryProfile =>
      'OFFICIAL LITERARY PROFILE - WREADOM.IN';

  @override
  String shareProfileSubject(String name) {
    return '$name on Wreadom';
  }

  @override
  String failedToPostReply(String error) {
    return 'Failed to post reply: $error';
  }

  @override
  String get shareAQuote => 'Share a quote';

  @override
  String get pleaseEnterQuote => 'Please enter a quote';

  @override
  String get quoteShared => 'Quote shared!';

  @override
  String failedToShareQuote(String error) {
    return 'Failed to share quote: $error';
  }

  @override
  String get enterQuoteHint => 'Enter the quote from the content...';

  @override
  String get addThoughtsOptional => 'Add your thoughts (optional)';

  @override
  String get postQuote => 'Post quote';

  @override
  String get pleaseSelectRating => 'Please select a rating';

  @override
  String get pleaseWriteShortReview => 'Please write a short review';

  @override
  String get pleaseLoginToReview => 'Please log in to review';

  @override
  String get reviewShared => 'Review shared!';

  @override
  String reviewTitle(String title) {
    return 'Review: $title';
  }

  @override
  String get reviewHint => 'What did you think of this content?';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get mustBeLoggedInToReportContent =>
      'You must be logged in to report content.';

  @override
  String get reportSubmittedThanks =>
      'Thank you for your report. We will review it shortly.';

  @override
  String failedToSubmitReport(String error) {
    return 'Failed to submit report: $error';
  }

  @override
  String reportTarget(String targetType) {
    return 'Report $targetType';
  }

  @override
  String get whyReportContent => 'Why are you reporting this content?';

  @override
  String get additionalDetailsOptional => 'Additional details (optional)';

  @override
  String get submitReport => 'Submit report';

  @override
  String get reasonSpam => 'Spam';

  @override
  String get reasonOffensiveContent => 'Offensive content';

  @override
  String get reasonInappropriateLanguage => 'Inappropriate language';

  @override
  String get reasonHarassment => 'Harassment';

  @override
  String get reasonSpoiler => 'Spoiler without warning';

  @override
  String get reasonOther => 'Other';

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get deleteChat => 'Delete chat';

  @override
  String get deleteChatTitle => 'Delete chat?';

  @override
  String get noConversationsYet =>
      'No conversations yet. Start from a user profile.';

  @override
  String get postNotFoundOrDeleted => 'Post not found or deleted';

  @override
  String get savedBooksTitle => 'Saved Content';

  @override
  String get noSavedOrDownloadedBooksYet =>
      'No saved or downloaded content yet.';

  @override
  String get dailyTopicNotFound => 'Daily topic not found.';

  @override
  String get participateNow => 'Participate now';

  @override
  String get noSubmissionsYet => 'No submissions received yet.';

  @override
  String get blockUser => 'Block user';

  @override
  String get messageHint => 'Message...';

  @override
  String get blockUserTitle => 'Block user?';

  @override
  String get block => 'Block';

  @override
  String get userBlocked => 'User blocked.';

  @override
  String get noRatings => 'No ratings';

  @override
  String get removeSavedBookTitle => 'Remove saved content?';

  @override
  String get removeSavedBookBody =>
      'The offline download will stay available unless you remove it separately.';

  @override
  String get unsave => 'Unsave';

  @override
  String get bookSaved => 'Content saved.';

  @override
  String get downloadSavedBookTitle => 'Download for offline reading?';

  @override
  String get downloadSavedBookBody =>
      'Keep this content available even when you are offline.';

  @override
  String get notNow => 'Not now';

  @override
  String get download => 'Download';

  @override
  String get keep => 'Keep';

  @override
  String get bookSavedDownloaded =>
      'Content saved and downloaded for offline reading.';

  @override
  String get published => 'Published';

  @override
  String get drafts => 'Drafts';

  @override
  String get reads => 'Reads';

  @override
  String get deleteDraftTitle => 'Delete draft?';

  @override
  String get deleteDraftBody =>
      'This draft will be removed from your dashboard.';

  @override
  String get draftDeleted => 'Draft deleted.';

  @override
  String get deleteConversationBody =>
      'This removes the conversation from your messages.';

  @override
  String failedToLoadSavedBooks(String error) {
    return 'Failed to load saved content: $error';
  }

  @override
  String failedToLoadPost(String error) {
    return 'Failed to load post: $error';
  }

  @override
  String failedToLoadComments(String error) {
    return 'Failed to load comments: $error';
  }

  @override
  String noFollowersYet(String title) {
    return 'No $title yet.';
  }

  @override
  String failedToLoadTitle(String title, String error) {
    return 'Failed to load $title: $error';
  }

  @override
  String get all => 'All';

  @override
  String get noNotificationsYet => 'No notifications yet';

  @override
  String get noMessageNotificationsYet => 'No message notifications yet';

  @override
  String get noPostNotificationsYet => 'No post notifications yet';

  @override
  String get noBookNotificationsYet => 'No content notifications yet';

  @override
  String get notificationContentFilter => 'Content';

  @override
  String get showLess => 'Show less';

  @override
  String saveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get writerDashboard => 'Writer Dashboard';

  @override
  String get createContent => 'Create Content';

  @override
  String get noPublishedStoriesYet => 'No published stories yet';

  @override
  String get noDraftsYet => 'No drafts yet';

  @override
  String get draft => 'Draft';

  @override
  String get lastUpdate => 'Last update';

  @override
  String get editStory => 'Edit story';

  @override
  String get collaboration => 'Collaboration';

  @override
  String get collab => 'Collab';

  @override
  String get collabAcceptedDescription =>
      'Accepted collaboration. Both authors can edit this content.';

  @override
  String get collabPendingDescription =>
      'Request pending. The co-author can preview and respond.';

  @override
  String get collabInviteDescription =>
      'Invite one followed author to co-write this content.';

  @override
  String get collabLoadAuthorsFailed => 'Could not load followed authors.';

  @override
  String get collabFollowAuthorFirst =>
      'Follow an author first to invite them.';

  @override
  String get coAuthor => 'Co-author';

  @override
  String get wantsToCollaborate => 'wants to collaborate with you.';

  @override
  String couldNotDeleteDraft(String error) {
    return 'Could not delete draft: $error';
  }

  @override
  String get welcomeBackComma => 'Welcome back,';

  @override
  String get aboutThisTopic => 'About this topic';

  @override
  String get submissionsReceived => 'Submissions received';

  @override
  String failedToLoadTopic(String error) {
    return 'Failed to load topic: $error';
  }

  @override
  String writeOnDailyTopic(String topic, String link) {
    return 'Write on \"$topic\" on Wreadom: $link';
  }

  @override
  String failedToLoadSubmissions(String error) {
    return 'Failed to load submissions: $error';
  }

  @override
  String get cannotSendMessages =>
      'You can\'t send messages in this conversation.';

  @override
  String get oneMessageAllowed =>
      'Only one message allowed unless the recipient replies.';

  @override
  String get blockUserBody =>
      'They will no longer be able to send messages in this conversation.';

  @override
  String get sentYouAMessage => 'sent you a message.';

  @override
  String get sentYouBook => 'sent you a book.';

  @override
  String get targetComment => 'Target comment';

  @override
  String get fromNotifications => 'from notifications';

  @override
  String get removeReadingHistoryTitle => 'Remove from read history?';

  @override
  String get removeReadingHistoryBody =>
      'This only removes the content from your read history.';

  @override
  String get gotIt => 'Got it';

  @override
  String get swipeHintBookComments =>
      'Swipe comments left or right to reveal actions.';

  @override
  String get swipeHintMessages =>
      'Swipe message rows to reveal available actions.';

  @override
  String get sentMessage => 'Message sent';

  @override
  String get viewComments => 'View Comments';

  @override
  String get writeReview => 'Write Review';

  @override
  String get deleteChapter => 'Delete chapter';

  @override
  String get deleteChapterTitle => 'Delete chapter?';

  @override
  String get unsavedChanges => 'Unsaved changes';

  @override
  String get draftSaved => 'Draft saved';

  @override
  String get noSavedBooksYet => 'No saved content yet.';

  @override
  String get noDownloadedBooksYet => 'No downloaded content yet.';

  @override
  String failedToLoadDownloadedBooks(String error) {
    return 'Failed to load downloaded content: $error';
  }

  @override
  String downloadedOn(String date) {
    return 'Downloaded $date';
  }

  @override
  String get removeDownloadedBookTitle => 'Remove download?';

  @override
  String removeDownloadedBookBody(String title) {
    return 'Remove \"$title\" from offline storage.';
  }

  @override
  String get downloadRemoved => 'Download removed.';

  @override
  String get onboardingDiscoverTitle => 'Discover your next read';

  @override
  String get onboardingDiscoverBody =>
      'Browse originals, classics, trending works, and authors curated for your reading mood.';

  @override
  String get onboardingOfflineTitle => 'Read anywhere';

  @override
  String get onboardingOfflineBody =>
      'Download content to your device and keep reading even when the network disappears.';

  @override
  String get onboardingWriteTitle => 'Write and publish';

  @override
  String get onboardingWriteBody =>
      'Draft chapters, add details, publish your work, and grow your presence as a Wreadom author.';

  @override
  String get onboardingCommunityTitle => 'Join the conversation';

  @override
  String get onboardingCommunityBody =>
      'Share quotes, reviews, posts, and comments with readers and writers across the community.';

  @override
  String get onboardingProfileTitle => 'Make Wreadom yours';

  @override
  String get onboardingProfileBody =>
      'Follow creators, message connections, manage your shelf, and shape a profile readers remember.';

  @override
  String get noPostsYetStartSharing =>
      'No posts yet.\nStart sharing your reading journey!';

  @override
  String get changeProfilePicture => 'Change profile picture';

  @override
  String get changeCoverPicture => 'Change cover picture';

  @override
  String get profilePictureUpdated => 'Profile picture updated.';

  @override
  String get coverPictureUpdated => 'Cover picture updated.';

  @override
  String couldNotUpdatePicture(String error) {
    return 'Could not update picture: $error';
  }

  @override
  String get writerWritingEditor => 'Writing Editor';

  @override
  String get writerContentDetails => 'Content Details';

  @override
  String get writerSaving => 'Saving...';

  @override
  String get writerConvertToDraft => 'Convert to Draft';

  @override
  String get writerDraft => 'Draft';

  @override
  String get writerNext => 'Next';

  @override
  String get writerPublish => 'Publish';

  @override
  String writerChapterTitleHint(int number) {
    return 'Chapter $number title';
  }

  @override
  String get writerChapters => 'Chapters';

  @override
  String get writerStartWriting => 'Start writing...';

  @override
  String get writerContentIdentity => 'Content identity';

  @override
  String get title => 'Title';

  @override
  String get synopsis => 'Synopsis';

  @override
  String get writerTitleHint => 'Give your work a title';

  @override
  String get writerSynopsisHint => 'A short pitch for readers';

  @override
  String get writerCoverOptional => 'Cover (optional)';

  @override
  String get writerUploading => 'Uploading...';

  @override
  String get writerUploadCover => 'Upload cover';

  @override
  String get remove => 'Remove';

  @override
  String get writerDiscovery => 'Discovery';

  @override
  String get contentType => 'Content type';

  @override
  String get category => 'Category';

  @override
  String get topicsOptional => 'Topics (optional)';

  @override
  String get topicsHint => 'magic, friendship, survival';

  @override
  String get publishContent => 'Publish Content';

  @override
  String get saveDraft => 'Save Draft';

  @override
  String get insertImage => 'Insert image';

  @override
  String get insertMedia => 'Insert media';

  @override
  String get deleteChapterBody => 'This removes the chapter from this draft.';

  @override
  String get signInBeforeUploadingImages => 'Sign in before uploading images.';

  @override
  String get imageInserted => 'Image inserted.';

  @override
  String couldNotUploadImage(String error) {
    return 'Could not upload image: $error';
  }

  @override
  String get signInBeforeUploadingCover => 'Sign in before uploading a cover.';

  @override
  String get coverUploaded => 'Cover uploaded.';

  @override
  String couldNotUploadCover(String error) {
    return 'Could not upload cover: $error';
  }

  @override
  String get writerMediaUrlLabel => 'YouTube, Instagram, or Spotify URL';

  @override
  String get insert => 'Insert';

  @override
  String get unsupportedLinksInsertedAsPlainText =>
      'Unsupported links are inserted as plain text.';

  @override
  String get addTitleBeforeSaving => 'Add a title before saving.';

  @override
  String get writerPublishing => 'Publishing...';

  @override
  String get writerSavingDraft => 'Saving draft...';

  @override
  String get writerPublishedStatus => 'Published';

  @override
  String get storyPublished => 'Story published.';

  @override
  String couldNotSave(String error) {
    return 'Could not save: $error';
  }

  @override
  String get savedOnDevice => 'Saved on device';

  @override
  String get localSaveFailed => 'Local save failed';

  @override
  String get follow => 'Follow';

  @override
  String get unfollow => 'Unfollow';

  @override
  String get signInToContinueAction => 'Sign in to continue.';

  @override
  String followActionFailed(String error) {
    return 'Could not update follow: $error';
  }

  @override
  String get startedFollowingYou => 'started following you.';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get skip => 'Skip';

  @override
  String get done => 'Done';

  @override
  String get open => 'Open';

  @override
  String get chapterOverview => 'Chapter overview';

  @override
  String chapterCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapters',
      one: '1 chapter',
    );
    return '$_temp0';
  }

  @override
  String get addNewChapter => 'Add new chapter';

  @override
  String get noContentYet => 'No content yet';

  @override
  String get editing => 'Editing';

  @override
  String wordCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get writerSaveFailed => 'Save failed';

  @override
  String get untitledStory => 'Untitled content';

  @override
  String publishedBookNotification(String title) {
    return 'published \"$title\".';
  }

  @override
  String get repliedToYourBookComment => 'replied to your content comment.';

  @override
  String get commentedOnYourContent => 'commented on your content.';

  @override
  String get reviewedYourBook => 'reviewed your content.';

  @override
  String get updatedReviewOnYourBook => 'updated a review on your content.';

  @override
  String get authorsCannotReviewOwnBook =>
      'Authors cannot review their own content.';

  @override
  String get feedTypePost => 'Post';

  @override
  String get feedTypeComment => 'Comment';

  @override
  String get feedTypeQuote => 'Quote';

  @override
  String get feedTypeReview => 'Review';

  @override
  String get feedTypeTestimony => 'Testimony';

  @override
  String get noRatingsYet => 'No ratings yet';

  @override
  String ratingMetric(String rating) {
    return '$rating rating';
  }

  @override
  String readsMetric(String count) {
    return '$count reads';
  }

  @override
  String worksMetric(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count works',
      one: '1 work',
    );
    return '$_temp0';
  }

  @override
  String get helpTitle => 'Help & Support';

  @override
  String get helpSearchHint => 'Search for help topics...';

  @override
  String get helpCategoryReading => 'Reading';

  @override
  String get helpCategoryWriting => 'Writing';

  @override
  String get helpCategoryDiscovery => 'Discovery';

  @override
  String get helpCategoryCommunity => 'Community';

  @override
  String get helpCategoryAccount => 'Account';

  @override
  String get helpCategoryCollaboration => 'Collaboration';

  @override
  String get faqCustomizeReaderQ => 'How do I customize the reader?';

  @override
  String get faqCustomizeReaderA =>
      'Open any book and tap the \'Aa\' icon in the top toolbar. You can change the font size, switch between Serif and Sans fonts, and choose a theme (Light, Sepia, or Dark).';

  @override
  String get faqOfflineReadingQ => 'Can I read books offline?';

  @override
  String get faqOfflineReadingA =>
      'Yes! Tap the download icon on the book details page. Once downloaded, you can access the book from your \'Saved\' tab even without an internet connection.';

  @override
  String get faqBookmarksQ => 'How do bookmarks work?';

  @override
  String get faqBookmarksA =>
      'Wreadom automatically saves your progress as you read. To manually mark a specific spot, tap the bookmark icon in the reader\'s top toolbar.';

  @override
  String get faqQuoteCommentQ => 'What is \'Quote & Comment\'?';

  @override
  String get faqQuoteCommentA =>
      'Highlight any text in a book to see the selection menu. You can \'Quote & Comment\' to share your thoughts on a specific passage with the community.';

  @override
  String get faqStartStoryQ => 'How do I start a new story?';

  @override
  String get faqStartStoryA =>
      'Go to the \'Writer Dashboard\' from your profile menu and tap the \'Add\' icon. This will open the Writer Pad where you can start drafting your first chapter.';

  @override
  String get faqAutoSaveQ => 'Is there an auto-save feature?';

  @override
  String get faqAutoSaveA =>
      'Yes, the Writer Pad automatically saves your drafts every 10 seconds. You can see the \'Last Saved\' status at the top of the editor.';

  @override
  String get faqPublishWorkQ => 'How do I publish my work?';

  @override
  String get faqPublishWorkA =>
      'Once your story is ready, tap \'Publish\' in the Writer Pad. You\'ll be asked to provide a title, synopsis, and relevant topics before it goes live for the community.';

  @override
  String get faqOrganizeChaptersQ => 'Can I organize chapters?';

  @override
  String get faqOrganizeChaptersA =>
      'Absolutely! Use the chapter menu (list icon) in the editor to add new chapters, switch between them, or reorder your story structure.';

  @override
  String get faqCollaborationQ => 'How do collaborations work?';

  @override
  String get faqCollaborationA =>
      'In the Writer Pad, enable Collaboration and choose a user you follow as a co-author. They receive a request, and once accepted, both authors can edit the content and appear together on the book page.';

  @override
  String get faqFindBooksQ => 'How do I find new books?';

  @override
  String get faqFindBooksA =>
      'Use the \'Discover\' tab to browse by trending genres like Fantasy, Romance, and Sci-Fi. You can also search specifically for titles or authors.';

  @override
  String get faqOriginalsQ => 'What are \'Originals\'?';

  @override
  String get faqOriginalsA =>
      'Originals are stories written and published directly by authors within the Wreadom community.';

  @override
  String get faqInternetArchiveQ => 'What is the Internet Archive integration?';

  @override
  String get faqInternetArchiveA =>
      'Wreadom connects to the Internet Archive to give you access to millions of classic books and public domain works alongside community originals.';

  @override
  String get faqDailyTopicQ => 'What is the Daily Topic?';

  @override
  String get faqDailyTopicA =>
      'Every day, Wreadom features a new writing or discussion prompt. Tap the banner on the Home feed to participate and see what others are sharing.';

  @override
  String get faqFollowAuthorQ => 'How do I follow an author?';

  @override
  String get faqFollowAuthorA =>
      'Tap on an author\'s name or avatar to visit their public profile, then tap \'Follow\' to see their latest posts and story updates in your feed.';

  @override
  String get faqMessagingQ => 'Can I message other users?';

  @override
  String get faqMessagingA =>
      'Yes, you can start direct conversations with other users. Visit their profile or use the \'Messages\' icon on your navigation bar to manage your chats.';

  @override
  String get faqChangeThemeQ => 'How do I change the app theme?';

  @override
  String get faqChangeThemeA =>
      'Go to Profile -> Menu (top-right) -> Theme. You can choose between Light, Dark, or System default modes.';

  @override
  String get faqUpdateProfileQ => 'How do I update my profile?';

  @override
  String get faqUpdateProfileA =>
      'In the \'Edit Profile\' section of your settings, you can update your display name, pen name, and bio.';

  @override
  String get faqNotificationsQ => 'Where are my notifications?';

  @override
  String get faqNotificationsA =>
      'Tap the bell icon on the home screen or profile to see updates about likes, comments, and new followers.';

  @override
  String get faqChangeLanguageQ => 'How do I change the app language?';

  @override
  String get faqChangeLanguageA =>
      'Go to Settings -> Language to switch between English and Hindi.';

  @override
  String get faqWhatAreReadsQ => 'What are \'Reads\'?';

  @override
  String get faqWhatAreReadsA =>
      'Reads indicate how many times a story has been viewed. It updates automatically as the community explores your work.';

  @override
  String get faqTapToSeekQ => 'How does tap-to-seek work in Read Aloud?';

  @override
  String get faqTapToSeekA =>
      'While \'Read Aloud\' is active, simply tap on any paragraph to jump the voice directly to that section.';

  @override
  String get faqShareQuoteImageQ => 'Can I share quotes as images?';

  @override
  String get faqShareQuoteImageA =>
      'Yes! Highlight any text and choose \'Share Quote\' to create a beautiful, shareable image of that passage.';

  @override
  String get faqReportContentQ => 'How do I report inappropriate content?';

  @override
  String get faqReportContentA =>
      'Tap the three-dot menu on any post, comment, or book and select \'Report\'. Our team will review it promptly.';

  @override
  String get faqPinUnpinQ => 'Can I pin my favorite comments?';

  @override
  String get faqPinUnpinA =>
      'Yes! If you are the author of a post, you can pin a comment to the top of the discussion by tapping the \'Pin\' option in its menu.';

  @override
  String get faqMessagingRulesQ => 'Are there rules for messaging?';

  @override
  String get faqMessagingRulesA =>
      'To prevent spam, you can only send one message to a new contact. Once they reply, you can chat freely.';

  @override
  String get faqDailyTopicsParticipationQ =>
      'How do I participate in Daily Topics?';

  @override
  String get faqDailyTopicsParticipationA =>
      'Tap the Daily Topic banner on your home feed. You can read submissions or add your own response to the prompt.';

  @override
  String get faqFeedUpdatesQ => 'What shows up in my Feed?';

  @override
  String get faqFeedUpdatesA =>
      'Your Feed is a personalized stream of updates from authors you follow, including new posts, reviews, and story chapters.';

  @override
  String get faqMultiChapterWriterQ => 'Can I write multiple chapters at once?';

  @override
  String get faqMultiChapterWriterA =>
      'Yes! In the Writer Pad, use the chapters list to create multiple segments of your story. You can save them all as a single draft before publishing.';

  @override
  String get faqProfilePicturesQ =>
      'How do I update my profile and cover images?';

  @override
  String get faqProfilePicturesA =>
      'Visit your profile and tap on the camera icons on your avatar or cover photo to upload new images from your device.';

  @override
  String get stillNeedHelp => 'Still need help?';

  @override
  String get communitySupportAssist => 'Our community team is here to assist.';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get emailSupport => 'Email support';

  @override
  String noHelpTopicsFound(String query) {
    return 'No help topics found for \"$query\"';
  }
}

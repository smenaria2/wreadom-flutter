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
  String get history => 'History';

  @override
  String get saved => 'Saved';

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
  String get searchBooks => 'Search books';

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
  String get searchBooksAuthors => 'Search books and authors';

  @override
  String get searchHint => 'Search books, authors...';

  @override
  String get suggestedBooks => 'Suggested Books';

  @override
  String get noSuggestedBooks => 'No suggested books found.';

  @override
  String noBooksFoundIn(String genre) {
    return 'No books found in $genre.';
  }

  @override
  String noResultsFor(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get originalBooks => 'Original Books';

  @override
  String get moreBooks => 'More Books';

  @override
  String get profiles => 'Profiles';

  @override
  String get unknownAuthor => 'Unknown Author';

  @override
  String get internetArchive => 'Internet Archive';

  @override
  String get bookNotFound => 'Book not found';

  @override
  String get editBook => 'Edit book';

  @override
  String get reportBook => 'Report book';

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
  String get aboutThisBook => 'About this Book';

  @override
  String defaultShareMessage(String title) {
    return 'I\'m reading \"$title\" on Wreadom. Check it out.';
  }

  @override
  String get shareToFeed => 'Share to feed';

  @override
  String get signInToShare => 'Sign in to share this book.';

  @override
  String get sendToChat => 'Send to chat';

  @override
  String get noRecentConversations => 'No recent conversations yet.';

  @override
  String get conversation => 'Conversation';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get sentYouABook => 'sent you a book.';

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
  String get internetArchivePreparation =>
      'Internet Archive books can take a moment to prepare.';

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
      'Thousands of free books and original stories, curated for you.';

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
    return '$author\'s books';
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
  String get books => 'Books';

  @override
  String get noPublishedBooksYet => 'No published books yet.';

  @override
  String failedToLoadBooks(String error) {
    return 'Failed to load books: $error';
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
  String get enterQuoteHint => 'Enter the quote from the book...';

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
  String get reviewHint => 'What did you think of this book?';

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
  String get savedBooksTitle => 'Saved Books';

  @override
  String get noSavedOrDownloadedBooksYet => 'No saved or downloaded books yet.';

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
  String get removeSavedBookTitle => 'Remove saved book?';

  @override
  String get removeSavedBookBody =>
      'The offline download will stay available unless you remove it separately.';

  @override
  String get unsave => 'Unsave';

  @override
  String get bookSavedDownloaded =>
      'Book saved and downloaded for offline reading.';

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
    return 'Failed to load saved books: $error';
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
  String get noBookNotificationsYet => 'No book notifications yet';

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
  String get noSavedBooksYet => 'No saved books yet.';

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
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Wreadom'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @submitError.
  ///
  /// In en, this message translates to:
  /// **'Report an issue'**
  String get submitError;

  /// No description provided for @followers.
  ///
  /// In en, this message translates to:
  /// **'Followers'**
  String get followers;

  /// No description provided for @following.
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get following;

  /// No description provided for @works.
  ///
  /// In en, this message translates to:
  /// **'Works'**
  String get works;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @posts.
  ///
  /// In en, this message translates to:
  /// **'Posts'**
  String get posts;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'Read Content'**
  String get history;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @penName.
  ///
  /// In en, this message translates to:
  /// **'Pen Name'**
  String get penName;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get public;

  /// No description provided for @followersOnly.
  ///
  /// In en, this message translates to:
  /// **'Followers Only'**
  String get followersOnly;

  /// No description provided for @private.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private;

  /// No description provided for @saveSettings.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get saveSettings;

  /// No description provided for @pleaseSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please Sign In'**
  String get pleaseSignIn;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back!'**
  String get welcomeBack;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue reading'**
  String get signInToContinue;

  /// No description provided for @joinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join our community of readers'**
  String get joinCommunity;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredField;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @minChars.
  ///
  /// In en, this message translates to:
  /// **'Min 6 chars'**
  String get minChars;

  /// No description provided for @loginBtn.
  ///
  /// In en, this message translates to:
  /// **'LOGIN'**
  String get loginBtn;

  /// No description provided for @signupBtn.
  ///
  /// In en, this message translates to:
  /// **'SIGN UP'**
  String get signupBtn;

  /// No description provided for @orDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @enterEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter your email first'**
  String get enterEmailFirst;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent'**
  String get passwordResetSent;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// No description provided for @signUpLink.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUpLink;

  /// No description provided for @loginLink.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginLink;

  /// No description provided for @feed.
  ///
  /// In en, this message translates to:
  /// **'Feed'**
  String get feed;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @searchBooks.
  ///
  /// In en, this message translates to:
  /// **'Search content'**
  String get searchBooks;

  /// No description provided for @mine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get mine;

  /// No description provided for @noFollowingPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts from people you follow yet'**
  String get noFollowingPosts;

  /// No description provided for @noPosts.
  ///
  /// In en, this message translates to:
  /// **'No posts yet'**
  String get noPosts;

  /// No description provided for @beFirstToPost.
  ///
  /// In en, this message translates to:
  /// **'Be the first to post something!'**
  String get beFirstToPost;

  /// No description provided for @createAPost.
  ///
  /// In en, this message translates to:
  /// **'Create a Post'**
  String get createAPost;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @post.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get post;

  /// No description provided for @discover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @searchBooksAuthors.
  ///
  /// In en, this message translates to:
  /// **'Search content and authors'**
  String get searchBooksAuthors;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search content, authors...'**
  String get searchHint;

  /// No description provided for @suggestedBooks.
  ///
  /// In en, this message translates to:
  /// **'Suggested Content'**
  String get suggestedBooks;

  /// No description provided for @noSuggestedBooks.
  ///
  /// In en, this message translates to:
  /// **'No suggested content found.'**
  String get noSuggestedBooks;

  /// No description provided for @noBooksFoundIn.
  ///
  /// In en, this message translates to:
  /// **'No content found in {genre}.'**
  String noBooksFoundIn(String genre);

  /// No description provided for @noResultsFor.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String noResultsFor(String query);

  /// No description provided for @originalBooks.
  ///
  /// In en, this message translates to:
  /// **'Original Content'**
  String get originalBooks;

  /// No description provided for @moreBooks.
  ///
  /// In en, this message translates to:
  /// **'More Content'**
  String get moreBooks;

  /// No description provided for @profiles.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get profiles;

  /// No description provided for @unknownAuthor.
  ///
  /// In en, this message translates to:
  /// **'Unknown Author'**
  String get unknownAuthor;

  /// No description provided for @internetArchive.
  ///
  /// In en, this message translates to:
  /// **'Internet Archive'**
  String get internetArchive;

  /// No description provided for @bookNotFound.
  ///
  /// In en, this message translates to:
  /// **'Content not found'**
  String get bookNotFound;

  /// No description provided for @editBook.
  ///
  /// In en, this message translates to:
  /// **'Edit content'**
  String get editBook;

  /// No description provided for @reportBook.
  ///
  /// In en, this message translates to:
  /// **'Report content'**
  String get reportBook;

  /// No description provided for @shareBookMessage.
  ///
  /// In en, this message translates to:
  /// **'Read \"{title}\" on Wreadom: {link}'**
  String shareBookMessage(String title, String link);

  /// No description provided for @readsStat.
  ///
  /// In en, this message translates to:
  /// **'{count} reads'**
  String readsStat(String count);

  /// No description provided for @chaptersStat.
  ///
  /// In en, this message translates to:
  /// **'{count} chapters'**
  String chaptersStat(String count);

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue Reading'**
  String get continueReading;

  /// No description provided for @startReading.
  ///
  /// In en, this message translates to:
  /// **'Start Reading'**
  String get startReading;

  /// No description provided for @aboutThisBook.
  ///
  /// In en, this message translates to:
  /// **'About this content'**
  String get aboutThisBook;

  /// No description provided for @defaultShareMessage.
  ///
  /// In en, this message translates to:
  /// **'I\'m reading \"{title}\" on Wreadom. Check it out.'**
  String defaultShareMessage(String title);

  /// No description provided for @shareToFeed.
  ///
  /// In en, this message translates to:
  /// **'Share to feed'**
  String get shareToFeed;

  /// No description provided for @signInToShare.
  ///
  /// In en, this message translates to:
  /// **'Sign in to share this content.'**
  String get signInToShare;

  /// No description provided for @sendToChat.
  ///
  /// In en, this message translates to:
  /// **'Send to chat'**
  String get sendToChat;

  /// No description provided for @noRecentConversations.
  ///
  /// In en, this message translates to:
  /// **'No recent conversations yet.'**
  String get noRecentConversations;

  /// No description provided for @conversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get conversation;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @sentYouABook.
  ///
  /// In en, this message translates to:
  /// **'sent you content.'**
  String get sentYouABook;

  /// No description provided for @sentBookSnack.
  ///
  /// In en, this message translates to:
  /// **'Sent \"{title}\".'**
  String sentBookSnack(String title);

  /// No description provided for @sharedToFeed.
  ///
  /// In en, this message translates to:
  /// **'Shared to feed.'**
  String get sharedToFeed;

  /// No description provided for @latestDiscussion.
  ///
  /// In en, this message translates to:
  /// **'Latest discussion'**
  String get latestDiscussion;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// No description provided for @failedToLoadChats.
  ///
  /// In en, this message translates to:
  /// **'Failed to load chats: {error}'**
  String failedToLoadChats(String error);

  /// No description provided for @fetchingPublicDomain.
  ///
  /// In en, this message translates to:
  /// **'Fetching public-domain text...'**
  String get fetchingPublicDomain;

  /// No description provided for @chaptersTitle.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get chaptersTitle;

  /// No description provided for @viewChapterComments.
  ///
  /// In en, this message translates to:
  /// **'View chapter comments'**
  String get viewChapterComments;

  /// No description provided for @nextChapter.
  ///
  /// In en, this message translates to:
  /// **'Next Chapter'**
  String get nextChapter;

  /// No description provided for @shareChapter.
  ///
  /// In en, this message translates to:
  /// **'Share Chapter'**
  String get shareChapter;

  /// No description provided for @closeReader.
  ///
  /// In en, this message translates to:
  /// **'Close Reader'**
  String get closeReader;

  /// No description provided for @internetArchivePreparation.
  ///
  /// In en, this message translates to:
  /// **'Internet Archive content can take a moment to prepare.'**
  String get internetArchivePreparation;

  /// No description provided for @viewPdf.
  ///
  /// In en, this message translates to:
  /// **'View PDF'**
  String get viewPdf;

  /// No description provided for @upvote.
  ///
  /// In en, this message translates to:
  /// **'Upvote'**
  String get upvote;

  /// No description provided for @downvote.
  ///
  /// In en, this message translates to:
  /// **'Downvote'**
  String get downvote;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @readAloud.
  ///
  /// In en, this message translates to:
  /// **'Read aloud'**
  String get readAloud;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @stopReadingAloud.
  ///
  /// In en, this message translates to:
  /// **'Stop reading aloud'**
  String get stopReadingAloud;

  /// No description provided for @readerSettings.
  ///
  /// In en, this message translates to:
  /// **'Reader Settings'**
  String get readerSettings;

  /// No description provided for @shareQuote.
  ///
  /// In en, this message translates to:
  /// **'Share Quote'**
  String get shareQuote;

  /// No description provided for @quoteAndComment.
  ///
  /// In en, this message translates to:
  /// **'Quote & Comment'**
  String get quoteAndComment;

  /// No description provided for @genreFantasy.
  ///
  /// In en, this message translates to:
  /// **'Fantasy'**
  String get genreFantasy;

  /// No description provided for @genreRomance.
  ///
  /// In en, this message translates to:
  /// **'Romance'**
  String get genreRomance;

  /// No description provided for @genreSciFi.
  ///
  /// In en, this message translates to:
  /// **'Science Fiction'**
  String get genreSciFi;

  /// No description provided for @genreMystery.
  ///
  /// In en, this message translates to:
  /// **'Mystery'**
  String get genreMystery;

  /// No description provided for @genreHorror.
  ///
  /// In en, this message translates to:
  /// **'Horror'**
  String get genreHorror;

  /// No description provided for @genreHistorical.
  ///
  /// In en, this message translates to:
  /// **'Historical'**
  String get genreHistorical;

  /// No description provided for @genreAdventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get genreAdventure;

  /// No description provided for @genrePoetry.
  ///
  /// In en, this message translates to:
  /// **'Poetry'**
  String get genrePoetry;

  /// No description provided for @genreClassic.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get genreClassic;

  /// No description provided for @genreSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get genreSocial;

  /// No description provided for @genreHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get genreHistory;

  /// No description provided for @genreStories.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get genreStories;

  /// No description provided for @genreCompetition.
  ///
  /// In en, this message translates to:
  /// **'Wreadom Competition #1'**
  String get genreCompetition;

  /// No description provided for @genreOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genreOther;

  /// No description provided for @genreBiography.
  ///
  /// In en, this message translates to:
  /// **'Biography'**
  String get genreBiography;

  /// No description provided for @genrePhilosophy.
  ///
  /// In en, this message translates to:
  /// **'Philosophy'**
  String get genrePhilosophy;

  /// No description provided for @writer.
  ///
  /// In en, this message translates to:
  /// **'Writer'**
  String get writer;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @shelfCommunityClassics.
  ///
  /// In en, this message translates to:
  /// **'Community Classics'**
  String get shelfCommunityClassics;

  /// No description provided for @shelfOriginals.
  ///
  /// In en, this message translates to:
  /// **'Wreadom Originals'**
  String get shelfOriginals;

  /// No description provided for @shelfTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending Works'**
  String get shelfTrending;

  /// No description provided for @shelfPopular.
  ///
  /// In en, this message translates to:
  /// **'Popular Now'**
  String get shelfPopular;

  /// No description provided for @shelfRecentlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get shelfRecentlyAdded;

  /// No description provided for @keepReading.
  ///
  /// In en, this message translates to:
  /// **'Keep Reading'**
  String get keepReading;

  /// No description provided for @heroBannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Thousands of free content and original stories, curated for you.'**
  String get heroBannerSubtitle;

  /// No description provided for @exploreNow.
  ///
  /// In en, this message translates to:
  /// **'Explore Now'**
  String get exploreNow;

  /// No description provided for @dailyTopic.
  ///
  /// In en, this message translates to:
  /// **'Daily Topic'**
  String get dailyTopic;

  /// No description provided for @readMore.
  ///
  /// In en, this message translates to:
  /// **'Read More'**
  String get readMore;

  /// No description provided for @yourShelf.
  ///
  /// In en, this message translates to:
  /// **'Your Shelf'**
  String get yourShelf;

  /// No description provided for @percentComplete.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String percentComplete(int percent);

  /// No description provided for @readyToResume.
  ///
  /// In en, this message translates to:
  /// **'Ready to resume'**
  String get readyToResume;

  /// No description provided for @chapterNumber.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String chapterNumber(int number);

  /// No description provided for @errorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithDetails(String message);

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @authorsToFollow.
  ///
  /// In en, this message translates to:
  /// **'Authors to Follow'**
  String get authorsToFollow;

  /// No description provided for @topRatedAuthors.
  ///
  /// In en, this message translates to:
  /// **'Top Rated Authors'**
  String get topRatedAuthors;

  /// No description provided for @mostReadAuthors.
  ///
  /// In en, this message translates to:
  /// **'Most Read Authors'**
  String get mostReadAuthors;

  /// No description provided for @mostPublishedAuthors.
  ///
  /// In en, this message translates to:
  /// **'Most Published Authors'**
  String get mostPublishedAuthors;

  /// No description provided for @featuredWreadomAuthor.
  ///
  /// In en, this message translates to:
  /// **'Featured Wreadom author.'**
  String get featuredWreadomAuthor;

  /// No description provided for @authorSpotlight.
  ///
  /// In en, this message translates to:
  /// **'Author Spotlight'**
  String get authorSpotlight;

  /// No description provided for @authorBooks.
  ///
  /// In en, this message translates to:
  /// **'{author}\'s content'**
  String authorBooks(String author);

  /// No description provided for @couldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load {title}.'**
  String couldNotLoad(String title);

  /// No description provided for @bookByAuthor.
  ///
  /// In en, this message translates to:
  /// **'{title} by {author}'**
  String bookByAuthor(String title, String author);

  /// No description provided for @failedToLoadWithError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load: {error}'**
  String failedToLoadWithError(String error);

  /// No description provided for @writeSomethingFirst.
  ///
  /// In en, this message translates to:
  /// **'Please write something first'**
  String get writeSomethingFirst;

  /// No description provided for @loginToPost.
  ///
  /// In en, this message translates to:
  /// **'Please log in to post'**
  String get loginToPost;

  /// No description provided for @postShared.
  ///
  /// In en, this message translates to:
  /// **'Post shared'**
  String get postShared;

  /// No description provided for @shareAnUpdate.
  ///
  /// In en, this message translates to:
  /// **'Share an update'**
  String get shareAnUpdate;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @postBtn.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postBtn;

  /// No description provided for @postHint.
  ///
  /// In en, this message translates to:
  /// **'What are you reading, thinking, or building?'**
  String get postHint;

  /// No description provided for @removeImage.
  ///
  /// In en, this message translates to:
  /// **'Remove image'**
  String get removeImage;

  /// No description provided for @addImage.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get addImage;

  /// No description provided for @likedYourPost.
  ///
  /// In en, this message translates to:
  /// **'liked your post.'**
  String get likedYourPost;

  /// No description provided for @deletePostTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete post?'**
  String get deletePostTitle;

  /// No description provided for @deletePostContent.
  ///
  /// In en, this message translates to:
  /// **'This will remove the post and its comments.'**
  String get deletePostContent;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @postDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post deleted'**
  String get postDeleted;

  /// No description provided for @couldNotDeletePost.
  ///
  /// In en, this message translates to:
  /// **'Could not delete post: {error}'**
  String couldNotDeletePost(String error);

  /// No description provided for @editPost.
  ///
  /// In en, this message translates to:
  /// **'Edit post'**
  String get editPost;

  /// No description provided for @updateYourPost.
  ///
  /// In en, this message translates to:
  /// **'Update your post'**
  String get updateYourPost;

  /// No description provided for @replaceImage.
  ///
  /// In en, this message translates to:
  /// **'Replace image'**
  String get replaceImage;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @reportPost.
  ///
  /// In en, this message translates to:
  /// **'Report Post'**
  String get reportPost;

  /// No description provided for @regarding.
  ///
  /// In en, this message translates to:
  /// **'Regarding'**
  String get regarding;

  /// No description provided for @unlikePost.
  ///
  /// In en, this message translates to:
  /// **'Unlike post'**
  String get unlikePost;

  /// No description provided for @likePost.
  ///
  /// In en, this message translates to:
  /// **'Like post'**
  String get likePost;

  /// No description provided for @showComments.
  ///
  /// In en, this message translates to:
  /// **'Show comments'**
  String get showComments;

  /// No description provided for @sharePost.
  ///
  /// In en, this message translates to:
  /// **'Share post'**
  String get sharePost;

  /// No description provided for @checkOutPostOnWreadom.
  ///
  /// In en, this message translates to:
  /// **'Check out this post on Wreadom: {link}'**
  String checkOutPostOnWreadom(String link);

  /// No description provided for @wreadomPost.
  ///
  /// In en, this message translates to:
  /// **'Wreadom Post'**
  String get wreadomPost;

  /// No description provided for @repliedToYourComment.
  ///
  /// In en, this message translates to:
  /// **'replied to your comment.'**
  String get repliedToYourComment;

  /// No description provided for @commentedOnYourPost.
  ///
  /// In en, this message translates to:
  /// **'commented on your post.'**
  String get commentedOnYourPost;

  /// No description provided for @errorSubmittingComment.
  ///
  /// In en, this message translates to:
  /// **'Error submitting comment: {error}'**
  String errorSubmittingComment(String error);

  /// No description provided for @commentsCount.
  ///
  /// In en, this message translates to:
  /// **'Comments ({count})'**
  String commentsCount(int count);

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @commentsLoading.
  ///
  /// In en, this message translates to:
  /// **'Comments...'**
  String get commentsLoading;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Be the first!'**
  String get noCommentsYet;

  /// No description provided for @errorLoadingComments.
  ///
  /// In en, this message translates to:
  /// **'Error loading comments: {error}'**
  String errorLoadingComments(String error);

  /// No description provided for @replyingTo.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String replyingTo(String name);

  /// No description provided for @addAReply.
  ///
  /// In en, this message translates to:
  /// **'Add a reply...'**
  String get addAReply;

  /// No description provided for @addAComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get addAComment;

  /// No description provided for @editComment.
  ///
  /// In en, this message translates to:
  /// **'Edit comment'**
  String get editComment;

  /// No description provided for @editReply.
  ///
  /// In en, this message translates to:
  /// **'Edit reply'**
  String get editReply;

  /// No description provided for @editFailed.
  ///
  /// In en, this message translates to:
  /// **'Edit failed: {error}'**
  String editFailed(String error);

  /// No description provided for @deleteCommentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Comment?'**
  String get deleteCommentTitle;

  /// No description provided for @deleteReplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Reply?'**
  String get deleteReplyTitle;

  /// No description provided for @deleteActionUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get deleteActionUndone;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailed(String error);

  /// No description provided for @pin.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pin;

  /// No description provided for @unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpin;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @writeYourUpdate.
  ///
  /// In en, this message translates to:
  /// **'Write your update'**
  String get writeYourUpdate;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String daysAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(int count);

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(int count);

  /// No description provided for @shareProfile.
  ///
  /// In en, this message translates to:
  /// **'Share profile'**
  String get shareProfile;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @readWithUserOnWreadom.
  ///
  /// In en, this message translates to:
  /// **'Read with {name} on Wreadom\n{link}'**
  String readWithUserOnWreadom(String name, String link);

  /// No description provided for @noBioYet.
  ///
  /// In en, this message translates to:
  /// **'No bio yet.'**
  String get noBioYet;

  /// No description provided for @averageRating.
  ///
  /// In en, this message translates to:
  /// **'Average rating'**
  String get averageRating;

  /// No description provided for @totalReads.
  ///
  /// In en, this message translates to:
  /// **'Total reads'**
  String get totalReads;

  /// No description provided for @booksPublished.
  ///
  /// In en, this message translates to:
  /// **'Books published'**
  String get booksPublished;

  /// No description provided for @dateJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get dateJoined;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @themeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeDialogTitle;

  /// No description provided for @errorType.
  ///
  /// In en, this message translates to:
  /// **'Issue type'**
  String get errorType;

  /// No description provided for @whatWentWrong.
  ///
  /// In en, this message translates to:
  /// **'What went wrong?'**
  String get whatWentWrong;

  /// No description provided for @describeIssueHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue and what you were doing.'**
  String get describeIssueHint;

  /// No description provided for @deviceLogsIncluded.
  ///
  /// In en, this message translates to:
  /// **'Device info and recent app logs will be included.'**
  String get deviceLogsIncluded;

  /// No description provided for @viewCollectedLogs.
  ///
  /// In en, this message translates to:
  /// **'View collected logs'**
  String get viewCollectedLogs;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @collectedLogs.
  ///
  /// In en, this message translates to:
  /// **'Collected logs'**
  String get collectedLogs;

  /// No description provided for @noAppLogsYet.
  ///
  /// In en, this message translates to:
  /// **'No app logs have been collected yet.'**
  String get noAppLogsYet;

  /// No description provided for @pleaseDescribeIssue.
  ///
  /// In en, this message translates to:
  /// **'Please describe the issue.'**
  String get pleaseDescribeIssue;

  /// No description provided for @mustBeLoggedInToSubmitIssues.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to submit issues.'**
  String get mustBeLoggedInToSubmitIssues;

  /// No description provided for @issueReportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Issue report submitted.'**
  String get issueReportSubmitted;

  /// No description provided for @failedToSubmitIssueReport.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit issue report: {error}'**
  String failedToSubmitIssueReport(String error);

  /// No description provided for @userNotFound.
  ///
  /// In en, this message translates to:
  /// **'User not found'**
  String get userNotFound;

  /// No description provided for @penNameValue.
  ///
  /// In en, this message translates to:
  /// **'Pen name: {name}'**
  String penNameValue(String name);

  /// No description provided for @privateAccountNotice.
  ///
  /// In en, this message translates to:
  /// **'This account is private. Only basic profile info is visible.'**
  String get privateAccountNotice;

  /// No description provided for @followToSeeFullProfile.
  ///
  /// In en, this message translates to:
  /// **'Follow this account to see their full profile.'**
  String get followToSeeFullProfile;

  /// No description provided for @books.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get books;

  /// No description provided for @noPublishedBooksYet.
  ///
  /// In en, this message translates to:
  /// **'No published content yet.'**
  String get noPublishedBooksYet;

  /// No description provided for @failedToLoadBooks.
  ///
  /// In en, this message translates to:
  /// **'Failed to load content: {error}'**
  String failedToLoadBooks(String error);

  /// No description provided for @failedToLoadPosts.
  ///
  /// In en, this message translates to:
  /// **'Failed to load posts: {error}'**
  String failedToLoadPosts(String error);

  /// No description provided for @noReadingHistoryYet.
  ///
  /// In en, this message translates to:
  /// **'No reading history yet.'**
  String get noReadingHistoryYet;

  /// No description provided for @errorLoadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Error loading history: {error}'**
  String errorLoadingHistory(String error);

  /// No description provided for @wreadomCreator.
  ///
  /// In en, this message translates to:
  /// **'WREADOM CREATOR'**
  String get wreadomCreator;

  /// No description provided for @officialLiteraryProfile.
  ///
  /// In en, this message translates to:
  /// **'OFFICIAL LITERARY PROFILE - WREADOM.IN'**
  String get officialLiteraryProfile;

  /// No description provided for @shareProfileSubject.
  ///
  /// In en, this message translates to:
  /// **'{name} on Wreadom'**
  String shareProfileSubject(String name);

  /// No description provided for @failedToPostReply.
  ///
  /// In en, this message translates to:
  /// **'Failed to post reply: {error}'**
  String failedToPostReply(String error);

  /// No description provided for @shareAQuote.
  ///
  /// In en, this message translates to:
  /// **'Share a quote'**
  String get shareAQuote;

  /// No description provided for @pleaseEnterQuote.
  ///
  /// In en, this message translates to:
  /// **'Please enter a quote'**
  String get pleaseEnterQuote;

  /// No description provided for @quoteShared.
  ///
  /// In en, this message translates to:
  /// **'Quote shared!'**
  String get quoteShared;

  /// No description provided for @failedToShareQuote.
  ///
  /// In en, this message translates to:
  /// **'Failed to share quote: {error}'**
  String failedToShareQuote(String error);

  /// No description provided for @enterQuoteHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the quote from the content...'**
  String get enterQuoteHint;

  /// No description provided for @addThoughtsOptional.
  ///
  /// In en, this message translates to:
  /// **'Add your thoughts (optional)'**
  String get addThoughtsOptional;

  /// No description provided for @postQuote.
  ///
  /// In en, this message translates to:
  /// **'Post quote'**
  String get postQuote;

  /// No description provided for @pleaseSelectRating.
  ///
  /// In en, this message translates to:
  /// **'Please select a rating'**
  String get pleaseSelectRating;

  /// No description provided for @pleaseWriteShortReview.
  ///
  /// In en, this message translates to:
  /// **'Please write a short review'**
  String get pleaseWriteShortReview;

  /// No description provided for @pleaseLoginToReview.
  ///
  /// In en, this message translates to:
  /// **'Please log in to review'**
  String get pleaseLoginToReview;

  /// No description provided for @reviewShared.
  ///
  /// In en, this message translates to:
  /// **'Review shared!'**
  String get reviewShared;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review: {title}'**
  String reviewTitle(String title);

  /// No description provided for @reviewHint.
  ///
  /// In en, this message translates to:
  /// **'What did you think of this content?'**
  String get reviewHint;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @mustBeLoggedInToReportContent.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to report content.'**
  String get mustBeLoggedInToReportContent;

  /// No description provided for @reportSubmittedThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your report. We will review it shortly.'**
  String get reportSubmittedThanks;

  /// No description provided for @failedToSubmitReport.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit report: {error}'**
  String failedToSubmitReport(String error);

  /// No description provided for @reportTarget.
  ///
  /// In en, this message translates to:
  /// **'Report {targetType}'**
  String reportTarget(String targetType);

  /// No description provided for @whyReportContent.
  ///
  /// In en, this message translates to:
  /// **'Why are you reporting this content?'**
  String get whyReportContent;

  /// No description provided for @additionalDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Additional details (optional)'**
  String get additionalDetailsOptional;

  /// No description provided for @submitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get submitReport;

  /// No description provided for @reasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reasonSpam;

  /// No description provided for @reasonOffensiveContent.
  ///
  /// In en, this message translates to:
  /// **'Offensive content'**
  String get reasonOffensiveContent;

  /// No description provided for @reasonInappropriateLanguage.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate language'**
  String get reasonInappropriateLanguage;

  /// No description provided for @reasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get reasonHarassment;

  /// No description provided for @reasonSpoiler.
  ///
  /// In en, this message translates to:
  /// **'Spoiler without warning'**
  String get reasonSpoiler;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reasonOther;

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @deleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete chat'**
  String get deleteChat;

  /// No description provided for @deleteChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete chat?'**
  String get deleteChatTitle;

  /// No description provided for @noConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet. Start from a user profile.'**
  String get noConversationsYet;

  /// No description provided for @postNotFoundOrDeleted.
  ///
  /// In en, this message translates to:
  /// **'Post not found or deleted'**
  String get postNotFoundOrDeleted;

  /// No description provided for @savedBooksTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Content'**
  String get savedBooksTitle;

  /// No description provided for @noSavedOrDownloadedBooksYet.
  ///
  /// In en, this message translates to:
  /// **'No saved or downloaded content yet.'**
  String get noSavedOrDownloadedBooksYet;

  /// No description provided for @dailyTopicNotFound.
  ///
  /// In en, this message translates to:
  /// **'Daily topic not found.'**
  String get dailyTopicNotFound;

  /// No description provided for @participateNow.
  ///
  /// In en, this message translates to:
  /// **'Participate now'**
  String get participateNow;

  /// No description provided for @noSubmissionsYet.
  ///
  /// In en, this message translates to:
  /// **'No submissions received yet.'**
  String get noSubmissionsYet;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get blockUser;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get messageHint;

  /// No description provided for @blockUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Block user?'**
  String get blockUserTitle;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @userBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked.'**
  String get userBlocked;

  /// No description provided for @noRatings.
  ///
  /// In en, this message translates to:
  /// **'No ratings'**
  String get noRatings;

  /// No description provided for @removeSavedBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove saved content?'**
  String get removeSavedBookTitle;

  /// No description provided for @removeSavedBookBody.
  ///
  /// In en, this message translates to:
  /// **'The offline download will stay available unless you remove it separately.'**
  String get removeSavedBookBody;

  /// No description provided for @unsave.
  ///
  /// In en, this message translates to:
  /// **'Unsave'**
  String get unsave;

  /// No description provided for @bookSaved.
  ///
  /// In en, this message translates to:
  /// **'Content saved.'**
  String get bookSaved;

  /// No description provided for @downloadSavedBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Download for offline reading?'**
  String get downloadSavedBookTitle;

  /// No description provided for @downloadSavedBookBody.
  ///
  /// In en, this message translates to:
  /// **'Keep this content available even when you are offline.'**
  String get downloadSavedBookBody;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @keep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// No description provided for @bookSavedDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Content saved and downloaded for offline reading.'**
  String get bookSavedDownloaded;

  /// No description provided for @published.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get published;

  /// No description provided for @drafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get drafts;

  /// No description provided for @reads.
  ///
  /// In en, this message translates to:
  /// **'Reads'**
  String get reads;

  /// No description provided for @deleteDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete draft?'**
  String get deleteDraftTitle;

  /// No description provided for @deleteDraftBody.
  ///
  /// In en, this message translates to:
  /// **'This draft will be removed from your dashboard.'**
  String get deleteDraftBody;

  /// No description provided for @draftDeleted.
  ///
  /// In en, this message translates to:
  /// **'Draft deleted.'**
  String get draftDeleted;

  /// No description provided for @removeCollabBeforeDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove collaboration before deleting this draft.'**
  String get removeCollabBeforeDelete;

  /// No description provided for @deleteConversationBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the conversation from your messages.'**
  String get deleteConversationBody;

  /// No description provided for @failedToLoadSavedBooks.
  ///
  /// In en, this message translates to:
  /// **'Failed to load saved content: {error}'**
  String failedToLoadSavedBooks(String error);

  /// No description provided for @failedToLoadPost.
  ///
  /// In en, this message translates to:
  /// **'Failed to load post: {error}'**
  String failedToLoadPost(String error);

  /// No description provided for @failedToLoadComments.
  ///
  /// In en, this message translates to:
  /// **'Failed to load comments: {error}'**
  String failedToLoadComments(String error);

  /// No description provided for @noFollowersYet.
  ///
  /// In en, this message translates to:
  /// **'No {title} yet.'**
  String noFollowersYet(String title);

  /// No description provided for @failedToLoadTitle.
  ///
  /// In en, this message translates to:
  /// **'Failed to load {title}: {error}'**
  String failedToLoadTitle(String title, String error);

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @noNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotificationsYet;

  /// No description provided for @noMessageNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No message notifications yet'**
  String get noMessageNotificationsYet;

  /// No description provided for @noPostNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No post notifications yet'**
  String get noPostNotificationsYet;

  /// No description provided for @noBookNotificationsYet.
  ///
  /// In en, this message translates to:
  /// **'No content notifications yet'**
  String get noBookNotificationsYet;

  /// No description provided for @notificationContentFilter.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get notificationContentFilter;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get showLess;

  /// Shown when saving a content fails
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(String error);

  /// No description provided for @writerDashboard.
  ///
  /// In en, this message translates to:
  /// **'Writer Dashboard'**
  String get writerDashboard;

  /// No description provided for @createContent.
  ///
  /// In en, this message translates to:
  /// **'Create Content'**
  String get createContent;

  /// No description provided for @noPublishedStoriesYet.
  ///
  /// In en, this message translates to:
  /// **'No published stories yet'**
  String get noPublishedStoriesYet;

  /// No description provided for @noDraftsYet.
  ///
  /// In en, this message translates to:
  /// **'No drafts yet'**
  String get noDraftsYet;

  /// No description provided for @draft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get draft;

  /// No description provided for @lastUpdate.
  ///
  /// In en, this message translates to:
  /// **'Last update'**
  String get lastUpdate;

  /// No description provided for @editStory.
  ///
  /// In en, this message translates to:
  /// **'Edit story'**
  String get editStory;

  /// No description provided for @collaboration.
  ///
  /// In en, this message translates to:
  /// **'Collaboration'**
  String get collaboration;

  /// No description provided for @collab.
  ///
  /// In en, this message translates to:
  /// **'Collab'**
  String get collab;

  /// No description provided for @collabAcceptedDescription.
  ///
  /// In en, this message translates to:
  /// **'Accepted collaboration. Both authors can edit this content.'**
  String get collabAcceptedDescription;

  /// No description provided for @collabPendingDescription.
  ///
  /// In en, this message translates to:
  /// **'Request pending. The co-author can preview and respond.'**
  String get collabPendingDescription;

  /// No description provided for @collabInviteDescription.
  ///
  /// In en, this message translates to:
  /// **'Invite one followed author to co-write this content.'**
  String get collabInviteDescription;

  /// No description provided for @collabLoadAuthorsFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load followed authors.'**
  String get collabLoadAuthorsFailed;

  /// No description provided for @collabFollowAuthorFirst.
  ///
  /// In en, this message translates to:
  /// **'Follow an author first to invite them.'**
  String get collabFollowAuthorFirst;

  /// No description provided for @collabEditWarning.
  ///
  /// In en, this message translates to:
  /// **'The co-author will be able to edit this book, remove chapters, and draft or unpublish the book.'**
  String get collabEditWarning;

  /// No description provided for @collabBookInfo.
  ///
  /// In en, this message translates to:
  /// **'This book is a collaboration. Both authors can write and edit it.'**
  String get collabBookInfo;

  /// No description provided for @selectCoAuthorBeforeSaving.
  ///
  /// In en, this message translates to:
  /// **'Select a co-author before saving collaboration.'**
  String get selectCoAuthorBeforeSaving;

  /// No description provided for @coAuthor.
  ///
  /// In en, this message translates to:
  /// **'Co-author'**
  String get coAuthor;

  /// No description provided for @wantsToCollaborate.
  ///
  /// In en, this message translates to:
  /// **'wants to collaborate with you.'**
  String get wantsToCollaborate;

  /// No description provided for @removedYouAsCoAuthor.
  ///
  /// In en, this message translates to:
  /// **'removed you as co-author.'**
  String get removedYouAsCoAuthor;

  /// No description provided for @removedThemselfAsCoAuthor.
  ///
  /// In en, this message translates to:
  /// **'removed themselves as co-author.'**
  String get removedThemselfAsCoAuthor;

  /// Shown when deleting a draft fails
  ///
  /// In en, this message translates to:
  /// **'Could not delete draft: {error}'**
  String couldNotDeleteDraft(String error);

  /// No description provided for @welcomeBackComma.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcomeBackComma;

  /// No description provided for @aboutThisTopic.
  ///
  /// In en, this message translates to:
  /// **'About this topic'**
  String get aboutThisTopic;

  /// No description provided for @submissionsReceived.
  ///
  /// In en, this message translates to:
  /// **'Submissions received'**
  String get submissionsReceived;

  /// Shown when daily topic cannot load
  ///
  /// In en, this message translates to:
  /// **'Failed to load topic: {error}'**
  String failedToLoadTopic(String error);

  /// Share text for a daily topic
  ///
  /// In en, this message translates to:
  /// **'Write on \"{topic}\" on Wreadom: {link}'**
  String writeOnDailyTopic(String topic, String link);

  /// Shown when submissions cannot load
  ///
  /// In en, this message translates to:
  /// **'Failed to load submissions: {error}'**
  String failedToLoadSubmissions(String error);

  /// No description provided for @cannotSendMessages.
  ///
  /// In en, this message translates to:
  /// **'You can\'t send messages in this conversation.'**
  String get cannotSendMessages;

  /// No description provided for @oneMessageAllowed.
  ///
  /// In en, this message translates to:
  /// **'Only one message allowed unless the recipient replies.'**
  String get oneMessageAllowed;

  /// No description provided for @blockUserBody.
  ///
  /// In en, this message translates to:
  /// **'They will no longer be able to send messages in this conversation.'**
  String get blockUserBody;

  /// No description provided for @sentYouAMessage.
  ///
  /// In en, this message translates to:
  /// **'sent you a message.'**
  String get sentYouAMessage;

  /// No description provided for @sentYouBook.
  ///
  /// In en, this message translates to:
  /// **'sent you a book.'**
  String get sentYouBook;

  /// No description provided for @targetComment.
  ///
  /// In en, this message translates to:
  /// **'Target comment'**
  String get targetComment;

  /// No description provided for @fromNotifications.
  ///
  /// In en, this message translates to:
  /// **'from notifications'**
  String get fromNotifications;

  /// No description provided for @removeReadingHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove from read history?'**
  String get removeReadingHistoryTitle;

  /// No description provided for @removeReadingHistoryBody.
  ///
  /// In en, this message translates to:
  /// **'This only removes the content from your read history.'**
  String get removeReadingHistoryBody;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @swipeHintBookComments.
  ///
  /// In en, this message translates to:
  /// **'Swipe comments left or right to reveal actions.'**
  String get swipeHintBookComments;

  /// No description provided for @swipeHintMessages.
  ///
  /// In en, this message translates to:
  /// **'Swipe message rows to reveal available actions.'**
  String get swipeHintMessages;

  /// No description provided for @sentMessage.
  ///
  /// In en, this message translates to:
  /// **'Message sent'**
  String get sentMessage;

  /// No description provided for @viewComments.
  ///
  /// In en, this message translates to:
  /// **'View Comments'**
  String get viewComments;

  /// No description provided for @writeReview.
  ///
  /// In en, this message translates to:
  /// **'Write Review'**
  String get writeReview;

  /// No description provided for @deleteChapter.
  ///
  /// In en, this message translates to:
  /// **'Delete chapter'**
  String get deleteChapter;

  /// No description provided for @deleteChapterTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete chapter?'**
  String get deleteChapterTitle;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChanges;

  /// No description provided for @draftSaved.
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get draftSaved;

  /// No description provided for @noSavedBooksYet.
  ///
  /// In en, this message translates to:
  /// **'No saved content yet.'**
  String get noSavedBooksYet;

  /// No description provided for @noDownloadedBooksYet.
  ///
  /// In en, this message translates to:
  /// **'No downloaded content yet.'**
  String get noDownloadedBooksYet;

  /// No description provided for @failedToLoadDownloadedBooks.
  ///
  /// In en, this message translates to:
  /// **'Failed to load downloaded content: {error}'**
  String failedToLoadDownloadedBooks(String error);

  /// No description provided for @downloadedOn.
  ///
  /// In en, this message translates to:
  /// **'Downloaded {date}'**
  String downloadedOn(String date);

  /// No description provided for @removeDownloadedBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove download?'**
  String get removeDownloadedBookTitle;

  /// No description provided for @removeDownloadedBookBody.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" from offline storage.'**
  String removeDownloadedBookBody(String title);

  /// No description provided for @downloadRemoved.
  ///
  /// In en, this message translates to:
  /// **'Download removed.'**
  String get downloadRemoved;

  /// No description provided for @onboardingDiscoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover your next read'**
  String get onboardingDiscoverTitle;

  /// No description provided for @onboardingDiscoverBody.
  ///
  /// In en, this message translates to:
  /// **'Browse originals, classics, trending works, and authors curated for your reading mood.'**
  String get onboardingDiscoverBody;

  /// No description provided for @onboardingOfflineTitle.
  ///
  /// In en, this message translates to:
  /// **'Read anywhere'**
  String get onboardingOfflineTitle;

  /// No description provided for @onboardingOfflineBody.
  ///
  /// In en, this message translates to:
  /// **'Download content to your device and keep reading even when the network disappears.'**
  String get onboardingOfflineBody;

  /// No description provided for @onboardingWriteTitle.
  ///
  /// In en, this message translates to:
  /// **'Write and publish'**
  String get onboardingWriteTitle;

  /// No description provided for @onboardingWriteBody.
  ///
  /// In en, this message translates to:
  /// **'Draft chapters, add details, publish your work, and grow your presence as a Wreadom author.'**
  String get onboardingWriteBody;

  /// No description provided for @onboardingCommunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Join the conversation'**
  String get onboardingCommunityTitle;

  /// No description provided for @onboardingCommunityBody.
  ///
  /// In en, this message translates to:
  /// **'Share quotes, reviews, posts, and comments with readers and writers across the community.'**
  String get onboardingCommunityBody;

  /// No description provided for @onboardingProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Make Wreadom yours'**
  String get onboardingProfileTitle;

  /// No description provided for @onboardingProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Follow creators, message connections, manage your shelf, and shape a profile readers remember.'**
  String get onboardingProfileBody;

  /// No description provided for @noPostsYetStartSharing.
  ///
  /// In en, this message translates to:
  /// **'No posts yet.\nStart sharing your reading journey!'**
  String get noPostsYetStartSharing;

  /// No description provided for @changeProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Change profile picture'**
  String get changeProfilePicture;

  /// No description provided for @changeCoverPicture.
  ///
  /// In en, this message translates to:
  /// **'Change cover picture'**
  String get changeCoverPicture;

  /// No description provided for @profilePictureUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated.'**
  String get profilePictureUpdated;

  /// No description provided for @coverPictureUpdated.
  ///
  /// In en, this message translates to:
  /// **'Cover picture updated.'**
  String get coverPictureUpdated;

  /// No description provided for @couldNotUpdatePicture.
  ///
  /// In en, this message translates to:
  /// **'Could not update picture: {error}'**
  String couldNotUpdatePicture(String error);

  /// No description provided for @writerWritingEditor.
  ///
  /// In en, this message translates to:
  /// **'Writing Editor'**
  String get writerWritingEditor;

  /// No description provided for @writerContentDetails.
  ///
  /// In en, this message translates to:
  /// **'Content Details'**
  String get writerContentDetails;

  /// No description provided for @writerSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get writerSaving;

  /// No description provided for @writerConvertToDraft.
  ///
  /// In en, this message translates to:
  /// **'Convert to Draft'**
  String get writerConvertToDraft;

  /// No description provided for @writerDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get writerDraft;

  /// No description provided for @writerNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get writerNext;

  /// No description provided for @writerPublish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get writerPublish;

  /// No description provided for @writerChapterTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number} title'**
  String writerChapterTitleHint(int number);

  /// No description provided for @writerChapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get writerChapters;

  /// No description provided for @writerStartWriting.
  ///
  /// In en, this message translates to:
  /// **'Start writing...'**
  String get writerStartWriting;

  /// No description provided for @writerContentIdentity.
  ///
  /// In en, this message translates to:
  /// **'Content identity'**
  String get writerContentIdentity;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @synopsis.
  ///
  /// In en, this message translates to:
  /// **'Synopsis'**
  String get synopsis;

  /// No description provided for @writerTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Give your work a title'**
  String get writerTitleHint;

  /// No description provided for @writerSynopsisHint.
  ///
  /// In en, this message translates to:
  /// **'A short pitch for readers'**
  String get writerSynopsisHint;

  /// No description provided for @writerCoverOptional.
  ///
  /// In en, this message translates to:
  /// **'Cover (optional)'**
  String get writerCoverOptional;

  /// No description provided for @writerUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get writerUploading;

  /// No description provided for @writerUploadCover.
  ///
  /// In en, this message translates to:
  /// **'Upload cover'**
  String get writerUploadCover;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @writerDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Discovery'**
  String get writerDiscovery;

  /// No description provided for @contentType.
  ///
  /// In en, this message translates to:
  /// **'Content type'**
  String get contentType;

  /// No description provided for @contentTypeStory.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get contentTypeStory;

  /// No description provided for @contentTypePoem.
  ///
  /// In en, this message translates to:
  /// **'Poem'**
  String get contentTypePoem;

  /// No description provided for @contentTypeArticle.
  ///
  /// In en, this message translates to:
  /// **'Article'**
  String get contentTypeArticle;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @topicsOptional.
  ///
  /// In en, this message translates to:
  /// **'Topics (optional)'**
  String get topicsOptional;

  /// No description provided for @topicsHint.
  ///
  /// In en, this message translates to:
  /// **'magic, friendship, survival'**
  String get topicsHint;

  /// No description provided for @publishContent.
  ///
  /// In en, this message translates to:
  /// **'Publish Content'**
  String get publishContent;

  /// No description provided for @saveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get saveDraft;

  /// No description provided for @insertImage.
  ///
  /// In en, this message translates to:
  /// **'Insert image'**
  String get insertImage;

  /// No description provided for @insertMedia.
  ///
  /// In en, this message translates to:
  /// **'Insert media'**
  String get insertMedia;

  /// No description provided for @deleteChapterBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the chapter from this draft.'**
  String get deleteChapterBody;

  /// No description provided for @signInBeforeUploadingImages.
  ///
  /// In en, this message translates to:
  /// **'Sign in before uploading images.'**
  String get signInBeforeUploadingImages;

  /// No description provided for @imageInserted.
  ///
  /// In en, this message translates to:
  /// **'Image inserted.'**
  String get imageInserted;

  /// No description provided for @couldNotUploadImage.
  ///
  /// In en, this message translates to:
  /// **'Could not upload image: {error}'**
  String couldNotUploadImage(String error);

  /// No description provided for @signInBeforeUploadingCover.
  ///
  /// In en, this message translates to:
  /// **'Sign in before uploading a cover.'**
  String get signInBeforeUploadingCover;

  /// No description provided for @coverUploaded.
  ///
  /// In en, this message translates to:
  /// **'Cover uploaded.'**
  String get coverUploaded;

  /// No description provided for @couldNotUploadCover.
  ///
  /// In en, this message translates to:
  /// **'Could not upload cover: {error}'**
  String couldNotUploadCover(String error);

  /// No description provided for @writerMediaUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'YouTube, Instagram, or Spotify URL'**
  String get writerMediaUrlLabel;

  /// No description provided for @insert.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get insert;

  /// No description provided for @unsupportedLinksInsertedAsPlainText.
  ///
  /// In en, this message translates to:
  /// **'Unsupported links are inserted as plain text.'**
  String get unsupportedLinksInsertedAsPlainText;

  /// No description provided for @addTitleBeforeSaving.
  ///
  /// In en, this message translates to:
  /// **'Add a title before saving.'**
  String get addTitleBeforeSaving;

  /// No description provided for @writerPublishing.
  ///
  /// In en, this message translates to:
  /// **'Publishing...'**
  String get writerPublishing;

  /// No description provided for @writerSavingDraft.
  ///
  /// In en, this message translates to:
  /// **'Saving draft...'**
  String get writerSavingDraft;

  /// No description provided for @writerPublishedStatus.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get writerPublishedStatus;

  /// No description provided for @storyPublished.
  ///
  /// In en, this message translates to:
  /// **'Story published.'**
  String get storyPublished;

  /// No description provided for @couldNotSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String couldNotSave(String error);

  /// No description provided for @savedOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Saved on device'**
  String get savedOnDevice;

  /// No description provided for @localSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Local save failed'**
  String get localSaveFailed;

  /// No description provided for @follow.
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// No description provided for @unfollow.
  ///
  /// In en, this message translates to:
  /// **'Unfollow'**
  String get unfollow;

  /// No description provided for @signInToContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue.'**
  String get signInToContinueAction;

  /// No description provided for @followActionFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update follow: {error}'**
  String followActionFailed(String error);

  /// No description provided for @startedFollowingYou.
  ///
  /// In en, this message translates to:
  /// **'started following you.'**
  String get startedFollowingYou;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @chapterOverview.
  ///
  /// In en, this message translates to:
  /// **'Chapter overview'**
  String get chapterOverview;

  /// No description provided for @chapterCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 chapter} other{{count} chapters}}'**
  String chapterCount(int count);

  /// No description provided for @addNewChapter.
  ///
  /// In en, this message translates to:
  /// **'Add new chapter'**
  String get addNewChapter;

  /// No description provided for @noContentYet.
  ///
  /// In en, this message translates to:
  /// **'No content yet'**
  String get noContentYet;

  /// No description provided for @editing.
  ///
  /// In en, this message translates to:
  /// **'Editing'**
  String get editing;

  /// No description provided for @wordCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word} other{{count} words}}'**
  String wordCountLabel(int count);

  /// No description provided for @writerSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get writerSaveFailed;

  /// No description provided for @untitledStory.
  ///
  /// In en, this message translates to:
  /// **'Untitled content'**
  String get untitledStory;

  /// No description provided for @publishedBookNotification.
  ///
  /// In en, this message translates to:
  /// **'published \"{title}\".'**
  String publishedBookNotification(String title);

  /// No description provided for @repliedToYourBookComment.
  ///
  /// In en, this message translates to:
  /// **'replied to your content comment.'**
  String get repliedToYourBookComment;

  /// No description provided for @commentedOnYourContent.
  ///
  /// In en, this message translates to:
  /// **'commented on your content.'**
  String get commentedOnYourContent;

  /// No description provided for @reviewedYourBook.
  ///
  /// In en, this message translates to:
  /// **'reviewed your content.'**
  String get reviewedYourBook;

  /// No description provided for @updatedReviewOnYourBook.
  ///
  /// In en, this message translates to:
  /// **'updated a review on your content.'**
  String get updatedReviewOnYourBook;

  /// No description provided for @authorsCannotReviewOwnBook.
  ///
  /// In en, this message translates to:
  /// **'Authors cannot review their own content.'**
  String get authorsCannotReviewOwnBook;

  /// No description provided for @feedTypePost.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get feedTypePost;

  /// No description provided for @feedTypeComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get feedTypeComment;

  /// No description provided for @feedTypeQuote.
  ///
  /// In en, this message translates to:
  /// **'Quote'**
  String get feedTypeQuote;

  /// No description provided for @feedTypeReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get feedTypeReview;

  /// No description provided for @feedTypeTestimony.
  ///
  /// In en, this message translates to:
  /// **'Testimony'**
  String get feedTypeTestimony;

  /// No description provided for @noRatingsYet.
  ///
  /// In en, this message translates to:
  /// **'No ratings yet'**
  String get noRatingsYet;

  /// No description provided for @ratingMetric.
  ///
  /// In en, this message translates to:
  /// **'{rating} rating'**
  String ratingMetric(String rating);

  /// No description provided for @readsMetric.
  ///
  /// In en, this message translates to:
  /// **'{count} reads'**
  String readsMetric(String count);

  /// No description provided for @worksMetric.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 work} other{{count} works}}'**
  String worksMetric(int count);

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpTitle;

  /// No description provided for @helpSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for help topics...'**
  String get helpSearchHint;

  /// No description provided for @helpCategoryReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get helpCategoryReading;

  /// No description provided for @helpCategoryWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get helpCategoryWriting;

  /// No description provided for @helpCategoryDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Discovery'**
  String get helpCategoryDiscovery;

  /// No description provided for @helpCategoryCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get helpCategoryCommunity;

  /// No description provided for @helpCategoryAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get helpCategoryAccount;

  /// No description provided for @helpCategoryCollaboration.
  ///
  /// In en, this message translates to:
  /// **'Collaboration'**
  String get helpCategoryCollaboration;

  /// No description provided for @faqCustomizeReaderQ.
  ///
  /// In en, this message translates to:
  /// **'How do I customize the reader?'**
  String get faqCustomizeReaderQ;

  /// No description provided for @faqCustomizeReaderA.
  ///
  /// In en, this message translates to:
  /// **'Open any book and tap the \'Aa\' icon in the top toolbar. You can change the font size, switch between Serif and Sans fonts, and choose a theme (Light, Sepia, or Dark).'**
  String get faqCustomizeReaderA;

  /// No description provided for @faqOfflineReadingQ.
  ///
  /// In en, this message translates to:
  /// **'Can I read books offline?'**
  String get faqOfflineReadingQ;

  /// No description provided for @faqOfflineReadingA.
  ///
  /// In en, this message translates to:
  /// **'Yes! Tap the download icon on the book details page. Once downloaded, you can access the book from your \'Saved\' tab even without an internet connection.'**
  String get faqOfflineReadingA;

  /// No description provided for @faqBookmarksQ.
  ///
  /// In en, this message translates to:
  /// **'How do bookmarks work?'**
  String get faqBookmarksQ;

  /// No description provided for @faqBookmarksA.
  ///
  /// In en, this message translates to:
  /// **'Wreadom automatically saves your progress as you read. To manually mark a specific spot, tap the bookmark icon in the reader\'s top toolbar.'**
  String get faqBookmarksA;

  /// No description provided for @faqQuoteCommentQ.
  ///
  /// In en, this message translates to:
  /// **'What is \'Quote & Comment\'?'**
  String get faqQuoteCommentQ;

  /// No description provided for @faqQuoteCommentA.
  ///
  /// In en, this message translates to:
  /// **'Highlight any text in a book to see the selection menu. You can \'Quote & Comment\' to share your thoughts on a specific passage with the community.'**
  String get faqQuoteCommentA;

  /// No description provided for @faqStartStoryQ.
  ///
  /// In en, this message translates to:
  /// **'How do I start a new story?'**
  String get faqStartStoryQ;

  /// No description provided for @faqStartStoryA.
  ///
  /// In en, this message translates to:
  /// **'Go to the \'Writer Dashboard\' from your profile menu and tap the \'Add\' icon. This will open the Writer Pad where you can start drafting your first chapter.'**
  String get faqStartStoryA;

  /// No description provided for @faqAutoSaveQ.
  ///
  /// In en, this message translates to:
  /// **'Is there an auto-save feature?'**
  String get faqAutoSaveQ;

  /// No description provided for @faqAutoSaveA.
  ///
  /// In en, this message translates to:
  /// **'Yes, the Writer Pad automatically saves your drafts every 10 seconds. You can see the \'Last Saved\' status at the top of the editor.'**
  String get faqAutoSaveA;

  /// No description provided for @faqPublishWorkQ.
  ///
  /// In en, this message translates to:
  /// **'How do I publish my work?'**
  String get faqPublishWorkQ;

  /// No description provided for @faqPublishWorkA.
  ///
  /// In en, this message translates to:
  /// **'Once your story is ready, tap \'Publish\' in the Writer Pad. You\'ll be asked to provide a title, synopsis, and relevant topics before it goes live for the community.'**
  String get faqPublishWorkA;

  /// No description provided for @faqOrganizeChaptersQ.
  ///
  /// In en, this message translates to:
  /// **'Can I organize chapters?'**
  String get faqOrganizeChaptersQ;

  /// No description provided for @faqOrganizeChaptersA.
  ///
  /// In en, this message translates to:
  /// **'Absolutely! Use the chapter menu (list icon) in the editor to add new chapters, switch between them, or reorder your story structure.'**
  String get faqOrganizeChaptersA;

  /// No description provided for @faqCollaborationQ.
  ///
  /// In en, this message translates to:
  /// **'How do collaborations work?'**
  String get faqCollaborationQ;

  /// No description provided for @faqCollaborationA.
  ///
  /// In en, this message translates to:
  /// **'In the Writer Pad, enable Collaboration and choose a user you follow as a co-author. They receive a request, and once accepted, both authors can edit the content and appear together on the book page.'**
  String get faqCollaborationA;

  /// No description provided for @faqFindBooksQ.
  ///
  /// In en, this message translates to:
  /// **'How do I find new books?'**
  String get faqFindBooksQ;

  /// No description provided for @faqFindBooksA.
  ///
  /// In en, this message translates to:
  /// **'Use the \'Discover\' tab to browse by trending genres like Fantasy, Romance, and Sci-Fi. You can also search specifically for titles or authors.'**
  String get faqFindBooksA;

  /// No description provided for @faqOriginalsQ.
  ///
  /// In en, this message translates to:
  /// **'What are \'Originals\'?'**
  String get faqOriginalsQ;

  /// No description provided for @faqOriginalsA.
  ///
  /// In en, this message translates to:
  /// **'Originals are stories written and published directly by authors within the Wreadom community.'**
  String get faqOriginalsA;

  /// No description provided for @faqInternetArchiveQ.
  ///
  /// In en, this message translates to:
  /// **'What is the Internet Archive integration?'**
  String get faqInternetArchiveQ;

  /// No description provided for @faqInternetArchiveA.
  ///
  /// In en, this message translates to:
  /// **'Wreadom connects to the Internet Archive to give you access to millions of classic books and public domain works alongside community originals.'**
  String get faqInternetArchiveA;

  /// No description provided for @faqDailyTopicQ.
  ///
  /// In en, this message translates to:
  /// **'What is the Daily Topic?'**
  String get faqDailyTopicQ;

  /// No description provided for @faqDailyTopicA.
  ///
  /// In en, this message translates to:
  /// **'Every day, Wreadom features a new writing or discussion prompt. Tap the banner on the Home feed to participate and see what others are sharing.'**
  String get faqDailyTopicA;

  /// No description provided for @faqFollowAuthorQ.
  ///
  /// In en, this message translates to:
  /// **'How do I follow an author?'**
  String get faqFollowAuthorQ;

  /// No description provided for @faqFollowAuthorA.
  ///
  /// In en, this message translates to:
  /// **'Tap on an author\'s name or avatar to visit their public profile, then tap \'Follow\' to see their latest posts and story updates in your feed.'**
  String get faqFollowAuthorA;

  /// No description provided for @faqMessagingQ.
  ///
  /// In en, this message translates to:
  /// **'Can I message other users?'**
  String get faqMessagingQ;

  /// No description provided for @faqMessagingA.
  ///
  /// In en, this message translates to:
  /// **'Yes, you can start direct conversations with other users. Visit their profile or use the \'Messages\' icon on your navigation bar to manage your chats.'**
  String get faqMessagingA;

  /// No description provided for @faqChangeThemeQ.
  ///
  /// In en, this message translates to:
  /// **'How do I change the app theme?'**
  String get faqChangeThemeQ;

  /// No description provided for @faqChangeThemeA.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile -> Menu (top-right) -> Theme. You can choose between Light, Dark, or System default modes.'**
  String get faqChangeThemeA;

  /// No description provided for @faqUpdateProfileQ.
  ///
  /// In en, this message translates to:
  /// **'How do I update my profile?'**
  String get faqUpdateProfileQ;

  /// No description provided for @faqUpdateProfileA.
  ///
  /// In en, this message translates to:
  /// **'In the \'Edit Profile\' section of your settings, you can update your display name, pen name, and bio.'**
  String get faqUpdateProfileA;

  /// No description provided for @faqNotificationsQ.
  ///
  /// In en, this message translates to:
  /// **'Where are my notifications?'**
  String get faqNotificationsQ;

  /// No description provided for @faqNotificationsA.
  ///
  /// In en, this message translates to:
  /// **'Tap the bell icon on the home screen or profile to see updates about likes, comments, and new followers.'**
  String get faqNotificationsA;

  /// No description provided for @faqChangeLanguageQ.
  ///
  /// In en, this message translates to:
  /// **'How do I change the app language?'**
  String get faqChangeLanguageQ;

  /// No description provided for @faqChangeLanguageA.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings -> Language to switch between English and Hindi.'**
  String get faqChangeLanguageA;

  /// No description provided for @faqWhatAreReadsQ.
  ///
  /// In en, this message translates to:
  /// **'What are \'Reads\'?'**
  String get faqWhatAreReadsQ;

  /// No description provided for @faqWhatAreReadsA.
  ///
  /// In en, this message translates to:
  /// **'Reads indicate how many times a story has been viewed. It updates automatically as the community explores your work.'**
  String get faqWhatAreReadsA;

  /// No description provided for @faqTapToSeekQ.
  ///
  /// In en, this message translates to:
  /// **'How does tap-to-seek work in Read Aloud?'**
  String get faqTapToSeekQ;

  /// No description provided for @faqTapToSeekA.
  ///
  /// In en, this message translates to:
  /// **'While \'Read Aloud\' is active, simply tap on any paragraph to jump the voice directly to that section.'**
  String get faqTapToSeekA;

  /// No description provided for @faqShareQuoteImageQ.
  ///
  /// In en, this message translates to:
  /// **'Can I share quotes as images?'**
  String get faqShareQuoteImageQ;

  /// No description provided for @faqShareQuoteImageA.
  ///
  /// In en, this message translates to:
  /// **'Yes! Highlight any text and choose \'Share Quote\' to create a beautiful, shareable image of that passage.'**
  String get faqShareQuoteImageA;

  /// No description provided for @faqReportContentQ.
  ///
  /// In en, this message translates to:
  /// **'How do I report inappropriate content?'**
  String get faqReportContentQ;

  /// No description provided for @faqReportContentA.
  ///
  /// In en, this message translates to:
  /// **'Tap the three-dot menu on any post, comment, or book and select \'Report\'. Our team will review it promptly.'**
  String get faqReportContentA;

  /// No description provided for @faqPinUnpinQ.
  ///
  /// In en, this message translates to:
  /// **'Can I pin my favorite comments?'**
  String get faqPinUnpinQ;

  /// No description provided for @faqPinUnpinA.
  ///
  /// In en, this message translates to:
  /// **'Yes! If you are the author of a post, you can pin a comment to the top of the discussion by tapping the \'Pin\' option in its menu.'**
  String get faqPinUnpinA;

  /// No description provided for @faqMessagingRulesQ.
  ///
  /// In en, this message translates to:
  /// **'Are there rules for messaging?'**
  String get faqMessagingRulesQ;

  /// No description provided for @faqMessagingRulesA.
  ///
  /// In en, this message translates to:
  /// **'To prevent spam, you can only send one message to a new contact. Once they reply, you can chat freely.'**
  String get faqMessagingRulesA;

  /// No description provided for @faqDailyTopicsParticipationQ.
  ///
  /// In en, this message translates to:
  /// **'How do I participate in Daily Topics?'**
  String get faqDailyTopicsParticipationQ;

  /// No description provided for @faqDailyTopicsParticipationA.
  ///
  /// In en, this message translates to:
  /// **'Tap the Daily Topic banner on your home feed. You can read submissions or add your own response to the prompt.'**
  String get faqDailyTopicsParticipationA;

  /// No description provided for @faqFeedUpdatesQ.
  ///
  /// In en, this message translates to:
  /// **'What shows up in my Feed?'**
  String get faqFeedUpdatesQ;

  /// No description provided for @faqFeedUpdatesA.
  ///
  /// In en, this message translates to:
  /// **'Your Feed is a personalized stream of updates from authors you follow, including new posts, reviews, and story chapters.'**
  String get faqFeedUpdatesA;

  /// No description provided for @faqMultiChapterWriterQ.
  ///
  /// In en, this message translates to:
  /// **'Can I write multiple chapters at once?'**
  String get faqMultiChapterWriterQ;

  /// No description provided for @faqMultiChapterWriterA.
  ///
  /// In en, this message translates to:
  /// **'Yes! In the Writer Pad, use the chapters list to create multiple segments of your story. You can save them all as a single draft before publishing.'**
  String get faqMultiChapterWriterA;

  /// No description provided for @faqProfilePicturesQ.
  ///
  /// In en, this message translates to:
  /// **'How do I update my profile and cover images?'**
  String get faqProfilePicturesQ;

  /// No description provided for @faqProfilePicturesA.
  ///
  /// In en, this message translates to:
  /// **'Visit your profile and tap on the camera icons on your avatar or cover photo to upload new images from your device.'**
  String get faqProfilePicturesA;

  /// No description provided for @stillNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Still need help?'**
  String get stillNeedHelp;

  /// No description provided for @communitySupportAssist.
  ///
  /// In en, this message translates to:
  /// **'Our community team is here to assist.'**
  String get communitySupportAssist;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @emailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email support'**
  String get emailSupport;

  /// No description provided for @noHelpTopicsFound.
  ///
  /// In en, this message translates to:
  /// **'No help topics found for \"{query}\"'**
  String noHelpTopicsFound(String query);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

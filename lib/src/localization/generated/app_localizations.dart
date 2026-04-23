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

  /// No description provided for @internetArchivePreparation.
  ///
  /// In en, this message translates to:
  /// **'Internet Archive content can take a moment to prepare.'**
  String get internetArchivePreparation;

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

import 'package:flutter/material.dart';

import '../../domain/models/book.dart';
import '../../domain/models/feed_post.dart';
import '../../utils/app_link_helper.dart';
import '../screens/book_detail_screen.dart';
import '../screens/category_books_screen.dart';
import '../screens/conversation_screen.dart';
import '../screens/daily_topic_screen.dart';
import '../screens/discovery_screen.dart';
import '../screens/follow_list_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_navigation_shell.dart';
import '../screens/notifications_screen.dart';
import '../screens/post_detail_screen.dart';
import '../screens/profile_settings_screen.dart';
import '../screens/public_profile_screen.dart';
import '../screens/reader_screen.dart';
import '../screens/saved_books_screen.dart';
import '../screens/static_info_screen.dart';
import '../screens/writer_dashboard_screen.dart';
import '../screens/writer_pad_screen.dart';
import 'app_routes.dart';

class ReaderArguments {
  const ReaderArguments({required this.book, this.initialChapterIndex = 0});

  final Book book;
  final int initialChapterIndex;
}

class PublicProfileArguments {
  const PublicProfileArguments({required this.userId});

  final String userId;
}

class BookDetailArguments {
  const BookDetailArguments({required this.bookId, this.book});

  final String bookId;
  final Book? book;
}

class ConversationArguments {
  const ConversationArguments({
    required this.conversationId,
    required this.title,
    this.subtitle,
  });

  final String conversationId;
  final String title;
  final String? subtitle;
}

class WriterPadArguments {
  const WriterPadArguments({this.book});

  final Book? book;
}

class PostDetailArguments {
  const PostDetailArguments({required this.postId, this.post});

  final String postId;
  final FeedPost? post;
}

class AppRouter {
  static MaterialPageRoute _notFound([String? message]) {
    return MaterialPageRoute(
      builder: (_) => StaticInfoScreen(
        title: 'Not Found',
        body: message ?? 'The requested page could not be found.',
      ),
    );
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    String? name = settings.name;
    Object? arguments = settings.arguments;

    if (name != null &&
        (name.startsWith('http://') || name.startsWith('https://'))) {
      final resolved = AppLinkHelper.resolve(name);
      if (resolved != null) {
        name = resolved.route;
        arguments = resolved.payload;
      }
    }

    switch (name) {
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.main:
      case AppRoutes.root:
        final initialIndex = (arguments ?? settings.arguments) as int? ?? 0;
        return MaterialPageRoute(
          builder: (_) => MainNavigationShell(initialIndex: initialIndex),
        );
      case AppRoutes.bookDetail:
        final args = arguments ?? settings.arguments;
        String bookId;
        Book? book;

        if (args is Book) {
          bookId = args.id;
          book = args;
        } else if (args is BookDetailArguments) {
          bookId = args.bookId;
          book = args.book;
        } else if (args == null ||
            args.toString().trim().isEmpty ||
            args.toString() == 'null') {
          return _notFound('Book details are missing.');
        } else {
          bookId = args.toString();
        }

        return MaterialPageRoute(
          builder: (_) => BookDetailScreen(bookId: bookId, preloadedBook: book),
        );
      case AppRoutes.reader:
        final argsValue = arguments ?? settings.arguments;
        if (argsValue is! ReaderArguments) {
          return _notFound('Reader details are missing.');
        }
        final args = argsValue;
        return MaterialPageRoute(
          builder: (_) => ReaderScreen(
            book: args.book,
            initialChapterIndex: args.initialChapterIndex,
          ),
        );
      case AppRoutes.publicProfile:
        final argsValue = arguments ?? settings.arguments;
        final args = argsValue is PublicProfileArguments
            ? argsValue
            : PublicProfileArguments(userId: argsValue.toString());
        return MaterialPageRoute(
          builder: (_) => PublicProfileScreen(userId: args.userId),
        );
      case AppRoutes.notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      case AppRoutes.conversation:
        final argsValue = arguments ?? settings.arguments;
        if (argsValue is! ConversationArguments) {
          return _notFound('Conversation details are missing.');
        }
        final args = argsValue;
        return MaterialPageRoute(
          builder: (_) => ConversationScreen(
            conversationId: args.conversationId,
            title: args.title,
            subtitle: args.subtitle,
          ),
        );
      case AppRoutes.writerDashboard:
        return MaterialPageRoute(builder: (_) => const WriterDashboardScreen());
      case AppRoutes.discovery:
        return MaterialPageRoute(
          settings: RouteSettings(
            name: name,
            arguments: arguments ?? settings.arguments,
          ),
          builder: (_) => const DiscoveryScreen(),
        );
      case AppRoutes.writerPad:
        final argsValue = arguments ?? settings.arguments;
        if (argsValue != null && argsValue is! WriterPadArguments) {
          return _notFound('Writer details are missing.');
        }
        final args = argsValue as WriterPadArguments?;
        return MaterialPageRoute(
          builder: (_) => WriterPadScreen(book: args?.book),
        );
      case AppRoutes.postDetail:
        final args = arguments ?? settings.arguments;
        String postId;
        FeedPost? post;

        if (args is FeedPost) {
          postId = args.id ?? '';
          post = args;
        } else if (args is PostDetailArguments) {
          postId = args.postId;
          post = args.post;
        } else if (args == null ||
            args.toString().trim().isEmpty ||
            args.toString() == 'null') {
          return _notFound('Post details are missing.');
        } else {
          postId = args.toString();
        }

        return MaterialPageRoute(
          builder: (_) => PostDetailScreen(postId: postId, preloadedPost: post),
        );
      case AppRoutes.category:
        final args = arguments ?? settings.arguments;
        final category = args is CategoryBooksArguments
            ? args.category
            : args.toString();
        return MaterialPageRoute(
          builder: (_) => CategoryBooksScreen(category: category),
        );
      case AppRoutes.savedBooks:
        return MaterialPageRoute(builder: (_) => const SavedBooksScreen());
      case AppRoutes.followList:
        final argsValue = arguments ?? settings.arguments;
        if (argsValue is! FollowListArguments) {
          return _notFound('Follow list details are missing.');
        }
        final args = argsValue;
        return MaterialPageRoute(
          builder: (_) => FollowListScreen(
            userId: args.userId,
            mode: args.mode,
            title: args.title,
          ),
        );
      case AppRoutes.profileSettings:
        return MaterialPageRoute(builder: (_) => const ProfileSettingsScreen());
      case AppRoutes.help:
        return MaterialPageRoute(
          builder: (_) => const StaticInfoScreen(
            title: 'Help',
            body:
                'Wreadom helps you read, write, connect, and manage your profile from one app. Use the profile settings screen to update privacy and account preferences.',
          ),
        );
      case AppRoutes.privacy:
        return MaterialPageRoute(
          builder: (_) => const StaticInfoScreen(
            title: 'Privacy Policy',
            body: _privacyPolicyBody,
          ),
        );
      case AppRoutes.terms:
        return MaterialPageRoute(
          builder: (_) => const StaticInfoScreen(
            title: 'Terms of Use',
            body: _termsOfUseBody,
          ),
        );
      case AppRoutes.certificate:
        return MaterialPageRoute(
          builder: (_) => const StaticInfoScreen(
            title: 'Certificate',
            body:
                'Participation certificates are supported in the main Wreadom experience. This Flutter build exposes the route and can be expanded to render generated certificates from backend data.',
          ),
        );
      case AppRoutes.dailyTopic:
        final args = arguments ?? settings.arguments;
        String? topicId;
        DailyTopicArguments? topicArgs;
        if (args is DailyTopicArguments) {
          topicArgs = args;
          topicId = args.topicId;
        } else if (args != null && args.toString() != 'null') {
          topicId = args.toString();
        }
        return MaterialPageRoute(
          builder: (_) => DailyTopicScreen(
            topicId: topicId,
            preloadedTopic: topicArgs?.topic,
          ),
        );
      case AppRoutes.competition:
        return MaterialPageRoute(
          builder: (_) => const StaticInfoScreen(
            title: 'Competition',
            body:
                'Competitions and winners can be surfaced from the shared Wreadom backend. This route provides the mobile entry point for that experience.',
          ),
        );
      default:
        return _notFound();
    }
  }
}

const _privacyPolicyBody = r'''Last Updated: February 20, 2026

1. Introduction

Welcome to Wreadom ("we," "our," or "us"). We are committed to protecting your personal information and your right to privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our web application and services (collectively, the "Service").

This Privacy Policy is compliant with the Information Technology Act, 2000, the Information Technology (Reasonable Security Practices and Procedures and Sensitive Personal Data or Information) Rules, 2011, and the Digital Personal Data Protection Act, 2023 (DPDPA).

2. Information We Collect

2.1 Personal Information

We collect the following personal information when you register and use our Service:

- Name and display name
- Email address
- Username and password (encrypted)
- Profile picture (optional)
- Pen name and biography (optional)

2.2 Content Information

- Books, stories, poems, and articles you create or upload
- Comments, reviews, and testimonies you post
- Bookmarks and reading history
- Feed posts and social interactions

2.3 Usage Information

- Device information (browser type, operating system)
- IP address and general location data
- Reading preferences and settings
- Usage patterns and analytics

3. How We Use Your Information

We use your information for the following purposes:

- To provide, maintain, and improve our Service
- To create and manage your account
- To enable you to read, write, and publish content
- To facilitate social features (following, testimonies, feed)
- To personalize your reading experience
- To communicate with you about updates and features
- To ensure security and prevent fraud
- To comply with legal obligations

4. Data Sharing and Disclosure

4.1 Public Information

Your published works, public profile information, comments, and feed posts are visible to other users based on your privacy settings.

4.2 Service Providers

We use third-party service providers including:

- Google Firebase (for authentication and database hosting)
- Vercel (for hosting)
- Internet Archive (for accessing public domain books)

4.3 Legal Requirements

We may disclose your information if required by law, court order, or government authority, or to protect our rights and safety.

5. Data Storage and Security

We implement industry-standard security measures to protect your personal information, including:

- Encryption of data in transit using SSL/TLS
- Secure authentication through Firebase Auth
- Regular security audits and updates
- Access controls and authentication requirements

Your data is stored on secure servers maintained by Google Firebase, which complies with international security standards.

6. Your Rights Under Indian Law

Under the DPDPA 2023 and IT Act 2000, you have the following rights:

- Right to Access: You can access your personal data through your account settings
- Right to Correction: You can update or correct your information at any time
- Right to Erasure: You can request deletion of your account and data
- Right to Data Portability: You can request a copy of your data in a portable format
- Right to Withdraw Consent: You can withdraw consent for data processing
- Right to Grievance Redressal: You can file complaints regarding data handling

7. Cookies and Tracking

We use browser storage (sessionStorage and localStorage) to enhance your experience by:

- Remembering your login session
- Saving your reader preferences
- Maintaining your reading position
- Persisting your application state

8. Children's Privacy

Our Service is not directed to individuals under the age of 13. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.

9. Data Retention

We retain your personal information for as long as your account is active or as needed to provide you services. You may request deletion of your account at any time, after which we will delete or anonymize your data within 30 days, except where we are required to retain it for legal purposes.

10. International Data Transfers

Your information may be transferred to and processed in countries other than India. We ensure appropriate safeguards are in place to protect your data in accordance with this Privacy Policy and applicable laws.

11. Changes to This Privacy Policy

We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date. Your continued use of the Service after any changes constitutes acceptance of the updated Privacy Policy.

12. Grievance Officer

In accordance with the Information Technology Act, 2000, and the DPDPA 2023, we have appointed a Grievance Officer to address your concerns regarding data protection and privacy:

Name: S. Menaria
Email: smenaria2@gmail.com
Response Time: Within 30 days of receiving a complaint

13. Contact Us

If you have any questions about this Privacy Policy or our data practices, please contact us at:

Email: smenaria2@gmail.com''';

const _termsOfUseBody = r'''Last Updated: February 20, 2026

1. Acceptance of Terms

Welcome to Wreadom. By accessing or using our Service, you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, please do not use our Service.

These Terms constitute a legally binding agreement under the Indian Contract Act, 1872, between you and Wreadom. The Service is governed by the laws of India, and disputes shall be subject to the exclusive jurisdiction of courts in Rajasthan, India only.

2. Definitions

- "Service" refers to the Wreadom web application and all associated features
- "User," "you," "your" refers to the individual accessing or using the Service
- "Content" refers to text, images, comments, reviews, and other materials
- "Original Works" refers to stories, poems, articles created by users
- "We," "us," "our" refers to Wreadom and its operators

3. Eligibility

To use our Service, you must:

- Be at least 13 years of age
- Have the legal capacity to enter into a binding contract
- Not be prohibited from using the Service under Indian law
- Provide accurate and complete registration information

If you are between 13 and 18 years of age, you may only use the Service under the supervision of a parent or legal guardian who agrees to be bound by these Terms.

4. User Accounts

4.1 Account Creation

You must create an account to access certain features. You are responsible for:

- Maintaining the confidentiality of your password
- All activities that occur under your account
- Notifying us immediately of any unauthorized use

4.2 Account Termination

We reserve the right to suspend or terminate your account if you violate these Terms or engage in conduct that we deem inappropriate or harmful to the Service or other users.

5. Intellectual Property Rights

5.1 Your Content

You retain all ownership rights to the Original Works and other content you create and publish on Wreadom. By publishing content, you grant us a non-exclusive, worldwide, royalty-free license to:

- Display, distribute, and promote your content on our Service
- Make your published works available to other users
- Create derivative works for the purpose of formatting and displaying content

You represent and warrant that you own or have the necessary rights to all content you publish and that your content does not infringe upon the intellectual property rights of any third party.

5.2 Our Content

The Service itself, including its design, functionality, text, graphics, logos, and software, is owned by Wreadom and protected under the Copyright Act, 1957, and other applicable intellectual property laws. You may not copy, modify, distribute, or reverse engineer any part of our Service without our written permission.

5.3 Third-Party Content

We provide access to public domain books from Internet Archive and other sources. We do not claim ownership of these works and they remain subject to their respective copyright status.

6. User Conduct and Prohibited Activities

You agree NOT to:

- Publish content that is illegal, harmful, threatening, abusive, defamatory, obscene, or otherwise objectionable
- Infringe upon the intellectual property rights of others
- Impersonate any person or entity or misrepresent your affiliation
- Harass, bully, or harm other users
- Distribute spam, viruses, or malicious code
- Attempt to gain unauthorized access to our systems
- Use automated tools (bots, scrapers) without our permission
- Violate any applicable laws or regulations of India
- Engage in any activity that disrupts or interferes with the Service

7. Content Moderation

We reserve the right, but are not obligated, to:

- Monitor and review user-generated content
- Remove or modify content that violates these Terms
- Take action against users who violate these Terms

In compliance with the Information Technology (Intermediary Guidelines and Digital Media Ethics Code) Rules, 2021, we will make reasonable efforts to remove unlawful content upon receiving actual knowledge or notification.

8. Privacy and Data Protection

Your use of the Service is also governed by our Privacy Policy, which explains how we collect, use, and protect your personal information in compliance with the Digital Personal Data Protection Act, 2023, and the Information Technology Act, 2000. By using the Service, you consent to our data practices as described in the Privacy Policy.

9. Copyright Infringement

We respect intellectual property rights and expect our users to do the same. If you believe your copyright has been infringed, please contact us with:

- Identification of the copyrighted work
- Identification of the infringing material
- Your contact information
- A statement of good faith belief that the use is unauthorized
- A statement of accuracy under penalty of perjury

Send notices to: smenaria2@gmail.com

10. Disclaimer of Warranties

THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO:

- Warranties of merchantability or fitness for a particular purpose
- Warranties that the Service will be uninterrupted or error-free
- Warranties regarding the accuracy or reliability of content

11. Limitation of Liability

To the fullest extent permitted by law, Wreadom shall not be liable for any indirect, incidental, special, consequential, or punitive damages arising out of or relating to your use of the Service, including but not limited to:

- Loss of data or content
- Loss of profits or revenue
- Personal injury or property damage
- Third-party claims

Our total liability shall not exceed Rs. 1,000 (One Thousand Rupees) or the amount you paid us in the last 12 months, whichever is greater.

12. Indemnification

You agree to indemnify, defend, and hold harmless Wreadom, its officers, directors, employees, and agents from any claims, damages, losses, liabilities, and expenses (including legal fees) arising out of:

- Your use of the Service
- Your violation of these Terms
- Your violation of any third-party rights
- Content you publish on the Service

13. Dispute Resolution

13.1 Governing Law

These Terms shall be governed by and construed in accordance with the laws of India, without regard to conflict of law principles.

13.2 Jurisdiction

Any disputes arising out of or relating to these Terms or the Service shall be subject to the exclusive jurisdiction of the courts in Rajasthan, India.

13.3 Arbitration

Before filing any lawsuit, you agree to attempt to resolve disputes through good faith negotiations. If negotiations fail, disputes may be resolved through binding arbitration in accordance with the Arbitration and Conciliation Act, 1996.

14. Changes to Terms

We reserve the right to modify these Terms at any time. We will notify you of material changes by posting the updated Terms on the Service and updating the "Last Updated" date. Your continued use of the Service after such changes constitutes your acceptance of the modified Terms.

15. Termination

We may terminate or suspend your access to the Service immediately, without prior notice, for any reason, including but not limited to:

- Violation of these Terms
- Fraudulent or illegal activity
- Extended period of inactivity
- Request by law enforcement or government authority

Upon termination, your right to use the Service will cease immediately. We may, but are not obligated to, delete your account and content.

16. Severability

If any provision of these Terms is found to be unlawful, void, or unenforceable, that provision shall be deemed severable and shall not affect the validity and enforceability of the remaining provisions.

17. Entire Agreement

These Terms, along with our Privacy Policy, constitute the entire agreement between you and Wreadom regarding the use of the Service and supersede all prior agreements and understandings.

18. Contact Information

If you have any questions about these Terms, please contact us:

Email: smenaria2@gmail.com

Important Notice:

By using Wreadom, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service and our Privacy Policy.''';

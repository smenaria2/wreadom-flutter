import 'package:flutter_riverpod/flutter_riverpod.dart';

class WriterTaxonomy {
  const WriterTaxonomy({
    required this.categoriesByType,
    required this.contentTypes,
    required this.languages,
    required this.contentTypeDefaults,
  });

  final Map<String, List<String>> categoriesByType;
  final List<String> contentTypes;
  final List<String> languages;
  final Map<String, String> contentTypeDefaults;

  List<String> get allCategories =>
      categoriesByType.values.expand((categories) => categories).toSet().toList();

  List<String> categoriesFor(String contentType) {
    return categoriesByType[contentType] ?? const <String>[];
  }

  String defaultCategoryFor(String contentType) {
    return contentTypeDefaults[contentType] ?? 'Other';
  }
}

final writerTaxonomyProvider = Provider<WriterTaxonomy>((ref) {
  return const WriterTaxonomy(
    categoriesByType: {
      'story': [
        'Romance',
        'Mystery',
        'Thriller',
        'Science Fiction',
        'Fantasy',
        'Horror',
        'Adventure',
        'Historical Fiction',
        'Young Adult',
        'Literary Fiction',
        'Comedy',
        'Drama',
        'Crime',
        'Stories',
        'Fan Fiction',
        'Other',
      ],
      'poem': [
        'Lyrical',
        'Narrative',
        'Haiku',
        'Free Verse',
        'Sonnet',
        'Ghazal',
        'Blank Verse',
        'Ode',
        'Elegy',
        'Ballad',
        'Prose Poetry',
        'Spoken Word',
        'Visual Poetry',
        'Acrostic',
        'Experimental',
        'Other',
      ],
      'article': [
        'Technology',
        'Science',
        'Health',
        'Education',
        'Business',
        'Politics',
        'Travel',
        'Lifestyle',
        'Personal Development',
        'Finance',
        'Environment',
        'Arts & Culture',
        'Food & Cooking',
        'Sports',
        'History',
        'Other',
      ],
    },
    contentTypes: ['story', 'poem', 'article'],
    languages: [
      'English',
      'Hindi',
      'Bengali',
      'Telugu',
      'Marathi',
      'Tamil',
      'Gujarati',
      'Urdu',
      'Kannada',
      'Malayalam',
      'Arabic',
      'French',
      'German',
      'Spanish',
      'Portuguese',
      'Russian',
      'Chinese',
      'Japanese',
      'Korean',
    ],
    contentTypeDefaults: {
      'story': 'Romance',
      'poem': 'Lyrical',
      'article': 'Technology',
    },
  );
});

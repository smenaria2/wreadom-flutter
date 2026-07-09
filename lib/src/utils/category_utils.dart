import 'package:flutter/material.dart';

String getLocalizedCategory(BuildContext context, String category) {
  final locale = Localizations.localeOf(context).languageCode;
  final isHindi = locale == 'hi';
  final normalized = category.trim().toLowerCase();

  if (isHindi) {
    const hindiMap = {
      // Stories
      'romance': 'प्रेम',
      'mystery': 'रहस्य',
      'thriller': 'थ्रिलर',
      'science fiction': 'विज्ञान',
      'fantasy': 'फैंटसी',
      'horror': 'हॉरर',
      'adventure': 'रोमांच',
      'historical fiction': 'ऐतिहासिक',
      'young adult': 'कॉलेज-लाइफ',
      'literary fiction': 'क्लासिक',
      'comedy': 'हास्य',
      'drama': 'नाटक',
      'crime': 'अपराध',
      'stories': 'लघुकथा',
      'fan fiction': 'फैन-फिक्शन',

      // Poems
      'lyrical': 'गीत',
      'narrative': 'कथा-काव्य',
      'haiku': 'हाइकु',
      'free verse': 'मुक्तक',
      'sonnet': 'छंद',
      'ghazal': 'ग़ज़ल',
      'blank verse': 'अतुकांत',
      'ode': 'प्रशंसा',
      'elegy': 'शोकगीत',
      'ballad': 'लोकगीत',
      'prose poetry': 'गद्य-काव्य',
      'spoken word': 'कवि-सम्मेलन',
      'visual poetry': 'दृश्य-काव्य',
      'acrostic': 'पहेली',
      'experimental': 'प्रायोगिक',

      // Articles
      'technology': 'तकनीक',
      'science': 'विज्ञान',
      'health': 'स्वास्थ्य',
      'education': 'शिक्षा',
      'business': 'व्यापार',
      'politics': 'राजनीति',
      'travel': 'यात्रा',
      'lifestyle': 'जीवनशैली',
      'personal development': 'आत्म-विकास',
      'finance': 'वित्त',
      'environment': 'पर्यावरण',
      'arts & culture': 'संस्कृति',
      'food & cooking': 'खान-पान',
      'sports': 'खेल',
      'history': 'इतिहास',
      'other': 'अन्य',
    };
    return hindiMap[normalized] ?? category;
  } else {
    const englishMap = {
      // Stories
      'romance': 'Romance',
      'mystery': 'Mystery',
      'thriller': 'Thriller',
      'science fiction': 'Sci-Fi',
      'fantasy': 'Fantasy',
      'horror': 'Horror',
      'adventure': 'Adventure',
      'historical fiction': 'History',
      'young adult': 'Youth',
      'literary fiction': 'Classic',
      'comedy': 'Comedy',
      'drama': 'Drama',
      'crime': 'Crime',
      'stories': 'Stories',
      'fan fiction': 'Fanfiction',

      // Poems
      'lyrical': 'Song',
      'narrative': 'Narrative',
      'haiku': 'Haiku',
      'free verse': 'Freeverse',
      'sonnet': 'Verse',
      'ghazal': 'Ghazal',
      'blank verse': 'Blankverse',
      'ode': 'Praise',
      'elegy': 'Mourning',
      'ballad': 'Folk',
      'prose poetry': 'Prose',
      'spoken word': 'Spoken',
      'visual poetry': 'Visual',
      'acrostic': 'Acrostic',
      'experimental': 'Experimental',

      // Articles
      'technology': 'Tech',
      'science': 'Science',
      'health': 'Health',
      'education': 'Education',
      'business': 'Business',
      'politics': 'Politics',
      'travel': 'Travel',
      'lifestyle': 'Lifestyle',
      'personal development': 'Growth',
      'finance': 'Finance',
      'environment': 'Environment',
      'arts & culture': 'Culture',
      'food & cooking': 'Food',
      'sports': 'Sports',
      'history': 'History',
      'other': 'Other',
    };
    return englishMap[normalized] ?? _titleCase(category);
  }
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value
      .split(RegExp(r'[\s_-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

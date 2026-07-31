import 'package:flutter/foundation.dart';

@immutable
class AttributionLink {
  const AttributionLink({
    required this.label,
    required this.url,
  });

  final String label;
  final String url;
}

@immutable
class AttributionItem {
  const AttributionItem({
    required this.id,
    required this.name,
    required this.purpose,
    required this.credit,
    required this.licenseName,
    this.licenseUrl,
    required this.links,
    this.disclaimer,
  });

  final String id;
  final String name;
  final String purpose;
  final String credit;
  final String licenseName;
  final String? licenseUrl;
  final List<AttributionLink> links;
  final String? disclaimer;
}

class AttributionCatalog {
  static const List<AttributionItem> items = [
    AttributionItem(
      id: 'dictionary',
      name: 'Dictionary & Word Definitions',
      purpose: 'In-app word definition lookups for readers',
      credit: 'FreeDictionaryAPI.com & Wiktionary contributors',
      licenseName: 'CC BY-SA 4.0',
      licenseUrl: 'https://creativecommons.org/licenses/by-sa/4.0/',
      links: [
        AttributionLink(
          label: 'FreeDictionaryAPI',
          url: 'https://freedictionaryapi.com/',
        ),
        AttributionLink(
          label: 'Wiktionary',
          url: 'https://www.wiktionary.org',
        ),
        AttributionLink(
          label: 'CC BY-SA 4.0 License',
          url: 'https://creativecommons.org/licenses/by-sa/4.0/',
        ),
      ],
      disclaimer: 'Data provided by Wiktionary via FreeDictionaryAPI.com.',
    ),
    AttributionItem(
      id: 'dakshina',
      name: 'Hindi Transliteration Dataset',
      purpose: 'Dakshina Dataset v1.0 for Hindi text transliteration',
      credit: 'Google Research (Roark et al.)',
      licenseName: 'CC BY-SA 4.0',
      licenseUrl: 'https://creativecommons.org/licenses/by-sa/4.0/',
      links: [
        AttributionLink(
          label: 'Dakshina Dataset Repository',
          url: 'https://github.com/google-research-datasets/dakshina',
        ),
        AttributionLink(
          label: 'CC BY-SA 4.0 License',
          url: 'https://creativecommons.org/licenses/by-sa/4.0/',
        ),
      ],
    ),
    AttributionItem(
      id: 'devlipi',
      name: 'Devlipi Transliteration Engine',
      purpose: 'Devanagari script transliteration utilities',
      credit: '© 2025 JBDEV',
      licenseName: 'MIT License',
      licenseUrl: 'https://pub.dev/packages/devlipi/license',
      links: [
        AttributionLink(
          label: 'Devlipi Package',
          url: 'https://pub.dev/packages/devlipi',
        ),
        AttributionLink(
          label: 'MIT License',
          url: 'https://pub.dev/packages/devlipi/license',
        ),
      ],
    ),
    AttributionItem(
      id: 'typography',
      name: 'Typography & Typefaces',
      purpose: 'App typography (Plus Jakarta Sans, Noto Sans Devanagari, Dancing Script, Cormorant Garamond, Inter, Caveat)',
      credit: 'Respective font authors & Google Fonts',
      licenseName: 'SIL Open Font License 1.1 (OFL-1.1)',
      licenseUrl: 'http://scripts.sil.org/OFL',
      links: [
        AttributionLink(
          label: 'SIL OFL 1.1 Specification',
          url: 'http://scripts.sil.org/OFL',
        ),
      ],
    ),
    AttributionItem(
      id: 'media_sources',
      name: 'Media & Content Discovery',
      purpose: 'Cover-image search & public domain book discovery',
      credit: 'Unsplash & Internet Archive',
      licenseName: 'Platform Terms & Public Domain',
      links: [
        AttributionLink(
          label: 'Unsplash',
          url: 'https://unsplash.com',
        ),
        AttributionLink(
          label: 'Internet Archive',
          url: 'https://archive.org',
        ),
      ],
      disclaimer: 'Cover image search powered by Unsplash. Public domain book discovery enabled via Internet Archive without blanket claims on individual works.',
    ),
  ];
}

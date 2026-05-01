class HomeBanner {
  const HomeBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.coverImageUrl,
    required this.buttonText,
    required this.buttonLink,
    required this.isEnabled,
    required this.timestamp,
    required this.lastUpdated,
  });

  final String id;
  final String title;
  final String subtitle;
  final String body;
  final String coverImageUrl;
  final String buttonText;
  final String buttonLink;
  final bool isEnabled;
  final int timestamp;
  final int lastUpdated;

  factory HomeBanner.fromJson(Map<String, dynamic> json) {
    return HomeBanner(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      coverImageUrl: json['coverImageUrl']?.toString() ?? '',
      buttonText: json['buttonText']?.toString() ?? '',
      buttonLink: json['buttonLink']?.toString() ?? '',
      isEnabled: json['isEnabled'] != false,
      timestamp: _timestampToMillis(json['timestamp']) ?? 0,
      lastUpdated: _timestampToMillis(json['lastUpdated']) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'body': body,
    'coverImageUrl': coverImageUrl,
    'buttonText': buttonText,
    'buttonLink': buttonLink,
    'isEnabled': isEnabled,
    'timestamp': timestamp,
    'lastUpdated': lastUpdated,
  };

  int get sortTimestamp => timestamp == 0 ? lastUpdated : timestamp;
}

int? _timestampToMillis(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  try {
    final milliseconds = value.millisecondsSinceEpoch;
    if (milliseconds is int) return milliseconds;
  } catch (_) {
    return null;
  }
  return null;
}

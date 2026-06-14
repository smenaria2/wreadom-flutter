import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ParticipationCertificate extends StatelessWidget {
  const ParticipationCertificate({
    super.key,
    required this.userName,
    required this.userPhotoUrl,
    required this.topicName,
    required this.date,
    this.bookCoverUrl,
  });

  final String userName;
  final String? userPhotoUrl;
  final String topicName;
  final String date;
  final String? bookCoverUrl;

  @override
  Widget build(BuildContext context) {
    final displayName = userName.trim().isEmpty ? 'User' : userName.trim();
    return Material(
      color: Colors.white,
      child: Container(
        width: 842,
        height: 595,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFC5A059), width: 16),
        ),
        child: Stack(
          children: [
            if (bookCoverUrl != null && bookCoverUrl!.isNotEmpty)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.05,
                  child: CachedNetworkImage(
                    imageUrl: bookCoverUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const SizedBox.shrink(),
                  ),
                ),
              ),
            for (final alignment in const [
              Alignment.topLeft,
              Alignment.topRight,
              Alignment.bottomLeft,
              Alignment.bottomRight,
            ])
              Align(
                alignment: alignment,
                child: Container(
                  width: 128,
                  height: 128,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: alignment.y < 0
                          ? const BorderSide(color: Color(0xFFC5A059), width: 8)
                          : BorderSide.none,
                      bottom: alignment.y > 0
                          ? const BorderSide(color: Color(0xFFC5A059), width: 8)
                          : BorderSide.none,
                      left: alignment.x < 0
                          ? const BorderSide(color: Color(0xFFC5A059), width: 8)
                          : BorderSide.none,
                      right: alignment.x > 0
                          ? const BorderSide(color: Color(0xFFC5A059), width: 8)
                          : BorderSide.none,
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 40,
              right: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'DATE',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(72, 32, 72, 128),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/app_logo.png',
                          width: 56,
                          height: 56,
                        ),
                        const SizedBox(width: 16),
                        ClipOval(
                          child: Image.asset(
                            'assets/images/agaaz_logo.jpg',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'CERTIFICATE',
                      style: TextStyle(
                        color: Color(0xFF8B6B23),
                        fontSize: 34,
                        fontFamily: 'Serif',
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                      ),
                    ),
                    const Text(
                      'OF PARTICIPATION',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'This is to certify that',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 14),
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: const Color(0xFFFF8A65),
                      backgroundImage:
                          userPhotoUrl != null && userPhotoUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(userPhotoUrl!)
                          : null,
                      child: userPhotoUrl == null || userPhotoUrl!.isEmpty
                          ? Text(
                              displayName.characters.first.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(42, 0, 42, 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Color(0x55C5A059),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 30,
                          fontFamily: 'Serif',
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'has successfully participated in the',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      topicName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const SizedBox(
                      width: 470,
                      child: Text(
                        '"We appreciate your participation and your contribution to the spirit of literature through your writing."',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                          height: 1.45,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 40,
              bottom: 30,
              child: _CertificateSignature(
                name: "Shraddha 'Meera'",
                title: 'Agaaz Admin',
              ),
            ),
            Positioned(
              right: 40,
              bottom: 30,
              child: _CertificateSignature(
                name: 'Sumit Menaria',
                title: 'Wreadom Admin',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatCertificateDateFromMillis(int? millis) {
  final date = millis == null
      ? DateTime.now()
      : DateTime.fromMillisecondsSinceEpoch(millis);
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class _CertificateSignature extends StatelessWidget {
  const _CertificateSignature({required this.name, required this.title});

  final String name;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 172,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: -0.05,
            child: Text(
              name,
              style: GoogleFonts.dancingScript(
                color: const Color(0xCC4338CA),
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(
            width: 132,
            child: Divider(color: Color(0xFFE2E8F0), height: 12),
          ),
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

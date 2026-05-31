import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialLinksMenu extends StatelessWidget {
  const SocialLinksMenu({super.key});

  static const String whatsappUrl = 'https://whatsapp.com/channel/0029VaA0ZIDCnA7r1tXCQJ0L';
  static const String instagramUrl = 'https://www.instagram.com/wreadom.in?igsh=N3J6N3I3dTNwNGI5&utm_source=qr';

  Future<void> _launch(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('Could not open link: $url')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error opening link: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          dense: true,
          leading: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xFF25D366),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.phone,
              color: Colors.white,
              size: 13,
            ),
          ),
          title: const Text(
            'WhatsApp',
            style: TextStyle(fontSize: 13.5),
          ),
          subtitle: const Text(
            'Join our channel',
            style: TextStyle(fontSize: 11.5),
          ),
          onTap: () => _launch(context, whatsappUrl),
        ),
        ListTile(
          dense: true,
          leading: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0xFFFFE57F),
                  Color(0xFFF50057),
                  Color(0xFFD500F9),
                ],
                center: Alignment.bottomLeft,
                radius: 1.0,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.camera_alt_rounded,
              color: Colors.white,
              size: 13,
            ),
          ),
          title: const Text(
            'Instagram',
            style: TextStyle(fontSize: 13.5),
          ),
          subtitle: const Text(
            'Follow @wreadom.in',
            style: TextStyle(fontSize: 11.5),
          ),
          onTap: () => _launch(context, instagramUrl),
        ),
      ],
    );
  }
}

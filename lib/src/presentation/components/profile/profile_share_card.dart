import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/models/user_model.dart';
import '../../../utils/app_link_helper.dart';
import '../../../utils/format_utils.dart';

Future<void> shareUserProfileCard(
  BuildContext context, {
  required UserModel user,
  required int worksCount,
  required String fallbackText,
}) async {
  final boundaryKey = GlobalKey();
  final overlay = Overlay.of(context);
  late final OverlayEntry entry;

  entry = OverlayEntry(
    builder: (_) => Positioned(
      left: -2000,
      top: 0,
      child: RepaintBoundary(
        key: boundaryKey,
        child: Material(
          color: Colors.transparent,
          child: ProfileShareCard(user: user, worksCount: worksCount),
        ),
      ),
    ),
  );

  try {
    overlay.insert(entry);
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    final image = await boundary?.toImage(pixelRatio: 2.0);
    final bytes = await image
        ?.toByteData(format: ui.ImageByteFormat.png)
        .then((data) => data?.buffer.asUint8List());
    final displayName = _displayName(user);

    if (bytes == null || bytes.isEmpty) {
      await Share.share(fallbackText, subject: '$displayName on Wreadom');
      return;
    }

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: '${_safeFilePart(user.username)}-profile-card.png',
          mimeType: 'image/png',
        ),
      ],
      text: AppLinkHelper.user(user.id),
      subject: '$displayName on Wreadom',
    );
  } catch (_) {
    await Share.share(
      fallbackText,
      subject: '${_displayName(user)} on Wreadom',
    );
  } finally {
    entry.remove();
  }
}

class ProfileShareCard extends StatelessWidget {
  const ProfileShareCard({
    super.key,
    required this.user,
    required this.worksCount,
  });

  final UserModel user;
  final int worksCount;

  @override
  Widget build(BuildContext context) {
    final name = _displayName(user);
    final penName = user.penName?.trim();
    final bio = user.bio?.trim();

    return SizedBox(
      width: 1050,
      height: 600,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 40,
              top: 40,
              right: 40,
              bottom: 40,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 380,
              top: 100,
              bottom: 100,
              child: Container(
                width: 1,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            Positioned(
              left: 90,
              top: 160,
              child: _ProfileCardAvatar(user: user, name: name),
            ),
            Positioned(
              left: 90,
              top: 462,
              width: 240,
              child: Text(
                'Wreadom',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.28),
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Positioned(
              left: 430,
              top: 118,
              right: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 72,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (penName != null &&
                      penName.isNotEmpty &&
                      penName != name) ...[
                    const SizedBox(height: 16),
                    Text(
                      '($penName)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.64),
                        fontSize: 32,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFFA5B4FC),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${FormatUtils.formatNumber(user.totalPoints ?? 0)} POINTS',
                        style: const TextStyle(
                          color: Color(0xFFA5B4FC),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  if (bio != null && bio.isNotEmpty) ...[
                    const SizedBox(height: 34),
                    Text(
                      bio,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 24,
                        height: 1.34,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 430,
              right: 80,
              bottom: 92,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _CardStat(
                    label: 'Followers',
                    value: user.followersCount ?? 0,
                  ),
                  _CardStat(label: 'Works', value: worksCount),
                  _CardStat(
                    label: 'Following',
                    value: user.followingCount ?? 0,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 80,
              bottom: 70,
              child: Text(
                'OFFICIAL LITERARY PROFILE - WREADOM.IN',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.34),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCardAvatar extends StatelessWidget {
  const _ProfileCardAvatar({required this.user, required this.name});

  final UserModel user;
  final String name;

  @override
  Widget build(BuildContext context) {
    final photoUrl = user.photoURL;
    return Container(
      width: 240,
      height: 240,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: CircleAvatar(
        backgroundColor: Colors.white,
        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
            ? CachedNetworkImageProvider(photoUrl)
            : null,
        child: photoUrl == null || photoUrl.isEmpty
            ? Text(
                name.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF4F46E5),
                  fontSize: 100,
                  fontWeight: FontWeight.w900,
                ),
              )
            : null,
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  const _CardStat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          FormatUtils.formatNumber(value),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.44),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

String _displayName(UserModel user) {
  final displayName = user.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) return displayName;
  final penName = user.penName?.trim();
  if (penName != null && penName.isNotEmpty) return penName;
  return user.username;
}

String _safeFilePart(String value) {
  final safe = value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return safe.isEmpty ? 'wreadom' : safe;
}

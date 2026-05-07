import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
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
  final l10n = AppLocalizations.of(context)!;
  final displayName = _displayName(user);
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
    if (bytes == null || bytes.isEmpty) {
      await Share.share(
        fallbackText,
        subject: l10n.shareProfileSubject(displayName),
      );
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
      subject: l10n.shareProfileSubject(displayName),
    );
  } catch (_) {
    await Share.share(
      fallbackText,
      subject: l10n.shareProfileSubject(displayName),
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
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: 1050,
      height: 600,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF4),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFFFBF4),
              const Color(0xFFF2E7D3),
              const Color(0xFFE9F0EE),
            ],
          ),
          border: Border.all(
            color: const Color(0xFF243447).withValues(alpha: 0.18),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 34,
              top: 34,
              right: 34,
              bottom: 34,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: const Color(0xFFB8893A).withValues(alpha: 0.24),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 370,
              top: 74,
              bottom: 74,
              child: Container(
                width: 1,
                color: const Color(0xFFB8893A).withValues(alpha: 0.35),
              ),
            ),
            Positioned(
              left: 92,
              top: 126,
              child: _ProfileCardAvatar(user: user, name: name),
            ),
            Positioned(
              left: 80,
              top: 408,
              width: 240,
              child: Column(
                children: [
                  Text(
                    l10n.wreadomCreator.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF8E6425),
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 86,
                    height: 2,
                    color: const Color(0xFFB8893A).withValues(alpha: 0.55),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'wreadom.in',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF243447),
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 430,
              top: 88,
              right: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF172536),
                      fontSize: 66,
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
                        color: const Color(0xFF48606D).withValues(alpha: 0.9),
                        fontSize: 30,
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
                          color: const Color(0xFF1D6F6A).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFF1D6F6A,
                            ).withValues(alpha: 0.24),
                          ),
                        ),
                        child: const Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFF1D6F6A),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        l10n.wreadomCreator.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF1D6F6A),
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
                        color: const Color(0xFF243447).withValues(alpha: 0.78),
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
              right: 72,
              bottom: 82,
              child: Row(
                children: [
                  Expanded(
                    child: _CardStat(
                      label: l10n.followers,
                      value: user.followersCount ?? 0,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _CardStat(label: l10n.works, value: worksCount),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _CardStat(
                      label: l10n.following,
                      value: user.followingCount ?? 0,
                    ),
                  ),
                ],
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
      width: 236,
      height: 236,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFFBF4),
        border: Border.all(color: const Color(0xFFB8893A), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: const Color(0xFFE9F0EE),
        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
            ? CachedNetworkImageProvider(photoUrl)
            : null,
        child: photoUrl == null || photoUrl.isEmpty
            ? Text(
                name.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF1D6F6A),
                  fontSize: 96,
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF243447).withValues(alpha: 0.11),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              FormatUtils.formatNumber(value),
              style: const TextStyle(
                color: Color(0xFF172536),
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: const Color(0xFF243447).withValues(alpha: 0.56),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
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

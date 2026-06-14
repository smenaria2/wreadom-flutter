import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as image_codec;
import 'package:librebook_flutter/src/localization/generated/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/models/book.dart';
import '../../../domain/models/leaf_attachment.dart';
import '../../../utils/app_link_helper.dart';
import 'participation_certificate.dart';

void showCertificateLeaf(
  BuildContext context, {
  required Book book,
  required LeafAttachment leaf,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _CertificateLeafViewer(book: book, leaf: leaf),
    ),
  );
}

class _CertificateLeafViewer extends StatefulWidget {
  const _CertificateLeafViewer({required this.book, required this.leaf});

  final Book book;
  final LeafAttachment leaf;

  @override
  State<_CertificateLeafViewer> createState() => _CertificateLeafViewerState();
}

class _CertificateLeafViewerState extends State<_CertificateLeafViewer> {
  final GlobalKey _certificateKey = GlobalKey();
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    final certificate = _certificate();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Share certificate',
            onPressed: _isSharing ? null : _shareCertificate,
            icon: _isSharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
          ),
        ],
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: RepaintBoundary(key: _certificateKey, child: certificate),
          ),
        ),
      ),
    );
  }

  Widget _certificate() {
    final leaf = widget.leaf;
    final l10n = AppLocalizations.of(context)!;
    final issuedAt =
        leaf.certificateIssuedAt ??
        widget.book.publishedAt ??
        widget.book.createdAt ??
        widget.book.updatedAt;
    return ParticipationCertificate(
      userName: _participantName(),
      userPhotoUrl: leaf.certificateParticipantPhotoUrl,
      topicName: leaf.certificateTopicName?.trim().isNotEmpty == true
          ? leaf.certificateTopicName!.trim()
          : l10n.dailyTopic,
      date: formatCertificateDateFromMillis(issuedAt),
    );
  }

  String _participantName() {
    final fromLeaf = widget.leaf.certificateParticipantName?.trim();
    if (fromLeaf != null && fromLeaf.isNotEmpty) return fromLeaf;
    final firstAuthor = widget.book.authors.firstOrNull?.name.trim();
    if (firstAuthor != null && firstAuthor.isNotEmpty) return firstAuthor;
    return 'User';
  }

  Future<void> _shareCertificate() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final bytes = await _captureCertificateBytes();
      if (bytes == null) return;

      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: '${_safeFilePart(widget.book.title)}-certificate.jpg',
            mimeType: 'image/jpeg',
          ),
        ],
        text:
            'My Wreadom participation certificate for "${widget.book.title}"\n'
            '${AppLinkHelper.book(widget.book.id)}',
        subject: widget.book.title,
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<Uint8List?> _captureCertificateBytes() async {
    final boundary =
        _certificateKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData?.buffer.asUint8List();
    if (pngBytes == null) return null;
    final decoded = image_codec.decodePng(pngBytes);
    if (decoded == null) return pngBytes;
    return Uint8List.fromList(image_codec.encodeJpg(decoded, quality: 95));
  }

  String _safeFilePart(String value) {
    final safe = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return safe.isEmpty ? 'wreadom' : safe;
  }
}

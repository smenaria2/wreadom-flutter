import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/home_banner.dart';
import 'homepage_providers.dart';

final homeBannerByIdProvider = FutureProvider.family<HomeBanner, String>((ref, id) async {
  // First check cached/loaded list in homeBannersProvider
  final list = await ref.read(homeBannersProvider.future);
  final found = list.cast<HomeBanner?>().firstWhere(
    (b) => b?.id == id,
    orElse: () => null,
  );
  if (found != null) return found;

  // Otherwise, fetch from Firestore directly
  final doc = await FirebaseFirestore.instance.collection('home-banners').doc(id).get();
  if (doc.exists) {
    final data = Map<String, dynamic>.from(doc.data()!);
    data['id'] = doc.id;
    return HomeBanner.fromJson(data);
  }
  throw Exception('Banner not found');
});

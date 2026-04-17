import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firebase_report_repository.dart';
import '../../domain/repositories/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return FirebaseReportRepository();
});

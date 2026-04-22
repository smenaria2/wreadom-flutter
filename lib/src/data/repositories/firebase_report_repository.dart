import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/report.dart';
import '../../domain/repositories/report_repository.dart';

class FirebaseReportRepository implements ReportRepository {
  FirebaseReportRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> submitReport(Report report) async {
    final data = report.toJson()..remove('id');
    await _firestore.collection('reports').add(data);
  }

  @override
  Future<void> submitErrorReport(Map<String, dynamic> report) async {
    await _firestore.collection('reports').add({
      ...report,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

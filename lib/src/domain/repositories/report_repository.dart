import '../models/report.dart';

abstract class ReportRepository {
  Future<void> submitReport(Report report);
  Future<void> submitErrorReport(Map<String, dynamic> report);
}

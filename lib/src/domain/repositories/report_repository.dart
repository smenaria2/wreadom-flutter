import '../models/report.dart';

abstract class ReportRepository {
  Future<void> submitReport(Report report);
}

import 'package:cloud_firestore/cloud_firestore.dart';

Map<String, dynamic> mapFirestoreData(Map<String, dynamic> data, String id) {
  final Map<String, dynamic> result = Map<String, dynamic>.from(data);
  result['id'] = id;

  // Convert Timestamps to milliseconds since epoch for the model
  if (result['timestamp'] is Timestamp) {
    result['timestamp'] = (result['timestamp'] as Timestamp).millisecondsSinceEpoch;
  }

  // Ensure likes is at least an empty list if missing
  if (result['likes'] == null) {
    result['likes'] = <String>[];
  } else if (result['likes'] is! List) {
     result['likes'] = <String>[];
  }

  // Ensure visibility exists
  if (result['visibility'] == null) {
    result['visibility'] = 'public';
  }

  // Ensure type exists
  if (result['type'] == null) {
    result['type'] = 'post';
  }

  // Ensure text exists
  if (result['text'] == null) {
    result['text'] = '';
  }

  return result;
}

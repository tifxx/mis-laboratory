import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ListItem {
  final String id;
  final String userId;
  final String courseName;
  final DateTime dateTime;

  ListItem({
    this.id = '',
    required this.userId,
    required this.courseName,
    required this.dateTime
  });

    Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'courseName': courseName,
    'dateTime': dateTime,
  };

  static ListItem fromJson(Map<String, dynamic> json) => ListItem(
    id: json['id'],
    userId: json['userId'],
    courseName: json['courseName'],
    dateTime: (json['dateTime'] as Timestamp).toDate());
}

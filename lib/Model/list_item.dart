import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

class ListItem {
  final String id;
  final String userId;
  final String courseName;
  final DateTime dateTime;
  final double latitude;
  final double longitude;

  ListItem({
    this.id = '',
    required this.userId,
    required this.courseName,
    required this.dateTime,
    required this.latitude,
    required this.longitude
  });

    Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'courseName': courseName,
    'dateTime': dateTime,
    'latitude': latitude,
    'longitude': longitude
  };

  static ListItem fromJson(Map<String, dynamic> json) => ListItem(
    id: json['id'],
    userId: json['userId'],
    courseName: json['courseName'],
    dateTime: (json['dateTime'] as Timestamp).toDate(),
    latitude: json['latitude'],
    longitude: json['longitude']
    );
}

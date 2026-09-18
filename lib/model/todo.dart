import 'package:cloud_firestore/cloud_firestore.dart';

class Todo {
  String content;
  Timestamp date;

  Todo(
  {
    required this.content,
    required this.date,
  }
  );

}
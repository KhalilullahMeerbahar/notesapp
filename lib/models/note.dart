import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'note.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  String title;
  
  @HiveField(1)
  String? content;
  
  @HiveField(2)
  bool isCompleted;
  
  @HiveField(3)
  DateTime createdAt;
  
  @HiveField(4)
  DateTime? dueDate;
  
  @HiveField(5)  // Add this new field
  int? colorIndex;
  
  Note({
    required this.title,
    this.content,
    this.isCompleted = false,
    required this.createdAt,
    this.dueDate,
    this.colorIndex,
  });

  String get formattedCreatedDate {
    return DateFormat('MMM dd, yyyy').format(createdAt);
  }

  String? get formattedDueDate {
    return dueDate != null ? DateFormat('MMM dd, yyyy').format(dueDate!) : null;
  }
}
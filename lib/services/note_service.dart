import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';

class NoteService {
  static const _key = 'notes';

  static Future<List<Note>> loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final notesData = prefs.getString(_key);
    if (notesData == null) return [];

    final List<dynamic> jsonList = json.decode(notesData);
    return jsonList.map((e) => Note.fromJson(e)).toList();
  }

  static Future<void> saveNotes(List<Note> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = notes.map((note) => note.toJson()).toList();
    await prefs.setString(_key, json.encode(jsonList));
  }
}

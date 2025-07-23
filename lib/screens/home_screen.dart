import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:notesapp/models/note.dart';

enum FilterStatus { all, completed, incomplete }
enum NoteColor { purple, blue, green, orange, pink }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Box<Note> notesBox;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  FilterStatus _filterStatus = FilterStatus.all;
  DateTime? _selectedDueDate;
  NoteColor _selectedColor = NoteColor.purple;
  bool _isGridLayout = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    notesBox = Hive.box<Note>('notes');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Notely', style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: Colors.black87,
        )),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(_isGridLayout ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridLayout = !_isGridLayout),
            color: Colors.deepPurple,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
            color: Colors.deepPurple,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNoteDialog,
        backgroundColor: const Color(0xFF6C5CE7),
        child: const Icon(Icons.add, size: 28),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _buildFilterChips(),
            const SizedBox(height: 16),
            Expanded(
              child: ValueListenableBuilder<Box<Note>>(
                valueListenable: notesBox.listenable(),
                builder: (context, box, _) {
                  List<Note> notes = box.values.toList().cast<Note>();
                  
                  // Filter by status
                  if (_filterStatus != FilterStatus.all) {
                    notes = notes.where((note) {
                      return _filterStatus == FilterStatus.completed 
                          ? note.isCompleted 
                          : !note.isCompleted;
                    }).toList();
                  }
                  
                  // Filter by search query
                  if (_searchQuery.isNotEmpty) {
                    notes = notes.where((note) {
                      final titleMatch = note.title.toLowerCase().contains(_searchQuery.toLowerCase());
                      final contentMatch = note.content?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
                      return titleMatch || contentMatch;
                    }).toList();
                  }
                  
                  // Sort by date
                  notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  
                  if (notes.isEmpty) {
                    return _buildEmptyState();
                  }
                  
                  return _isGridLayout 
                      ? _buildGridLayout(notes) 
                      : _buildListLayout(notes);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: FilterStatus.values.map((status) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(status.toString().split('.').last),
              selected: _filterStatus == status,
              onSelected: (_) => setState(() => _filterStatus = status),
              selectedColor: _getChipColor(status),
              labelStyle: TextStyle(
                color: _filterStatus == status ? Colors.white : Colors.black54,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getChipColor(FilterStatus status) {
    switch (status) {
      case FilterStatus.all:
        return const Color(0xFF6C5CE7);
      case FilterStatus.completed:
        return Colors.green;
      case FilterStatus.incomplete:
        return Colors.orange;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.note_add, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty ? 'No notes yet!' : 'No notes found',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty 
                ? 'Tap the + button to add your first note' 
                : 'Try a different search term',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListLayout(List<Note> notes) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: notes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final note = notes[index];
        return _buildNoteCard(note);
      },
    );
  }

  Widget _buildGridLayout(List<Note> notes) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _buildNoteCard(note, isGrid: true);
      },
    );
  }

  Widget _buildNoteCard(Note note, {bool isGrid = false}) {
    final color = _getNoteColor(note.colorIndex ?? 0);
    
    return Dismissible(
      key: Key(note.key.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.red),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Note'),
            content: const Text('Are you sure you want to delete this note?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => note.delete(),
      child: GestureDetector(
        onTap: () => _showEditNoteDialog(note),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      note.title,
                      style: TextStyle(
                        fontSize: isGrid ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        decoration: note.isCompleted 
                            ? TextDecoration.lineThrough 
                            : null,
                        color: note.isCompleted 
                            ? Colors.grey 
                            : color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isGrid) _buildCheckbox(note),
                ],
              ),
              if (note.content != null && note.content!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    note.content!,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: isGrid ? 12 : 14,
                    ),
                    maxLines: isGrid ? 3 : 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const Spacer(),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd').format(note.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (note.dueDate != null) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _isNoteOverdue(note) 
                            ? Colors.red.withOpacity(0.2) 
                            : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        DateFormat('MMM dd').format(note.dueDate!),
                        style: TextStyle(
                          fontSize: 11,
                          color: _isNoteOverdue(note) 
                              ? Colors.red 
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (isGrid) _buildCheckbox(note),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox(Note note) {
    return Transform.scale(
      scale: 1.2,
      child: Checkbox(
        value: note.isCompleted,
        onChanged: (value) {
          setState(() {
            note.isCompleted = value ?? false;
            note.save();
          });
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
        side: MaterialStateBorderSide.resolveWith(
          (states) => const BorderSide(width: 1.5, color: Colors.grey),
        ),
        activeColor: const Color(0xFF6C5CE7),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Notes'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search by title or content...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _searchQuery = '');
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAddNoteDialog() {
    _titleController.clear();
    _contentController.clear();
    _dueDateController.clear();
    _selectedDueDate = null;
    _selectedColor = NoteColor.purple;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'New Note',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () {
                          if (_titleController.text.isNotEmpty) {
                            final note = Note(
                              title: _titleController.text,
                              content: _contentController.text.isEmpty 
                                  ? null 
                                  : _contentController.text,
                              createdAt: DateTime.now(),
                              dueDate: _selectedDueDate,
                              colorIndex: _selectedColor.index,
                            );
                            notesBox.add(note);
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        TextField(
                          controller: _titleController,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Title',
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _contentController,
                          decoration: const InputDecoration(
                            hintText: 'Start typing...',
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                        ),
                        const SizedBox(height: 32),
                        _buildColorSelector(),
                        const SizedBox(height: 24),
                        _buildDueDateSelector(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: NoteColor.values.map((color) {
            final isSelected = _selectedColor == color;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNoteColor(color.index).withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(
                          color: _getNoteColor(color.index),
                          width: 2,
                        )
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: _getNoteColor(color.index),
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDueDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Due Date',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedDueDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: Color(0xFF6C5CE7),
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _selectedDueDate = picked;
                _dueDateController.text = DateFormat('MMM dd, yyyy').format(picked);
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _selectedDueDate == null
                      ? 'Select a date'
                      : DateFormat('MMM dd, yyyy').format(_selectedDueDate!),
                  style: TextStyle(
                    color: _selectedDueDate == null
                        ? Colors.grey[500]
                        : Colors.black87,
                  ),
                ),
                if (_selectedDueDate != null) ...[
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedDueDate = null;
                        _dueDateController.clear();
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showEditNoteDialog(Note note) {
    _titleController.text = note.title;
    _contentController.text = note.content ?? '';
    _selectedDueDate = note.dueDate;
    _dueDateController.text = note.dueDate != null
        ? DateFormat('MMM dd, yyyy').format(note.dueDate!)
        : '';
    _selectedColor = NoteColor.values[note.colorIndex ?? 0];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Note',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: () {
                          if (_titleController.text.isNotEmpty) {
                            note.title = _titleController.text;
                            note.content = _contentController.text.isEmpty 
                                ? null 
                                : _contentController.text;
                            note.dueDate = _selectedDueDate;
                            note.colorIndex = _selectedColor.index;
                            note.save();
                            Navigator.pop(context);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        TextField(
                          controller: _titleController,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Title',
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _contentController,
                          decoration: const InputDecoration(
                            hintText: 'Start typing...',
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                        ),
                        const SizedBox(height: 32),
                        _buildColorSelector(),
                        const SizedBox(height: 24),
                        _buildDueDateSelector(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isNoteOverdue(Note note) {
    if (note.dueDate == null || note.isCompleted) return false;
    return note.dueDate!.isBefore(DateTime.now());
  }

  Color _getNoteColor(int index) {
    switch (NoteColor.values[index]) {
      case NoteColor.purple:
        return const Color(0xFF6C5CE7);
      case NoteColor.blue:
        return const Color(0xFF00CEFF);
      case NoteColor.green:
        return const Color(0xFF00B894);
      case NoteColor.orange:
        return const Color(0xFFFDCB6E);
      case NoteColor.pink:
        return const Color(0xFFFD79A8);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }
}
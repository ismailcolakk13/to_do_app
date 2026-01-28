import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/model/todo.dart';
import 'package:to_do_app/screens/settings.dart';
import 'package:to_do_app/services/notification_service.dart';
import 'package:to_do_app/utils/helper_ui_functions.dart';
import '../constants/colors.dart';
import '../widgets/todo_item.dart';
import 'package:lottie/lottie.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  List<ToDo> todosList = [];
  Map<String, List<ToDo>> groupedTodos = {};
  List<ToDo> _foundToDo = [];

  final _searchController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _hasScrolledToToday = false;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _headerKeys = {};

  void _groupTodosByDate() {
    Map<String, List<ToDo>> grouped = {};

    for (var todo in _foundToDo) {
      String dateKey = DateFormat("yyyy-MM-dd").format(todo.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(todo);
    }

    var sortedEntries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    setState(() {
      groupedTodos = Map.fromEntries(sortedEntries.reversed);
      _headerKeys.clear();

      if (groupedTodos.isEmpty) {
        _animationController.repeat();
      } else {
        _animationController.stop();
        _animationController.value = 0;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
      _hasScrolledToToday = true;
    });
  }

  void _scrollToToday() {
    if (_hasScrolledToToday) return;
    final todayKey = DateFormat("yyyy-MM-dd").format(DateTime.now());
    final key = _headerKeys[todayKey];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting("tr_TR", null);
    _loadTodos();
    HelperUiFunctions.requestNotificationPermission();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _scaleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 20),
          TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 20),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 20),
          TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 40),
        ]).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    final String? todosString = prefs.getString("todos");

    if (todosString != null) {
      List<dynamic> todosJson = json.decode(todosString);
      setState(() {
        todosList = todosJson.map((json) => ToDo.fromJson(json)).toList();
        _foundToDo = todosList;
        _groupTodosByDate();
      });
    } else {
      setState(() {
        todosList = [];
        _foundToDo = todosList;
        _groupTodosByDate();
      });
    }
  }

  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> todosJson = todosList
        .map((todo) => todo.toJson())
        .toList();
    await prefs.setString("todos", json.encode(todosJson));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tdBGColor,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Column(
              children: [
                _searchBox(),
                Expanded(
                  child: groupedTodos.isEmpty ? _emptyView() : _todoListView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ListView _todoListView() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: groupedTodos.length,
      itemBuilder: (context, index) {
        String dateKey = groupedTodos.keys.elementAt(index);
        List<ToDo> todosForDate = groupedTodos[dateKey]!;

        // Create or reuse key
        if (!_headerKeys.containsKey(dateKey)) {
          _headerKeys[dateKey] = GlobalKey();
        }
        final headerKey = _headerKeys[dateKey]!;

        // Check if this is today
        final isToday =
            dateKey == DateFormat("yyyy-MM-dd").format(DateTime.now());

        return Column(
          key: isToday ? headerKey : null,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(top: 30, bottom: 15),
              padding: EdgeInsets.only(left: 10),
              child: Text(
                HelperUiFunctions.formatDateHeader(dateKey),
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ),
            ...todosForDate.map(
              (todo) => ToDoItem(
                todoo: todo,
                onToDoChanged: _handleToDoChange,
                onDeleteItem: _handleDeleteItem,
              ),
            ),
          ],
        );
      },
    );
  }

  Column _emptyView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Yeni birşey ekliyorsan +' ya bas\nArama yapıyorsan aradığın yok\nHiçbiri değilse işin yok :D",
          style: TextStyle(fontSize: 20, color: Colors.grey[800]),
          textAlign: TextAlign.center,
        ),
        Lottie.asset(
          "assets/lotties/emptyghost.json",
          frameRate: FrameRate(60),
          repeat: true,
          animate: true,
          height: 400,
          width: 400,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  Column _searchBox() {
    return Column(spacing: 0, children: [_textRow(), _slidingDateRow()]);
  }

  Container _textRow() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: tdBlack, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _runFilter(value),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: "Ara veya ekle",
                hintStyle: TextStyle(color: tdGrey),
                isDense: true,
              ),
            ),
          ),
          ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 32,
              decoration: BoxDecoration(
                color: groupedTodos.isEmpty ? tdBlue : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {
                  if (_searchController.text.isNotEmpty) {
                    _handleAddItem(_searchController.text);
                    _searchController.clear();
                    _runFilter("");
                  }
                },
                icon: Icon(Icons.add, size: 20),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  AnimatedContainer _slidingDateRow() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
      height: groupedTodos.isEmpty ? 40 : 0,
      padding: EdgeInsets.symmetric(horizontal: 15),
      margin: EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: groupedTodos.isEmpty
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate != null
                      ? DateFormat(
                          "d MMMM yyyy",
                          "tr_TR",
                        ).format(_selectedDate!)
                      : "Ne zamana yapıcan?",
                  style: TextStyle(
                    color: _selectedDate != null ? tdBlack : tdGrey,
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.calendar_today, size: 20, color: tdBlue),
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2040),
                      locale: Locale('tr', 'TR'),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDate = picked;
                      });
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                Text(
                  (_selectedTime != null && _selectedDate != null)
                      ? DateFormat("hh:mm", "tr_TR").format(
                          _selectedDate!.add(
                            Duration(
                              hours: _selectedTime!.hour,
                              minutes: _selectedTime!.minute,
                            ),
                          ),
                        )
                      : "",
                  // ? "${_selectedTime!.hour}:${_selectedTime!.minute}"
                  // : "",
                  style: TextStyle(
                    color: _selectedDate != null ? tdBlack : tdGrey,
                    fontSize: 14,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.timer, size: 20, color: tdBlue),
                  onPressed: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                      builder: (context, child) {
                        return MediaQuery(
                          data: MediaQuery.of(
                            context,
                          ).copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedTime = picked;
                      });
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            )
          : SizedBox(width: 300),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: tdBGColor,
      elevation: 0,
      title: Text("İşgüç", style: TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.settings, color: tdBlack, size: 30),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SettingsScreen()),
          );
        },
      ),
    );
  }

  void _handleToDoChange(ToDo todo) {
    setState(() {
      todo.isDone = !todo.isDone;
    });
    _saveTodos();
  }

  void _handleDeleteItem(String id) {
    setState(() {
      todosList.removeWhere((item) => item.id == id);
      _foundToDo = todosList;
      _groupTodosByDate();
    });
    _saveTodos();
  }

  void _handleAddItem(String todo) async {
    if (todo.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final reminderHour = prefs.getInt("reminder_hour") ?? 2;
    final reminderMinute = prefs.getInt("reminder_minute") ?? 0;
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;

    setState(() {
      final newTodoId = DateTime.now().millisecondsSinceEpoch.toString();
      final taskDate = (_selectedDate ?? DateTime.now()).add(
        Duration(hours: _selectedTime!.hour, minutes: _selectedTime!.minute),
      );

      todosList.add(
        ToDo(
          id: newTodoId,
          date: taskDate,
          todoText: todo,
          creationDate: DateTime.now(),
        ),
      );

      if (notificationsEnabled) {
        // Check if the task date is in the future
        _createNotification(
          taskDate,
          newTodoId,
          todo,
          reminderHour,
          reminderMinute,
        );
      }

      _foundToDo = todosList;
      _groupTodosByDate();
      _selectedDate = null;
      _selectedTime = null;
    });
    _saveTodos();
  }

  void _createNotification(
    DateTime taskDate,
    String newTodoId,
    String todo,
    int reminderHour,
    int reminderMinute,
  ) {
    if (taskDate.isAfter(DateTime.now())) {
      NotificationService().scheduleTaskReminder(
        id: int.parse(newTodoId.substring(newTodoId.length - 9)),
        title: "Hatırlatma: $todo",
        scheduledDate: taskDate,
      );

      final reminderTime = taskDate.subtract(
        Duration(hours: reminderHour, minutes: reminderMinute),
      );
      debugPrint("Task reminder scheduled for: $reminderTime");
    }
  }

  void _runFilter(String enteredKeyword) {
    List<ToDo> results = [];
    if (enteredKeyword.isEmpty) {
      results = todosList;
    } else {
      results = todosList
          .where(
            (item) => item.todoText!.toLowerCase().contains(
              enteredKeyword.toLowerCase(),
            ),
          )
          .toList();
    }

    setState(() {
      _foundToDo = results;
      _groupTodosByDate();
    });
  }
}

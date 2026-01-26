import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/model/todo.dart';
import 'package:to_do_app/services/notification_service.dart';
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
  final _todoController = TextEditingController();
  final _searchController = TextEditingController();
  DateTime? _selectedDate;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  Future<void> _requestNotificationPermission() async {
  if (Platform.isAndroid) {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        FlutterLocalNotificationsPlugin().resolvePlatformSpecificImplementation
            <AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation?.requestNotificationsPermission();
    final bool? exactAlarmGranted = await androidImplementation?.requestExactAlarmsPermission();
    debugPrint('Exact alarm permission: $exactAlarmGranted');
  }
}

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

      if (groupedTodos.isEmpty) {
        _animationController.repeat();
      } else {
        _animationController.stop();
        _animationController.value = 0;
      }
    });
  }

  String _formatDateHeader(String dateKey) {
    DateTime date = DateTime.parse(dateKey);
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime todoDate = DateTime(date.year, date.month, date.day);

    if (todoDate == today) {
      return "Bugün";
    } else if (todoDate == today.add(Duration(days: 1))) {
      return "Yarın";
    } else if (todoDate == today.subtract(Duration(days: 1))) {
      return "Dün";
    } else if (todoDate.year == today.year) {
      return DateFormat("d MMMM", "tr_TR").format(date);
    } else {
      return DateFormat("d MMMM yyyy", "tr_TR").format(date);
    }
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting("tr_TR", null);
    _loadTodos();
    _requestNotificationPermission();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(microseconds: 16500),
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
    _todoController.dispose();
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
            child: Column(children: [_searchBox(), _todoListView()]),
          ),
        ],
      ),
    );
  }

  Expanded _todoListView() {
    return Expanded(
      child: groupedTodos.isEmpty
          ? Column(
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
            )
          : ListView.builder(
              itemCount: groupedTodos.length,
              itemBuilder: (context, index) {
                String dateKey = groupedTodos.keys.elementAt(index);
                List<ToDo> todosForDate = groupedTodos[dateKey]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 30, bottom: 15),
                      padding: EdgeInsets.only(left: 10),
                      child: Text(
                        _formatDateHeader(dateKey),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
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
            ),
    );
  }

  Column _searchBox() {
    return Column(
      spacing: 0,
      children: [
        Container(
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
                  // height: 32,
                  decoration: BoxDecoration(
                    color: groupedTodos.isEmpty
                        ? Colors.green
                        : Colors.transparent,
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
        ),
        AnimatedContainer(
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
                          lastDate: DateTime(2030),
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
                  ],
                )
              : SizedBox(width: 300),
        ),
      ],
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: tdBGColor,
      elevation: 0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(Icons.menu, color: tdBlack, size: 30),
          Text("İşgüç"),
          ElevatedButton(onPressed: () {
            NotificationService().showNotification(id: 1,title: "Test",body: "bildirimmm");
          }, child: const Text("b1")),
          ElevatedButton(onPressed: () {
          NotificationService().scheduleNotification(id: 5, title: "zamanlı test", body: "Yap artık şunu!", scheduledDate: DateTime.now().add(Duration(seconds: 5)));
          }, child: const Text("b2")),
          SizedBox(
            height: 40,
            width: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Icon(Icons.person),
            ),
          ),
        ],
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

  void _handleAddItem(String todo) {
    if (todo.isEmpty) return;
    setState(() {
      todosList.add(
        ToDo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: _selectedDate ?? DateTime.now(),
          todoText: todo,
          creationDate: DateTime.now(),
        ),
      );
      NotificationService().scheduleNotification(id: 5, title: todo, body: "Yap artık şunu!", scheduledDate: (_selectedDate ?? DateTime.now()).copyWith(hour:9));
      debugPrint("çalıştı?");
      _foundToDo = todosList;
      _groupTodosByDate();
      _selectedDate = null;
    });
    _todoController.clear();
    _saveTodos();
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

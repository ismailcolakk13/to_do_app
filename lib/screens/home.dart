import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/model/todo.dart';
import '../constants/colors.dart';
import '../widgets/todo_item.dart';
import 'package:lottie/lottie.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<ToDo> todosList = [];
  Map<String, List<ToDo>> groupedTodos = {};
  List<ToDo> _foundToDo = [];
  final _todoController = TextEditingController();
  final _searchController = TextEditingController();

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

    groupedTodos = Map.fromEntries(sortedEntries);
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
  }

  @override
  void dispose() {
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
        todosList = ToDo.todoList();
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

  Row _addTodoItem() {
    return Row(
      children: [
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: 20, right: 20, left: 20),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                const BoxShadow(
                  color: Colors.grey,
                  offset: Offset(0, 0),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Yeni bir şey?",
                border: InputBorder.none,
              ),
              controller: _todoController,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(bottom: 20, right: 20),
          child: ElevatedButton(
            onPressed: () {
              _handleAddItem(_todoController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: tdBlue,
              foregroundColor: Colors.white,
              minimumSize: Size(60, 60),
              elevation: 10,
            ),
            child: Text("+", style: TextStyle(fontSize: 40)),
          ),
        ),
      ],
    );
  }

  Expanded _todoListView() {
    return Expanded(
      child: groupedTodos.isEmpty
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Yeni birşey ekliyorsan +' ya bas\nArama yapıyorsan aradığın yok\nHiçbiri değilse işin yok :D",
                      style: TextStyle(fontSize: 20, color: Colors.grey[800]),
                      textAlign: TextAlign.center,
                    ),
                    Lottie.asset("assets/lotties/emptyghost.json"),
                  ],
                ),
                Positioned(
                  top: 20,
                  right: 35,
                  child: CustomPaint(
                    size: Size(120, 100),
                    painter: CurvedArrowPainter(),
                  ),
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
                      margin: EdgeInsets.only(top: 30, bottom: 20),
                      padding: EdgeInsets.only(left: 10),
                      child: Text(
                        _formatDateHeader(dateKey),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w500,
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

  Container _searchBox() {
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
                hintText: "Ara",
                hintStyle: TextStyle(color: tdGrey),
                isDense: true,
              ),
            ),
          ),
          IconButton(
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
        ],
      ),
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
          SizedBox(
            height: 40,
            width: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset("assets/img/avatar.jpg"),
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
          date: DateTime.now(),
          todoText: todo,
        ),
      );
      _foundToDo = todosList;
      _groupTodosByDate();
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

class CurvedArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[600]!
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Start point (bottom of arrow, near the text)
    path.moveTo(size.width * 0.5, size.height * 0.8);

    // Create a curved path going up and to the right
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.4, // Control point
      size.width * 0.9,
      size.height * 0.1, // End point
    );

    canvas.drawPath(path, paint);

    // Draw arrowhead
    final arrowPath = Path();
    arrowPath.moveTo(size.width * 0.9, size.height * 0.1);
    arrowPath.lineTo(size.width * 0.85, size.height * 0.15);
    arrowPath.moveTo(size.width * 0.9, size.height * 0.1);
    arrowPath.lineTo(size.width * 0.95, size.height * 0.13);

    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

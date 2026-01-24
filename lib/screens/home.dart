import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:to_do_app/model/todo.dart';
import '../constants/colors.dart';
import '../widgets/todo_item.dart';

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
    } else {
      return DateFormat("d MMMM, yyyy").format(date);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final prefs= await SharedPreferences.getInstance();
    final String? todosString = prefs.getString("todos");

    if(todosString!=null){
      List<dynamic> todosJson=json.decode(todosString);
      setState(() {
        todosList = todosJson.map((json) => ToDo.fromJson(json)).toList();
        _foundToDo=todosList;
        _groupTodosByDate();
      });
    }else{
      setState(() {
        todosList=ToDo.todoList();
        _foundToDo=todosList;
        _groupTodosByDate();
      });
    }
  }

  Future<void> _saveTodos() async {
    final prefs=await SharedPreferences.getInstance();
    List<Map<String,dynamic>> todosJson = todosList.map((todo)=> todo.toJson()).toList();
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
          Align(alignment: Alignment.bottomCenter, child: _addTodoItem()),
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
                hintText: "Add a new todo item",
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
      child: ListView.builder(
        itemCount: groupedTodos.length,
        itemBuilder: (context, index) {
          String dateKey = groupedTodos.keys.elementAt(index);
          List<ToDo> todosForDate = groupedTodos[dateKey]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(top: 50, bottom: 20),
                padding: EdgeInsets.only(left: 10),
                child: Text(
                  _formatDateHeader(dateKey),
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500),
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
      child: TextField(
        onChanged: (value) => _runFilter(value),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.all(0),
          prefixIcon: Icon(Icons.search, color: tdBlack, size: 20),
          prefixIconConstraints: BoxConstraints(maxHeight: 20, minWidth: 25),
          border: InputBorder.none,
          hintText: "Search",
          hintStyle: TextStyle(color: tdGrey),
        ),
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
      _foundToDo=todosList;
      _groupTodosByDate();
    });
    _saveTodos();
  }

  void _handleAddItem(String todo) {
    setState(() {
      todosList.add(
        ToDo(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: DateTime.now(),
          todoText: todo,
        ),
      );
      _foundToDo=todosList;
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

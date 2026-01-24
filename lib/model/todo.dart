class ToDo {
  String? id;
  String? todoText;
  DateTime date;
  bool isDone;

  ToDo({
    required this.id,
    required this.todoText,
    required this.date,
    this.isDone = false,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "todotext": todoText,
    "date": date.toIso8601String(),
    "isdone": isDone,
  };

  factory ToDo.fromJson(Map<String, dynamic> json) {
    return ToDo(
      id: json["id"],
      todoText: json["todotext"],
      date: DateTime.parse(json["date"]),
      isDone: json["isdone"] ?? false,
    );
  }

  static List<ToDo> todoList() {
    return [
      ToDo(
        id: "01",
        todoText: "Morning Exercise",
        date: DateTime(2026, 1, 21, 17, 30),
        isDone: true,
      ),
      ToDo(
        id: "02",
        todoText: "Buy Groceries",
        date: DateTime(2026, 1, 21, 17, 30),
        isDone: true,
      ),
      ToDo(
        id: "03",
        todoText: "Check Emails",
        date: DateTime(2026, 1, 20, 17, 30),
      ),
      ToDo(
        id: "04",
        todoText: "Team Meeting",
        date: DateTime(2026, 1, 20, 17, 30),
      ),
      ToDo(
        id: "05",
        todoText: "Work on mobile apps for 2 hour",
        date: DateTime(2026, 1, 19, 17, 30),
      ),
      ToDo(
        id: "06",
        todoText: "Dinner with Jenny",
        date: DateTime(2026, 1, 22, 17, 30),
      ),
    ];
  }
}

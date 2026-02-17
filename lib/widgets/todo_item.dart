import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:to_do_app/constants/colors.dart';
import 'package:to_do_app/model/todo.dart';

class ToDoItem extends StatelessWidget {
  final ToDo todoo;
  final Function(ToDo) onToDoChanged;
  final Function(String) onDeleteItem;
  const ToDoItem({
    super.key,
    required this.todoo,
    required this.onToDoChanged,
    required this.onDeleteItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      child: ListTile(
        onTap: () {
          onToDoChanged(todoo);
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(20),
          side: BorderSide(
            color: todoo.isDone ? tdBlue.withValues(alpha: 0.5) : ((todoo.date.isBefore(DateTime.now())) ? tdRed.withValues(alpha: 0.5) :Colors.transparent),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside
          )
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        tileColor: Colors.white,
        leading: todoo.isDone
            ? Icon(Icons.check_box, color: tdBlue)
            : Icon(Icons.check_box_outline_blank, color: Colors.grey),
        title: Text(
          todoo.todoText!,
          style: TextStyle(
            fontSize: 16,
            color: tdBlack,
            decoration: todoo.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_alt_outlined, size: 12),
                SizedBox(width: 3),
                Text(
                  DateFormat("d/MM/yyyy", "tr_TR").format(todoo.creationDate),
                  style: TextStyle(color: tdGrey, fontSize: 12),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.alarm_rounded, size: 12),
                SizedBox(width: 3),
                Text(
                  DateFormat("HH:mm", "tr_TR").format(todoo.creationDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.all(0),
          margin: EdgeInsets.symmetric(vertical: 12),
          height: 35,
          width: 35,
          decoration: BoxDecoration(
            color: tdRed,
            borderRadius: BorderRadius.circular(5),
          ),
          child: IconButton(
            onPressed: () async {
              final bool? confirmed = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Emin misin?"),
                    content: Text(
                      "Bu görevi silmek istediğine emin misin? Bu işlem geri alınamaz.",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(false), // Cancel
                        child: Text("İptal", style: TextStyle(color: tdGrey)),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(true), // Confirm
                        child: Text("Sil", style: TextStyle(color: tdRed)),
                      ),
                    ],
                  );
                },
              );
              if (confirmed == true) onDeleteItem(todoo.id!);
            },
            icon: Icon(Icons.delete),
            color: Colors.white,
            iconSize: 18,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        tileColor: Colors.white,
        leading: todoo.isDone
            ? Icon(Icons.check_box, color: Colors.green)
            : Icon(Icons.check_box_outline_blank, color: Colors.grey),
        title: Text(
          todoo.todoText!,
          style: TextStyle(
            fontSize: 16,
            color: tdBlack,
            decoration: todoo.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          "Oluşturma tarihi: ${todoo.creationDate.day}/${todoo.creationDate.month}/${todoo.creationDate.year}",
          style: TextStyle(color: tdGrey, fontSize: 12),
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
              final bool? confirmed = await showCupertinoDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return CupertinoAlertDialog(
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
              if(confirmed==true) onDeleteItem(todoo.id!);
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

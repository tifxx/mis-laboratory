import 'package:flutter/material.dart';
import 'package:lab3/Model/list_item.dart';
import 'package:nanoid/nanoid.dart';
import 'package:intl/intl.dart';

import 'adaptive_flat_button.dart';

class NovElement extends StatefulWidget {
  final Function addItem;

  NovElement(this.addItem);
  @override
  State<StatefulWidget> createState() => _NovElementState();
}

class _NovElementState extends State<NovElement> {
  final _nameController = TextEditingController();
  final _dateTimeController = TextEditingController();

  late String courseName;
  late DateTime dateTime;

  void _submitData() {
    if (_dateTimeController.text.isEmpty) {
      return;
    }
    final inputedName = _nameController.text;
    final inputedDateTime = DateTime.parse(_dateTimeController.text);

    if (inputedName.isEmpty) {
      return;
    }

    final newItem = ListItem(
        id: nanoid(5), courseName: inputedName, dateTime: inputedDateTime);
    widget.addItem(newItem);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      child: Column(
        children: [
          Text(
            'Add colloquium',
            style: TextStyle(fontSize: 20, color: Colors.cyan),
          ),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: "Enter Name of the Course"),
            onSubmitted: (_) => _submitData(),
          ),
          TextField(
            controller: _dateTimeController,
            decoration: InputDecoration(
                icon: Icon(Icons.calendar_today),
                labelText: "Enter Date and Time"),
            readOnly: true,
            onTap: () async {
              final date = await pickDate();

              if (date != null) {
                print(date);
                String formattedDate = DateFormat('yyyy-MM-dd').format(date);
                print(formattedDate);
                setState(() {
                  _dateTimeController.text = formattedDate;
                });
              } else {
                print("Date is not selected");
              }

              final pickedTime = (await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: 12, minute: 0)))!;
              if (pickedTime != null) {
                print(pickedTime.format(context));
                DateTime parsedTime = DateFormat.jm()
                    .parse(pickedTime.format(context).toString());
                print(parsedTime);
                String formattedTime = DateFormat('HH:mm').format(parsedTime);
                print(formattedTime);
                setState(() {
                  _dateTimeController.text =
                      "${_dateTimeController.text} $formattedTime";
                });
                print(_dateTimeController.text);
              } else {
                print("Time is not selected");
              }
            },
            onSubmitted: (_) => _submitData(),
          ),
          Container(
            child: AdaptiveFlatButton(
              "Add",
              _submitData,
            ),
            margin: const EdgeInsets.all(15),

          )
        ],
      ),
    );
  }

  Future<DateTime?> pickDate() => showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2022),
        lastDate: DateTime(2030),
      );
}

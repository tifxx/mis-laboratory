import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lab3/Model/list_item.dart';
import 'package:nanoid/nanoid.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';


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
  final _locationController = TextEditingController();
  //Completer<GoogleMapController> _controller = Completer();
   GoogleMapController? _controller;

  final FirebaseAuth auth = FirebaseAuth.instance;

  late String courseName;
  late DateTime dateTime;

  Future addItemToDB({required ListItem item}) async {
    final docItem =
        FirebaseFirestore.instance.collection('courses').doc(item.id);
    final json = item.toJson();
    await docItem.set(json);
  }

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
        id: nanoid(5),
        userId: auth.currentUser!.uid,
        courseName: inputedName,
        dateTime: inputedDateTime);

    widget.addItem(newItem);
    addItemToDB(item: newItem);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15),
      height: 750,
      child: Column(
        children: [
          Text(
            'Add exam',
            style: TextStyle(fontSize: 25, color: Colors.cyan),
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
          //         GoogleMap(
          //         onMapCreated: (GoogleMapController controller) {
          //   _controller.complete(controller);
          // },
          //         initialCameraPosition: CameraPosition(
          //           target: LatLng(45.521563, -122.677433),
          //           zoom: 11.0,
          //         )),
          SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 400,
              child: GoogleMap(
                mapType: MapType.normal,
                onMapCreated: (GoogleMapController controller) {
                  _controller = controller;
                },
                initialCameraPosition: CameraPosition(
                    target: LatLng(42.0041222, 21.4073592), zoom: 10),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,

              )
             // child: Card(child: Text('Hello World!')),
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

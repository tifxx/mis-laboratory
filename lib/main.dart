import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'Model/list_item.dart';
import 'widgets/new_element.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MIS Laboratory exercise No. 3',
      theme: ThemeData(
          primarySwatch: Colors.cyan,
          accentColor: Colors.red,
          textTheme: ThemeData.light()
              .textTheme
              .copyWith(titleMedium: TextStyle(fontSize: 26))),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<ListItem> _elements = [
    ListItem(id: "T1", courseName: "Mobile information systems", dateTime: DateTime(2022, 12, 22, 10, 00)),
    ListItem(id: "T2", courseName: "Web programming", dateTime: DateTime(2022, 12, 19, 11, 00)),
  ];

  void _addItemFunction(BuildContext ct) {
    showModalBottomSheet(
        context: ct,
        builder: (_) {
          return GestureDetector(
              onTap: () {},
              child: NovElement(_addNewItemToList),
              behavior: HitTestBehavior.opaque);
        });
  }

  void _addNewItemToList(ListItem item) {
    setState(() {
      _elements.add(item);
    });
  }

  void _deleteItem(String id) {
    setState(() {
      _elements.removeWhere((elem) => elem.id == id);
    });
  }

  Widget _createBody() {
    return Center(
      child: _elements.isEmpty
          ? Text("No elements")
          : ListView.builder(
              itemBuilder: (ctx, index) {
                return Card(
                  elevation: 3,
                  margin: EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 10,
                  ),
                  child: ListTile(
                    title: Text(_elements[index].courseName, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),),
                    subtitle: Text("${DateFormat("dd/MM/yyyy hh:mm").format(_elements[index].dateTime)}", style: TextStyle(color: Colors.grey)),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteItem(_elements[index].id),
                    ),
                  ),
                );
              },
              itemCount: _elements.length,
            ),
    );
  }

  PreferredSizeWidget _createAppBar() {
    return AppBar(
        title: Text("Laboratory Exercise No. 3", style: TextStyle(color: Colors.white, ),),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add, color: Colors.white,),
            onPressed: () => _addItemFunction(context),
          )
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _createAppBar(),
      body: _createBody(),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lab3/widgets/calendar.dart';
import 'Model/list_item.dart';
import 'widgets/new_element.dart';
import 'package:firebase_core/firebase_core.dart';
import 'widgets/login_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationDetails androidNotificationDetails =
    AndroidNotificationDetails('main_channel', 'Main Channel',
        channelDescription: 'ashwin',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker');
const NotificationDetails notificationDetails = NotificationDetails(
  android: androidNotificationDetails,
  iOS: DarwinNotificationDetails(
    sound: 'default.wav',
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  ),
);

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.requestPermission();

  runApp(MyApp());
}

final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MIS Laboratory exercise No. 3',
      restorationScopeId: 'root',
      theme: ThemeData(
          primarySwatch: Colors.cyan,
          textTheme: ThemeData.light()
              .textTheme
              .copyWith(titleMedium: TextStyle(fontSize: 26))),
      home: MainPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(
        body: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(
                child: Text('Something went wrong!'),
              );
            } else if (snapshot.hasData) {
              final uid = FirebaseAuth.instance.currentUser!.uid;
              return MyHomePage();
            } else {
              return LoginWidget();
            }
          },
        ),
      );
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with RestorationMixin {
  @override
  void initState() {
    super.initState();

    flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  final user = FirebaseAuth.instance.currentUser!;
  List<ListItem> listCourses = [];

  final RestorableInt _index = RestorableInt(0);

  final List<ListItem> _elements = [
    // ListItem(
    //     id: "T1",
    //     courseName: "Mobile information systems",
    //     dateTime: DateTime(2022, 12, 22, 10, 00)),
    // ListItem(
    //     id: "T2",
    //     courseName: "Web programming",
    //     dateTime: DateTime(2022, 12, 19, 11, 00)),
  ];

  Future<List<ListItem>> readItems() => FirebaseFirestore.instance
      .collection('courses')
      .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
      .get()
      .then((response) => response.docs
          .map((element) => ListItem.fromJson(element.data()))
          .toList());

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

  Widget _createBody() {
    return Container(
        alignment: Alignment.center,
        child: new Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(35),
              child: Column(
                children: [
                  Text(
                    "Signed In as:",
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.email!,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
                padding: const EdgeInsets.all(30),
                child: FutureBuilder<List<ListItem>>(
                    future: readItems(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(
                          "Error! ${snapshot.error.toString()}",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w500),
                        );
                      } else if (snapshot.hasData) {
                        listCourses = snapshot.data!;
                        if (listCourses.length == 0) {
                          const Text(
                            "No exams yet!",
                            style: TextStyle(
                                fontSize: 30, fontWeight: FontWeight.w500),
                          );
                        }
                        return ListView(
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          children: listCourses.map(buildCourse).toList(),
                        );
                      } else {
                        return Center(child: CircularProgressIndicator());
                      }
                    })
                //   ),
                ),
            ElevatedButton(
              onPressed: _showCalendar,
              child: const Text(
                "Show calendar",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.cyan,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              ),
            ),
          ],
        ));
  }

  Widget buildCourse(ListItem course) => ListTile(
        title: Text(
          course.courseName,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan),
        ),
        subtitle: Text(
            "${DateFormat("dd/MM/yyyy hh:mm").format(course.dateTime)}",
            style: TextStyle(color: Colors.grey)),
        trailing: FittedBox(
          fit: BoxFit.fill,
          child: Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () async {
                  await deleteCourse(course.id);
                  setState(() => {});
                },
              ),
              IconButton(
                icon: Icon(Icons.access_alarm),
                onPressed: () async {
                  await flutterLocalNotificationsPlugin.show(
                      0,
                      'Reminder for exam',
                      '${course.courseName} on ${DateFormat("dd/MM/yyyy hh:mm").format(course.dateTime)}',
                      notificationDetails,
                      payload: '${course.dateTime.toString()}');
                },
              ),
            ],
          ),
        ),
      );

  Future deleteCourse(String id) async {
    try {
      await FirebaseFirestore.instance.collection("courses").doc(id).delete();
    } catch (e) {
      return false;
    }
  }

  PreferredSizeWidget _createAppBar() {
    return AppBar(
        title: Text(
          "MIS Courses Management",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.add,
              color: Colors.white,
            ),
            onPressed: () => _addItemFunction(context),
          ),
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
            color: Colors.white,
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

  void _showCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Calendar(items: listCourses.toList())),
    );
  }

  @override
  String get restorationId => 'home_page';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_index, 'nav_bar_index');
  }
}

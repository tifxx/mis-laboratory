import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:lab3/widgets/calendar.dart';
import 'package:location/location.dart';
import 'Model/list_item.dart';
import 'widgets/new_element.dart';
import 'package:firebase_core/firebase_core.dart';
import 'widgets/login_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_key.dart';

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
    locatePosition();
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
  GoogleMapController? _controller;
  List<Marker> markers = [];
  List<Polyline> polyline = [];
  List<LatLng> polylineCoordinates = [];
  late geolocator.Position currentPosition;
  var geoLocator = geolocator.Geolocator();

  void locatePosition() async {
    geolocator.Position position =
        await geolocator.Geolocator.getCurrentPosition(
            desiredAccuracy: geolocator.LocationAccuracy.high);
    currentPosition = position;
  }

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
        isScrollControlled: true,
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
              padding: const EdgeInsets.all(25),
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
                padding: const EdgeInsets.all(15),
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
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              ),
            ),
            ElevatedButton(
              onPressed: _showLocations,
              child: const Text(
                "Show locations of exams",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                primary: Colors.cyan,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
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
              IconButton(
                icon: Icon(Icons.location_on_outlined),
                onPressed: () {
                  _onPressedForMap(course);
                },
              ),
            ],
          ),
        ),
      );

  Widget _widget = CircularProgressIndicator();

  void _onPressedForMap(ListItem course) {
    polylineCoordinates.clear();
    getPolyPoints(course.latitude, course.longitude, currentPosition.latitude,
            currentPosition.longitude)
        .then((e) {
      if (polylineCoordinates.isEmpty) {
        setState(() {
          _widget = CircularProgressIndicator();
        });
      } else {
        setState(() => MapScreen(course));
      }
    });
  }

  void MapScreen(ListItem course) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 500,
            child: GoogleMap(
              mapType: MapType.normal,
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
              },
              initialCameraPosition: const CameraPosition(
                  target: LatLng(42.0041222, 21.4073592), zoom: 14),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: setMarker(course.latitude, course.longitude),
              polylines: {
                Polyline(
                  polylineId: PolylineId(course.id),
                  points: polylineCoordinates,
                  color: Colors.red,
                  width: 6,
                ),
              },
            )));
  }

  Future<List<LatLng>?> getPolyPoints(double sourceLat, double sourceLon,
      double destLat, double destLon) async {
    PolylinePoints polylinePoints = PolylinePoints();

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleMapsApiKey,
      PointLatLng(sourceLat, sourceLon),
      PointLatLng(destLat, destLon),
      travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      result.points.forEach(
        (PointLatLng point) => polylineCoordinates.add(
          LatLng(point.latitude, point.longitude),
        ),
      );
      setState(() {});

      return polylineCoordinates;
    } else {
      print(result.errorMessage);
      return null;
    }
  }

  Set<Marker> setMarker(double lat, double lon) {
    LatLng point = LatLng(lat, lon);
    Set<Marker> set = Set();
    Marker marker = Marker(
      markerId: MarkerId('1'),
      position: point,
      infoWindow: InfoWindow(title: 'Location for your exam'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );
    set.add(marker);
    return set;
  }

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
          "Course exams",
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

  void _showLocations() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 500,
            child: GoogleMap(
              mapType: MapType.normal,
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
              },
              initialCameraPosition: const CameraPosition(
                  target: LatLng(42.0041222, 21.4073592), zoom: 14),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: setMarkers(listCourses),
            )));
  }

  Set<Marker> setMarkers(List<ListItem> listCourses) {
    return listCourses.map((course) {
      LatLng point = LatLng(course.latitude, course.longitude);

      return Marker(
        markerId: MarkerId(course.id),
        position: point,
        infoWindow: InfoWindow(title: 'Location for ${course.courseName} exam'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    }).toSet();
  }

  @override
  String get restorationId => 'home_page';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_index, 'nav_bar_index');
  }
}

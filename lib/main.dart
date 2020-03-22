import 'dart:async';
import 'package:location/location.dart' as Location;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_google_webservices/flutter_google_webservices.dart';
import 'package:cached_network_image/cached_network_image.dart';

final _placesApiClient =
    GoogleMapsPlaces(apiKey: "AIzaSyB-6qUvv1d6r98qJQh24KAsMZyal_A_pGU");
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyMaps',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'MyMaps'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

Set<Marker> markers;

class _MyHomePageState extends State<MyHomePage> {
  Stream<QuerySnapshot> data_stream;
  static const kGoogleApiKey = "AIzaSyB-6qUvv1d6r98qJQh24KAsMZyal_A_pGU";
  bool toogle_data = false;

  GoogleMapsPlaces _places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

  MapType type;
  String address;
  final TextEditingController _textController = TextEditingController();
  Location.Location _loc = Location.Location();
  LatLng userloc;
  Location.PermissionStatus _permissionGranted;
  static LatLng _center = const LatLng(21.7679, 78.8718);
  GoogleMapController mapController;
  LatLng _lastMapPosition = _center;
  String night_theme = 'default';
  String _placePhotoUrl = '';
  bool _disposed = false;

  Future<void> _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
  }

  Future<void> getPerm() async {
    if (_permissionGranted != Location.PermissionStatus.GRANTED) {
      _permissionGranted = await _loc.requestPermission();
    }

    print("gg $_permissionGranted");
  }

//function to get live location of user
  void getLiveLoc() {
    _loc.getLocation().then((_location) {
      print("gg $_permissionGranted");
      if (_permissionGranted == Location.PermissionStatus.GRANTED) {
        print("changing view");
      setState(() {
          mapController
            .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
                target: LatLng(
                  _location.latitude,
                  _location.longitude,
                ),
                zoom: 16.0,
                tilt: 45,
                bearing: 90.0)));
      });
      }
    });
  }

  void _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;
  }

  Future<void> _retrievePlacesDetails(String s) async {
    try {
      final details = await _placesApiClient.getDetailsByPlaceId(s);
      if (!_disposed) {
        print("coming in !!");
        setState(() {
          if (details.result != null) {
            _placePhotoUrl = _placesApiClient.buildPhotoUrl(
              photoReference: details.result.photos[0].photoReference,
              maxHeight: 300,
            );
            print("name nae is ${details.result.name}");
          }
        });
      }
    } catch (e) {}
    print("disposed $_disposed");
  }

//to get the place details 
  Future<void> getPlaceDetails() async {
    try {
      // final place =
      //   await _placesApiClient.getDetailsByPlaceId("ChIJF7QkuDsDLz4R0rJ4SsxFl9w");
      //   print("name name is"+place.result.name);

      var details = GetDetails();

      var result = details.getDetailsById("ChIJFznzYW-5wjsR4aa9qvl_zSk",
          "AIzaSyB-6qUvv1d6r98qJQh24KAsMZyal_A_pGU");
      await result.then((onValue) {
        print("data data data is " + onValue.result.rating.toString());
      });
    } catch (e) {
      print("err " + e.toString());
    }
  }


  // to change My Theme to Night Mode used this function
  void changeMapMode() {
    night_theme == 'default'
        ? getJsonFile("assets/night.json").then(setMapStyle).then((val) {
            setState(() {
              night_theme = 'night';
            });
            Fluttertoast.showToast(
                msg: "Night Theme",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIos: 1,
                backgroundColor: Colors.white,
                textColor: Colors.black,
                fontSize: 14.0);
          })
        : getJsonFile("assets/mapStyle.txt").then(setMapStyle).then((val) {
            setState(() {
              night_theme = 'default';
            });
          });
  }

  Future<String> getJsonFile(String path) async {
    return await rootBundle.loadString(path);
  }

  void setMapStyle(String mapStyle) {
    mapController.setMapStyle(mapStyle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        // appBar: AppBar(
        //   title: Text('Maps Sample App'),
        //   backgroundColor: Colors.green[700],
        // ),
        body: Stack(
          children: <Widget>[
            GoogleMap(
              markers: markers,
              mapType: type,
              onMapCreated: _onMapCreated,
              myLocationButtonEnabled: false,
              initialCameraPosition: CameraPosition(target: _center, zoom: 6.0),
              onCameraMove: _onCameraMove,
              myLocationEnabled: true,
              onTap: (position) {
                Marker mk1 = Marker(
                  markerId: MarkerId('1'),
                  position: position,
                );
                setState(() {
                  markers.add(mk1);
                });
                print("tapped" +
                    position.latitude.toString() +
                    " " +
                    position.longitude.toString());
              },
            ),
            Positioned(
              top: 35.0,
              right: 15.0,
              left: 15.0,
              child: Container(
                height: 50.0,
                width: double.infinity,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Colors.white),
                child: TextField(
                  textInputAction: TextInputAction.done,
                  onSubmitted: (value) {
                    print("value is $value");
                    searchAddress();
                  },
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Search Here',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(left: 15.0, top: 15.0),
                    suffixIcon: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          //FocusScope.of(context).unfocus();
                          WidgetsBinding.instance.addPostFrameCallback(
                              (_) => _textController.clear());

                          // _textController.clear();
                        }),
                    prefixIcon: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: searchAddress,
                        iconSize: 30.0),
                  ),
                  onChanged: (val) {
                    setState(() {
                      address = val;
                    });
                  },
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 100.0),
              child: Align(
                alignment: Alignment.topRight,
                child: Column(
                  children: <Widget>[
                    Container(
                      width: 50,
                      height: 50,
                      child: FloatingActionButton(
                        onPressed: () {
                          setState(() {
                            type = type == MapType.hybrid
                                ? MapType.normal
                                : MapType.hybrid;
                          });
                        },
                        child: Icon(Icons.map),
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      child: FloatingActionButton(
                        child: Icon(Icons.zoom_in),
                        onPressed: () async {
                          await (await mapController)
                              .animateCamera(CameraUpdate.zoomIn());
                        },
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      child: FloatingActionButton(
                        child: Icon(Icons.zoom_out),
                        onPressed: () async {
                          await (await mapController)
                              .animateCamera(CameraUpdate.zoomOut());
                        },
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      child: FloatingActionButton(
                        child: Icon(Icons.collections),
                        onPressed: () {
                          changeMapMode();
                        },
                      ),
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 8,
                    ),
                    FloatingActionButton(
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.my_location,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        getLiveLoc();
                      },
                    ),
                  ],
                ),
              ),
            ),
            //floating buttons for different actions
            Padding(
              padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 100.0),
              child: Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: 50,
                        height: 50,
                        child: FloatingActionButton(
                          onPressed: () {
                            if (toogle_data == false) {
                              Fluttertoast.showToast(
                                  msg: "Pizza Stores",
                                  toastLength: Toast.LENGTH_LONG,
                                  gravity: ToastGravity.CENTER,
                                  timeInSecForIos: 1,
                                  backgroundColor: Colors.yellow,
                                  textColor: Colors.black,
                                  fontSize: 14.0);
                              setState(() {
                                toogle_data = true;
                                data_stream = Firestore.instance
                                    .collection("pizza_stores")
                                    .orderBy("name")
                                    .snapshots();
                              });
                            } else {
                              setState(() {
                                toogle_data = false;
                              });
                            }
                          },
                          child: Icon(Icons.local_pizza),
                        ),
                      ),
                      SizedBox(
                        height: 10.0,
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        child: FloatingActionButton(
                          onPressed: () {
                            if (toogle_data == false) {
                              Fluttertoast.showToast(
                                  msg: "Corona Infected Places",
                                  toastLength: Toast.LENGTH_LONG,
                                  gravity: ToastGravity.CENTER,
                                  timeInSecForIos: 1,
                                  backgroundColor: Colors.yellow,
                                  textColor: Colors.black,
                                  fontSize: 14.0);
                              setState(() {
                                toogle_data = true;
                                data_stream = Firestore.instance
                                    .collection("corona_places")
                                    .orderBy("name")
                                    .snapshots();
                              });
                            } else {
                              setState(() {
                                toogle_data = false;
                              });
                            }
                          },
                          child: Icon(Icons.bug_report),
                        ),
                      ),
                    ],
                  )),
            ),//toogling the view of pizza stores and infected places
            toogle_data
                ? Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: StreamBuilder<QuerySnapshot>(
                        stream: data_stream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                                child: Text('Error: ${snapshot.error}'));
                          }
                          if (!snapshot.hasData) {
                            return Center(child: const Text('Loading...'));
                          }

                          return Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: SizedBox(
                                  height: 90,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: snapshot.data.documents.length,
                                    itemBuilder: (builder, index) {
                                      return SizedBox(
                                          width: 340,
                                          child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 8),
                                              child: Card(
                                                  child: Center(
                                                      child: ListTile(
                                                title: Text(snapshot.data
                                                    .documents[index]['name']),
                                                subtitle: Text(
                                                  snapshot.data.documents[index]
                                                      ['address'],
                                                  maxLines: 2,
                                                ),
                                                leading: Container(
                                                  child:
                                                      // ? CircleAvatar(backgroundImage: NetworkImage(_placePhotoUrl))
                                                      CachedNetworkImage(
                                                    imageUrl: snapshot.data
                                                            .documents[index]
                                                        ['image'],
                                                    placeholder:
                                                        (context, url) =>
                                                            SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child:
                                                            CircularProgressIndicator(),
                                                      ),
                                                    ),
                                                    errorWidget: (context, url,
                                                            error) =>
                                                        Icon(Icons.local_pizza),
                                                  ),
                                                  width: 100,
                                                  height: 60,
                                                ),
                                                onTap: () async {
                                                  await _retrievePlacesDetails(
                                                      snapshot.data
                                                              .documents[index]
                                                          ['placeId']);
                                                  final controller =
                                                      mapController;
                                                  await controller
                                                      .animateCamera(
                                                    CameraUpdate
                                                        .newCameraPosition(
                                                      CameraPosition(
                                                        target: LatLng(
                                                          snapshot.data
                                                                      .documents[
                                                                  index]
                                                              ['location'][0],
                                                          snapshot.data
                                                                      .documents[
                                                                  index]
                                                              ['location'][1],
                                                        ),
                                                        zoom: 18,
                                                      ),
                                                    ),
                                                  );
                                                  setState(() {
                                                    markers.add(Marker(
                                                      markerId: MarkerId(snapshot
                                                              .data
                                                              .documents[index]
                                                          ['placeId']),
                                                      position: LatLng(
                                                        snapshot.data.documents[
                                                                index]
                                                            ['location'][0],
                                                        snapshot.data.documents[
                                                                index]
                                                            ['location'][1],
                                                      ),
                                                      infoWindow: InfoWindow(
                                                        title: snapshot
                                                                .data.documents[
                                                            index]['name'],
                                                        snippet: snapshot
                                                                .data.documents[
                                                            index]['address'],
                                                      ),
                                                    ));
                                                  });
                                                },
                                              )))));
                                    },
                                  ),
                                ),
                              ));
                        },
                      ),
                    ),
                  )
                : Container()
          ],
        ));
  }
//init method of flutter lifecycle
  @override
  void initState() {
    super.initState();
    type = MapType.normal;
    markers = Set.from([]);
    getPerm();
  }


  // function to get a value from search bar and search it on map and to mark it.
  void searchAddress() {
    try {
      Geolocator().placemarkFromAddress(address).then((result) {
        if (result != null) {
          print("tapped" +
              result[0].position.latitude.toString() +
              " " +
              result[0].position.longitude.toString());
          mapController.animateCamera(CameraUpdate.newCameraPosition(
              CameraPosition(
                  target: LatLng(result[0].position.latitude,
                      result[0].position.longitude),
                  zoom: 15.0)));
          Marker mk1 = Marker(
            markerId: MarkerId(_lastMapPosition.toString()),
            position: LatLng(
                result[0].position.latitude, result[0].position.longitude),
            infoWindow: InfoWindow(title: address),
          );
          setState(() {
            // markers.clear();
            print("adding adding adding markerers");
            markers.add(mk1);
          });
        } else {
          print("addressnotfound");
        }
      });
    } on PlatformException catch (e) {
      //Flutter Toasts to show the toast messages
      Fluttertoast.showToast(
          msg: "Address not found",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIos: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 14.0);
    } catch (error) {
      Fluttertoast.showToast(
          msg: "Address not found",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIos: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 14.0);
    }
  }
}

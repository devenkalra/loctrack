// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:flutter_map/flutter_map.dart';
import 'package:map_controller/map_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:loctrack/models/location.dart';
import 'dart:developer' as dvl;
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'dart:async';
import 'dart:math' show cos, sqrt, asin;
import 'map.dart';

//import 'package:loctrack/screens/location.dartx';
import 'package:window_size/window_size.dart';
import 'dart:developer';
import 'package:latlong/latlong.dart';
//import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';


void main() {
  log("In Main");
  setupWindow();
  runApp(MyApp());
}

const double windowWidth = 800;
const double windowHeight = 1000;

void setupWindow() {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    WidgetsFlutterBinding.ensureInitialized();
    setWindowTitle('Provider Demo');
    setWindowMinSize(const Size(windowWidth, windowHeight));
    setWindowMaxSize(const Size(windowWidth, windowHeight));
    getCurrentScreen().then((screen) {
      setWindowFrame(Rect.fromCenter(
        center: screen.frame.center,
        width: windowWidth,
        height: windowHeight,
      ));
    });
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LocApp(),
    );
  }
}

class LocApp extends StatefulWidget {
  const LocApp({
    Key key,
  }) : super(key: key);

  @override
  _LocAppState createState() => _LocAppState();
}

class _LocAppState extends State<LocApp> {
  AppState _state = AppState();
  CitiesManager citiesManager;

  void _handleCitiesUpdate(dynamic d) {
    //dvl.log("Handle Cities Update");
    setState(() {});
  }

  _LocAppState() : super() {
    _state.lastMarkerUpdateLocation(_state.mapState.location());
    citiesManager = CitiesManager(
        geoMarkersState: _state.markerState,
        citiesUpdated: _handleCitiesUpdate);
    // ##### citiesManager.updateCitiesAroundLocation(_state.lastMarkerUpdateLocation());
  }

  /**
   * Update the location of the device
   * Update GeoMarkers if location has moved substiantially
   */

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  bool cityUpdateQueuePending = false;
  Timer cityUpdateQueueTimer;

  void queueCityUpdateNeedLater() {
    if (cityUpdateQueuePending) {
      dvl.log("Cancel Timer");
      cityUpdateQueueTimer.cancel();
      cityUpdateQueuePending = false;
    }
    dvl.log("Queuing");
    cityUpdateQueueTimer = Timer(Duration(milliseconds: 5000), () {
      dvl.log("Executing");
      updateMarkerDataIfNeeded();
    });
    cityUpdateQueuePending = true;
  }

  void updateMarkerDataIfNeeded() {
    LatLng l = _state.mapState.location();
    double distance = calculateDistance(
        l.latitude,
        l.longitude,
        _state.lastMarkerUpdateLocation().latitude,
        _state.lastMarkerUpdateLocation().longitude);
    //dvl.log("Distance =" + distance.toString());
    if (distance > 5) {
      dvl.log("Distance > 5");
      if (citiesManager.updateCitiesAroundLocation(l)) {
        _state.lastMarkerUpdateLocation(_state.mapState.location());
      } else {
        queueCityUpdateNeedLater();
      }
    }
  }

  void moveLocation(double x_speed, double y_speed) {
    dvl.log("moveLocation");
    LatLng l = _state.mapState.location();
    l.latitude = l.latitude + 0.005 * y_speed;
    l.longitude = l.longitude + 0.005 * x_speed;
    _state.mapState.updateLocation(l);
    updateMarkerDataIfNeeded();
    setState(() {});
  }

  void zoomIn(){
    double current_zoom = _state.mapState.zoom;
    _state.mapState.zoom = current_zoom + 1;
    setState(() {});
  }

  void zoomOut(){
    double current_zoom = _state.mapState.zoom;
    _state.mapState.zoom = current_zoom - 1;
    setState(() {});
  }

  void mapEventHandler(Map m) {
    String type = m["type"];
    LatLng l = m["location"];
    switch (type) {
      case 'LTap':
        _state.mapState.updateLocation(l);
        moveLocation(0, 0);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    //dvl.log("Calling LocApp Build, location:" +
    //    _state.mapState.location.toString());

    /*
    _state.markerState.markers.add(GeoMarker(
        location:
            LatLng(_state.mapState.mapCenterLat, _state.mapState.mapCenterLng),
        name: "My Location"));
*/
    return MyMap(center:LatLng(37.25898, -122.02903), zoom:15);
    return Stack(textDirection: TextDirection.ltr, children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          LocMap(state: _state, eventHandler: this.mapEventHandler)
        ])
      ]),
      LocationText(mapState: _state.mapState),
      SizedBox(
          width: 200,
          height: 200,
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                  child: Text(
                    "Forward",
                    style: TextStyle(fontSize: 20),
                  ),
                  onPressed: () => moveLocation(0, 1))
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              ElevatedButton(
                  child: Text(
                    "Left",
                    style: TextStyle(fontSize: 20),
                  ),
                  onPressed: () => moveLocation(-1, 0)),
              SizedBox(
                  width: 20,
                  height: 20,
                  child: ElevatedButton(
                      child: Text(
                        "C",
                        style: TextStyle(fontSize: 10),
                      ),
                      onPressed: () => moveLocation(0, 0))),
              ElevatedButton(
                  child: Text(
                    "Right",
                    style: TextStyle(fontSize: 20),
                  ),
                  onPressed: () => moveLocation(1, 0))
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                  child: Text(
                    "Down",
                    style: TextStyle(fontSize: 20),
                  ),
                  onPressed: () => moveLocation(0, -1))
            ]),Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                  child: Text(
                    "Zoom In",
                    style: TextStyle(fontSize: 20),
                  ),
                  onPressed: () => zoomIn())
            ]),Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              ElevatedButton(
                  child: Text(
                    "Zoom Out",
                    style: TextStyle(fontSize: 20),
                  ),
                  onPressed: () => zoomOut())
            ]),
          ])),
    ]);
  }
}

class Place {
  Place(String type, String n, [LatLng l = null]) {
    _type = type;
    _name = n;
    _location = l;
  }

  String _name = "";
  LatLng _location = null;
  String _type = "";

  String get name => _name;

  LatLng get location => _location;
}

class CitiesManager {
  GeoMarkersState geoMarkersState;
  final ValueChanged citiesUpdated;
  bool cityUpdateInProgress = false;
  DateTime timeLastCityUpdateStarted = DateTime(0);

  CitiesManager({this.geoMarkersState, this.citiesUpdated});

  bool nodeHasTag(XmlNode node, String tagAttribute, String tagAttributeValue,
      {String value = null}) {
    var tags = node.findAllElements("tag");
    for (var tag in tags) {
      //print("Tag:"+tag.toString());
      var key = tag.getAttribute(tagAttribute);
      if (key == tagAttributeValue) {
        return true;
      }
    }
    return false;
  }

  LatLng getWayCenter(XmlNode node){
    var center = node.findElements("center");
    if(center != null){
      String lat = center.first.getAttribute("lat");

      String lon = center.first.getAttribute("lon");
      if(lat != null && lon != null) {
        return LatLng(double.parse(lat), double.parse(lon));
      }
    }
    return LatLng(0, 0);

  }
  void parseResponseAirportWays(XmlDocument document, List<Place> places) {
    var nodes = document.findAllElements('way');
    for (var node in nodes) {
      if (nodeHasTag(node, "k", "aeroway")) {
        LatLng location = getWayCenter(node);
        var tags = node.findAllElements("tag");
        String name = "";
        String type = "";
        for (var tag in tags) {
          //print("Tag:" + tag.attributes.toString());
          var key = tag.getAttribute("k");
          String attribute = tag.getAttribute("v");
          if (attribute == null) {
            attribute = "";
          }
          switch (key) {
            case "name":
              name = attribute;
              dvl.log("Name=${name}");
              break;
          }
        }
        if (location != null) {
          dvl.log("Place: ${type}, ${name}, ${location.toString()}");
          places.add(Place("place_airport", name, location));
        }
      }
    }
  }

  void parseResponseNodes(XmlDocument document, List<Place> places) {
    var nodes = document.findAllElements('node');

    for (var node in nodes) {
      //print(node.toString());
      if (nodeHasTag(node, "k", "place")) {
        String latS = node.getAttribute("lat");
        String lngS = node.getAttribute("lon");
        LatLng location = null;
        if (latS != null && lngS != null) {
          location = LatLng(double.parse(latS), double.parse(lngS));
        }
        var tags = node.findAllElements("tag");
        String name = "";
        String type = "";
        for (var tag in tags) {
          //print("Tag:" + tag.attributes.toString());
          var key = tag.getAttribute("k");
          String attribute = tag.getAttribute("v");
          if (attribute == null) {
            attribute = "";
          }
          switch (key) {
            case "name":
              name = attribute;
              dvl.log("Name=${name}");
              break;
            case "place":
              type = "place_" + attribute;
              break;
          }
        }
        if (location != null) {
          dvl.log("Place: ${type}, ${name}, ${location.toString()}");
          places.add(Place(type, name, location));
        }
      }
    }
  }

  List<Place> getPlaces(http.Response p) {
    //aprint(p.body.toString());
    final document = XmlDocument.parse(p.body);
    List<Place> places =
        List<Place>.generate(0, (index) => Place("", "", null));
    places.clear();
    parseResponseNodes(document, places);
    parseResponseAirportWays(document, places);
    //print("NumPlaces:${places.length.toString()}");
    return places;
  }

  void updateMarkersState(List<Place> places) {
    //dvl.log("++++++ Update Markers State");
    //dvl.log("Num Places found:" + places.length.toString());
    geoMarkersState.clear();
    for (Place p in places) {
      //dvl.log("Place:" + p.name);
      geoMarkersState.add(GeoMarker(name: p.name, location: p.location, type:p._type));
    }
    dvl.log("City update completed");
    cityUpdateInProgress = false;
    citiesUpdated("");
  }

  Future<http.Response> getGeoEntitiesByLatLng(
      LatLng l, double distance, List<String> types) {
    double c_lat = l.latitude;
    double c_lng = l.longitude;
    String query = "";
    for (String type in types) {
      if (type == "cities") {
        query +=
            'node(around:${distance.toString()},${c_lat.toString()}, ${c_lng.toString()})["place"="city"];>;';
        query +=
            'node(around:${distance.toString()},${c_lat.toString()}, ${c_lng.toString()})["place"="town"];>;';
      } else if (type == "airports") {
        query +=
            'way(around:${distance.toString()},${c_lat.toString()}, ${c_lng.toString()})["aeroway"="aerodrome"];>;';
      }
    }
    query = "(${query});out center body;";

    print("Query:" + query);
    return http.post(Uri.parse('https://overpass-api.de/api/interpreter'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: query);
  }

  bool updateCitiesAroundLocation(LatLng l) {
    dvl.log("Now:" + DateTime.now().toString());
    dvl.log("Last:" + timeLastCityUpdateStarted.toString());
    dvl.log("InProgress:" + cityUpdateInProgress.toString());
    if (!cityUpdateInProgress &&
        DateTime.now().difference(timeLastCityUpdateStarted).inSeconds > 10) {
      dvl.log("Started City Lookup");
      timeLastCityUpdateStarted = DateTime.now();
      cityUpdateInProgress = true;
      getGeoEntitiesByLatLng(l, 20000, ["cities", "airports"])
          .then((p) => updateMarkersState(getPlaces(p)));
      return true;
    }
    return false;
  }
}

class LocationText extends StatelessWidget {
  MapState mapState;

  LocationText({Key key, this.mapState});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Column(mainAxisAlignment: MainAxisAlignment.start, children: [
        Text(mapState.locationAltitude.toStringAsFixed(0),
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 80,
            )),
        Text(mapState.locationLat.toStringAsFixed(4),
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 40,
            )),
        Text(mapState.locationLng.toStringAsFixed(4),
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 40,
            ))
      ])
    ]);
  }
}

class LocMap extends StatefulWidget {
  AppState state;
  MapState mapState;
  GeoMarkersState geoMarkers;
  final ValueChanged<Map> eventHandler;

  LocMap({Key key, this.state, this.eventHandler})
      : super(key: key) {
    mapState = this.state.mapState;
    geoMarkers = this.state.markerState;
  }

  @override
  _LocMapState createState() => _LocMapState();
}

class _LocMapState extends State<LocMap> {
  MapController mapController = MapController();

  StatefulMapController statefulMapController;
  StreamSubscription<StatefulMapControllerStateChange> sub;

  void mapControllerHandler(change) {
    dvl.log("SMC");
    setState(() {});
  }

  MapDisplayState() {
    //mapController = MapController();
    statefulMapController = StatefulMapController(mapController: mapController);
    // wait for the controller to be ready before using it
    //statefulMapController.onReady
    //    .then((_) => print("The map controller is ready"));

    statefulMapController.onReady.then((_) {
      dvl.log("SMC Ready");
      statefulMapController.changeFeed.listen((change) {
        dvl.log("Change");
        // setState(() {});
      });
    });

    /// [Important] listen to the changefeed to rebuild the map on changes:
    /// this will rebuild the map when for example addMarker or any method
    /// that mutates the map assets is called
    sub = statefulMapController.changeFeed
        .listen((change) => mapControllerHandler(change));
  }

  @override
  void initState() {
    //dvl.log("Init State Map State");
    super.initState();
    //dvl.log("IS location:" + widget.location.mapCenter.toString());
    statefulMapController = StatefulMapController(mapController: mapController);
    // wait for the controller to be ready before using it
    //statefulMapController.onReady
    //    .then((_) => print("The map controller is ready"));

    statefulMapController.onReady.then((_) {
      dvl.log("SMC Ready");
      statefulMapController.changeFeed.listen((change) {
        dvl.log("Change");
        // setState(() {});
      });
    });

    /// [Important] listen to the changefeed to rebuild the map on changes:
    /// this will rebuild the map when for example addMarker or any method
    /// that mutates the map assets is called
    sub = statefulMapController.changeFeed
        .listen((change) => mapControllerHandler(change));
  }

  @override
  void didUpdateWidget(old) {
    //dvl.log("Old:" + old.location.mapCenter.toString());
    //dvl.log("LocMap updated");
    super.didUpdateWidget(old);
    //dvl.log("Update Location: " + widget.mapState.location.toString());
    mapController.move(widget.mapState.location(), widget.mapState.zoom);
  }

  @override
  Widget build(BuildContext context) {
    GeoMarkersState geoMarkers = widget.geoMarkers;
    //dvl.log("GM:" + geoMarkers.toString());
    List<Marker> markers = [];
    markers.add(Marker(
        width: 80.0,
        height: 80.0,
        point: widget.state.mapState.location(),
        builder: (ctx) => Container(
              child: Container(
                child: CustomPaint(
                  painter: OpenPainter(0, 0, Color(0xffaa44aa), "Me"),
                ),
              ),
            )));
    markers.add(Marker(
        width: 80.0,
        height: 80.0,
        point: widget.state.lastMarkerUpdateLocation(),
        builder: (ctx) => Container(
              child: Container(
                child: CustomPaint(
                  painter: OpenPainter(0, 0, Color(0xffaa0000), "Me"),
                ),
              ),
            )));
    String s = "";
    for (Marker x in markers) {
      s += x.point.toString();
    }
    //dvl.log("Markers:" + s);
    for (GeoMarker m in geoMarkers.markers) {
      //dvl.log("Marker Loc Loc Map:" + widget.mapState.location.toString());
      Color markerColor = Colors.cyan;
      if(m.type == "place_airport"){
        markerColor = Colors.green;
      }
      else if(m.type == "place_town"){
        markerColor = Colors.blue;
      }
      markers.add(Marker(
          width: 80.0,
          height: 80.0,
          point: m.location(),
          builder: (ctx) => Container(
                child: Container(
                  child: CustomPaint(
                    painter: OpenPainter(0, 0, markerColor, m.name()),
                  ),
                ),
              )));
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Column(children: [
        SizedBox(
            width: windowWidth,
            height: windowHeight,
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                  onTap: (LatLng latlng) {
                    dvl.log("Got Tap on " + latlng.toString());
                  },
                  onLongPress: (LatLng latLng) {
                    dvl.log("Got LTap on " + latLng.toString());
                    widget.eventHandler({"type": "LTap", "location": latLng});
                  },
                  center: LatLng(0.0, 0.0),
                  zoom: widget.mapState.zoom),
              layers: [
                TileLayerOptions(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c'],
                ),
                MarkerLayerOptions(markers: markers),
              ],
            ))
      ])
    ]);
  }
}

class OpenPainter extends CustomPainter {
  var x = 0.0;
  var y = 0.0;
  Color fillColor = Colors.pink;

  String text = "";

  OpenPainter(x, y, fillColor, text) {
    this.x = x;
    this.y = y;
    this.fillColor = fillColor;
    this.text = text;
  }

  @override
  void paint(Canvas canvas, Size size) {
    double markerRadius = 4;
    var paint1 = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final textStyle = TextStyle(
      color: Colors.cyan,
      fontSize: 10,
    );
    final textSpan = TextSpan(
      text: this.text,
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    final xCenter = (size.width - textPainter.width) / 2;
    final yCenter = (size.height - textPainter.height) / 2;
    final offset = Offset(xCenter, yCenter + markerRadius * 2);
    //textPainter.paint(canvas, offset);
    canvas.drawCircle(
        Offset(
            xCenter + textPainter.width / 2, yCenter + textPainter.height / 2),
        markerRadius,
        paint1);

    final paint = Paint()
      ..color = Color(0xffaa44aa)
      ..strokeWidth = 4;
    //canvas.drawLine(Offset(27, 632), Offset(x, y), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/*
    LocApp
       LocationText
       Map

 */

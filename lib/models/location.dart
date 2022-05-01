// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

//import 'package:provider_shopper/models/catalog.dart';
import 'package:latlong/latlong.dart';
import 'dart:developer';
import 'dart:developer' as dev;
class GeoMarker {
  String _name = "";
  LatLng _location = LatLng(51.0, 0.0);
  String _type = "";
  String get type => _type;

  LatLng location([LatLng p=null]){
    if (p != null){
      _location.latitude = p.latitude;
      _location.longitude = p.longitude;
    }
    return _location;
  }


  dynamic name([String n=null]){
    if (n != null){
      _name = n;
      return this;
    }else{
      return _name;
    }
  }

  GeoMarker({name, location, String type=""}) {
    _name = name;
    _location = location;
    _type = type;
  }
}


class GeoMarkersState {
  List<GeoMarker> _markers = List<GeoMarker>.generate(
      0, (index) => GeoMarker(location: LatLng(51.0, 0.0), name: "New"));

  List<GeoMarker> get markers => _markers;

  GeoMarkersState() {
    dev.log("Creating Geo Marker State");
    _markers = [];
    _markers
        .add(GeoMarker(location: LatLng(37.25898, -122.02903), name: "XYZ"));
    dev.log("Init:" + toString());
  }

  GeoMarkersState clear(){
    _markers.clear();
    return this;
  }
  GeoMarkersState add(GeoMarker g){
    _markers.add(g);
    return this;
  }

  String toString() {
    String s = "";
    for (GeoMarker m in markers) {
      s += "Marker: " + m.location.toString();
    }
    return s;
  }

}

class MapState {
  /// The private field backing [catalog].
  // CatalogModel _catalog;
  var _altitude = 542.0;
  var _mapCenter = LatLng(36.905980, -122.028030);
  var _location = LatLng(37.255980, -122.028030);
  var _zoom = 10.0;

  double get locationLat => _location.latitude;

  double get locationLng => _location.longitude;

  double get mapCenterLat => _mapCenter.latitude;

  double get mapCenterLng => _mapCenter.longitude;

  double get locationAltitude => _altitude;

  double get zoom => _zoom;

  void set zoom(double z){
    _zoom = z;
  }

  void set altitude(double a){
    _altitude = a;
  }

  dynamic location([LatLng l = null]){
    if (l != null) {
      _location.latitude = l.latitude;
      _location.longitude = l.longitude;
      return this;
    }else{
      return _location;
    }
  }

  LatLng get mapCenter => _mapCenter;

  void simulateChange(){

  }
  MapState setMapCenter(LatLng l) {
    _mapCenter = l;
    return this;
  }

  void updateMapCenter(LatLng pos) {
    _mapCenter = pos;
    log("Updating Center ${pos}");
  }

  void updateLocation(LatLng pos) {
    _location = LatLng(pos.latitude, pos.longitude);
  }

  LatLng moveLatLng(LatLng l, [List<double> delta = const []]) {
    if (delta.length == 0) {
      return LatLng(l.latitude + 0.001, l.longitude + 0.002);
    } else {
      return LatLng(l.latitude + delta[0], l.longitude + delta[1]);
    }
  }

  LatLng moveLatLngBack(LatLng l) {
    return LatLng(l.latitude - 0.03, l.longitude - 0.05);
  }

  void moveMe() {
    log("Moving Map Center");
    updateMapCenter(LatLng(mapCenterLat + 0.03, mapCenterLng + 0.05));
  }

  void moveBack() {
    log("Moving Location back");
    updateLocation(LatLng(locationLat - 0.05, locationLng - 0.03));
  }
}

class AppState {
   GeoMarkersState _markerState;
   MapState _mapState;
  LatLng _lastMarkerUpdateLocation = LatLng(0.0, 0.0);

  AppState() {
    dev.log("Creating AppState");
    _markerState = GeoMarkersState();
    _mapState = MapState();
  }

  dynamic lastMarkerUpdateLocation([LatLng p=null]){
    if(p != null) {
      _lastMarkerUpdateLocation.longitude = p.longitude;
      _lastMarkerUpdateLocation.latitude = p.latitude;
      return this;
    }else{
      return _lastMarkerUpdateLocation;
    }
  }

  MapState get mapState => _mapState;
  GeoMarkersState get markerState => _markerState;
}

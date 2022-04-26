// Copyright 2019 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
//import 'package:provider_shopper/models/catalog.dart';
import 'package:latlong/latlong.dart' as latLng;
import 'dart:developer';

class LocationModel {
  /// The private field backing [catalog].
  //late CatalogModel _catalog;

  var _altitude = 542.0;
  var _mapCenter = latLng.LatLng(37.255980, -122.028030);
  var _location = latLng.LatLng(37.255980, -122.028030);
  var _zoom = 12.0;
  double get locationLat => _location.latitude;
  double get locationLng => _location.longitude;
  double get mapCenterLat => _mapCenter.latitude;
  double get mapCenterLng => _mapCenter.longitude;
  double get locationAltitude => _altitude;
  double get zoom => _zoom;

  latLng.LatLng get location => _location;
  latLng.LatLng get mapCenter => _mapCenter;

  void set mapCenter(latLng.LatLng l){
    _mapCenter = l;

  }

  void updateMapCenter(latLng.LatLng pos) {
    _mapCenter = pos;
    log("Updating Center ${pos}");
  }

  void updateLocation(latLng.LatLng pos) {
    _location = pos;
  }
  latLng.LatLng moveLatLng(latLng.LatLng l, [List<double> delta = const[]]){
    if(delta.length == 0) {
      return latLng.LatLng(l.latitude + 0.001, l.longitude + 0.002);
    }else{
      return latLng.LatLng(l.latitude + delta[0], l.longitude + delta[1]);

    }
  }
  latLng.LatLng moveLatLngBack(latLng.LatLng l){
    return latLng.LatLng(l.latitude - 0.03, l.longitude - 0.05);
  }
  void moveMe(){
    log("Moving Map Center");
    updateMapCenter(latLng.LatLng(mapCenterLat + 0.03, mapCenterLng + 0.05) );
  }

  void moveBack(){
    log("Moving Location back");
    updateLocation(latLng.LatLng(locationLat - 0.05, locationLng - 0.03) );
  }
}

/*
FlutterMap(

import 'package:flutter/cupertino.dart';

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
)
*/
import 'dart:io';
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
import 'dart:math' as math;

import 'package:complex/fastmath.dart';

//import 'package:loctrack/screens/location.dartx';
import 'package:window_size/window_size.dart';
import 'dart:developer';
import 'package:latlong/latlong.dart';

class MyMap extends StatefulWidget {
  LatLng center = null;
  double zoom;

  MyMap({Key key, this.center, this.zoom}) : super(key: key);

  @override
  _MyMapState createState() => _MyMapState();
}

class _MyMapState extends State<MyMap> {
  final TILE_SIZE = 512;
  double width = 60, height = 1200;
  final PI = 3.1415927;

  List<double> deg2num(LatLng l, double zoom) {
    double lat_rad = l.latitude * PI / 180;
    double n = math.pow(2.0, zoom);
    double xtile = ((l.longitude + 180.0) / 360.0 * n);
    double ytile =
        ((1.0 - math.log(math.tan(lat_rad) + (1 / math.cos(lat_rad))) / PI) /
            2.0 *
            n);
    return [xtile, ytile];
  }

  LatLng num2deg(int xtile, int ytile, double zoom) {
    double n = math.pow(2.0, zoom);
    double lon_deg = xtile / n * 360.0 - 180.0;
    double lat_rad = math.atan(sinh(PI * (1 - 2 * ytile / n)));
    double lat_deg = lat_rad * 180 / PI;
    LatLng(lat_deg, lon_deg);
  }

  @override
  Widget build(BuildContext context) {
    List<double> d_t = deg2num(widget.center, widget.zoom);
    print("D:${d_t[0]}, ${d_t[1]}");
    List<int> t = [d_t[0].toInt(), d_t[1].toInt()];
    int nXTiles = (width.toDouble() / TILE_SIZE).ceil();

    print("width=${width}, height=${height}");
    int nYTiles = (height.toDouble() / TILE_SIZE + 0.5).ceil();
    if (nXTiles % 2 == 1) {
      nXTiles++;
    }
    if (nYTiles % 2 == 1) {
      nYTiles++;
    }
    print("nXTiles=${nXTiles}, nYTiles=${nYTiles}");
    int xOffset = ((d_t[0] - t[0]) * TILE_SIZE).toInt();
    int yOffset = ((d_t[1] - t[1]) * TILE_SIZE).toInt();

    List<Widget> rows = [];
    String iUrl = "";
    int startYTile = t[1] - (nYTiles / 2 + 0.1).toInt();
    for (int y = 0; y < nYTiles; y++) {
      int startXTile = t[0] - (nXTiles / 2 + 0.1).toInt();
      List<Widget> cols = [];
      for (int x = 0; x < nXTiles; x++) {
        String url =
            'http://a.tile.openstreetmap.org/${widget.zoom.toInt()}/${startXTile}/${startYTile}.png';
        print(url);
        iUrl = url;
        startXTile++;
        cols.add(Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(width: 2.0, color: Color(0xFFFFFFFF)),
                left: BorderSide(width: 2.0, color: Color(0xFFFFFFFF)),
                right: BorderSide(width: 2.0, color: Color(0xFFFF0000)),
                bottom: BorderSide(width: 2.0, color: Color(0xFFFF0000)),
              ),
            ),
            child: Image(
              image: NetworkImage(url)
            )));
      }
      startYTile++;
      rows.add(Row(children: cols));
    }

    return  Container(
      alignment:Alignment.center,
      child:ClipRect(
        child:Align(
          heightFactor: 0.5,
            widthFactor: 1.0,
            alignment: Alignment(-1.0, -1.0),
            child:Column(children:rows)   //Image.network(iUrl)
        )
      )
    );

    return SizedBox(
        width:1000,
        height:100,
        child:ClipOval(
        child: Container(
            child: Align(
                alignment: Alignment.center,
                widthFactor: 0.4,
                heightFactor: 0.5,
                child: Image.network(iUrl)
                ))));
  }

  _MyMapState() : super() {}
}

class WrapExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 480,
      child: Card(
        child: Wrap(
          direction: Axis.horizontal,
          spacing: 8.0, // gap between adjacent chips
          runSpacing: 4.0, // gap between lines
          children: <Widget>[
            Chip(
              avatar: CircleAvatar(
                  backgroundColor: Colors.blue.shade900, child: Text('AH')),
              label: Text('Hamilton'),
            ),
            Chip(
              avatar: CircleAvatar(
                  backgroundColor: Colors.blue.shade900, child: Text('ML')),
              label: Text('Lafayette'),
            ),
            Chip(
              avatar: CircleAvatar(
                  backgroundColor: Colors.blue.shade900, child: Text('HM')),
              label: Text('Mulligan'),
            ),
            Chip(
              avatar: CircleAvatar(
                  backgroundColor: Colors.blue.shade900, child: Text('JL')),
              label: Text('Laurens'),
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart' as latlng;

class History extends StatefulWidget {
  final ethUtils;
  final contractInfo;
  const History({super.key, this.ethUtils, this.contractInfo});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  List<Marker> markers = [];

  latlng.LatLng startingCoord = latlng.LatLng(7.052977, 38.486543);

  @override
  void initState() {
    getEmployeeLocations();
    // TODO: implement initState
    super.initState();
  }

  void getEmployeeLocations() async {
    List<Marker> m = [];
    double lat = double.parse(getCoordFromOffset(
        widget.contractInfo['coord_lat'], widget.contractInfo['lat_offset']));
    double lng = double.parse(getCoordFromOffset(
        widget.contractInfo['coord_long'], widget.contractInfo['lng_offset']));
    latlng.LatLng v = latlng.LatLng(lat, lng);
    m.add(Marker(
      width: 40,
      height: 40,
      point: v,
      builder: (context) => const Icon(
        Icons.location_on_rounded,
        color: Colors.black,
      ),
    ));
    var len = await widget.ethUtils.getEmployeeLocationCount();
    // var empLocation = await widget.ethUtils.getEmployeeLocation(BigInt.from(0));
    // len = 1;
    for (int i = 0; i < int.parse(len.toString()); i++) {
      var empLocation =
          await widget.ethUtils.getEmployeeLocation(BigInt.from(i));
      if (int.parse(empLocation[1].toString()) ==
          int.parse(widget.contractInfo['id'])) {
        double lg =
            double.parse(getCoordFromOffset(empLocation[2], empLocation[3]));
        double lt =
            double.parse(getCoordFromOffset(empLocation[4], empLocation[5]));
        bool status = empLocation[8];
        latlng.LatLng vv = latlng.LatLng(lt, lg);
        m.add(Marker(
          width: 50,
          height: 50,
          point: vv,
          builder: (context) => Icon(
            Icons.location_history_outlined,
            color: status ? Colors.green : Colors.red,
          ),
        ));
      }
    }

    print("HISTORY ###########");
    setState(() {
      markers = m;
    });
  }

  String getCoordFromOffset(coord, index) {
    String val = "";
    var p = [
      coord.toString().substring(0, int.parse(index.toString())),
      ".",
      coord.toString().substring(int.parse(index.toString()))
    ];
    val = p.join('');
    return val;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("History"),
      ),
      body: FlutterMap(
        options: MapOptions(center: startingCoord, zoom: 15.0),
        layers: [
          TileLayerOptions(
            urlTemplate:
                "https://api.mapbox.com/styles/v1/natrix/ckg6wnrz7114z19nwrt4j8taw/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoibmF0cml4IiwiYSI6ImNrM2FkeXZhZzBhdGgzZ21ycGM0bzd1MXIifQ.RWcyUBbXiv2jbzebgNNdSA",
            additionalOptions: {
              'accessToken':
                  'pk.eyJ1IjoibmF0cml4IiwiYSI6ImNrM2FkeXZhZzBhdGgzZ21ycGM0bzd1MXIifQ.RWcyUBbXiv2jbzebgNNdSA',
              'id': 'mapbox.mapbox-streets-v8'
            },
          ),
          MarkerLayerOptions(
            markers: markers,
          ),
        ],
      ),
    );
  }
}

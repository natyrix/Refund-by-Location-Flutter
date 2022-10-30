import 'dart:async';
import 'dart:ffi';
import 'dart:math' show cos, sqrt, asin;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong/latlong.dart' as latlng;
import 'package:location_permissions/location_permissions.dart';
import 'package:refund_location_mob_app/contract_utils.dart';
import 'package:refund_location_mob_app/pages/history.dart';
import 'package:refund_location_mob_app/utils.dart';

//https://api.mapbox.com/styles/v1/natrix/ckg6wnrz7114z19nwrt4j8taw/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoibmF0cml4IiwiYSI6ImNrM2FkeXZhZzBhdGgzZ21ycGM0bzd1MXIifQ.RWcyUBbXiv2jbzebgNNdSA
class MapPage extends ConsumerStatefulWidget {
  final String address;
  const MapPage(this.address, {super.key});
  static const String ACCESS_TOKEN =
      "pk.eyJ1IjoibmF0cml4IiwiYSI6ImNrM2FkeXZhZzBhdGgzZ21ycGM0bzd1MXIifQ.RWcyUBbXiv2jbzebgNNdSA";

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  bool isTrackingEnabled = false;
  String employeeAdress = "0x806d6834f5991fc0bde702d546702131690aa1d2";

  latlng.LatLng startingCoord = latlng.LatLng(7.052977, 38.486543);

  Map<String, dynamic> contractInfo = {};
  bool hasContract = false;

  List<Marker> markers = [];
  late Timer timer;

  @override
  void initState() {
    // TODO: implement initState
    initLocation();
    super.initState();
  }

  @override
  void dispose() {
    try {
      timer.cancel();
    } catch (e) {}
    // TODO: implement dispose
    super.dispose();
  }

  // void getEmployeesCount(ethUtils) async {
  //   print("*********SENDING");
  //   // ethUtils.getEmployeeCount();
  //   print("SENT***********");
  // }

  void initLocation() async {
    PermissionStatus st = await checkPermission();
    if (st == PermissionStatus.granted) {
      Position? position = await getCurrentLocation();
      if (position != null) {
        latlng.LatLng v = latlng.LatLng(position.latitude, position.longitude);
        List<Marker> m = [
          Marker(
            width: 40,
            height: 40,
            point: v,
            builder: (context) => const Icon(
              Icons.location_history,
              color: Colors.black54,
            ),
          )
        ];
        setState(() {
          startingCoord = v;
          markers = m;
        });
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: errorColor,
          content: Text(
            "Location Error",
            style: TextStyle(
              fontSize: 15,
              color: primaryColor,
            ),
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } else {
      await LocationPermissions().requestPermissions();
      initLocation();
    }
  }

  Future<Position?> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      return position;
    } catch (e) {
      print(e);
      return null;
    }
  }

  checkPermission() async {
    PermissionStatus permission =
        await LocationPermissions().checkPermissionStatus();
    return permission;
  }

  void track(ethUtils) async {
    try {
      timer.cancel();
    } catch (e) {
      print(e);
    }
    try {
      print("*********SENDING");
      var len = await ethUtils.getContractCount();
      bool isFound = false;
      // print("*********");
      // print(len);
      // print(len.runtimeType);
      /**
       * uint id;
        address employee_address;
        address employer_address;
        uint coord_long;
        uint lng_offset;
        uint coord_lat;
        uint lat_offset;
        uint radius;
       * 
       * 
       */
      for (int i = 0; i < int.parse(len.toString()); i++) {
        var resContract = await ethUtils.getContract(BigInt.from(i));
        print("CHECK ADDRESS");
        print(resContract[1].toString());
        print(widget.address);
        print(resContract[1].toString() == widget.address);
        print("CHECK ADDRESS");
        if (resContract[1].toString().toLowerCase() ==
            widget.address.toLowerCase()) {
          isFound = true;
          Map<String, dynamic> contractVal = {
            'id': resContract[0].toString(),
            'employee_adress': resContract[1].toString(),
            'employer_adress': resContract[2].toString(),
            'coord_long': resContract[3].toString(),
            'lng_offset': resContract[4].toString(),
            'coord_lat': resContract[5].toString(),
            'lat_offset': resContract[6].toString(),
            'radius': resContract[7].toString(),
          };
          setState(() {
            contractInfo = contractVal;
            hasContract = true;
          });
          break;
        }
      }
      if (!isFound) {
        print("HEREEE");
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: const Text("No contract found under your address!"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Close"))
            ],
          ),
        );
      } else {
        enabledTraking(ethUtils);
      }
      print("SENT***********");
    } catch (e) {
      print(e);
    }
  }

  String getCoordFromOffset(coord, index) {
    String val = "";
    var p = [
      coord.toString().substring(0, int.parse(index)),
      ".",
      coord.toString().substring(int.parse(index))
    ];
    val = p.join('');
    return val;
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  void sendLocation(ethUtils, contractLat, contractLng, contractRadius) async {
    Position? position = await getCurrentLocation();
    if (position != null) {
      double distance = calculateDistance(contractLat, contractLng,
          startingCoord.latitude, startingCoord.longitude);
      int dis = (distance * 1000).toInt();
      bool status = dis > int.parse(contractRadius);
      print("######CALCULATING DISTANCE#########");
      print(dis);
      print(status);
      print("######CALCULATING DISTANCE#########");
      try {
        BigInt lt = BigInt.from(
            int.parse(position.latitude.toString().split('.').join("")));
        BigInt latoffset =
            BigInt.from(position.latitude.toString().indexOf('.'));
        BigInt ln = BigInt.from(
            int.parse(position.longitude.toString().split('.').join("")));
        BigInt lngffset =
            BigInt.from(position.longitude.toString().indexOf('.'));

        print("######CALCULATING DISTANCE#########");
        print(dis);
        print(status);
        print(lt);
        print(latoffset);
        print(ln);
        print(lngffset);
        print(DateTime.now().toUtc().toString());
        print("######CALCULATING DISTANCE#########");

        await ethUtils.sendLocation(
            BigInt.from(int.parse(contractInfo['id'])),
            lt,
            latoffset,
            ln,
            lngffset,
            contractInfo['employee_adress'],
            DateTime.now().toUtc().toString(),
            !status,
            BigInt.from(dis));
      } catch (e) {
        print(e);
      }
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: errorColor,
        content: Text(
          "Location Error",
          style: TextStyle(
            fontSize: 15,
            color: primaryColor,
          ),
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void enabledTraking(ethUtils) async {
    if (contractInfo != {}) {
      double lat = double.parse(getCoordFromOffset(
          contractInfo['coord_lat'], contractInfo['lat_offset']));
      double lng = double.parse(getCoordFromOffset(
          contractInfo['coord_long'], contractInfo['lng_offset']));
      latlng.LatLng v = latlng.LatLng(lat, lng);
      markers.add(Marker(
        width: 40,
        height: 40,
        point: v,
        builder: (context) => const Icon(
          Icons.location_on_rounded,
          color: Colors.red,
        ),
      ));
      setState(() {});
      sendLocation(ethUtils, lat, lng, contractInfo['radius']);
      // timer = Timer.periodic(const Duration(seconds: 60), (t) {
      //   sendLocation(ethUtils, lat, lng, contractInfo['radius']);
      // });
      // print("######CALCULATING DISTANCE#########");
      // print(calculateDistance(
      //     lat, lng, startingCoord.latitude, startingCoord.longitude));
      // print("######CALCULATING DISTANCE#########");
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: const Text("No contract found under your address!"),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Close"))
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(ethUtilsProviders);
    final ethUtils = ref.watch(ethUtilsProviders.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tracker"),
        actions: [
          Switch(
              value: isTrackingEnabled,
              onChanged: (val) {
                setState(() {
                  isTrackingEnabled = val;
                });
                if (val) {
                  track(ethUtils);
                }
              }),
          TextButton(
              onPressed: () {
                if (hasContract && contractInfo != {}) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => History(
                        contractInfo: contractInfo,
                        ethUtils: ethUtils,
                      ),
                    ),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      content:
                          const Text("No contract found under your address!"),
                      actions: [
                        TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text("Close"))
                      ],
                    ),
                  );
                }
              },
              child: const Text("History"))
        ],
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

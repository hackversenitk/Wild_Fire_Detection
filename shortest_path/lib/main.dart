import 'package:audioplayer/audioplayer.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:async';

void main() => runApp(MyApp());

const double CAMERA_ZOOM = 17.5;
const double CAMERA_TILT = 20;
const double CAMERA_BEARING = 0;
const LatLng SOURCE_LOCATION = LatLng(13.0110, 74.7943);
LatLng DEST_LOCATION = LatLng(13.0092, 74.7937);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shortest Path',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MapsPage(title: 'Maps'),
    );
  }
}

class MapsPage extends StatefulWidget {
  MapsPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  State<MapsPage> createState() => _MapsPageState();
}

class _MapsPageState extends State<MapsPage> {
  Completer<GoogleMapController> _controller = Completer();
  AudioPlayer audioPlugin;
  Set<Marker> _markers = Set<Marker>();

  final String googleAPIKey = "AIzaSyCXK3oSbWRD3cwhvY1XCp3iDo-N6uVQKjc";

  LocationData currentLocation;
  LocationData destinationLocation;
  Location location;

  var dbRef = FirebaseDatabase.instance.reference().child('NITK');

  @override
  void initState() {
    location = new Location();

    location.onLocationChanged().listen((LocationData cLoc) {
      currentLocation = cLoc;
      updatePinOnMap();
    });
    setInitialLocation();

    super.initState();
  }

  void setInitialLocation() async {
    currentLocation = await location.getLocation();

    // // hard-coded destination for this example
    // destinationLocation = LocationData.fromMap({
    //   "latitude": DEST_LOCATION.latitude,
    //   "longitude": DEST_LOCATION.longitude
    // });
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _controller.complete(controller);

    showPinsOnMap();
  }

  void showPinsOnMap() {
    var pinPosition =
        LatLng(currentLocation.latitude, currentLocation.longitude);

    var destPosition =
        LatLng(destinationLocation.latitude, destinationLocation.longitude);

    _markers.add(Marker(
      markerId: MarkerId('sourcePin'),
      position: pinPosition,
      infoWindow: InfoWindow(
        title: 'NITK',
        snippet: 'Surathkal, Karnataka',
      ),
    ));

    _markers.add(Marker(
      markerId: MarkerId('destPin'),
      position: destPosition,
      infoWindow: InfoWindow(
        title: 'NITK Dept',
        snippet: 'Surathkal, Karnataka',
      ),
    ));
  }

  void updatePinOnMapDest() async {

    setState(() {
      var pinDestPosition =
        LatLng(destinationLocation.latitude, destinationLocation.longitude);

        _markers.removeWhere((m) => m.markerId.value == 'destPin');
      _markers.add(Marker(
        markerId: MarkerId('destPin'),
        position: pinDestPosition, // updated position
        icon: BitmapDescriptor.defaultMarker,
      ));
    });
    
  }

  void updatePinOnMap() async {
    CameraPosition cPosition = CameraPosition(
      zoom: CAMERA_ZOOM,
      tilt: CAMERA_TILT,
      bearing: CAMERA_BEARING,
      target: LatLng(currentLocation.latitude, currentLocation.longitude),
    );
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(cPosition));

    setState(() {
      var pinPosition =
          LatLng(currentLocation.latitude, currentLocation.longitude);

      _markers.removeWhere((m) => m.markerId.value == 'sourcePin');
      _markers.add(Marker(
        markerId: MarkerId('sourcePin'),
        position: pinPosition, // updated position
        icon: BitmapDescriptor.defaultMarkerWithHue(220),
      ));
    });
  }

  Future<void> _goToDesiredPlace(CameraPosition _destination) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_destination));
  }

  @override
  Widget build(BuildContext context) {
    CameraPosition _initialCameraPosition = CameraPosition(
      target: SOURCE_LOCATION,
      zoom: CAMERA_ZOOM,
      tilt: CAMERA_TILT,
      bearing: CAMERA_BEARING,
    );

    if (currentLocation != null) {
      _initialCameraPosition = CameraPosition(
          target: LatLng(currentLocation.latitude, currentLocation.longitude),
          zoom: CAMERA_ZOOM,
          tilt: CAMERA_TILT,
          bearing: CAMERA_BEARING);
    }

    CameraPosition _kDesiredPlace = CameraPosition(
        target: DEST_LOCATION,
        zoom: CAMERA_ZOOM,
        tilt: CAMERA_TILT,
        bearing: CAMERA_BEARING);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Scaffold(
        body: StreamBuilder<Object>(
            stream: dbRef.onValue,
            builder: (context, AsyncSnapshot snap) {
              if (snap.hasData) {
                destinationLocation = LocationData.fromMap({
                  "latitude": snap.data.snapshot.value['Lat'].toDouble(),
                  "longitude": snap.data.snapshot.value['Long'].toDouble(),
                });
                DEST_LOCATION = LatLng(snap.data.snapshot.value['Lat'].toDouble(), snap.data.snapshot.value['Long'].toDouble());
                showPinsOnMap();
                return GoogleMap(
                  mapType: MapType.normal,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  compassEnabled: true,
                  tiltGesturesEnabled: false,
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: _initialCameraPosition,
                  markers: _markers,
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            }),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _goToDesiredPlace(_kDesiredPlace),
          label: Text('Destination'),
          icon: Icon(Icons.directions_boat),
        ),
      ),
    );
  }
}

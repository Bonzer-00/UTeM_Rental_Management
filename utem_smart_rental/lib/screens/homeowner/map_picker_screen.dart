import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/constants.dart';

class MapPickerScreen extends StatefulWidget {
  final String? initialAddress; // <--- NEW: Receives typed address from form [12]
  const MapPickerScreen({super.key, this.initialAddress});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late GoogleMapController _mapController;
  final TextEditingController _searchCtrl = TextEditingController(); // <--- NEW: Map Search Bar
  
  // Official Campus Coordinates
  final LatLng _utemInduk = const LatLng(2.3083, 102.3177); 
  final LatLng _utemTekno = const LatLng(2.2782, 102.2750); 
  
  LatLng _currentPosition = const LatLng(2.3083, 102.3177); 
  String _currentAddress = "Move the map to select a location...";
  
  double _distanceToInduk = 0.0;
  double _distanceToTekno = 0.0;
  bool _isDragging = false;

  // --- NEW: Set of Markers for 3-Marker View ---
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initCampusMarkers(); // Put permanent UTeM flags on the map!
  }

  // Draw the official campus landmarks on the map
  void _initCampusMarkers() {
    _markers.add(
      Marker(
        markerId: const MarkerId('utem_induk'),
        position: _utemInduk,
        infoWindow: const InfoWindow(title: 'UTeM Kampus Induk (Main)', snippet: 'Durian Tunggal'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure), // Cyan/Blue Marker
      ),
    );
    _markers.add(
      Marker(
        markerId: const MarkerId('utem_tekno'),
        position: _utemTekno,
        infoWindow: const InfoWindow(title: 'UTeM Kampus Teknologi', snippet: 'Ayer Keroh'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange), // Orange Marker
      ),
    );
  }

// --- UPDATED: AUTO-PIN TYPED ADDRESS WITH NATIVE STABILITY DELAY --- [12]
  void _moveToInitialLocation() async {
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      try {
        // 1. Add a small delay so the native Google Map finishes rendering first [12]
        await Future.delayed(const Duration(milliseconds: 500));
        
        // 2. Turn the typed text address into GPS coordinates
        List<Location> locations = await locationFromAddress(widget.initialAddress!);
        
        if (locations.isNotEmpty) {
          LatLng target = LatLng(locations.first.latitude, locations.first.longitude);
          
          // 3. Slide the camera directly to their typed house address! [12]
          _mapController.animateCamera(CameraUpdate.newLatLngZoom(target, 15));
          
          // 4. Update coordinates so the bottom sheet calculates UTeM distances instantly! [12]
          setState(() {
            _currentPosition = target;
          });
        }
      } catch (e) {
        debugPrint("Initial address not found: $e");
      }
    }
  }

  // --- NEW: Search Bar execution --- [12]
  void _searchAddress() async {
    String query = _searchCtrl.text.trim();
    if (query.isNotEmpty) {
      FocusScope.of(context).unfocus();
      try {
        List<Location> locations = await locationFromAddress(query);
        if (locations.isNotEmpty) {
          LatLng target = LatLng(locations.first.latitude, locations.first.longitude);
          _mapController.animateCamera(CameraUpdate.newLatLngZoom(target, 15));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.red, content: Text("Could not find this search location.")),
        );
      }
    }
  }

  void _onCameraMove(CameraPosition position) {
    setState(() {
      _currentPosition = position.target;
      _isDragging = true;
    });
  }

  void _onCameraIdle() async {
    setState(() => _isDragging = false);
    await _updateAddressAndDistance();
  }

  Future<void> _updateAddressAndDistance() async {
    try {
      _distanceToInduk = Geolocator.distanceBetween(_utemInduk.latitude, _utemInduk.longitude, _currentPosition.latitude, _currentPosition.longitude) / 1000;
      _distanceToTekno = Geolocator.distanceBetween(_utemTekno.latitude, _utemTekno.longitude, _currentPosition.latitude, _currentPosition.longitude) / 1000;

      List<Placemark> placemarks = await placemarkFromCoordinates(_currentPosition.latitude, _currentPosition.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = "";
        if (place.street != null && place.street!.isNotEmpty) address += "${place.street}, ";
        if (place.subLocality != null && place.subLocality!.isNotEmpty) address += "${place.subLocality}, ";
        if (place.locality != null && place.locality!.isNotEmpty) address += "${place.locality}, ";
        if (place.postalCode != null && place.postalCode!.isNotEmpty) address += "${place.postalCode}, ";
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) address += place.administrativeArea!;

        setState(() {
          _currentAddress = address.trim().replaceAll(RegExp(r',$'), '');
        });
      }
    } catch (e) {
      setState(() => _currentAddress = "Address not found for this location.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 1, iconTheme: const IconThemeData(color: textDark),
        title: const Text("Pin Location", style: TextStyle(color: textDark, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children:[
          // 1. Map (Includes campus markers)
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _utemInduk, zoom: 13),
            markers: _markers, // Displays both campus flags!
            onMapCreated: (controller) {
              _mapController = controller;
              _moveToInitialLocation(); // Auto-pin logic starts here! [12]
            },
            onCameraMove: _onCameraMove, onCameraIdle: _onCameraIdle,
            myLocationButtonEnabled: false, zoomControlsEnabled: false,
          ),

          // 2. Center House Pin (Our drag anchor)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40), 
              child: Icon(Icons.location_on, size: 50, color: _isDragging ? Colors.grey : Colors.redAccent),
            ),
          ),

          // 3. NEW: FLOATING SEARCH BAR ON THE MAP --- [12]
          Positioned(
            top: 16, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _searchAddress(),
                decoration: InputDecoration(
                  hintText: "Search for address...",
                  hintStyle: const TextStyle(color: textGrey, fontSize: 14),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search, color: primaryBlue),
                    onPressed: _searchAddress,
                  ),
                ),
              ),
            ),
          ),

          // 4. Bottom Sheet details
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)), boxShadow:[BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))]),
              child: Column(
                mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
                children:[
                  Row(
                    children:[
                      Expanded(child: _buildDistanceBadge("Induk", _distanceToInduk, primaryBlue)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildDistanceBadge("Tekno", _distanceToTekno, Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text("Full Address:", style: TextStyle(color: textGrey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(_isDragging ? "Locating..." : _currentAddress, style: const TextStyle(color: textDark, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      onPressed: _isDragging ? null : () {
                        Navigator.pop(context, {
                          'address': _currentAddress,
                          'distInduk': _distanceToInduk.toStringAsFixed(1),
                          'distTekno': _distanceToTekno.toStringAsFixed(1),
                          'latitude': _currentPosition.latitude.toString(), 
                          'longitude': _currentPosition.longitude.toString(), 
                        });
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: const Text("Confirm Location", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 190),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              heroTag: "btn1", backgroundColor: Colors.white, mini: true,
              onPressed: () => _mapController.animateCamera(CameraUpdate.newLatLngZoom(_utemInduk, 14)),
              child: const Icon(Icons.school, color: primaryBlue),
            ),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: "btn2", backgroundColor: Colors.white, mini: true,
              onPressed: () => _mapController.animateCamera(CameraUpdate.newLatLngZoom(_utemTekno, 14)),
              child: const Icon(Icons.domain, color: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceBadge(String campus, double distance, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car, color: color, size: 16),
          const SizedBox(width: 4),
          Text("${distance.toStringAsFixed(1)}km to $campus", style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
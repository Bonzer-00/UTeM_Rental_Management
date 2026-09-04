import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../utils/constants.dart';
import 'map_picker_screen.dart';

class AddPropertyScreen extends StatefulWidget {
  final Property? property;
  const AddPropertyScreen({super.key, this.property});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  final PropertyService _propertyService = PropertyService();
  
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _depositCtrl;    // <--- NEW [1]
  late TextEditingController _utilitiesCtrl;  // <--- NEW [1]
  late TextEditingController _addFeesCtrl;    // <--- NEW [1]
  late TextEditingController _locationCtrl;
  late TextEditingController _distanceIndukCtrl; 
  late TextEditingController _distanceTeknoCtrl; 
  late TextEditingController _capacityCtrl;
  late TextEditingController _currentTenantsCtrl;
  late TextEditingController _facilitiesCtrl;
  late TextEditingController _rulesCtrl; // <--- NEW
  double _latitude = 2.3083;  // Default to UTeM
  double _longitude = 102.3177; // Default to UTeM

  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  List<String> _existingImages = [];
  bool _isSaving = false;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.property?.title ?? '');
    _descCtrl = TextEditingController(text: widget.property?.description ?? '');
    _priceCtrl = TextEditingController(text: widget.property?.price.toString() ?? '');
    
    // Initialize new fields [1]
    _depositCtrl = TextEditingController(text: widget.property?.deposit.toString() ?? ''); 
    _utilitiesCtrl = TextEditingController(text: widget.property?.utilities.toString() ?? '');
    _addFeesCtrl = TextEditingController(text: widget.property?.additionalFees.toString() ?? '0');
    
    _locationCtrl = TextEditingController(text: widget.property?.location ?? '');
    _distanceIndukCtrl = TextEditingController(text: widget.property?.distanceInduk.toString() ?? ''); 
    _distanceTeknoCtrl = TextEditingController(text: widget.property?.distanceTekno.toString() ?? ''); 
    _capacityCtrl = TextEditingController(text: widget.property?.capacity.toString() ?? '');
    _currentTenantsCtrl = TextEditingController(text: widget.property?.currentTenants.toString() ?? '0');
    _facilitiesCtrl = TextEditingController(text: widget.property?.facilities.join(', ') ?? '');
    _rulesCtrl = TextEditingController(text: widget.property?.customRules ?? ''); // <--- NEW
    
    if (widget.property != null) {
      _existingImages = List.from(widget.property!.imageUrls);
    }
  }

  Future<void> _openMapPicker() async {
    FocusScope.of(context).unfocus(); 
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialAddress: _locationCtrl.text.trim(), 
        ),
      ),
    );

    if (result != null && result is Map<String, String>) {
      setState(() {
        _locationCtrl.text = result['address'] ?? '';
        _distanceIndukCtrl.text = result['distInduk'] ?? '';
        _distanceTeknoCtrl.text = result['distTekno'] ?? '';
        _latitude = double.parse(result['latitude'] ?? '2.3083');
        _longitude = double.parse(result['longitude'] ?? '102.3177');
      });
    }
  }

  Future<void> _calculateDistance() async {
    if (_locationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please type an address first!")));
      return;
    }

    setState(() => _isCalculating = true);
    try {
      List<Location> locations = await locationFromAddress(_locationCtrl.text.trim());
      if (locations.isNotEmpty) {
        double lat = locations.first.latitude;
        double lng = locations.first.longitude;

        double distInduk = Geolocator.distanceBetween(2.3083, 102.3177, lat, lng) / 1000;
        double distTekno = Geolocator.distanceBetween(2.2782, 102.2750, lat, lng) / 1000;

        setState(() {
          _distanceIndukCtrl.text = distInduk.toStringAsFixed(1);
          _distanceTeknoCtrl.text = distTekno.toStringAsFixed(1);

           _latitude = lat;
          _longitude = lng;
        });
        
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Distances calculated!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.red, content: Text("Could not find this address.")));
      }
    }
    setState(() => _isCalculating = false);
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() => _selectedImages.addAll(images));
    }
  }

  Future<List<String>> _uploadImagesToFirebase() async {
    List<String> uploadedUrls = [];
    for (var image in _selectedImages) {
      try {
        String fileName = 'prop_${DateTime.now().millisecondsSinceEpoch}_${image.name}';
        Reference ref = FirebaseStorage.instance.ref().child('property_images/$fileName');
        SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
        UploadTask uploadTask = ref.putFile(File(image.path), metadata);
        TaskSnapshot snapshot = await uploadTask;
        String url = await snapshot.ref.getDownloadURL();
        uploadedUrls.add(url);
      } catch (e) {
        debugPrint("Upload error: $e");
      }
    }
    return uploadedUrls;
  }

  void _saveProperty() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        List<String> newUploadedUrls = await _uploadImagesToFirebase();
        List<String> finalImageUrls = [..._existingImages, ...newUploadedUrls];
        List<String> facilitiesList = _facilitiesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

        Property propData = Property(
          id: widget.property?.id ?? '',
          homeownerId: FirebaseAuth.instance.currentUser!.uid,
          title: _titleCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          price: double.parse(_priceCtrl.text),
          
          // Save new customizable values [1]
          deposit: double.parse(_depositCtrl.text),          
          utilities: double.parse(_utilitiesCtrl.text),      
          additionalFees: double.parse(_addFeesCtrl.text),    
          
          location: _locationCtrl.text.trim(),
          distanceInduk: double.parse(_distanceIndukCtrl.text), 
          distanceTekno: double.parse(_distanceTeknoCtrl.text), 
          latitude: _latitude,
          longitude: _longitude,
          capacity: int.parse(_capacityCtrl.text),
          currentTenants: int.parse(_currentTenantsCtrl.text),
          facilities: facilitiesList,
          imageUrls: finalImageUrls,
          customRules: _rulesCtrl.text.trim(), // <--- NEW [1]
        );

        if (widget.property == null) {
          await _propertyService.addProperty(propData);
        } else {
          await _propertyService.updateProperty(widget.property!.id, propData);
        }
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Property Saved!")));
        }
      } catch (e) {
        setState(() => _isSaving = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEditing = widget.property != null;
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: backgroundLight, elevation: 0, iconTheme: const IconThemeData(color: textDark),
        title: Text(isEditing ? 'Edit Property' : 'Add New Property', style: const TextStyle(color: textDark, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))]),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Basic Info", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                const SizedBox(height: 16),
                _buildModernTextField(_titleCtrl, "Property Title", "e.g. Single Room at Taman Tasik", false),
                
                // --- NEW: FINANCIAL GRID --- [1]
                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                const Text("Financial Requirements", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildModernTextField(_priceCtrl, "Monthly Rent (RM)", "350", true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildModernTextField(_depositCtrl, "Deposit (RM)", "700", true)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _buildModernTextField(_utilitiesCtrl, "Utility Deposit (RM)", "100", true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildModernTextField(_addFeesCtrl, "Additional Fees (RM)", "0", true)),
                  ],
                ),
                
                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Location & Distances", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                    TextButton.icon(
                      onPressed: _openMapPicker,
                      icon: const Icon(Icons.map, color: primaryBlue, size: 18),
                      label: const Text("Pin on Map", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(backgroundColor: primaryBlue.withOpacity(0.1)),
                    )
                  ],
                ),
                const SizedBox(height: 10),
                
                _buildModernTextField(
                  _locationCtrl, "Full Address", "Tap 'Pin on Map' to auto-fill...", false, maxLines: 2,
                  suffixIcon: _isCalculating 
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: primaryBlue))
                    : IconButton(
                        icon: const Icon(Icons.calculate, color: primaryBlue),
                        tooltip: "Calculate Distances",
                        onPressed: _calculateDistance,
                      ),
                ),
                
                Row(
                  children: [
                    Expanded(child: _buildModernTextField(_distanceIndukCtrl, "Dist to Induk (km)", "Auto-filled...", true)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildModernTextField(_distanceTeknoCtrl, "Dist to Tekno (km)", "Auto-filled...", true)),
                  ],
                ),
                
                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                const Text("Capacity & Features", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                const SizedBox(height: 10),
                Row(children: [Expanded(child: _buildModernTextField(_capacityCtrl, "Total Capacity", "e.g. 4", true)), const SizedBox(width: 16), Expanded(child: _buildModernTextField(_currentTenantsCtrl, "Current Tenants", "e.g. 2", true))]),
                _buildModernTextField(_facilitiesCtrl, "Facilities (comma separated)", "WiFi, Aircond, Fridge", false),
                _buildModernTextField(_descCtrl, "Description", "Tell students about the house...", false, maxLines: 3),
                _buildModernTextField(_rulesCtrl, "Custom Lease Rules & Agreement Clauses (Optional)", 
                  "e.g.\n1. Rent must be paid by the 1st of every month.\n2. No smoking inside the premises.\n3. Keep the common area clean.", false, maxLines: 4
                ),
                
                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                const Text("Property Photos", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                const SizedBox(height: 10),
                
                if (_existingImages.isNotEmpty) ...[
                  const Text("Currently Uploaded (Tap 'X' to remove):", style: TextStyle(color: textGrey, fontSize: 12)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _existingImages.length,
                      itemBuilder: (context, index) => Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(_existingImages[index], width: 80, height: 80, fit: BoxFit.cover),
                            ),
                          ),
                          // Red 'X' Button to delete existing uploaded photo!
                          Positioned(
                            top: 0, right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _existingImages.removeAt(index); // Removes the photo URL locally [23]
                                });
                              },
                              child: Container(
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                if (_selectedImages.isNotEmpty) ...[
                  const Text("New Photos to Upload:", style: TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) => Stack(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_selectedImages[index].path), width: 80, height: 80, fit: BoxFit.cover)),
                          ),
                          Positioned(
                            top: 0, right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImages.removeAt(index)),
                              child: Container(decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.white, size: 18)),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                OutlinedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library, color: primaryBlue),
                  label: const Text("Select from Gallery", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: primaryBlue), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                ),
                
                const SizedBox(height: 24),
                _isSaving 
                  ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                  : SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: _saveProperty,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: Text(isEditing ? 'Save Changes' : 'Upload & Publish Property', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

Widget _buildModernTextField(TextEditingController controller, String label, String hint, bool isNumber, {int maxLines = 1, Widget? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller, 
            
            // --- THE FIX: Unlocks the Enter key on mobile soft keyboards! --- [1]
            keyboardType: isNumber 
                ? TextInputType.number 
                : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
                
            maxLines: maxLines,
            validator: (label.contains("Current Tenants")) ? null : (v) => v!.isEmpty ? 'Required' : null,
            decoration: InputDecoration(
              hintText: hint, hintStyle: const TextStyle(color: Colors.grey, fontSize: 13), filled: true, fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: primaryBlue)),
              suffixIcon: suffixIcon,
            ),
          ),
        ],
      ),
    );
  }
}
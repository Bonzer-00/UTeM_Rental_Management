import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/vacancy_model.dart';
import '../../models/booking_model.dart';
import '../../models/property_model.dart';
import '../../services/vacancy_service.dart';
import '../../utils/constants.dart';

class AddVacancyScreen extends StatefulWidget {
  final Booking booking;
  final Property property;

  const AddVacancyScreen({super.key, required this.booking, required this.property});

  @override
  State<AddVacancyScreen> createState() => _AddVacancyScreenState();
}

class _AddVacancyScreenState extends State<AddVacancyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _slotsCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _isSaving = false;

  void _submitVacancy() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      final user = FirebaseAuth.instance.currentUser;
      String userName = user?.email?.split('@')[0] ?? 'Tenant';

      VacancyPost newPost = VacancyPost(
        id: '',
        studentId: user!.uid,
        studentName: userName.toUpperCase(),
        propertyId: widget.property.id,
        propertyTitle: widget.property.title,
        vacantSlots: int.parse(_slotsCtrl.text),
        price: double.parse(_priceCtrl.text),
        description: _descCtrl.text.trim(),
      );

      await VacancyService().createVacancy(newPost);
      
      setState(() => _isSaving = false);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text("Vacancy Posted Successfully!")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: backgroundLight, elevation: 0, iconTheme: const IconThemeData(color: textDark),
        title: const Text("Promote Vacant Slot", style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(defaultPadding),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("List Empty Room Space", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark)),
                const SizedBox(height: 8),
                Text("Promoting slots for: ${widget.property.title}", style: const TextStyle(color: textGrey, fontSize: 13)),
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider()),

                _buildModernTextField(_slotsCtrl, "Vacant Slots Available", "e.g. 2", true),
                _buildModernTextField(_priceCtrl, "Estimated Price per slot (RM/mo)", "e.g. 150", true),
                _buildModernTextField(_descCtrl, "Room Details (Gender, Preferences)", "Looking for 2 FTMK boys, clean, non-smoker...", false, maxLines: 4),

                const SizedBox(height: 20),
                _isSaving 
                  ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                  : SizedBox(
                      width: double.infinity, height: 50,
                      child: ElevatedButton(
                        onPressed: _submitVacancy,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                        child: const Text("Publish Post", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField(TextEditingController controller, String label, String hint, bool isNumber, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller, keyboardType: isNumber ? TextInputType.number : TextInputType.text, maxLines: maxLines,
            validator: (v) => v!.isEmpty ? 'Required' : null,
            decoration: InputDecoration(
              hintText: hint, hintStyle: const TextStyle(color: Colors.grey, fontSize: 13), filled: true, fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
        ],
      ),
    );
  }
}
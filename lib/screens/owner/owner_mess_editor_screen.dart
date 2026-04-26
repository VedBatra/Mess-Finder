// lib/screens/owner/owner_mess_editor_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/mess.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mess_provider.dart';
import '../../services/mess_service.dart';
import '../../utils/app_theme.dart';

class OwnerMessEditorScreen extends ConsumerStatefulWidget {
  const OwnerMessEditorScreen({super.key});

  @override
  ConsumerState<OwnerMessEditorScreen> createState() =>
      _OwnerMessEditorScreenState();
}

class _OwnerMessEditorScreenState extends ConsumerState<OwnerMessEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _lunchPriceCtrl = TextEditingController();
  final _dinnerPriceCtrl = TextEditingController();
  final _lunchCutoffCtrl = TextEditingController();
  final _dinnerCutoffCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _deliveryChargeCtrl = TextEditingController(text: '0');
  final _packagingChargeCtrl = TextEditingController(text: '0');
  bool _offersDelivery = false;
  bool _isLoading = false;
  Mess? _existingMess;

  // Google Maps location (defaults to center of India)
  LatLng _selectedLocation = const LatLng(20.5937, 78.9629);
  bool _locationPicked = false;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final profile = ref.read(authProvider).valueOrNull;
    if (profile == null) return;
    final mess = await MessService().getMessByOwner(profile.id);
    if (mess != null && mounted) {
      setState(() {
        _existingMess = mess;
        _nameCtrl.text = mess.messName;
        _addressCtrl.text = mess.address;
        _lunchPriceCtrl.text = mess.oneTimeLunchPrice.toString();
        _dinnerPriceCtrl.text = mess.oneTimeDinnerPrice.toString();
        _lunchCutoffCtrl.text = mess.lunchCutoff ?? '';
        _dinnerCutoffCtrl.text = mess.dinnerCutoff ?? '';
        _upiCtrl.text = mess.upiId ?? '';
        _offersDelivery = mess.offersDelivery;
        _deliveryChargeCtrl.text = mess.deliveryCharge.toString();
        _packagingChargeCtrl.text = mess.packagingCharge.toString();
        if (mess.latitude != 0 && mess.longitude != 0) {
          _selectedLocation = LatLng(mess.latitude, mess.longitude);
          _locationPicked = true;
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _addressCtrl, _lunchPriceCtrl, _dinnerPriceCtrl,
      _lunchCutoffCtrl, _dinnerCutoffCtrl, _upiCtrl,
      _deliveryChargeCtrl, _packagingChargeCtrl,
    ]) {
      c.dispose();
    }
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_locationPicked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please tap on the map to set your mess location',
              style: GoogleFonts.inter()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    final profile = ref.read(authProvider).valueOrNull;
    if (profile == null) return;

    final data = {
      'owner_id': profile.id,
      'mess_name': _nameCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'latitude': _selectedLocation.latitude,
      'longitude': _selectedLocation.longitude,
      'one_time_lunch_price': int.tryParse(_lunchPriceCtrl.text) ?? 0,
      'one_time_dinner_price': int.tryParse(_dinnerPriceCtrl.text) ?? 0,
      'lunch_cutoff': _lunchCutoffCtrl.text.trim(),
      'dinner_cutoff': _dinnerCutoffCtrl.text.trim(),
      'upi_id': _upiCtrl.text.trim(),
      'offers_delivery': _offersDelivery,
      'delivery_charge': int.tryParse(_deliveryChargeCtrl.text) ?? 0,
      'packaging_charge': int.tryParse(_packagingChargeCtrl.text) ?? 0,
      'status': 'approved',
    };

    try {
      if (_existingMess != null) {
        await MessService().updateMess(_existingMess!.id, data);
      } else {
        await MessService().createMess(data);
      }
      ref.invalidate(ownerMessProvider(profile.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mess profile saved and is now live!',
                style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: AppTheme.successColor,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          _existingMess != null ? 'Edit Mess' : 'Create Mess',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionHeader(text: 'Basic Information', icon: Icons.info_rounded),
            _Field(ctrl: _nameCtrl, label: 'Mess Name', icon: Icons.store_rounded),
            _Field(
              ctrl: _addressCtrl,
              label: 'Address',
              icon: Icons.location_on_rounded,
              lines: 2,
            ),
            const SizedBox(height: 20),

            // ── Google Maps Location Picker ──
            _SectionHeader(text: '📍 Mess Location', icon: Icons.map_rounded),
            Text(
              'Tap on the map to pin your exact mess location.',
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppTheme.softShadow,
                ),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation,
                    zoom: _locationPicked ? 15.0 : 5.0,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: (latLng) {
                    setState(() {
                      _selectedLocation = latLng;
                      _locationPicked = true;
                    });
                  },
                  markers: _locationPicked
                      ? {
                          Marker(
                            markerId: const MarkerId('selected'),
                            position: _selectedLocation,
                            infoWindow:
                                const InfoWindow(title: 'Your Mess Location'),
                          ),
                        }
                      : {},
                  zoomControlsEnabled: true,
                  mapToolbarEnabled: false,
                  myLocationButtonEnabled: false,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _locationPicked
                      ? AppTheme.successColor.withValues(alpha: 0.08)
                      : AppTheme.errorColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      _locationPicked
                          ? Icons.check_circle_rounded
                          : Icons.warning_amber_rounded,
                      size: 18,
                      color: _locationPicked
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _locationPicked
                          ? '📌 ${_selectedLocation.latitude.toStringAsFixed(5)}, '
                              '${_selectedLocation.longitude.toStringAsFixed(5)}'
                          : '⚠️ No location selected — tap the map',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _locationPicked
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            _SectionHeader(text: 'Pricing', icon: Icons.currency_rupee_rounded),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    ctrl: _lunchPriceCtrl,
                    label: '☀️ Lunch ₹',
                    keyboard: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                    ctrl: _dinnerPriceCtrl,
                    label: '🌙 Dinner ₹',
                    keyboard: TextInputType.number,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            _SectionHeader(
                text: 'Cutoff Times', icon: Icons.schedule_rounded),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    ctrl: _lunchCutoffCtrl,
                    label: 'Lunch (e.g. 12:30 PM)',
                    required: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Field(
                    ctrl: _dinnerCutoffCtrl,
                    label: 'Dinner (e.g. 8 PM)',
                    required: false,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            _SectionHeader(text: 'Payment', icon: Icons.payment_rounded),
            _Field(
              ctrl: _upiCtrl,
              label: 'UPI ID (e.g. name@upi)',
              icon: Icons.account_balance_wallet_rounded,
              required: false,
            ),

            const SizedBox(height: 12),
            _SectionHeader(
                text: 'Delivery', icon: Icons.delivery_dining_rounded),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.softShadow,
              ),
              child: SwitchListTile(
                value: _offersDelivery,
                onChanged: (v) => setState(() => _offersDelivery = v),
                title: Text('Offer Delivery',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: Text('Allow customers to order delivery',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.textSecondary)),
                activeThumbColor: AppTheme.primaryColor,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (_offersDelivery) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      ctrl: _deliveryChargeCtrl,
                      label: 'Delivery ₹',
                      keyboard: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Field(
                      ctrl: _packagingChargeCtrl,
                      label: 'Packaging ₹',
                      keyboard: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 28),

            // ── Save Button ──
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.primaryShadow,
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        _existingMess != null
                            ? 'Save Changes'
                            : 'Create Mess',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  final IconData icon;
  const _SectionHeader({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData? icon;
  final TextInputType keyboard;
  final int lines;
  final bool required;

  const _Field({
    required this.ctrl,
    required this.label,
    this.icon,
    this.keyboard = TextInputType.text,
    this.lines = 1,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        maxLines: lines,
        style: GoogleFonts.inter(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 14),
          prefixIcon: icon != null ? Icon(icon, size: 20) : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
        validator: required
            ? (v) => (v == null || v.isEmpty) ? 'Required' : null
            : null,
      ),
    );
  }
}

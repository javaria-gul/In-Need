import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

class PostJobScreen extends StatefulWidget {
  const PostJobScreen({super.key});

  @override
  State<PostJobScreen> createState() => _PostJobScreenState();
}

class _PostJobScreenState extends State<PostJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _skillCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  String _pricing = 'fixed';
  String _urgency = 'flexible';
  String _gender = 'any';
  bool _isRemote = false;
  bool _loading = false;
  bool _locLoading = false;
  double? _lat, _lon;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _skillCtrl.dispose();
    _priceCtrl.dispose();
    _hoursCtrl.dispose();
    _timeCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    setState(() => _locLoading = true);
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.deniedForever) {
        if (mounted) {
          showSnack(context, 'Enable location in Settings', err: true);
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );

      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lon = pos.longitude;
          _addressCtrl.text =
              '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        });
        showSnack(context, 'Location detected ✓', ok: true);
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Could not get location', err: true);
    } finally {
      if (mounted) setState(() => _locLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_priceCtrl.text.isEmpty) {
      showSnack(context, 'Enter a price', err: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await _api.createJob({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'skillRequired':
            _skillCtrl.text.trim().isEmpty ? null : _skillCtrl.text.trim(),
        'pricingType': _pricing,
        'price': double.parse(_priceCtrl.text.trim()),
        'urgency': _urgency,
        'genderPreference': _gender,
        'isRemote': _isRemote,
        if (!_isRemote && _lat != null) 'locationLat': _lat,
        if (!_isRemote && _lon != null) 'locationLon': _lon,
        if (!_isRemote) 'locationAddress': _addressCtrl.text.trim(),
        if (_hoursCtrl.text.isNotEmpty)
          'estimatedHours': double.tryParse(_hoursCtrl.text),
        if (_timeCtrl.text.isNotEmpty) 'requiredByTime': _timeCtrl.text.trim(),
      });
      if (mounted) {
        showSnack(context, 'Job posted! AI is finding workers…', ok: true);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), err: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Post a Job'),
        leading: const BackButton(color: kWhite),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _section('Job Details'),
            const SizedBox(height: 12),
            _card(
              Column(children: [
                _field(_titleCtrl, 'Job Title', Icons.work_outline_rounded,
                    required: true),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                  decoration: const InputDecoration(
                    labelText: 'Description (detailed)',
                    prefixIcon: Icon(Icons.description_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                _field(_skillCtrl, 'Skill Required (e.g. Electrician)',
                    Icons.build_circle_outlined),
              ]),
            ),
            const SizedBox(height: 20),
            _section('Pricing'),
            const SizedBox(height: 12),
            _card(
              Column(children: [
                Row(children: [
                  Expanded(
                      child: _chip('Fixed Price', 'fixed', _pricing,
                          (v) => setState(() => _pricing = v))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: _chip('Per Hour', 'hourly', _pricing,
                          (v) => setState(() => _pricing = v))),
                ]),
                const SizedBox(height: 12),
                _field(
                  _priceCtrl,
                  _pricing == 'hourly'
                      ? 'Rate per hour (Rs.)'
                      : 'Total Fixed Price (Rs.)',
                  Icons.money_rounded,
                  keyboardType: TextInputType.number,
                  required: true,
                ),
                if (_pricing == 'hourly') ...[
                  const SizedBox(height: 12),
                  _field(_hoursCtrl, 'Estimated Duration (hours)',
                      Icons.timer_outlined,
                      keyboardType: TextInputType.number),
                ],
              ]),
            ),
            const SizedBox(height: 20),
            _section('Urgency'),
            const SizedBox(height: 12),
            _card(
              Column(children: [
                Row(children: [
                  Expanded(
                      child: _chip('Urgent', 'urgent', _urgency,
                          (v) => setState(() => _urgency = v))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _chip('Today', 'today', _urgency,
                          (v) => setState(() => _urgency = v))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _chip('Flexible', 'flexible', _urgency,
                          (v) => setState(() => _urgency = v))),
                ]),
                const SizedBox(height: 12),
                _field(_timeCtrl, 'Required by (e.g. 5pm today)',
                    Icons.schedule_rounded),
              ]),
            ),
            const SizedBox(height: 20),
            _section('Location'),
            const SizedBox(height: 12),
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _isRemote,
                    onChanged: (v) => setState(() => _isRemote = v),
                    activeThumbColor: kBlue,
                    title: const Text('Remote / No Physical Location',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: kBlack)),
                    subtitle: const Text('Online or digital work',
                        style: TextStyle(fontSize: 12, color: kGrey)),
                  ),
                  if (!_isRemote) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: TextFormField(
                          controller: _addressCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Location / Address',
                            prefixIcon: Icon(Icons.location_on_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _locLoading ? null : _getLocation,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient:
                                _lat != null ? kValidationGrad : kBlueGrad,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: _locLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: CircularProgressIndicator(
                                      color: kWhite, strokeWidth: 2),
                                )
                              : Icon(
                                  _lat != null
                                      ? Icons.location_on_rounded
                                      : Icons.my_location_rounded,
                                  color: kWhite),
                        ),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            _section('Gender Preference'),
            const SizedBox(height: 12),
            _card(
              Row(children: [
                Expanded(child: _genderChip('Any', 'any')),
                const SizedBox(width: 8),
                Expanded(child: _genderChip('Male', 'male')),
                const SizedBox(width: 8),
                Expanded(child: _genderChip('Female', 'female')),
              ]),
            ),
            const SizedBox(height: 28),
            GradBtn(
              text: 'POST JOB & FIND WORKERS',
              loading: _loading,
              onTap: _submit,
              gradient: kBlueGrad,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _section(String t) => Text(t,
      style: const TextStyle(
          fontSize: 16, fontWeight: FontWeight.w800, color: kBlack));
  Widget _card(Widget child) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(18),
            boxShadow: kShadow),
        child: child,
      );

  Widget _field(TextEditingController ctrl, String label, IconData icon,
          {bool required = false,
          TextInputType keyboardType = TextInputType.text}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
            : null,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      );

  Widget _chip(String label, String value, String currentGroupValue,
      Function(String) onSelect) {
    final sel = currentGroupValue == value;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: sel ? kBlack : kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? kBlack : kDivider),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
                color: sel ? kWhite : kGrey,
                fontWeight: FontWeight.w700,
                fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _genderChip(String label, String value) {
    final sel = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: sel ? kBlue.withValues(alpha: 0.12) : kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? kBlue : kDivider),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
                color: sel ? kBlue : kGrey,
                fontWeight: FontWeight.w700,
                fontSize: 12),
          ),
        ),
      ),
    );
  }
}

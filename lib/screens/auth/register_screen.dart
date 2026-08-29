import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/profile_photo.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../widgets/profile_avatar.dart';
import '../home/home_shell.dart';
import 'one_tap_consent.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  int _step = 0;

  // Step 1 – account
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  String? _profilePhoto;
  bool _pickingPhoto = false;

  // Step 2 – body
  String _gender = 'male';
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  String _activity = 'moderate';
  String _fitnessLevel = 'beginner';
  String _workoutTime = 'afternoon';
  bool _veg = false;
  bool _eggEater = true;

  // Step 3 – measurements (optional but recommended)
  final _waist = TextEditingController();
  final _neck = TextEditingController();
  final _hip = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _age, _height, _weight, _waist, _neck, _hip]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _validateStep() {
    if (_step < 2) return _formKey.currentState!.validate();
    return true;
  }

  void _next() {
    if (!_validateStep()) return;
    if (_step < 2) {
      setState(() { _error = null; _step++; });
    } else {
      setState(() { _error = null; });
      _submit();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _pickPhoto() async {
    setState(() => _pickingPhoto = true);
    final base64 = await pickProfilePhoto(context);
    if (!mounted) return;
    setState(() {
      _pickingPhoto = false;
      if (base64 != null) _profilePhoto = base64;
    });
  }

  Widget _noPhotoAvatar() {
    return Center(
      child: Icon(Icons.person, color: AppColors.primary, size: 44),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final data = {
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text,
      'gender': _gender,
      'age': int.parse(_age.text),
      'heightCm': int.parse(_height.text),
      'weightKg': int.parse(_weight.text),
      'activityLevel': _activity,
      'fitnessLevel': _fitnessLevel,
      'workoutTime': _workoutTime,
      'veg': _veg,
      'eggFree': _veg && !_eggEater,
      if (_profilePhoto != null) 'profilePhoto': _profilePhoto,
      if (_waist.text.isNotEmpty) 'waistCm': (double.parse(_waist.text) * 2.54).round(),
      if (_neck.text.isNotEmpty) 'neckCm': (double.parse(_neck.text) * 2.54).round(),
      if (_hip.text.isNotEmpty) 'hipCm': (double.parse(_hip.text) * 2.54).round(),
    };
    try {
      final result = await ApiClient.instance.register(data);
      await Session.save(
        result.token,
        result.user.email,
        name: result.user.name,
      );
      ApiClient.instance.setToken(result.token);
      if (!mounted) return;
      // One-time consent dialog (only the very first login on this device).
      await maybePromptOneTapConsent(context);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: _step > 0 ? IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back)) : null),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Stepper(dots: _step),
                    const SizedBox(height: 20),
                    Text(
                      _step == 0
                          ? 'Create your account'
                          : _step == 1
                              ? 'Tell us about your body'
                              : 'Body measurements',
                      style:  TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _step == 2
                          ? 'Optional but makes your body fat % much more accurate'
                          : 'Step ${_step + 1} of 3',
                      style:  TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    if (_step == 0) _accountStep(),
                    if (_step == 1) _bodyStep(),
                    if (_step == 2) _measurementsStep(),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loading ? null : _next,
                      child: _loading
                          ?  SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.onPrimary),
                            )
                          : Text(_step == 2 ? 'Create account' : 'Continue'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style:  TextStyle(color: AppColors.danger, fontSize: 13), textAlign: TextAlign.center),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _accountStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: InkWell(
            onTap: _pickingPhoto ? null : _pickPhoto,
            borderRadius: BorderRadius.circular(70),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                ClipOval(
                  child: Container(
                    width: 96,
                    height: 96,
                    color: AppColors.primary.withValues(alpha: 0.12),
                    child: _profilePhoto != null
                        ? ProfileAvatar(
                            base64: _profilePhoto,
                            size: 96,
                          )
                        : _noPhotoAvatar(),
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: _pickingPhoto
                      ? const Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.photo_camera, color: Colors.white, size: 16),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add a profile photo (optional)',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        const _Label('Full name'),
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(hintText: 'e.g. Rahul Sharma'),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
        ),
        const SizedBox(height: 14),
        const _Label('Email'),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: const InputDecoration(hintText: 'you@example.com'),
          validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
        ),
        const SizedBox(height: 14),
        const _Label('Password'),
        TextFormField(
          controller: _password,
          obscureText: _obscure,
          decoration: InputDecoration(
            hintText: 'Minimum 6 characters',
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: AppColors.textSecondary),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
        ),
      ],
    );
  }

  Widget _bodyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Label('Gender'),
        Row(
          children: [
            Expanded(
              child: _ChoiceChip(
                label: 'Male',
                selected: _gender == 'male',
                onTap: () => setState(() => _gender = 'male'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ChoiceChip(
                label: 'Female',
                selected: _gender == 'female',
                onTap: () => setState(() => _gender = 'female'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Label('Age'),
                  TextFormField(
                    controller: _age,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '25'),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null) return 'Required';
                      if (n < 13 || n > 90) return '13-90';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Label('Height (cm)'),
                  TextFormField(
                    controller: _height,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '175'),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null) return 'Required';
                      if (n < 100 || n > 250) return '100-250';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Label('Weight (kg)'),
                  TextFormField(
                    controller: _weight,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: '70'),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null) return 'Required';
                      if (n < 30 || n > 300) return '30-300';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _Label('Activity level'),
        DropdownButtonFormField<String>(
          initialValue: _activity,
          decoration: const InputDecoration(hintText: 'Activity level'),
          items: const [
            DropdownMenuItem(value: 'sedentary', child: Text('Sedentary (desk job)')),
            DropdownMenuItem(value: 'light', child: Text('Light (1-3 workouts/week)')),
            DropdownMenuItem(value: 'moderate', child: Text('Moderate (3-5 workouts/week)')),
            DropdownMenuItem(value: 'active', child: Text('Active (6-7 workouts/week)')),
            DropdownMenuItem(value: 'athlete', child: Text('Athlete (hard daily training)')),
          ],
          onChanged: (v) => setState(() => _activity = v ?? 'moderate'),
        ),
        const SizedBox(height: 14),
        const _Label('Training experience'),
        DropdownButtonFormField<String>(
          initialValue: _fitnessLevel,
          decoration: const InputDecoration(hintText: 'Training experience'),
          items: const [
            DropdownMenuItem(value: 'beginner', child: Text('Beginner (new to gym)')),
            DropdownMenuItem(value: 'intermediate', child: Text('Intermediate (1-3 years)')),
            DropdownMenuItem(value: 'advanced', child: Text('Advanced (3+ years)')),
          ],
          onChanged: (v) => setState(() => _fitnessLevel = v ?? 'beginner'),
        ),
        const SizedBox(height: 14),
        const _Label('When do you train?'),
        DropdownButtonFormField<String>(
          initialValue: _workoutTime,
          decoration: const InputDecoration(hintText: 'Workout time'),
          items: const [
            DropdownMenuItem(value: 'morning', child: Text('Morning (5-9 AM)')),
            DropdownMenuItem(value: 'midday', child: Text('Midday (11 AM - 2 PM)')),
            DropdownMenuItem(value: 'afternoon', child: Text('Afternoon (3-6 PM)')),
            DropdownMenuItem(value: 'evening', child: Text('Evening (6-9 PM)')),
          ],
          onChanged: (v) => setState(() => _workoutTime = v ?? 'afternoon'),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() {
                  _veg = !_veg;
                  if (_veg) _eggEater = true;
                }),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: _veg ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _veg ? AppColors.primary : Colors.transparent),
                  ),
                  child:  Row(
                    children: [
                      Icon(Icons.eco, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text('Vegetarian diet', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_veg) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.surfaceLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Do you eat eggs?', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ChoiceChip(
                        label: 'Yes, eggetarian',
                        selected: _eggEater,
                        onTap: () => setState(() => _eggEater = true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ChoiceChip(
                        label: 'No, egg-free',
                        selected: !_eggEater,
                        onTap: () => setState(() => _eggEater = false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _measurementsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MeasurementField(
          controller: _waist,
          label: 'Waist (in)',
          hint: 'Tape around your navel',
        ),
        const SizedBox(height: 14),
        _MeasurementField(
          controller: _neck,
          label: 'Neck (in)',
          hint: 'Below the Adam\'s apple',
        ),
        const SizedBox(height: 14),
        if (_gender == 'female')
          _MeasurementField(
            controller: _hip,
            label: 'Hip (in)',
            hint: 'Widest point around hips',
          ),
        const SizedBox(height: 10),
         Text(
          'These three numbers let us measure your body fat % with the US Navy method — far more accurate than BMI alone.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.5),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  final int dots;
  const _Stepper({required this.dots});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final active = i <= dots;
        return Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style:  TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.onPrimary : AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MeasurementField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  const _MeasurementField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Label(label),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

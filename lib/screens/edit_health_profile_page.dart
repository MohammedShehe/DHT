import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/health_service.dart';
import '../models/health_profile_model.dart';
import '../utils/snackbar_helper.dart';

class EditHealthProfilePage extends StatefulWidget {
  final HealthProfileModel? existingProfile;

  const EditHealthProfilePage({super.key, this.existingProfile});

  @override
  State<EditHealthProfilePage> createState() => _EditHealthProfilePageState();
}

class _EditHealthProfilePageState extends State<EditHealthProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Personal Information
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  
  // Health Metrics
  final _bloodPressureController = TextEditingController();
  final _glucoseController = TextEditingController();
  final _cholesterolController = TextEditingController();
  
  // Dropdown values
  String _gender = 'Male';
  String _activityLevel = 'Moderate';
  String _healthGoal = 'Maintain Weight';
  String _bloodType = 'A+';
  String _allergies = '';
  String _medications = '';
  String _medicalConditions = '';
  
  // Toggle values
  bool _hasDiabetes = false;
  bool _hasHypertension = false;
  bool _hasHeartCondition = false;
  bool _smoker = false;
  bool _alcoholConsumer = false;
  
  List<String> _selectedActivityTypes = [];

  final List<String> _activityTypes = [
    'Walking',
    'Running',
    'Cycling',
    'Swimming',
    'Weight Training',
    'Yoga',
    'Pilates',
    'Team Sports',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  void _loadExistingProfile() {
    if (widget.existingProfile != null) {
      final profile = widget.existingProfile!;
      
      // Personal Information
      _ageController.text = profile.age?.toString() ?? '';
      _heightController.text = profile.height?.toString() ?? '';
      _weightController.text = profile.weight?.toString() ?? '';
      
      // Dropdown values
      _gender = profile.gender ?? 'Male';
      _activityLevel = profile.activityLevel ?? 'Moderate';
      _healthGoal = profile.healthGoal ?? 'Maintain Weight';
      _bloodType = profile.bloodType ?? 'A+';
      _allergies = profile.allergies ?? '';
      _medications = profile.medications ?? '';
      _medicalConditions = profile.medicalConditions ?? '';
      
      // Health Metrics
      _bloodPressureController.text = profile.bloodPressure ?? '';
      _glucoseController.text = profile.glucose?.toString() ?? '';
      _cholesterolController.text = profile.cholesterol?.toString() ?? '';
      
      // Toggle values
      _hasDiabetes = profile.hasDiabetes;
      _hasHypertension = profile.hasHypertension;
      _hasHeartCondition = profile.hasHeartCondition;
      _smoker = profile.smoker;
      _alcoholConsumer = profile.alcoholConsumer;
      
      // Activity types
      if (profile.activityTypes != null && profile.activityTypes!.isNotEmpty) {
        _selectedActivityTypes = profile.activityTypes!.split(',').toList();
      }
    }
  }

  void _toggleActivityType(String activity) {
    setState(() {
      if (_selectedActivityTypes.contains(activity)) {
        _selectedActivityTypes.remove(activity);
      } else {
        _selectedActivityTypes.add(activity);
      }
    });
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  Future<void> _submitSetup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create health profile from form data
      final profile = HealthProfileModel(
        age: int.tryParse(_ageController.text) ?? 0,
        gender: _gender,
        height: double.tryParse(_heightController.text) ?? 0,
        weight: double.tryParse(_weightController.text) ?? 0,
        bloodType: _bloodType,
        activityLevel: _activityLevel,
        healthGoal: _healthGoal,
        activityTypes: _selectedActivityTypes.join(','),
        bloodPressure: _bloodPressureController.text.isEmpty 
            ? null 
            : _bloodPressureController.text,
        glucose: _glucoseController.text.isEmpty 
            ? null 
            : double.tryParse(_glucoseController.text),
        cholesterol: _cholesterolController.text.isEmpty 
            ? null 
            : double.tryParse(_cholesterolController.text),
        hasDiabetes: _hasDiabetes,
        hasHypertension: _hasHypertension,
        hasHeartCondition: _hasHeartCondition,
        smoker: _smoker,
        alcoholConsumer: _alcoholConsumer,
        medications: _medications.isEmpty ? null : _medications,
        allergies: _allergies.isEmpty ? null : _allergies,
        medicalConditions: _medicalConditions.isEmpty ? null : _medicalConditions,
      );

      // Save to backend
      final response = await HealthService.saveHealthProfile(profile);
      
      if (response['success']) {
        if (mounted) {
          SnackbarHelper.showSuccess(
            context,
            'Health profile updated successfully!',
          );
          
          Navigator.pop(context, true); // Return true to indicate update
        }
      } else {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            response['message'] ?? 'Failed to update health profile',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Error: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _bloodPressureController.dispose();
    _glucoseController.dispose();
    _cholesterolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingProfile == null ? 'Create Health Profile' : 'Edit Health Profile',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Indicator
                LinearProgressIndicator(
                  value: 0.8,
                  backgroundColor: Colors.grey[200],
                  color: const Color(0xFF00C853),
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 6,
                ),
                const SizedBox(height: 20),

                const Text(
                  'Health Profile Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.existingProfile == null 
                      ? 'Personalized tracking starts with your health details'
                      : 'Update your health information below',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Personal Information Section
                _buildSectionTitle('Personal Information'),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageController,
                        validator: (value) => _validateRequired(value, 'age'),
                        decoration: InputDecoration(
                          labelText: 'Age (years)',
                          prefixIcon: const Icon(Icons.calendar_today),
                          filled: true,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField(
                        value: _gender,
                        items: ['Male', 'Female', 'Other']
                            .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _gender = v!),
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          prefixIcon: const Icon(Icons.person),
                          filled: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _heightController,
                        validator: (value) => _validateRequired(value, 'height'),
                        decoration: InputDecoration(
                          labelText: 'Height (cm)',
                          prefixIcon: const Icon(Icons.straighten),
                          suffixText: 'cm',
                          filled: true,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        validator: (value) => _validateRequired(value, 'weight'),
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          prefixIcon: const Icon(Icons.monitor_weight),
                          suffixText: 'kg',
                          filled: true,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField(
                  value: _bloodType,
                  items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _bloodType = v!),
                  decoration: InputDecoration(
                    labelText: 'Blood Type',
                    prefixIcon: const Icon(Icons.bloodtype),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 32),

                // Activity & Goals Section
                _buildSectionTitle('Activity & Goals'),
                const SizedBox(height: 16),

                DropdownButtonFormField(
                  value: _activityLevel,
                  items: ['Sedentary', 'Lightly Active', 'Moderate', 'Very Active', 'Extremely Active']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _activityLevel = v!),
                  decoration: InputDecoration(
                    labelText: 'Activity Level',
                    prefixIcon: const Icon(Icons.directions_run),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField(
                  value: _healthGoal,
                  items: ['Lose Weight', 'Maintain Weight', 'Gain Muscle', 'Improve Fitness', 'Manage Condition']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setState(() => _healthGoal = v!),
                  decoration: InputDecoration(
                    labelText: 'Primary Health Goal',
                    prefixIcon: const Icon(Icons.flag),
                    filled: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Preferred Activities
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preferred Activities',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _activityTypes.map((activity) {
                        final isSelected = _selectedActivityTypes.contains(activity);
                        return FilterChip(
                          label: Text(activity),
                          selected: isSelected,
                          onSelected: (_) => _toggleActivityType(activity),
                          selectedColor: const Color(0xFF00C853).withOpacity(0.2),
                          checkmarkColor: const Color(0xFF00C853),
                          backgroundColor: Colors.grey[100],
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF00C853) : Colors.grey[700],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Health Metrics Section
                _buildSectionTitle('Health Metrics (Optional)'),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _bloodPressureController,
                  decoration: InputDecoration(
                    labelText: 'Blood Pressure (mmHg)',
                    prefixIcon: const Icon(Icons.monitor_heart),
                    hintText: 'e.g., 120/80',
                    filled: true,
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _glucoseController,
                  decoration: InputDecoration(
                    labelText: 'Fasting Glucose (mg/dL)',
                    prefixIcon: const Icon(Icons.monitor_heart),
                    filled: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _cholesterolController,
                  decoration: InputDecoration(
                    labelText: 'Cholesterol (mg/dL)',
                    prefixIcon: const Icon(Icons.monitor_heart),
                    filled: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 32),

                // Health Conditions
                _buildSectionTitle('Health Conditions'),
                const SizedBox(height: 16),

                _buildToggleOption(
                  'Diabetes',
                  _hasDiabetes,
                  (value) => setState(() => _hasDiabetes = value),
                ),
                _buildToggleOption(
                  'Hypertension',
                  _hasHypertension,
                  (value) => setState(() => _hasHypertension = value),
                ),
                _buildToggleOption(
                  'Heart Condition',
                  _hasHeartCondition,
                  (value) => setState(() => _hasHeartCondition = value),
                ),
                _buildToggleOption(
                  'Smoker',
                  _smoker,
                  (value) => setState(() => _smoker = value),
                ),
                _buildToggleOption(
                  'Alcohol Consumer',
                  _alcoholConsumer,
                  (value) => setState(() => _alcoholConsumer = value),
                ),
                const SizedBox(height: 32),

                // Medications & Allergies
                _buildSectionTitle('Medications & Allergies'),
                const SizedBox(height: 16),

                TextFormField(
                  controller: TextEditingController(text: _medications),
                  decoration: InputDecoration(
                    labelText: 'Current Medications',
                    prefixIcon: const Icon(Icons.medication),
                    filled: true,
                    hintText: 'Enter any medications you take regularly',
                  ),
                  onChanged: (value) => _medications = value,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: TextEditingController(text: _allergies),
                  decoration: InputDecoration(
                    labelText: 'Allergies',
                    prefixIcon: const Icon(Icons.warning),
                    filled: true,
                    hintText: 'Enter any allergies you have',
                  ),
                  onChanged: (value) => _allergies = value,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: TextEditingController(text: _medicalConditions),
                  decoration: InputDecoration(
                    labelText: 'Medical Conditions',
                    prefixIcon: const Icon(Icons.medical_services),
                    filled: true,
                    hintText: 'Enter any other medical conditions',
                  ),
                  onChanged: (value) => _medicalConditions = value,
                ),
                const SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitSetup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.existingProfile == null
                                ? 'Create Health Profile'
                                : 'Update Health Profile',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  Widget _buildToggleOption(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF00C853),
          ),
        ],
      ),
    );
  }
}
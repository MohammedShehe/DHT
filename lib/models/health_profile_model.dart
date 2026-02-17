class HealthProfileModel {
  int? id;
  int? userId;
  int? age;
  String? gender;
  double? height;
  double? weight;
  String? bloodType;
  String? activityLevel;
  String? healthGoal;
  String? activityTypes;
  String? bloodPressure;
  double? glucose;
  double? cholesterol;
  bool hasDiabetes;
  bool hasHypertension;
  bool hasHeartCondition;
  bool smoker;
  bool alcoholConsumer;
  String? medications;
  String? allergies;
  String? medicalConditions;

  HealthProfileModel({
    this.id,
    this.userId,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.bloodType,
    this.activityLevel,
    this.healthGoal,
    this.activityTypes,
    this.bloodPressure,
    this.glucose,
    this.cholesterol,
    this.hasDiabetes = false,
    this.hasHypertension = false,
    this.hasHeartCondition = false,
    this.smoker = false,
    this.alcoholConsumer = false,
    this.medications,
    this.allergies,
    this.medicalConditions,
  });

  factory HealthProfileModel.fromJson(Map<String, dynamic> json) {
    
    return HealthProfileModel(
      id: json['id'] as int?,
      userId: json['user_id'] as int?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      height: json['height'] != null 
          ? double.tryParse(json['height'].toString()) 
          : null,
      weight: json['weight'] != null 
          ? double.tryParse(json['weight'].toString()) 
          : null,
      bloodType: json['blood_type'] as String?,
      activityLevel: json['activity_level'] as String?,
      healthGoal: json['health_goal'] as String?,
      activityTypes: json['activity_types'] as String?,
      bloodPressure: json['blood_pressure'] as String?,
      glucose: json['glucose'] != null 
          ? double.tryParse(json['glucose'].toString()) 
          : null,
      cholesterol: json['cholesterol'] != null 
          ? double.tryParse(json['cholesterol'].toString()) 
          : null,
      hasDiabetes: json['has_diabetes'] == 1 || json['has_diabetes'] == true,
      hasHypertension: json['has_hypertension'] == 1 || json['has_hypertension'] == true,
      hasHeartCondition: json['has_heart_condition'] == 1 || json['has_heart_condition'] == true,
      smoker: json['smoker'] == 1 || json['smoker'] == true,
      alcoholConsumer: json['alcohol_consumer'] == 1 || json['alcohol_consumer'] == true,
      medications: json['medications'] as String?,
      allergies: json['allergies'] as String?,
      medicalConditions: json['medical_conditions'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'blood_type': bloodType,
      'activity_level': activityLevel,
      'health_goal': healthGoal,
      'activity_types': activityTypes,
      'blood_pressure': bloodPressure,
      'glucose': glucose,
      'cholesterol': cholesterol,
      'has_diabetes': hasDiabetes ? 1 : 0,
      'has_hypertension': hasHypertension ? 1 : 0,
      'has_heart_condition': hasHeartCondition ? 1 : 0,
      'smoker': smoker ? 1 : 0,
      'alcohol_consumer': alcoholConsumer ? 1 : 0,
      'medications': medications,
      'allergies': allergies,
      'medical_conditions': medicalConditions,
    };
  }
}
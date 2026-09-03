class User {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String gender;
  final int age;
  final int heightCm;
  final int weightKg;
  final String activityLevel;
  final String fitnessLevel;
  final bool veg;
  final bool eggFree;
  final int? waistCm;
  final int? neckCm;
  final int? hipCm;
  final String? goal;
  final String workoutTime;
  final String workoutSplit;
  final Map<String, bool> gymPlans;
  final Map<String, bool> attendance;
  final String? profilePhoto;
  final String? profilePhotoUrl;
  final String? wakeTime;
  final String? sleepTime;
  final String? gymTime;

  User({
    required this.id,
    this.userId = '',
    required this.name,
    required this.email,
    required this.gender,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.fitnessLevel,
    required this.veg,
    this.eggFree = false,
    this.waistCm,
    this.neckCm,
    this.hipCm,
    this.goal,
    this.workoutTime = 'afternoon',
    this.workoutSplit = '',
    this.gymPlans = const {},
    this.attendance = const {},
    this.profilePhoto,
    this.profilePhotoUrl,
    this.wakeTime,
    this.sleepTime,
    this.gymTime,
  });

  factory User.fromJson(Map<String, dynamic> j) {
    return User(
      id: j['id'] as String? ?? '',
      userId: j['userId'] as String? ?? '',
      name: j['name'] as String? ?? '',
      email: j['email'] as String? ?? '',
      gender: j['gender'] as String? ?? 'male',
      age: (j['age'] as num?)?.toInt() ?? 0,
      heightCm: (j['heightCm'] as num?)?.toInt() ?? 0,
      weightKg: (j['weightKg'] as num?)?.toInt() ?? 0,
      activityLevel: j['activityLevel'] as String? ?? 'moderate',
      fitnessLevel: j['fitnessLevel'] as String? ?? 'beginner',
      veg: j['veg'] as bool? ?? false,
      eggFree: j['eggFree'] as bool? ?? false,
      waistCm: (j['waistCm'] as num?)?.toInt(),
      neckCm: (j['neckCm'] as num?)?.toInt(),
      hipCm: (j['hipCm'] as num?)?.toInt(),
      goal: j['goal'] as String?,
      workoutTime: j['workoutTime'] as String? ?? 'afternoon',
      workoutSplit: j['workoutSplit'] as String? ?? '',
      gymPlans: _boolMap(j['gymPlans']),
      attendance: _boolMap(j['attendance']),
      profilePhoto: j['profilePhoto'] as String?,
      profilePhotoUrl: j['profilePhotoUrl'] as String?,
      wakeTime: j['wakeTime'] as String?,
      sleepTime: j['sleepTime'] as String?,
      gymTime: j['gymTime'] as String?,
    );
  }

  static Map<String, bool> _boolMap(dynamic v) {
    if (v is! Map) return const {};
    return v.map((k, val) => MapEntry(k.toString(), val == true));
  }

  /// Returns the best available photo: server-stored URL or legacy base64.
  /// If [fullUrl] is true, prepends the API base URL for network loading.
  String? get displayPhoto => profilePhotoUrl ?? profilePhoto;
  bool get isPhotoUrl => profilePhotoUrl != null && profilePhotoUrl!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'gender': gender,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'activityLevel': activityLevel,
        'fitnessLevel': fitnessLevel,
        'veg': veg,
        'waistCm': waistCm,
        'neckCm': neckCm,
        'hipCm': hipCm,
        if (goal != null) 'goal': goal,
        'workoutTime': workoutTime,
        if (profilePhoto != null) 'profilePhoto': profilePhoto,
      };

  Map<String, dynamic> toBodyJson() => {
        'gender': gender,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'activityLevel': activityLevel,
        'fitnessLevel': fitnessLevel,
        'veg': veg,
        'workoutTime': workoutTime,
        if (waistCm != null) 'waistCm': waistCm,
        if (neckCm != null) 'neckCm': neckCm,
        if (hipCm != null) 'hipCm': hipCm,
      };
}

class Assessment {
  final double? bmi;
  final String bmiCategory;
  final double? bodyFatPct;
  final String bodyFatCategory;
  final double targetFatMin;
  final double targetFatMax;
  final double? leanMassKg;
  final double? fatMassKg;
  final double? ffmi;
  final double? normalizedFfmi;
  final String? ffmiCategory;
  final double? rfm;
  final String goal;
  final int bmr;
  final int tdee;
  final int calories;
  final int protein;
  final int fiber;
  final int carbs;
  final int? weeksToTarget;

  Assessment({
    required this.bmi,
    required this.bmiCategory,
    required this.bodyFatPct,
    this.bodyFatCategory = 'Fitness',
    required this.targetFatMin,
    required this.targetFatMax,
    this.leanMassKg,
    this.fatMassKg,
    this.ffmi,
    this.normalizedFfmi,
    this.ffmiCategory,
    this.rfm,
    required this.goal,
    required this.bmr,
    required this.tdee,
    required this.calories,
    required this.protein,
    required this.fiber,
    required this.carbs,
    this.weeksToTarget,
  });

  factory Assessment.fromJson(Map<String, dynamic> j) {
    final macros = j['macros'] as Map<String, dynamic>? ?? {};
    return Assessment(
      bmi: (j['bmi'] as num?)?.toDouble(),
      bmiCategory: j['bmiCategory'] as String? ?? '—',
      bodyFatPct: (j['bodyFatPct'] as num?)?.toDouble(),
      bodyFatCategory: j['bodyFatCategory'] as String? ?? 'Fitness',
      targetFatMin: ((j['targetBodyFat'] as Map<String, dynamic>?)?['min'] as num?)?.toDouble() ?? 15,
      targetFatMax: ((j['targetBodyFat'] as Map<String, dynamic>?)?['max'] as num?)?.toDouble() ?? 17,
      leanMassKg: (j['leanMassKg'] as num?)?.toDouble(),
      fatMassKg: (j['fatMassKg'] as num?)?.toDouble(),
      ffmi: (j['ffmi'] as num?)?.toDouble(),
      normalizedFfmi: (j['normalizedFfmi'] as num?)?.toDouble(),
      ffmiCategory: j['ffmiCategory'] as String?,
      rfm: (j['rfm'] as num?)?.toDouble(),
      goal: j['goal'] as String? ?? 'maintain',
      bmr: (j['bmr'] as num?)?.toInt() ?? 0,
      tdee: (j['tdee'] as num?)?.toInt() ?? 0,
      calories: (j['calories'] as num?)?.toInt() ?? 0,
      protein: (macros['protein'] as num?)?.toInt() ?? 0,
      fiber: (macros['fiber'] as num?)?.toInt() ?? 0,
      carbs: (macros['carbs'] as num?)?.toInt() ?? 0,
      weeksToTarget: (j['weeksToTarget'] as num?)?.toInt(),
    );
  }
}

class MealItem {
  final String name;
  final String unit;
  final int grams;
  final int kcal;
  final double protein;
  final double carbs;
  final double fat;

  MealItem.fromJson(Map<String, dynamic> j)
      : name = j['name'] as String? ?? '',
        unit = j['unit'] as String? ?? '',
        grams = (j['grams'] as num?)?.toInt() ?? 0,
        kcal = (j['kcal'] as num?)?.toInt() ?? 0,
        protein = (j['protein'] as num?)?.toDouble() ?? 0,
        carbs = (j['carbs'] as num?)?.toDouble() ?? 0,
        fat = (j['fat'] as num?)?.toDouble() ?? 0;
}

class Meal {
  final String name;
  final String time;
  final int kcal;
  final String tip;
  final List<MealItem> items;

  Meal.fromJson(Map<String, dynamic> j)
      : name = j['meal'] as String? ?? '',
        time = j['time'] as String? ?? '',
        kcal = (j['kcal'] as num?)?.toInt() ?? 0,
        tip = j['tip'] as String? ?? '',
        items = ((j['items'] as List?) ?? [])
            .map((e) => MealItem.fromJson(e as Map<String, dynamic>))
            .toList();
}

class DietPlan {
  final int calories;
  final int protein;
  final int carbs;
  final int fiber;
  final double waterLiters;
  final String note;
  final String workoutTime;
  final bool gymDay;
  final List<Meal> meals;

  DietPlan.fromJson(Map<String, dynamic> j)
      : calories = (j['calories'] as num?)?.toInt() ?? 0,
        protein = (j['protein'] as num?)?.toInt() ?? 0,
        carbs = (j['carbs'] as num?)?.toInt() ?? 0,
        fiber = (j['fiber'] as num?)?.toInt() ?? 0,
        waterLiters = (j['waterLiters'] as num?)?.toDouble() ?? 0,
        note = j['note'] as String? ?? '',
        workoutTime = j['workoutTime'] as String? ?? '',
        gymDay = j['gymDay'] as bool? ?? true,
        meals = ((j['meals'] as List?) ?? [])
            .map((e) => Meal.fromJson(e as Map<String, dynamic>))
            .toList();
}

class MealScheduleItem {
  final String meal;
  final String time;

  MealScheduleItem.fromJson(Map<String, dynamic> j)
      : meal = j['meal'] as String? ?? '',
        time = j['time'] as String? ?? '';
}

class MealSchedule {
  final List<MealScheduleItem> gym;
  final List<MealScheduleItem> rest;

  MealSchedule.fromJson(Map<String, dynamic> j)
      : gym = ((j['gym'] as List?) ?? [])
            .map((e) => MealScheduleItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        rest = ((j['rest'] as List?) ?? [])
            .map((e) => MealScheduleItem.fromJson(e as Map<String, dynamic>))
            .toList();
}

class Exercise {
  final String name;
  final String muscle;
  final int sets;
  final String reps;
  final int rest;

  Exercise.fromJson(Map<String, dynamic> j)
      : name = j['name'] as String? ?? '',
        muscle = j['muscle'] as String? ?? '',
        sets = (j['sets'] as num?)?.toInt() ?? 0,
        reps = j['reps'] as String? ?? '',
        rest = (j['rest'] as num?)?.toInt() ?? 0;
}

class WorkoutDay {
  final int day;
  final String label;
  final List<Exercise>? workout;
  final List<Exercise>? abs;
  final List<Exercise>? cardio;
  final bool done;

  WorkoutDay.fromJson(Map<String, dynamic> j)
      : day = (j['day'] as num?)?.toInt() ?? 0,
        label = j['label'] as String? ?? '',
        workout = ((j['workout'] as List?) ?? [])
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        abs = ((j['abs'] as List?) ?? [])
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        cardio = ((j['cardio'] as List?) ?? [])
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        done = j['done'] == true;
}

class WorkoutPlan {
  final String split;
  final String program;
  final String level;
  final int cycle;
  final String warmup;
  final String cooldown;
  final Map<String, dynamic> cardioGuidance;
  final List<WorkoutDay> weekly;
  final int currentDay;

  WorkoutPlan.fromJson(Map<String, dynamic> j)
      : split = j['split'] as String? ?? '',
        program = j['program'] as String? ?? '',
        level = j['level'] as String? ?? '',
        cycle = (j['cycle'] as num?)?.toInt() ?? 0,
        warmup = j['warmup'] as String? ?? '',
        cooldown = j['cooldown'] as String? ?? '',
        cardioGuidance = (j['cardioGuidance'] as Map<String, dynamic>?) ?? {},
        weekly = ((j['weekly'] as List?) ?? [])
            .map((e) => WorkoutDay.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentDay = (j['currentDay'] as num?)?.toInt() ?? 1;
}

String toTitleCase(String input) {
  return input
      .split('_')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

class DeveloperInfo {
  final String name;
  final String role;
  final String website;
  final String email;
  final String github;

  DeveloperInfo.fromJson(Map<String, dynamic> j)
      : name = j['name'] as String? ?? '',
        role = j['role'] as String? ?? '',
        website = j['website'] as String? ?? '',
        email = j['email'] as String? ?? '',
        github = j['github'] as String? ?? '';
}

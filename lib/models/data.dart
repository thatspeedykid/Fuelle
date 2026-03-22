import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// ── Colors ────────────────────────────────────────────────────────────────────
class FuelleColors {
  static const bg       = Color(0xFF0e0f0d);
  static const surface  = Color(0xFF161714);
  static const surface2 = Color(0xFF1e1f1c);
  static const border   = Color(0xFF2a2b27);
  static const accent   = Color(0xFFc8f56a);
  static const accent2  = Color(0xFF8dde1a);
  static const text     = Color(0xFFf0f0ec);
  static const muted    = Color(0xFF7a7b75);
  static const warn     = Color(0xFFf5a623);
  static const danger   = Color(0xFFf56a6a);
  static const teal     = Color(0xFF6af5e0);
  static const orange   = Color(0xFFf5a66a);
}

// ── Food Item ─────────────────────────────────────────────────────────────────
class FoodItem {
  String name;
  String portion;  // e.g. "150g"
  double cal;
  double carb;
  double prot;
  double fat;
  int? fdcId;

  FoodItem({
    required this.name,
    required this.portion,
    required this.cal,
    required this.carb,
    required this.prot,
    required this.fat,
    this.fdcId,
  });

  Map<String, dynamic> toJson() => {
    'name': name, 'portion': portion,
    'cal': cal, 'carb': carb, 'prot': prot, 'fat': fat,
    if (fdcId != null) 'fdcId': fdcId,
  };

  factory FoodItem.fromJson(Map<String, dynamic> j) => FoodItem(
    name:    j['name']    ?? '',
    portion: j['portion'] ?? '',
    cal:     (j['cal']    ?? 0).toDouble(),
    carb:    (j['carb']   ?? 0).toDouble(),
    prot:    (j['prot']   ?? 0).toDouble(),
    fat:     (j['fat']    ?? 0).toDouble(),
    fdcId:   j['fdcId'],
  );
}

// ── Meal Types ────────────────────────────────────────────────────────────────
enum MealType { breakfast, lunch, dinner, snacks }

extension MealTypeExt on MealType {
  String get label => switch (this) {
    MealType.breakfast => 'Breakfast',
    MealType.lunch     => 'Lunch',
    MealType.dinner    => 'Dinner',
    MealType.snacks    => 'Snacks',
  };
  String get icon => switch (this) {
    MealType.breakfast => '🌅',
    MealType.lunch     => '☀️',
    MealType.dinner    => '🌙',
    MealType.snacks    => '🍎',
  };
  String get key => name;
}

// ── Day Log ───────────────────────────────────────────────────────────────────
class DayLog {
  Map<MealType, List<FoodItem>> meals;

  DayLog({Map<MealType, List<FoodItem>>? meals})
      : meals = meals ?? {
          for (final m in MealType.values) m: [],
        };

  List<FoodItem> get allItems => meals.values.expand((l) => l).toList();

  double get totalCal  => allItems.fold(0, (s, f) => s + f.cal);
  double get totalCarb => allItems.fold(0, (s, f) => s + f.carb);
  double get totalProt => allItems.fold(0, (s, f) => s + f.prot);
  double get totalFat  => allItems.fold(0, (s, f) => s + f.fat);

  Map<String, dynamic> toJson() => {
    for (final m in MealType.values)
      m.key: meals[m]!.map((f) => f.toJson()).toList(),
  };

  factory DayLog.fromJson(Map<String, dynamic> j) => DayLog(
    meals: {
      for (final m in MealType.values)
        m: (j[m.key] as List? ?? [])
            .map((f) => FoodItem.fromJson(f as Map<String, dynamic>))
            .toList(),
    },
  );
}

// ── Goals ─────────────────────────────────────────────────────────────────────
class NutritionGoals {
  double cal;
  double carb;
  double prot;
  double fat;

  NutritionGoals({
    this.cal  = 2000,
    this.carb = 250,
    this.prot = 150,
    this.fat  = 65,
  });

  Map<String, dynamic> toJson() => {
    'cal': cal, 'carb': carb, 'prot': prot, 'fat': fat,
  };

  factory NutritionGoals.fromJson(Map<String, dynamic> j) => NutritionGoals(
    cal:  (j['cal']  ?? 2000).toDouble(),
    carb: (j['carb'] ?? 250).toDouble(),
    prot: (j['prot'] ?? 150).toDouble(),
    fat:  (j['fat']  ?? 65).toDouble(),
  );
}

// ── Root Data ─────────────────────────────────────────────────────────────────
class FuelleData {
  Map<String, DayLog>  log;       // keyed by "YYYY-MM-DD"
  NutritionGoals       goals;
  bool                 darkMode;
  double               fontSize;

  FuelleData({
    required this.log,
    required this.goals,
    required this.darkMode,
    this.fontSize = 15.0,
  });

  factory FuelleData.empty() => FuelleData(
    log:      {},
    goals:    NutritionGoals(),
    darkMode: true,
  );

  Map<String, dynamic> toJson() => {
    'log':      log.map((k, v) => MapEntry(k, v.toJson())),
    'goals':    goals.toJson(),
    'darkMode': darkMode,
    'fontSize': fontSize,
  };

  factory FuelleData.fromJson(Map<String, dynamic> j) => FuelleData(
    log: (j['log'] as Map<String, dynamic>? ?? {}).map(
      (k, v) => MapEntry(k, DayLog.fromJson(v as Map<String, dynamic>)),
    ),
    goals:    NutritionGoals.fromJson(j['goals'] as Map<String, dynamic>? ?? {}),
    darkMode: j['darkMode'] ?? true,
    fontSize: (j['fontSize'] ?? 15.0).toDouble(),
  );

  DayLog dayLog(String dateKey) {
    log.putIfAbsent(dateKey, () => DayLog());
    return log[dateKey]!;
  }
}

// ── Storage ───────────────────────────────────────────────────────────────────
class FuelleStorage {
  static Future<File> _getFile() async {
    final appDir = await getApplicationSupportDirectory();
    final file = File('${appDir.path}/fuelle_data.json');
    if (!await file.exists()) {
      await file.parent.create(recursive: true);
    }
    return file;
  }

  static Future<FuelleData> load() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        return FuelleData.fromJson(jsonDecode(await file.readAsString()));
      }
    } catch (_) {}
    return FuelleData.empty();
  }

  static Future<void> save(FuelleData data) async {
    final file = await _getFile();
    await file.writeAsString(jsonEncode(data.toJson()));
  }

  // Export: FUELLE1:<gzip+base64>
  static String exportCode(FuelleData data) {
    final json = jsonEncode(data.toJson());
    final compressed = GZipCodec().encode(utf8.encode(json));
    return 'FUELLE1:${base64.encode(compressed)}';
  }

  // Import: parse FUELLE1: code
  static FuelleData importCode(String code) {
    if (!code.startsWith('FUELLE1:')) throw Exception('Not a Fuelle backup code');
    final compressed = base64.decode(code.substring(8));
    final jsonBytes  = GZipCodec().decode(compressed);
    return FuelleData.fromJson(jsonDecode(utf8.decode(jsonBytes)));
  }
}

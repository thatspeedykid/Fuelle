import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../models/data.dart';

class TodayScreen extends StatefulWidget {
  final FuelleData data;
  final ValueChanged<FuelleData> onChanged;
  const TodayScreen({super.key, required this.data, required this.onChanged});
  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late FuelleData _data;
  int _dayOffset = 0;
  MealType? _openPanel;
  String? _toast;

  // Search state
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;
  Map<String, dynamic>? _pending;
  final _portionCtrl = TextEditingController(text: '100');

  @override
  void initState() { super.initState(); _data = widget.data; }
  @override
  void didUpdateWidget(TodayScreen old) { super.didUpdateWidget(old); _data = widget.data; }
  @override
  void dispose() { _searchCtrl.dispose(); _portionCtrl.dispose(); super.dispose(); }

  String get _dateKey {
    final d = DateTime.now().add(Duration(days: _dayOffset));
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }

  String get _dayLabel {
    if (_dayOffset == 0)  return 'Today';
    if (_dayOffset == -1) return 'Yesterday';
    if (_dayOffset == 1)  return 'Tomorrow';
    final d = DateTime.now().add(Duration(days: _dayOffset));
    return _weekday(d.weekday);
  }

  String get _dateSub {
    final d = DateTime.now().add(Duration(days: _dayOffset));
    return '${_monthName(d.month)} ${d.day}, ${d.year}';
  }

  String _weekday(int w) => ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][w - 1];
  String _monthName(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];

  void _save(FuelleData d) {
    setState(() => _data = d);
    widget.onChanged(d);
  }

  void _showToast(String msg) {
    setState(() => _toast = msg);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  // ── USDA Search ─────────────────────────────────────────────────────────
  Future<void> _searchFood() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _searching = true; _results = []; _pending = null; });
    try {
      final uri = Uri.parse(
        'https://api.nal.usda.gov/fdc/v1/foods/search'
        '?query=${Uri.encodeComponent(q)}'
        '&dataType=Foundation,SR%20Legacy'
        '&pageSize=10'
        '&api_key=DEMO_KEY',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final foods = (body['foods'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        setState(() => _results = foods);
      }
    } catch (_) {
      _showToast('Search failed — check your connection');
    }
    setState(() => _searching = false);
  }

  double _nutrient(List nutrients, String name) {
    for (final n in nutrients) {
      final nName = n['nutrientName'] ?? n['name'] ?? '';
      if (nName == name) return (n['value'] ?? 0).toDouble();
    }
    return 0;
  }

  void _selectFood(Map<String, dynamic> food) {
    setState(() { _pending = food; _portionCtrl.text = '100'; });
  }

  void _addFood(MealType meal) {
    if (_pending == null) { _showToast('Select a food first'); return; }
    final portion = double.tryParse(_portionCtrl.text) ?? 100;
    final scale   = portion / 100;
    final nuts    = _pending!['foodNutrients'] as List? ?? [];

    final item = FoodItem(
      name:    (_pending!['description'] as String? ?? '').length > 45
                 ? (_pending!['description'] as String).substring(0, 45) + '…'
                 : (_pending!['description'] ?? ''),
      portion: '${portion.toStringAsFixed(0)}g',
      cal:  (_nutrient(nuts, 'Energy') == 0
              ? _nutrient(nuts, 'Energy (Atwater General Factors)')
              : _nutrient(nuts, 'Energy')) * scale,
      carb: _nutrient(nuts, 'Carbohydrate, by difference') * scale,
      prot: _nutrient(nuts, 'Protein') * scale,
      fat:  _nutrient(nuts, 'Total lipid (fat)') * scale,
      fdcId: _pending!['fdcId'] as int?,
    );

    final newLog = Map<String, DayLog>.from(_data.log);
    final day    = DayLog.fromJson(
      (newLog[_dateKey] ?? DayLog()).toJson());
    day.meals[meal]!.add(item);
    newLog[_dateKey] = day;

    _save(FuelleData(
      log: newLog, goals: _data.goals,
      darkMode: _data.darkMode, fontSize: _data.fontSize,
    ));

    setState(() {
      _pending = null;
      _results = [];
      _searchCtrl.clear();
      _openPanel = null;
    });
    _showToast('Added to ${meal.label}!');
  }

  void _removeFood(MealType meal, int idx) {
    final newLog = Map<String, DayLog>.from(_data.log);
    final day    = DayLog.fromJson((newLog[_dateKey] ?? DayLog()).toJson());
    day.meals[meal]!.removeAt(idx);
    newLog[_dateKey] = day;
    _save(FuelleData(
      log: newLog, goals: _data.goals,
      darkMode: _data.darkMode, fontSize: _data.fontSize,
    ));
  }

  // ── Colors ───────────────────────────────────────────────────────────────
  Color get _bg       => _data.darkMode ? FuelleColors.bg       : const Color(0xFFf5f5f0);
  Color get _surface  => _data.darkMode ? FuelleColors.surface  : const Color(0xFFffffff);
  Color get _surface2 => _data.darkMode ? FuelleColors.surface2 : const Color(0xFFeeebe3);
  Color get _border   => _data.darkMode ? FuelleColors.border   : const Color(0xFFd8d5cc);
  Color get _accent   => _data.darkMode ? FuelleColors.accent   : const Color(0xFF5a8a00);
  Color get _muted    => _data.darkMode ? FuelleColors.muted    : const Color(0xFF7a7b75);
  Color get _txt      => _data.darkMode ? FuelleColors.text     : const Color(0xFF1a1a17);
  Color get _teal     => FuelleColors.teal;
  Color get _orange   => FuelleColors.orange;

  @override
  Widget build(BuildContext context) {
    final day    = _data.dayLog(_dateKey);
    final goals  = _data.goals;
    final calPct = (day.totalCal / goals.cal).clamp(0.0, 1.0);

    return Stack(children: [
      SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(children: [

          // ── Day Navigator ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: _muted),
                onPressed: () => setState(() { _dayOffset--; _openPanel = null; })),
              Expanded(child: Column(children: [
                Text(_dayLabel, style: GoogleFonts.playfairDisplay(
                  fontSize: 20, color: _txt, fontWeight: FontWeight.w700)),
                Text(_dateSub, style: GoogleFonts.dmMono(
                  fontSize: 10, color: _muted, letterSpacing: 1)),
              ])),
              IconButton(
                icon: Icon(Icons.chevron_right, color: _muted),
                onPressed: () => setState(() { _dayOffset++; _openPanel = null; })),
            ]),
          ),

          // ── Summary Card ────────────────────────────────────────────────
          _summaryCard(day, goals, calPct),

          // ── Meal Sections ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Column(children: [
              for (final meal in MealType.values)
                _mealSection(meal, day.meals[meal] ?? []),
            ]),
          ),
        ]),
      ),

      // ── Toast ──────────────────────────────────────────────────────────
      if (_toast != null)
        Positioned(
          bottom: 16, left: 24, right: 24,
          child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _surface2,
              border: Border.all(color: _accent),
              borderRadius: BorderRadius.circular(30)),
            child: Text(_toast!,
              style: GoogleFonts.dmMono(color: _txt, fontSize: 13)),
          )),
        ),
    ]);
  }

  Widget _summaryCard(DayLog day, NutritionGoals goals, double calPct) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        // Ring
        SizedBox(width: 80, height: 80, child: Stack(alignment: Alignment.center, children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: calPct),
            duration: const Duration(milliseconds: 600),
            builder: (_, v, __) => CircularProgressIndicator(
              value: v,
              strokeWidth: 7,
              backgroundColor: _border,
              valueColor: AlwaysStoppedAnimation(_accent),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(day.totalCal.toStringAsFixed(0),
              style: GoogleFonts.playfairDisplay(
                fontSize: 18, color: _accent, height: 1.1)),
            Text('kcal', style: GoogleFonts.dmMono(
              fontSize: 9, color: _muted, letterSpacing: 1)),
          ]),
        ])),
        const SizedBox(width: 16),
        // Stats
        Expanded(child: Column(children: [
          _statRow('Calories', day.totalCal, goals.cal, _accent, 'kcal'),
          const SizedBox(height: 8),
          _statRow('Carbs',   day.totalCarb, goals.carb, _teal,   'g'),
          const SizedBox(height: 8),
          _statRow('Protein', day.totalProt, goals.prot, _orange, 'g'),
        ])),
      ]),
    );
  }

  Widget _statRow(String label, double val, double goal, Color color, String unit) {
    final pct = (val / goal).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(label, style: GoogleFonts.dmMono(fontSize: 11, color: _muted)),
        const Spacer(),
        Text('${val.toStringAsFixed(0)}${unit == 'kcal' ? '' : unit} / ${goal.toStringAsFixed(0)}${unit == 'kcal' ? ' kcal' : unit}',
          style: GoogleFonts.dmMono(fontSize: 10, color: _txt)),
      ]),
      const SizedBox(height: 3),
      ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: pct),
          duration: const Duration(milliseconds: 500),
          builder: (_, v, __) => LinearProgressIndicator(
            value: v,
            minHeight: 4,
            backgroundColor: _border,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ),
    ]);
  }

  Widget _mealSection(MealType meal, List<FoodItem> items) {
    final mealCal = items.fold(0.0, (s, f) => s + f.cal);
    final isOpen  = _openPanel == meal;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: isOpen ? _accent.withOpacity(0.5) : _border),
        borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        // Header row
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(children: [
            Text(meal.icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Text(meal.label, style: GoogleFonts.dmMono(
              fontSize: 13, color: _txt, fontWeight: FontWeight.w600)),
            if (mealCal > 0) ...[
              const SizedBox(width: 8),
              Text('${mealCal.toStringAsFixed(0)} kcal',
                style: GoogleFonts.dmMono(fontSize: 11, color: _muted)),
            ],
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() {
                _openPanel = isOpen ? null : meal;
                _results = [];
                _pending = null;
                _searchCtrl.clear();
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOpen ? _accent : _surface2,
                  border: Border.all(color: isOpen ? _accent : _border),
                  borderRadius: BorderRadius.circular(8)),
                child: Text('+ Add',
                  style: GoogleFonts.dmMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isOpen ? _bg : _accent)),
              ),
            ),
          ]),
        ),

        // Food items
        if (items.isNotEmpty) ...[
          Divider(height: 1, color: _border),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            child: Column(children: [
              for (int i = 0; i < items.length; i++)
                _foodTile(items[i], () => _removeFood(meal, i)),
            ]),
          ),
        ],

        // Add panel
        if (isOpen) ...[
          Divider(height: 1, color: _border),
          _addPanel(meal),
        ],
      ]),
    );
  }

  Widget _foodTile(FoodItem f, VoidCallback onDel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
      decoration: BoxDecoration(
        color: _surface2,
        borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(f.name, style: GoogleFonts.dmMono(fontSize: 12, color: _txt)),
          Text(f.portion, style: GoogleFonts.dmMono(fontSize: 10, color: _muted)),
        ])),
        Text('${f.cal.toStringAsFixed(0)} kcal',
          style: GoogleFonts.dmMono(fontSize: 12, color: _accent, fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Text('${f.carb.toStringAsFixed(0)}g C',
          style: GoogleFonts.dmMono(fontSize: 10, color: _teal)),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onDel,
          child: Icon(Icons.close, size: 14, color: _muted)),
      ]),
    );
  }

  Widget _addPanel(MealType meal) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Search row
        Row(children: [
          Expanded(child: TextField(
            controller: _searchCtrl,
            style: GoogleFonts.dmMono(fontSize: 13, color: _txt),
            decoration: InputDecoration(
              hintText: 'Search foods… e.g. chicken breast',
              hintStyle: GoogleFonts.dmMono(fontSize: 12, color: _muted),
              filled: true,
              fillColor: _surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _border)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _border)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _accent)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onSubmitted: (_) => _searchFood(),
          )),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _searching ? null : _searchFood,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _searching ? _border : _accent,
                borderRadius: BorderRadius.circular(8)),
              child: _searching
                ? SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _bg))
                : Text('Search', style: GoogleFonts.dmMono(
                    fontSize: 12, fontWeight: FontWeight.w700, color: _bg)),
            ),
          ),
        ]),

        // Results
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final f = _results[i];
                final nuts = f['foodNutrients'] as List? ?? [];
                final cal  = _nutrient(nuts, 'Energy') == 0
                    ? _nutrient(nuts, 'Energy (Atwater General Factors)')
                    : _nutrient(nuts, 'Energy');
                final carb = _nutrient(nuts, 'Carbohydrate, by difference');
                final isSel = _pending == f;

                return GestureDetector(
                  onTap: () => _selectFood(f),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? _accent.withOpacity(0.12) : _surface,
                      border: Border.all(color: isSel ? _accent.withOpacity(0.4) : _border),
                      borderRadius: BorderRadius.circular(7)),
                    child: Row(children: [
                      Expanded(child: Text(
                        f['description'] ?? '',
                        style: GoogleFonts.dmMono(fontSize: 11, color: _txt),
                        maxLines: 2, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Text(
                        '${cal.toStringAsFixed(0)} kcal · ${carb.toStringAsFixed(0)}g C',
                        style: GoogleFonts.dmMono(fontSize: 10, color: _muted)),
                      const SizedBox(width: 6),
                      Icon(Icons.add_circle_outline, size: 14,
                        color: isSel ? _accent : _muted),
                    ]),
                  ),
                );
              },
            ),
          ),
        ],

        // Portion row
        if (_pending != null) ...[
          const SizedBox(height: 10),
          Row(children: [
            Icon(Icons.scale_outlined, size: 14, color: _muted),
            const SizedBox(width: 8),
            Text('Portion:', style: GoogleFonts.dmMono(fontSize: 12, color: _muted)),
            const SizedBox(width: 8),
            SizedBox(width: 80, child: TextField(
              controller: _portionCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.dmMono(fontSize: 13, color: _txt),
              decoration: InputDecoration(
                suffixText: 'g',
                suffixStyle: GoogleFonts.dmMono(fontSize: 12, color: _muted),
                filled: true,
                fillColor: _surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: _border)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: _border)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: _accent)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            )),
            const Spacer(),
            GestureDetector(
              onTap: () => _addFood(meal),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(8)),
                child: Text('Add to ${meal.label} →',
                  style: GoogleFonts.dmMono(
                    fontSize: 11, fontWeight: FontWeight.w700, color: _bg)),
              ),
            ),
          ]),
        ],
      ]),
    );
  }

}

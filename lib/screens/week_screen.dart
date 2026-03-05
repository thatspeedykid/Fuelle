import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/data.dart';

class WeekScreen extends StatefulWidget {
  final FuelleData data;
  final ValueChanged<FuelleData> onChanged;
  const WeekScreen({super.key, required this.data, required this.onChanged});
  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  late FuelleData _data;
  String? _selectedKey;

  @override
  void initState() {
    super.initState();
    _data = widget.data;
    _selectedKey = _todayKey;
  }

  @override
  void didUpdateWidget(WeekScreen old) {
    super.didUpdateWidget(old);
    _data = widget.data;
  }

  String get _todayKey {
    final d = DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }

  String _keyFor(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  String _monthName(int m) =>
    ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];

  Color get _bg       => _data.darkMode ? FuelleColors.bg       : const Color(0xFFf5f5f0);
  Color get _surface  => _data.darkMode ? FuelleColors.surface  : const Color(0xFFffffff);
  Color get _surface2 => _data.darkMode ? FuelleColors.surface2 : const Color(0xFFeeebe3);
  Color get _border   => _data.darkMode ? FuelleColors.border   : const Color(0xFFd8d5cc);
  Color get _accent   => _data.darkMode ? FuelleColors.accent   : const Color(0xFF5a8a00);
  Color get _muted    => _data.darkMode ? FuelleColors.muted    : const Color(0xFF7a7b75);
  Color get _txt      => _data.darkMode ? FuelleColors.text     : const Color(0xFF1a1a17);

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday % 7)); // Sunday start
    final weekDays = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('This Week', style: GoogleFonts.playfairDisplay(
          fontSize: 22, color: _txt, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),

        // Week strip
        Row(children: weekDays.asMap().entries.map((e) {
          final d   = e.value;
          final key = _keyFor(d);
          final log = _data.log[key];
          final hasData = log != null && log.totalCal > 0;
          final isToday = key == _todayKey;
          final isSel   = key == _selectedKey;

          return Expanded(child: GestureDetector(
            onTap: () => setState(() => _selectedKey = key),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSel ? _accent : isToday ? _accent.withValues(alpha: 0.08) : _surface2,
                border: Border.all(
                  color: isSel ? _accent : isToday ? _accent.withValues(alpha: 0.4) : Colors.transparent),
                borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                Text(dayNames[e.key],
                  style: GoogleFonts.dmMono(
                    fontSize: 9, letterSpacing: 1,
                    color: isSel ? _bg : _muted)),
                const SizedBox(height: 4),
                Text('${d.day}',
                  style: GoogleFonts.dmMono(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: isSel ? _bg : _txt)),
                const SizedBox(height: 4),
                Container(
                  width: 4, height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasData ? (isSel ? _bg : _accent) : Colors.transparent)),
              ]),
            ),
          ));
        }).toList()),

        const SizedBox(height: 16),

        // Selected day detail
        if (_selectedKey != null) _dayDetail(_selectedKey!),
      ]),
    );
  }

  Widget _dayDetail(String key) {
    final log   = _data.log[key];
    final d     = DateTime.parse(key);
    final label = '${_monthName(d.month)} ${d.day}, ${d.year}';
    final isToday = key == _todayKey;

    if (log == null || log.totalCal == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _surface,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Text(label, style: GoogleFonts.dmMono(
            fontSize: 11, color: _muted, letterSpacing: 1)),
          const SizedBox(height: 12),
          Text(isToday ? 'No meals logged today yet' : 'No meals logged',
            style: GoogleFonts.dmMono(fontSize: 13, color: _muted)),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: GoogleFonts.dmMono(
            fontSize: 11, color: _muted, letterSpacing: 1)),
          const Spacer(),
          if (isToday) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              border: Border.all(color: _accent.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(20)),
            child: Text('TODAY', style: GoogleFonts.dmMono(
              fontSize: 9, color: _accent, letterSpacing: 1.5))),
        ]),
        const SizedBox(height: 8),
        Text('${log.totalCal.toStringAsFixed(0)} kcal',
          style: GoogleFonts.playfairDisplay(fontSize: 28, color: _accent)),
        Text('${log.totalCarb.toStringAsFixed(0)}g carbs  ·  ${log.totalProt.toStringAsFixed(0)}g protein  ·  ${log.totalFat.toStringAsFixed(0)}g fat',
          style: GoogleFonts.dmMono(fontSize: 11, color: _muted)),
        const SizedBox(height: 14),

        for (final meal in MealType.values)
          if ((log.meals[meal] ?? []).isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 4, top: 4),
              child: Text('${meal.icon}  ${meal.label.toUpperCase()}',
                style: GoogleFonts.dmMono(
                  fontSize: 10, color: _muted, letterSpacing: 1.5,
                  fontWeight: FontWeight.w600)),
            ),
            for (final f in log.meals[meal]!)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(children: [
                  Expanded(child: Text(f.name,
                    style: GoogleFonts.dmMono(fontSize: 12, color: _txt))),
                  Text('${f.cal.toStringAsFixed(0)} kcal',
                    style: GoogleFonts.dmMono(fontSize: 11, color: _accent)),
                ]),
              ),
          ],
      ]),
    );
  }
}

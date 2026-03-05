import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/data.dart';

class HistoryScreen extends StatefulWidget {
  final FuelleData data;
  final ValueChanged<FuelleData> onChanged;
  const HistoryScreen({super.key, required this.data, required this.onChanged});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late FuelleData _data;

  @override
  void initState() { super.initState(); _data = widget.data; }
  @override
  void didUpdateWidget(HistoryScreen old) { super.didUpdateWidget(old); _data = widget.data; }

  String _monthName(int m) =>
    ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];
  String _weekday(int w) =>
    ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][w-1];

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
    final keys = _data.log.keys
        .where((k) => _data.log[k]!.totalCal > 0)
        .toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('History', style: GoogleFonts.playfairDisplay(
          fontSize: 22, color: _txt, fontWeight: FontWeight.w700)),

        if (keys.isEmpty) ...[
          const SizedBox(height: 40),
          Center(child: Column(children: [
            Text('🍽️', style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text('No history yet', style: GoogleFonts.dmMono(color: _muted, fontSize: 14)),
            const SizedBox(height: 4),
            Text('Start logging meals in Today',
              style: GoogleFonts.dmMono(color: _muted, fontSize: 11)),
          ])),
        ] else ...[
          const SizedBox(height: 8),
          // Weekly average banner
          if (keys.length >= 3) _weeklyBanner(keys),
          const SizedBox(height: 12),
          for (final key in keys.take(60)) _dayCard(key),
        ],
      ]),
    );
  }

  Widget _weeklyBanner(List<String> keys) {
    final recent = keys.take(7).toList();
    final logs = recent.map((k) => _data.log[k]!).toList();
    final avgCal  = logs.fold(0.0, (s, l) => s + l.totalCal) / logs.length;
    final avgCarb = logs.fold(0.0, (s, l) => s + l.totalCarb) / logs.length;
    final avgProt = logs.fold(0.0, (s, l) => s + l.totalProt) / logs.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accent.withValues(alpha: 0.06),
        border: Border.all(color: _accent.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${recent.length}-DAY AVERAGE',
          style: GoogleFonts.dmMono(fontSize: 10, color: _accent, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Row(children: [
          _avgChip('${avgCal.toStringAsFixed(0)} kcal', _accent),
          const SizedBox(width: 8),
          _avgChip('${avgCarb.toStringAsFixed(0)}g carbs', _teal),
          const SizedBox(width: 8),
          _avgChip('${avgProt.toStringAsFixed(0)}g protein', _orange),
        ]),
      ]),
    );
  }

  Widget _avgChip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      border: Border.all(color: color.withValues(alpha: 0.3)),
      borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: GoogleFonts.dmMono(fontSize: 11, color: color)),
  );

  Widget _dayCard(String key) {
    final log = _data.log[key]!;
    final d   = DateTime.parse(key);
    final label = '${_weekday(d.weekday)}, ${_monthName(d.month)} ${d.day}';
    final calPct = (log.totalCal / _data.goals.cal).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: GoogleFonts.dmMono(
            fontSize: 11, color: _muted, letterSpacing: 0.5)),
          const Spacer(),
          Text('${log.totalCal.toStringAsFixed(0)} kcal',
            style: GoogleFonts.playfairDisplay(fontSize: 18, color: _accent)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: calPct,
            minHeight: 3,
            backgroundColor: _border,
            valueColor: AlwaysStoppedAnimation(
              calPct > 1.05 ? FuelleColors.danger : _accent),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${log.totalCarb.toStringAsFixed(0)}g carbs  ·  '
          '${log.totalProt.toStringAsFixed(0)}g protein  ·  '
          '${log.totalFat.toStringAsFixed(0)}g fat',
          style: GoogleFonts.dmMono(fontSize: 10, color: _muted)),
      ]),
    );
  }
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'models/data.dart';
import 'screens/today_screen.dart';
import 'screens/week_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isMacOS) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
  }
  final data = await FuelleStorage.load();
  runApp(FuelleApp(initialData: data));
}

class FuelleApp extends StatefulWidget {
  final FuelleData initialData;
  const FuelleApp({super.key, required this.initialData});
  @override
  State<FuelleApp> createState() => _FuelleAppState();
}

class _FuelleAppState extends State<FuelleApp> {
  late FuelleData _data;
  int _tab = 0;

  @override
  void initState() { super.initState(); _data = widget.initialData; }

  void _update(FuelleData d) {
    setState(() => _data = d);
    FuelleStorage.save(d);
  }

  @override
  Widget build(BuildContext context) {
    final dark = _data.darkMode;
    return MaterialApp(
      title: 'Fuelle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: dark
            ? ColorScheme.dark(surface: FuelleColors.surface, primary: FuelleColors.accent)
            : ColorScheme.light(surface: const Color(0xFFffffff), primary: const Color(0xFF5a8a00)),
        scaffoldBackgroundColor: dark ? FuelleColors.bg : const Color(0xFFf5f5f0),
        textTheme: GoogleFonts.dmMonoTextTheme().apply(
          bodyColor:    dark ? FuelleColors.text : const Color(0xFF1a1a17),
          displayColor: dark ? FuelleColors.text : const Color(0xFF1a1a17),
        ),
        useMaterial3: true,
      ),
      builder: (ctx, child) {
        final scale = (_data.fontSize > 0 ? _data.fontSize : 15.0) / 15.0;
        return MediaQuery(
          data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!);
      },
      home: _FuelleShell(
        data: _data,
        tab: _tab,
        onTabChange: (t) => setState(() => _tab = t),
        onDataChanged: _update,
      ),
    );
  }
}

class _FuelleShell extends StatefulWidget {
  final FuelleData data;
  final int tab;
  final ValueChanged<int> onTabChange;
  final ValueChanged<FuelleData> onDataChanged;
  const _FuelleShell({required this.data, required this.tab,
    required this.onTabChange, required this.onDataChanged});
  @override
  State<_FuelleShell> createState() => _FuelleShellState();
}

class _FuelleShellState extends State<_FuelleShell> {
  late FuelleData _cur;

  @override
  void initState() { super.initState(); _cur = widget.data; }
  @override
  void didUpdateWidget(_FuelleShell old) { super.didUpdateWidget(old); _cur = widget.data; }

  void _save(FuelleData d) {
    setState(() => _cur = d);
    widget.onDataChanged(d);
  }

  void _openUrl(String url) {
    try {
      if (Platform.isWindows) Process.run('cmd', ['/c', 'start', '', url]);
      else if (Platform.isMacOS) Process.run('open', [url]);
      else Process.run('xdg-open', [url]);
    } catch (_) {}
  }

  static const _tabIcons = [
    Icons.restaurant_outlined,
    Icons.calendar_view_week_outlined,
    Icons.bar_chart_outlined,
  ];
  static const _tabLabels = ['Today', 'Week', 'History'];

  Color get _bg       => _cur.darkMode ? FuelleColors.bg       : const Color(0xFFf5f5f0);
  Color get _surface2 => _cur.darkMode ? FuelleColors.surface2 : const Color(0xFFeeebe3);
  Color get _border   => _cur.darkMode ? FuelleColors.border   : const Color(0xFFd8d5cc);
  Color get _accent   => _cur.darkMode ? FuelleColors.accent   : const Color(0xFF5a8a00);
  Color get _muted    => _cur.darkMode ? FuelleColors.muted    : const Color(0xFF7a7b75);
  Color get _txt      => _cur.darkMode ? FuelleColors.text     : const Color(0xFF1a1a17);

  @override
  Widget build(BuildContext context) {
    final screens = [
      TodayScreen(data: _cur, onChanged: _save),
      WeekScreen(data: _cur,  onChanged: _save),
      HistoryScreen(data: _cur, onChanged: _save),
    ];

    final width    = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final topPad   = (Platform.isIOS || Platform.isAndroid)
        ? MediaQuery.of(context).padding.top + 8
        : 10.0;

    // ── Tablet / Desktop sidebar layout ───────────────────────────────────
    if (isTablet) {
      return Scaffold(
        backgroundColor: _bg,
        body: Row(children: [
          Container(
            width: 200,
            color: _surface2,
            child: Column(children: [
              SizedBox(height: topPad),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      border: Border.all(color: _accent, width: 2),
                      borderRadius: BorderRadius.circular(9)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.asset(
                        _cur.darkMode ? 'assets/icon_dark.png' : 'assets/icon.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.restaurant, color: _accent, size: 22)))),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('fuelle', style: GoogleFonts.playfairDisplay(
                      fontSize: 20, color: _accent, fontWeight: FontWeight.w700, height: 1.1)),
                    Text('BY PRIVACYCHASE', style: GoogleFonts.dmMono(
                      fontSize: 7, color: _muted, letterSpacing: 1.5)),
                  ]),
                ]),
              ),
              Divider(color: _border, height: 1),
              const SizedBox(height: 8),
              ...List.generate(_tabLabels.length, (i) {
                final sel = i == widget.tab;
                return GestureDetector(
                  onTap: () => widget.onTabChange(i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? _accent.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: sel ? _accent.withOpacity(0.4) : Colors.transparent)),
                    child: Row(children: [
                      Icon(_tabIcons[i], size: 16, color: sel ? _accent : _muted),
                      const SizedBox(width: 10),
                      Text(_tabLabels[i], style: GoogleFonts.dmMono(
                        fontSize: 12, letterSpacing: 0.5,
                        color: sel ? _accent : _muted,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                    ]),
                  ),
                );
              }),
              const Spacer(),
              Padding(
                padding: EdgeInsets.fromLTRB(8, 0, 8, MediaQuery.of(context).padding.bottom + 12),
                child: Column(children: [
                  if (!Platform.isIOS && !Platform.isAndroid) ...[
                    GestureDetector(
                      onTap: () => _openUrl('https://www.paypal.me/Speeddevilx'),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _cur.darkMode ? const Color(0xFF1a2a0a) : const Color(0xFFe8f5c8),
                          border: Border.all(color: _accent.withOpacity(0.35)),
                          borderRadius: BorderRadius.circular(8)),
                        child: Row(children: [
                          const Text('☕', style: TextStyle(fontSize: 13)),
                          const SizedBox(width: 8),
                          Text('Buy me a coffee',
                            style: GoogleFonts.dmMono(color: _accent, fontSize: 11)),
                        ]),
                      )),
                    const SizedBox(height: 8),
                  ],
                  GestureDetector(
                    onTap: () => _showSettings(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        Icon(Icons.settings_outlined, color: _muted, size: 16),
                        const SizedBox(width: 10),
                        Text('Settings', style: GoogleFonts.dmMono(color: _muted, fontSize: 12)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
          Container(width: 1, color: _border),
          Expanded(child: screens[widget.tab]),
        ]),
      );
    }

    // ── Phone layout ──────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        Container(
          color: _surface2,
          child: Column(children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, topPad, 16, 0),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: _accent, width: 2),
                    borderRadius: BorderRadius.circular(8)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      _cur.darkMode ? 'assets/icon_dark.png' : 'assets/icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.restaurant, color: _accent, size: 20)))),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('fuelle', style: GoogleFonts.playfairDisplay(
                    fontSize: 22, color: _accent, fontWeight: FontWeight.w700, height: 1.1)),
                  Text('BY PRIVACYCHASE', style: GoogleFonts.dmMono(
                    fontSize: 8, color: _muted, letterSpacing: 2)),
                ]),
                const Spacer(),
                if (!Platform.isIOS && !Platform.isAndroid)
                  IconButton(
                    icon: Icon(Icons.settings_outlined, color: _muted, size: 20),
                    onPressed: () => _showSettings(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints()),
              ]),
            ),
            const SizedBox(height: 8),
            Row(children: List.generate(_tabLabels.length, (i) {
              final sel = i == widget.tab;
              return Expanded(child: GestureDetector(
                onTap: () => widget.onTabChange(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(border: Border(bottom: BorderSide(
                    color: sel ? _accent : Colors.transparent, width: 2))),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_tabIcons[i], size: 16, color: sel ? _accent : _muted),
                    const SizedBox(height: 3),
                    Text(_tabLabels[i], style: GoogleFonts.dmMono(
                      fontSize: 9, letterSpacing: 1.2,
                      color: sel ? _accent : _muted,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400)),
                  ]),
                ),
              ));
            })),
            Divider(height: 1, color: _border),
          ]),
        ),
        Expanded(child: screens[widget.tab]),
        Container(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 6,
            bottom: (Platform.isIOS || Platform.isAndroid)
                ? MediaQuery.of(context).padding.bottom + 6 : 6),
          decoration: BoxDecoration(
            color: _surface2,
            border: Border(top: BorderSide(color: _border))),
          child: Row(children: [
            const Spacer(),
            if (Platform.isIOS || Platform.isAndroid)
              GestureDetector(
                onTap: () => _showSettings(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.settings_outlined, color: _muted, size: 14),
                    const SizedBox(width: 6),
                    Text('Settings', style: GoogleFonts.dmMono(color: _muted, fontSize: 11)),
                  ]),
                ))
            else
              GestureDetector(
                onTap: () => _openUrl('https://www.paypal.me/Speeddevilx'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _cur.darkMode ? const Color(0xFF1a2a0a) : const Color(0xFFe8f5c8),
                    border: Border.all(color: _accent.withOpacity(0.35)),
                    borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('☕', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 5),
                    Text('Buy me a coffee',
                      style: GoogleFonts.dmMono(color: _accent, fontSize: 10)),
                  ]),
                )),
          ]),
        ),
      ]),
    );
  }

  // ── Settings Sheet ────────────────────────────────────────────────────────
  void _showSettings(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: _cur.darkMode ? const Color(0xFF1a1a1a) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Text('SETTINGS',
            style: GoogleFonts.dmMono(color: _muted, fontSize: 11, letterSpacing: 2))),
          const SizedBox(height: 8),

          // Theme toggle
          ListTile(
            leading: Icon(_cur.darkMode ? Icons.light_mode : Icons.dark_mode, color: _accent),
            title: Text(_cur.darkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              style: GoogleFonts.dmMono(color: _txt, fontSize: 14)),
            onTap: () {
              Navigator.pop(ctx);
              _save(_cur.copyWith(darkMode: !_cur.darkMode));
            }),
          Divider(color: _border),

          // Font size
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              Icon(Icons.format_size, color: _muted, size: 18),
              const SizedBox(width: 10),
              Text('Text Size', style: GoogleFonts.dmMono(color: _txt, fontSize: 14)),
              const Spacer(),
              for (final entry in [('A', 13.0), ('A', 15.0), ('A', 18.0)])
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _save(_cur.copyWith(fontSize: entry.$2));
                    },
                    child: Container(
                      width: 40, height: 36,
                      decoration: BoxDecoration(
                        color: _cur.fontSize == entry.$2 ? _accent.withOpacity(0.15) : Colors.transparent,
                        border: Border.all(color: _cur.fontSize == entry.$2 ? _accent : _border),
                        borderRadius: BorderRadius.circular(6)),
                      alignment: Alignment.center,
                      child: Text(entry.$1, style: TextStyle(
                        fontSize: entry.$2, fontWeight: FontWeight.bold,
                        color: _cur.fontSize == entry.$2 ? _accent : _muted)),
                    ),
                  ),
                ),
            ]),
          ),
          Divider(color: _border),

          // Goals
          ListTile(
            leading: Icon(Icons.track_changes, color: _muted),
            title: Text('Nutrition Goals',
              style: GoogleFonts.dmMono(color: _txt, fontSize: 14)),
            subtitle: Text('Set your daily calorie & macro targets',
              style: GoogleFonts.dmMono(color: _muted, fontSize: 10)),
            onTap: () { Navigator.pop(ctx); _showGoalsDialog(ctx); }),
          Divider(color: _border),

          // Export backup
          ListTile(
            leading: Icon(Icons.copy, color: _muted),
            title: Text('Copy Backup',
              style: GoogleFonts.dmMono(color: _txt, fontSize: 14)),
            subtitle: Text('Copies a single line — paste anywhere to save',
              style: GoogleFonts.dmMono(color: _muted, fontSize: 10)),
            onTap: () {
              Navigator.pop(ctx);
              try {
                final code = FuelleStorage.exportCode(_cur);
                Clipboard.setData(ClipboardData(text: code));
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Backup copied! Paste it in Notes, email, anywhere safe.',
                    style: GoogleFonts.dmMono(color: const Color(0xFF0f0f0f))),
                  backgroundColor: _accent, duration: const Duration(seconds: 4)));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Backup failed: $e')));
              }
            }),

          // Import backup
          ListTile(
            leading: Icon(Icons.restore, color: _muted),
            title: Text('Paste & Restore',
              style: GoogleFonts.dmMono(color: _txt, fontSize: 14)),
            subtitle: Text('Paste your Fuelle backup code to restore data',
              style: GoogleFonts.dmMono(color: _muted, fontSize: 10)),
            onTap: () {
              Navigator.pop(ctx);
              final ctrl = TextEditingController();
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  backgroundColor: _cur.darkMode ? const Color(0xFF1a1a1a) : Colors.white,
                  title: Text('Paste Backup', style: GoogleFonts.dmMono(color: _txt)),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text('Paste your FUELLE1:... backup code below:',
                      style: GoogleFonts.dmMono(color: _muted, fontSize: 12)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ctrl, maxLines: 4,
                      style: GoogleFonts.dmMono(fontSize: 11, color: _txt),
                      decoration: InputDecoration(
                        hintText: 'FUELLE1:...',
                        hintStyle: GoogleFonts.dmMono(color: _muted, fontSize: 11),
                        border: OutlineInputBorder(borderSide: BorderSide(color: _border)),
                        filled: true,
                        fillColor: _cur.darkMode ? const Color(0xFF222222) : const Color(0xFFf5f5f0))),
                  ]),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: Text('Cancel', style: GoogleFonts.dmMono(color: _muted))),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(c);
                        try {
                          final imported = FuelleStorage.importCode(ctrl.text.trim());
                          _save(imported);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Restored successfully!',
                              style: GoogleFonts.dmMono(color: const Color(0xFF0f0f0f))),
                            backgroundColor: _accent));
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Restore failed: $e'),
                              duration: const Duration(seconds: 6)));
                        }
                      },
                      child: Text('Restore', style: GoogleFonts.dmMono(color: _accent))),
                  ],
                ),
              );
            }),
          Divider(color: _border),

          // GitHub (desktop only)
          if (!Platform.isIOS && !Platform.isAndroid) ...[
            ListTile(
              leading: Icon(Icons.code, color: _muted),
              title: Text('GitHub', style: GoogleFonts.dmMono(color: _txt, fontSize: 14)),
              subtitle: Text('github.com/privacychase/fuelle',
                style: GoogleFonts.dmMono(color: _muted, fontSize: 10)),
              onTap: () { Navigator.pop(ctx); _openUrl('https://github.com/privacychase/fuelle'); }),
            Divider(color: _border),
          ],

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Fuelle v0.5.0 alpha', style: GoogleFonts.dmMono(color: _muted, fontSize: 12)),
              const SizedBox(height: 2),
              Text('Windows · Linux · Android · iOS · macOS',
                style: GoogleFonts.dmMono(color: _muted, fontSize: 10)),
              const SizedBox(height: 2),
              Text('by PrivacyChase — No accounts. No tracking. No ads.',
                style: GoogleFonts.dmMono(color: _muted, fontSize: 10)),
            ])),
        ]),
      ),
    );
  }

  void _showGoalsDialog(BuildContext ctx) {
    final calCtrl  = TextEditingController(text: _cur.goals.cal.toStringAsFixed(0));
    final carbCtrl = TextEditingController(text: _cur.goals.carb.toStringAsFixed(0));
    final protCtrl = TextEditingController(text: _cur.goals.prot.toStringAsFixed(0));
    final fatCtrl  = TextEditingController(text: _cur.goals.fat.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: _cur.darkMode ? const Color(0xFF1a1a1a) : Colors.white,
        title: Text('Daily Goals', style: GoogleFonts.dmMono(color: _txt)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _goalField('Calories (kcal)', calCtrl),
          const SizedBox(height: 10),
          _goalField('Carbs (g)', carbCtrl),
          const SizedBox(height: 10),
          _goalField('Protein (g)', protCtrl),
          const SizedBox(height: 10),
          _goalField('Fat (g)', fatCtrl),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text('Cancel', style: GoogleFonts.dmMono(color: _muted))),
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              _save(_cur.copyWith(goals: NutritionGoals(
                cal:  double.tryParse(calCtrl.text)  ?? _cur.goals.cal,
                carb: double.tryParse(carbCtrl.text) ?? _cur.goals.carb,
                prot: double.tryParse(protCtrl.text) ?? _cur.goals.prot,
                fat:  double.tryParse(fatCtrl.text)  ?? _cur.goals.fat,
              )));
            },
            child: Text('Save', style: GoogleFonts.dmMono(color: _accent))),
        ],
      ),
    );
  }

  Widget _goalField(String label, TextEditingController ctrl) => TextField(
    controller: ctrl,
    keyboardType: TextInputType.number,
    style: GoogleFonts.dmMono(fontSize: 13, color: _txt),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.dmMono(color: _muted, fontSize: 12),
      border: OutlineInputBorder(borderSide: BorderSide(color: _border)),
      filled: true,
      fillColor: _cur.darkMode ? const Color(0xFF222222) : const Color(0xFFf5f5f0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
  );
}

// ── copyWith extension ────────────────────────────────────────────────────────
extension FuelleDataCopyWith on FuelleData {
  FuelleData copyWith({
    Map<String, DayLog>? log,
    NutritionGoals? goals,
    bool? darkMode,
    double? fontSize,
  }) => FuelleData(
    log:      log      ?? this.log,
    goals:    goals    ?? this.goals,
    darkMode: darkMode ?? this.darkMode,
    fontSize: fontSize ?? this.fontSize,
  );
}

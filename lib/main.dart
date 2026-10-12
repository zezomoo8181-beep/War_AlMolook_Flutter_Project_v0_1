import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

void main() => runApp(const WarAlMolookApp());

class WarAlMolookApp extends StatelessWidget {
  const WarAlMolookApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'حرب الملوك',
    debugShowCheckedModeBanner: false,
    theme: buildGameTheme(),
    home: const GameHomePage(),
  );
}

class ResourceState {
  int wood = 420;
  int stone = 360;
  int iron = 240;
  int food = 520;
  int gold = 85;
  int keepLevel = 1;
  int barracksLevel = 1;
  int farmLevel = 1;
  int lumberLevel = 1;
  int stoneLevel = 1;
  int troops = 12;
  int trainingTarget = 0;
  int trainingFinish = 0;
  int selectedTab = 0;

  int get population => 24 + farmLevel * 8;
  bool get isTraining => trainingTarget > 0 && trainingFinish > DateTime.now().millisecondsSinceEpoch;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    wood = p.getInt('wood') ?? wood;
    stone = p.getInt('stone') ?? stone;
    iron = p.getInt('iron') ?? iron;
    food = p.getInt('food') ?? food;
    gold = p.getInt('gold') ?? gold;
    keepLevel = p.getInt('keepLevel') ?? keepLevel;
    barracksLevel = p.getInt('barracksLevel') ?? barracksLevel;
    farmLevel = p.getInt('farmLevel') ?? farmLevel;
    lumberLevel = p.getInt('lumberLevel') ?? lumberLevel;
    stoneLevel = p.getInt('stoneLevel') ?? stoneLevel;
    troops = p.getInt('troops') ?? troops;
    trainingTarget = p.getInt('trainingTarget') ?? trainingTarget;
    trainingFinish = p.getInt('trainingFinish') ?? trainingFinish;
    final last = p.getInt('lastTick') ?? DateTime.now().millisecondsSinceEpoch;
    final elapsed = ((DateTime.now().millisecondsSinceEpoch - last) / 60000).floor().clamp(0, 720).toInt();
    wood += elapsed * (2 + lumberLevel);
    stone += elapsed * (1 + stoneLevel);
    food += elapsed * (2 + farmLevel);
    iron += elapsed;
    await save();
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('wood', wood); await p.setInt('stone', stone);
    await p.setInt('iron', iron); await p.setInt('food', food); await p.setInt('gold', gold);
    await p.setInt('keepLevel', keepLevel); await p.setInt('barracksLevel', barracksLevel);
    await p.setInt('farmLevel', farmLevel); await p.setInt('lumberLevel', lumberLevel);
    await p.setInt('stoneLevel', stoneLevel); await p.setInt('troops', troops);
    await p.setInt('trainingTarget', trainingTarget); await p.setInt('trainingFinish', trainingFinish);
    await p.setInt('lastTick', DateTime.now().millisecondsSinceEpoch);
  }
}

class GameHomePage extends StatefulWidget {
  const GameHomePage({super.key});
  @override
  State<GameHomePage> createState() => _GameHomePageState();
}

class _GameHomePageState extends State<GameHomePage> {
  final ResourceState game = ResourceState();
  Timer? timer;
  bool ready = false;
  int seconds = 0;
  @override
  void initState() {
    super.initState();
    _init();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }
  Future<void> _init() async { await game.load(); if (mounted) setState(() => ready = true); }
  void _tick() {
    if (!ready) return;
    seconds++;
    if (seconds % 10 == 0) {
      game.wood += 1 + game.lumberLevel;
      game.stone += 1 + game.stoneLevel;
      game.food += 2 + game.farmLevel;
      game.iron += 1;
      game.save();
    }
    if (game.trainingTarget > 0 && game.trainingFinish <= DateTime.now().millisecondsSinceEpoch) {
      game.troops += game.trainingTarget;
      game.trainingTarget = 0;
      game.trainingFinish = 0;
      game.save();
      if (mounted) _toast('اكتمل تدريب الجنود وأصبحوا جاهزين!');
    }
    if (mounted) setState(() {});
  }
  @override
  void dispose() { timer?.cancel(); super.dispose(); }
  void _toast(String message) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, textDirection: TextDirection.rtl))); }
  void _selectTab(int index) => setState(() => game.selectedTab = index);

  @override
  Widget build(BuildContext context) {
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      body: SafeArea(child: !ready ? const Center(child: CircularProgressIndicator()) : Column(children: [
        _topBar(), _resourceBar(), Expanded(child: IndexedStack(index: game.selectedTab, children: [
          _villagePage(), _mapPage(), _armyPage(), _missionsPage(),
        ])),
      ])),
      bottomNavigationBar: _bottomBar(),
    ));
  }

  Widget _topBar() => Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 8), child: Row(children: [
    Container(width: 44, height: 44, decoration: BoxDecoration(gradient: const LinearGradient(colors: [GameColors.gold, GameColors.goldDark]), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.castle, color: Color(0xFF17201D), size: 27)),
    const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('حرب الملوك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: GameColors.text)), Text('مملكة الوادي • المستوى ${game.keepLevel}', style: const TextStyle(fontSize: 11, color: GameColors.muted))])),
    IconButton(tooltip: 'الإعدادات', onPressed: _settingsDialog, icon: const Icon(Icons.settings_outlined, color: GameColors.muted)),
    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: GameColors.panel, borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.shield, color: GameColors.gold, size: 18), const SizedBox(width: 5), Text('${game.troops}', style: const TextStyle(fontWeight: FontWeight.bold))])),
  ]));

  Widget _resourceBar() => Container(margin: const EdgeInsets.symmetric(horizontal: 12), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10), decoration: BoxDecoration(color: GameColors.panel, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(.04))), child: Row(children: [
    _resource(Icons.forest, game.wood, const Color(0xFF83C47A)), _resource(Icons.terrain, game.stone, const Color(0xFFB9C4C6)),
    _resource(Icons.hardware, game.iron, const Color(0xFF8AB8D5)), _resource(Icons.grass, game.food, const Color(0xFFE4C66C)), _resource(Icons.diamond, game.gold, GameColors.gold),
  ]));
  Widget _resource(IconData icon, int value, Color color) => Expanded(child: Column(children: [Icon(icon, size: 17, color: color), const SizedBox(height: 3), FittedBox(fit: BoxFit.scaleDown, child: Text(_number(value), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: GameColors.text)))]));
  String _number(int n) { if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}م'; if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}ك'; return '$n'; }

  Widget _villagePage() => ListView(padding: const EdgeInsets.fromLTRB(14, 14, 14, 18), children: [
    _welcomeBanner(), const SizedBox(height: 14), _sectionTitle('قريتك', 'طوّر مملكتك خطوة بخطوة'), const SizedBox(height: 10),
    ClipRRect(borderRadius: BorderRadius.circular(20), child: Container(height: 214, decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF456E52), Color(0xFF223F36)])), child: CustomPaint(painter: VillagePainter(keepLevel: game.keepLevel), child: Stack(children: [Positioned(top: 12, right: 12, child: _glassLabel('المقر الملكي', Icons.castle)), Positioned(bottom: 12, left: 12, child: _glassLabel('قرية آمنة', Icons.verified_user))])))),
    const SizedBox(height: 16), _sectionTitle('المباني', 'اضغط على ترقية لتطوير الإنتاج'), const SizedBox(height: 10),
    _buildingCard('المقر الملكي', 'قلب المملكة ومركز توسعها', Icons.castle, game.keepLevel, const Color(0xFFE5B85A), 'keep'),
    _buildingCard('منشرة الأخشاب', 'إنتاج الخشب مع مرور الوقت', Icons.forest, game.lumberLevel, const Color(0xFF7FC37B), 'lumber'),
    _buildingCard('محجر الحجارة', 'يوفر الحجارة لتشييد المباني', Icons.terrain, game.stoneLevel, const Color(0xFFB5C6CA), 'stone'),
    _buildingCard('المزرعة', 'غذاء أكثر وسعة سكانية أعلى', Icons.grass, game.farmLevel, const Color(0xFFE4C66C), 'farm'),
    _buildingCard('الثكنات', 'تدريب جنود للدفاع عن المملكة', Icons.shield, game.barracksLevel, const Color(0xFFD98B75), 'barracks'),
  ]);

  Widget _welcomeBanner() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(colors: [Color(0xFF3C5C43), Color(0xFF263B32)]),
      border: Border.all(color: GameColors.gold.withOpacity(.22)),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('أيها القائد، مرحبًا بعودتك!', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        const SizedBox(height: 5),
        const Text('اجمع الموارد، قوِّ جيشك، واستعد للمعارك القادمة.', style: TextStyle(fontSize: 12, color: GameColors.muted, height: 1.5)),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.bolt, color: GameColors.gold, size: 17),
          const SizedBox(width: 5),
          const Text('إنتاج الموارد يعمل تلقائيًا', style: TextStyle(color: GameColors.gold, fontSize: 11, fontWeight: FontWeight.bold)),
        ]),
      ])),
      const SizedBox(width: 8),
      const Icon(Icons.military_tech, color: GameColors.gold, size: 54),
    ]),
  );
  Widget _sectionTitle(String title, String subtitle) => Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: GameColors.muted, fontSize: 11))])), const Icon(Icons.auto_awesome, color: GameColors.gold, size: 20)]);
  Widget _glassLabel(String text, IconData icon) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Colors.black.withOpacity(.42), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withOpacity(.15))), child: Row(children: [Icon(icon, size: 14, color: GameColors.gold), const SizedBox(width: 5), Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))]));

  Widget _buildingCard(String title, String subtitle, IconData icon, int level, Color color, String id) {
    final cost = _cost(id, level);
    final canAfford = game.wood >= cost.$1 && game.stone >= cost.$2 && game.iron >= cost.$3;
    return Card(margin: const EdgeInsets.only(bottom: 9), child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [Container(width: 52, height: 52, decoration: BoxDecoration(color: color.withOpacity(.14), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: color, size: 28)), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: GameColors.muted, fontSize: 10)), const SizedBox(height: 7), Row(children: [Text('المستوى $level', style: const TextStyle(color: GameColors.gold, fontWeight: FontWeight.bold, fontSize: 11)), const SizedBox(width: 8), Text('خشب ${cost.$1} • حجر ${cost.$2} • حديد ${cost.$3}', style: const TextStyle(fontSize: 9, color: GameColors.muted))])])), const SizedBox(width: 6), SizedBox(width: 72, child: FilledButton(onPressed: canAfford ? () => _upgrade(id, cost) : null, style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 10), textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), child: const Text('ترقية')))])));
  }
  (int, int, int) _cost(String id, int level) { final factor = level + 1; final base = id == 'keep' ? 90 : id == 'barracks' ? 70 : 45; return (base * factor, (base * .72 * factor).round(), (base * .42 * factor).round()); }
  Future<void> _upgrade(String id, (int, int, int) cost) async {
    if (game.wood < cost.$1 || game.stone < cost.$2 || game.iron < cost.$3) { _toast('الموارد غير كافية للترقية.'); return; }
    game.wood -= cost.$1; game.stone -= cost.$2; game.iron -= cost.$3;
    switch (id) { case 'keep': game.keepLevel++; break; case 'lumber': game.lumberLevel++; break; case 'stone': game.stoneLevel++; break; case 'farm': game.farmLevel++; break; case 'barracks': game.barracksLevel++; break; }
    await game.save(); if (mounted) setState(() {}); _toast('تم تطوير المبنى بنجاح!');
  }

  Widget _mapPage() => ListView(padding: const EdgeInsets.all(14), children: [
    _sectionTitle('خريطة المملكة', 'استكشف الأراضي المحيطة بقريتك'), const SizedBox(height: 12),
    Container(height: 340, decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: GameColors.gold.withOpacity(.25))), child: ClipRRect(borderRadius: BorderRadius.circular(22), child: CustomPaint(painter: WorldMapPainter(), child: Stack(children: [Positioned(top: 12, right: 12, child: _glassLabel('الوادي الأخضر', Icons.map)), Positioned(bottom: 12, right: 12, child: _glassLabel('قريتك', Icons.castle))])))),
    const SizedBox(height: 14), _infoTile(Icons.explore, 'الأراضي المجاورة', 'المناطق للاستكشاف مرسومة حاليًا محليًا.', GameColors.green), _infoTile(Icons.public, 'اللعب الجماعي', 'سيتم ربط الخريطة بلاعبين حقيقيين عند إعداد الخادم.', GameColors.gold),
  ]);

  Widget _armyPage() => ListView(padding: const EdgeInsets.all(14), children: [
    _sectionTitle('الجيش والثكنات', 'درّب قواتك لتكون مستعدًا'),
    const SizedBox(height: 12),
    Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Color(0xFF493D32), Color(0xFF252D2A)]),
      ),
      child: Row(children: [
        const Icon(Icons.shield, size: 55, color: GameColors.gold),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('قوات المملكة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('${game.troops} جندي جاهز', style: const TextStyle(color: GameColors.muted)),
          const SizedBox(height: 8),
          Text('سعة السكان: ${game.population}', style: const TextStyle(color: GameColors.gold, fontSize: 12)),
        ])),
      ]),
    ),
    const SizedBox(height: 14),
    _infoTile(Icons.sports_martial_arts, 'المشاة', 'قوات أساسية للدفاع عن القرية.', const Color(0xFFD98B75)),
    const SizedBox(height: 12),
    Card(child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('تدريب الجنود', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 6),
        const Text('كل جندي يحتاج 25 طعامًا و10 حديد.', style: TextStyle(color: GameColors.muted, fontSize: 12)),
        const SizedBox(height: 14),
        if (game.isTraining) ...[
          _trainingProgress(),
          const SizedBox(height: 12),
        ] else Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => _train(5), child: const Text('تدريب 5'))),
          const SizedBox(width: 8),
          Expanded(child: FilledButton(onPressed: () => _train(10), child: const Text('تدريب 10'))),
        ]),
        if (game.isTraining) const Text('التدريب جارٍ بالفعل', style: TextStyle(color: GameColors.gold, fontSize: 12)),
      ]),
    )),
  ]);
  Widget _trainingProgress() {
    final total = game.trainingTarget * 5;
    final left = math.max(0, ((game.trainingFinish - DateTime.now().millisecondsSinceEpoch) / 1000).ceil());
    final progress = total == 0 ? 0.0 : (1 - left / total).clamp(0.0, 1.0).toDouble();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Expanded(child: Text('وقت التدريب المتبقي', style: TextStyle(fontSize: 12))),
        Text('${left ~/ 60}:${(left % 60).toString().padLeft(2, '0')}', style: const TextStyle(color: GameColors.gold, fontWeight: FontWeight.bold)),
      ]),
      const SizedBox(height: 8),
      LinearProgressIndicator(value: progress, minHeight: 7, borderRadius: BorderRadius.circular(8)),
    ]);
  }
  void _train(int count) { if (game.isTraining) { _toast('انتظر حتى ينتهي التدريب الحالي.'); return; } final foodCost = count * 25; final ironCost = count * 10; if (game.food < foodCost || game.iron < ironCost) { _toast('تحتاج إلى طعام وحديد أكثر لتدريب الجنود.'); return; } game.food -= foodCost; game.iron -= ironCost; game.trainingTarget = count; game.trainingFinish = DateTime.now().millisecondsSinceEpoch + count * 5000; game.save(); setState(() {}); _toast('بدأ تدريب $count جنود.'); }

  Widget _missionsPage() => ListView(padding: const EdgeInsets.all(14), children: [
    _sectionTitle('المهام اليومية', 'طوّر المملكة واجمع المكافآت'), const SizedBox(height: 12),
    _mission('اجمع الموارد', 'مواردك تزيد تلقائيًا مع الوقت.', Icons.inventory_2, true, 'مستمر'),
    _mission('طوّر المقر الملكي', 'ارفع مستوى المقر لتقوية قريتك.', Icons.castle, game.keepLevel > 1, 'مكافأة 25 ذهب'),
    _mission('كوّن جيشًا', 'درّب 5 جنود على الأقل.', Icons.shield, game.troops >= 17, 'مكافأة 40 طعام'),
    _mission('طوّر المزرعة', 'ارفع مستوى إنتاج الطعام.', Icons.grass, game.farmLevel > 1, 'مكافأة 30 خشب'),
    const SizedBox(height: 10), _infoTile(Icons.tips_and_updates, 'نصيحة القائد', 'وازن بين إنتاج الموارد وتطوير الثكنات حتى لا تتوقف توسعاتك.', GameColors.gold),
  ]);
  Widget _mission(String title, String desc, IconData icon, bool done, String reward) => Card(margin: const EdgeInsets.only(bottom: 9), child: Padding(padding: const EdgeInsets.all(13), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: (done ? GameColors.green : GameColors.gold).withOpacity(.14), borderRadius: BorderRadius.circular(13)), child: Icon(done ? Icons.check_circle : icon, color: done ? GameColors.green : GameColors.gold)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), const SizedBox(height: 3), Text(desc, style: const TextStyle(color: GameColors.muted, fontSize: 11)), const SizedBox(height: 5), Text(reward, style: const TextStyle(color: GameColors.gold, fontSize: 10))])), if (done) const Icon(Icons.verified, color: GameColors.green)])));
  Widget _infoTile(IconData icon, String title, String desc, Color color) => Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: GameColors.panel, borderRadius: BorderRadius.circular(16)), child: Row(children: [Icon(icon, color: color, size: 27), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 4), Text(desc, style: const TextStyle(color: GameColors.muted, fontSize: 11, height: 1.4))]))]));

  Widget _bottomBar() => NavigationBar(backgroundColor: GameColors.panel, indicatorColor: GameColors.gold.withOpacity(.17), selectedIndex: game.selectedTab, onDestinationSelected: _selectTab, destinations: const [NavigationDestination(icon: Icon(Icons.holiday_village_outlined), selectedIcon: Icon(Icons.holiday_village), label: 'القرية'), NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'الخريطة'), NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield), label: 'الجيش'), NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'المهام')]);
  void _settingsDialog() { showDialog<void>(context: context, builder: (ctx) => Directionality(textDirection: TextDirection.rtl, child: AlertDialog(title: const Text('إعدادات اللعبة'), content: const Text('هذه نسخة محلية تجريبية. يتم حفظ الموارد ومستويات المباني على هذا الجهاز. اللعب الجماعي يحتاج إلى خادم وحسابات في مرحلة لاحقة.'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('تمام')), TextButton(onPressed: () async { final p = await SharedPreferences.getInstance(); await p.clear(); if (!mounted) return; Navigator.pop(ctx); await game.load(); setState(() {}); _toast('تمت إعادة ضبط القرية.'); }, child: const Text('إعادة ضبط القرية'))]))); }
}

class VillagePainter extends CustomPainter {
  final int keepLevel;
  VillagePainter({required this.keepLevel});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..style = PaintingStyle.fill;
    final path = Path()..moveTo(size.width * .5, size.height * .08)..lineTo(size.width * .96, size.height * .5)..lineTo(size.width * .5, size.height * .94)..lineTo(size.width * .04, size.height * .5)..close();
    p.color = const Color(0xFF5E8A55); canvas.drawPath(path, p);
    for (int i = 0; i < 10; i++) { final x = size.width * ((i * 37 % 91 + 4) / 100); final y = size.height * ((i * 23 % 83 + 7) / 100); p.color = i.isEven ? const Color(0xFF6D995D) : const Color(0xFF4F794D); canvas.drawCircle(Offset(x, y), 7 + (i % 3) * 2, p); }
    p.color = const Color(0xFFB5A078); p.strokeWidth = 9; p.strokeCap = StrokeCap.round; p.style = PaintingStyle.stroke; canvas.drawLine(Offset(size.width * .48, size.height * .93), Offset(size.width * .52, size.height * .12), p); canvas.drawLine(Offset(size.width * .1, size.height * .53), Offset(size.width * .9, size.height * .48), p); p.style = PaintingStyle.fill;
    _house(canvas, Offset(size.width * .25, size.height * .38), 0.75, const Color(0xFFB77B4B)); _house(canvas, Offset(size.width * .72, size.height * .64), .8, const Color(0xFF9B6747)); _house(canvas, Offset(size.width * .72, size.height * .29), .6, const Color(0xFFBA8C59)); _castle(canvas, Offset(size.width * .49, size.height * .47), .92 + keepLevel * .04);
    p.color = const Color(0xFF31563E); for (int i = 0; i < 7; i++) { final x = size.width * (.1 + i * .125); canvas.drawCircle(Offset(x, size.height * (.16 + (i % 2) * .68)), 7, p); canvas.drawCircle(Offset(x - 3, size.height * (.16 + (i % 2) * .68) - 4), 5, Paint()..color = const Color(0xFF6C9A59)); }
  }
  void _house(Canvas c, Offset o, double s, Color color) { final p = Paint()..color = color; final w = 27 * s; final h = 22 * s; c.drawRect(Rect.fromCenter(center: o, width: w, height: h), p); final roof = Path()..moveTo(o.dx - w * .65, o.dy - h * .4)..lineTo(o.dx, o.dy - h * 1.15)..lineTo(o.dx + w * .65, o.dy - h * .4)..close(); c.drawPath(roof, Paint()..color = const Color(0xFF633D32)); c.drawRect(Rect.fromCenter(center: Offset(o.dx, o.dy + h * .15), width: 6 * s, height: 12 * s), Paint()..color = const Color(0xFF46342B)); }
  void _castle(Canvas c, Offset o, double s) { final p = Paint()..color = const Color(0xFFD8C9A3); final w = 46 * s; final h = 42 * s; c.drawRect(Rect.fromCenter(center: o, width: w, height: h), p); c.drawRect(Rect.fromLTWH(o.dx - w * .7, o.dy - h * .85, w * .32, h * .65), Paint()..color = const Color(0xFFE5D5B0)); c.drawRect(Rect.fromLTWH(o.dx + w * .38, o.dy - h * .85, w * .32, h * .65), Paint()..color = const Color(0xFFE5D5B0)); final r1 = Path()..moveTo(o.dx - w * .78, o.dy - h * .8)..lineTo(o.dx - w * .54, o.dy - h * 1.35)..lineTo(o.dx - w * .3, o.dy - h * .8)..close(); final r2 = Path()..moveTo(o.dx + w * .3, o.dy - h * .8)..lineTo(o.dx + w * .54, o.dy - h * 1.35)..lineTo(o.dx + w * .78, o.dy - h * .8)..close(); c.drawPath(r1, Paint()..color = const Color(0xFF8B493C)); c.drawPath(r2, Paint()..color = const Color(0xFF8B493C)); c.drawRect(Rect.fromCenter(center: Offset(o.dx, o.dy + h * .23), width: 12 * s, height: 25 * s), Paint()..color = const Color(0xFF654639)); c.drawCircle(Offset(o.dx, o.dy - h * .62), 3.5 * s, Paint()..color = GameColors.gold); }
  @override
  bool shouldRepaint(covariant VillagePainter oldDelegate) => oldDelegate.keepLevel != keepLevel;
}

class WorldMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size; canvas.drawRect(rect, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF315A43), Color(0xFF182D2A), Color(0xFF48664A)]).createShader(rect));
    final random = math.Random(8); final p = Paint();
    for (int i = 0; i < 45; i++) { final x = random.nextDouble() * size.width; final y = random.nextDouble() * size.height; final r = 5 + random.nextDouble() * 17; p.color = [const Color(0xFF406D4A), const Color(0xFF567C4D), const Color(0xFF294F3D)][i % 3].withOpacity(.7); canvas.drawCircle(Offset(x, y), r, p); }
    p.color = const Color(0xFF9C956F); p.strokeWidth = 13; p.strokeCap = StrokeCap.round; p.style = PaintingStyle.stroke; final road = Path()..moveTo(size.width * .02, size.height * .78)..quadraticBezierTo(size.width * .3, size.height * .45, size.width * .48, size.height * .57)..quadraticBezierTo(size.width * .68, size.height * .69, size.width * .98, size.height * .18); canvas.drawPath(road, p); p.style = PaintingStyle.fill;
    _marker(canvas, Offset(size.width * .49, size.height * .55), const Color(0xFFE7B85C), true); _marker(canvas, Offset(size.width * .2, size.height * .28), const Color(0xFFB7C3C0), false); _marker(canvas, Offset(size.width * .77, size.height * .35), const Color(0xFFE47766), false); _marker(canvas, Offset(size.width * .26, size.height * .78), const Color(0xFF91C47D), false);
    final textPainter = TextPainter(textDirection: TextDirection.rtl, textAlign: TextAlign.center); textPainter.text = const TextSpan(text: 'مملكتك', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)])); textPainter.layout(); textPainter.paint(canvas, Offset(size.width * .49 - textPainter.width / 2, size.height * .55 + 25));
  }
  void _marker(Canvas c, Offset o, Color color, bool home) { final p = Paint()..color = Colors.black.withOpacity(.25); c.drawCircle(o + const Offset(2, 4), home ? 20 : 14, p); p.color = color; c.drawCircle(o, home ? 17 : 12, p); p.color = const Color(0xFF1B2928); c.drawCircle(o, home ? 8 : 5, p); if (home) { c.drawRect(Rect.fromCenter(center: o, width: 7, height: 12), Paint()..color = GameColors.gold); } }
  @override
  bool shouldRepaint(covariant WorldMapPainter oldDelegate) => false;
}
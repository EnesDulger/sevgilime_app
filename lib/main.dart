import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lottie/lottie.dart';

// --- FİREBASE PAKETLERİ ---
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// --- DİĞER SAYFALARIN ---
import 'package:sevgilime/ani_duvari.dart';
import 'giris_ekrani.dart';
import 'memory.dart';
import 'zaman_kapsulu.dart';
import 'ask_testi.dart';
import 'ask_kuponlari.dart';
import 'bizim_haritamiz.dart';
import 'karar_carki.dart';

void main() async {
  // Flutter'ın başlatıldığından emin oluyoruz
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'i başlatıyoruz (YENİ EKLENEN KISIM)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Hive'ı başlatıyoruz
  await Hive.initFlutter();

  // Anı duvarı ve harita için bu kutuyu açmamız şart.
  await Hive.openBox('anilar_kutusu');

  runApp(const BenimUygulamam());
}

class BenimUygulamam extends StatelessWidget {
  const BenimUygulamam({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gülçin & Enes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        useMaterial3: true,
      ),
      home: const GirisEkrani(),
    );
  }
}

class KavanozEkrani extends StatefulWidget {
  const KavanozEkrani({super.key});

  @override
  State<KavanozEkrani> createState() => _KavanozEkraniState();
}

class _KavanozEkraniState extends State<KavanozEkrani> with TickerProviderStateMixin {
  final DateTime _baslangicTarihi = DateTime(2024, 10, 22);
  String _gun = "0", _saat = "0", _dakika = "0", _saniye = "0";
  Timer? _zamanlayici;
  String? _profilFotoYolu;

  // Gece Modu Kontrolü
  bool _isNightMode = false;

  // Müzik ve Animasyon
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  final List<String> _sevgiSozleri = [
    "Çünkü bana her baktığında içimi ısıtıyorsun.",
    "Çünkü seninleyken dünyanın en şanslı adamı gibi hissediyorum.",
    "Çünkü o güzel gülüşün bütün dertlerimi unutturuyor.",
    "Çünkü kokun evim gibi hissettiriyor.",
    "Çünkü inatçılığın bile dünyanın en tatlı şeyi.",
    "Çünkü seninle saçmalamayı her şeye tercih ederim.",
    "Çünkü sen benim en iyi arkadaşım ve en büyük aşkımsın."
  ];

  final List<Memory> _tumAnilar = [
    Memory(text: "Gülüşünle dünyamı aydınlatıyorsun güzelim.", mood: "Mutlu", color: Colors.orangeAccent),
    Memory(text: "Kokunu içime çekmeyi çok özledim yavrum...", mood: "Özlem", color: Colors.purpleAccent),
    Memory(text: "Kıyamam sana yavrum, senin bir damla gözyaşına dünyayı yakarım.", mood: "Üzgün", color: Colors.blueGrey),
    Memory(text: "Çok mu yoruldun balım? Bugün kendini şımartma günü olsun.", mood: "Yorgun", color: Colors.brown),
    Memory(text: "Sakin ol yavrum, derin bir nefes al. Her şey yoluna girecek.", mood: "Gergin", color: Colors.redAccent),
  ];

  String _gosterilenMetin = "Sana özel notlar için\nmodunu seç dandiğim :)";
  Color _kartRengi = Colors.white;

  @override
  void initState() {
    super.initState();
    _fotoYukle();
    _geceModuKontrolEt();
    _zamanlayici = Timer.periodic(const Duration(seconds: 1), (timer) {
      _zamaniHesapla();
      _geceModuKontrolEt();
    });

    _audioPlayer = AudioPlayer();
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 2.0, end: 15.0).animate(_glowController);
  }

  void _geceModuKontrolEt() {
    int hour = DateTime.now().hour;
    // 20:00 ile 06:00 arası gece modu
    bool night = hour >= 20 || hour < 6;
    if (night != _isNightMode) {
      setState(() => _isNightMode = night);
    }
  }

  void _zamaniHesapla() {
    final fark = DateTime.now().difference(_baslangicTarihi);
    if (mounted) {
      setState(() {
        _gun = fark.inDays.toString();
        _saat = (fark.inHours % 24).toString().padLeft(2, '0');
        _dakika = (fark.inMinutes % 60).toString().padLeft(2, '0');
        _saniye = (fark.inSeconds % 60).toString().padLeft(2, '0');
      });
    }
  }

  Future<void> _fotoSec() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profil_foto', image.path);
      setState(() => _profilFotoYolu = image.path);
    }
  }

  Future<void> _fotoYukle() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _profilFotoYolu = prefs.getString('profil_foto'));
  }

  void _muzigiAcKapat() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(AssetSource('bizim_sarkimiz.mp3'));
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  void _seniSeviyorumDe() {
    final rastgeleSoz = _sevgiSozleri[Random().nextInt(_sevgiSozleri.length)];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isNightMode ? const Color(0xFF1E1B4B) : Colors.pink.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(child: Text("Seni Seviyorum Çünkü...", style: GoogleFonts.pacifico(color: Colors.pink, fontSize: 22))),
        content: Text(rastgeleSoz, textAlign: TextAlign.center, style: GoogleFonts.nunito(fontSize: 18, color: _isNightMode ? Colors.white : Colors.black87)),
        actions: [
          Center(
            child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Ben de seni! ❤️")),
          )
        ],
      ),
    );
  }

  void _aniGetir(String moodKey) {
    List<Memory> uygunAnilar = _tumAnilar.where((memory) => memory.mood == moodKey).toList();
    if (uygunAnilar.isNotEmpty) {
      var rastgeleAni = (uygunAnilar..shuffle()).first;
      setState(() {
        _gosterilenMetin = rastgeleAni.text;
        _kartRengi = rastgeleAni.color.withOpacity(_isNightMode ? 0.3 : 0.15);
      });
    }
  }

  @override
  void dispose() {
    _zamanlayici?.cancel();
    _audioPlayer.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // --- TASARIM RENKLERİ ---
  Color get _bgMain => _isNightMode ? const Color(0xFF0F0C29) : const Color(0xFFF8F9FD);
  Color get _cardBg => _isNightMode ? const Color(0xFF1E1B4B).withOpacity(0.8) : Colors.white;
  Color get _textColor => _isNightMode ? Colors.white : Colors.black87;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgMain,
      appBar: AppBar(
        title: Text("Bize Özel", style: GoogleFonts.pacifico(color: _isNightMode ? Colors.cyanAccent : Colors.deepPurple)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _isNightMode ? Colors.cyanAccent : Colors.deepPurple,
      ),
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          if (_isNightMode)
            Positioned.fill(
              child: Opacity(
                opacity: 0.4,
                child: Lottie.network('https://assets9.lottiefiles.com/packages/lf20_tiviyc3p.json', fit: BoxFit.cover),
              ),
            ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 25),
                _buildGlowButton(),
                const SizedBox(height: 30),
                _buildCounterCard(),
                const SizedBox(height: 30),
                _buildNoteCard(),
                const SizedBox(height: 30),
                _buildMoodGrid(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: _fotoSec,
              child: CircleAvatar(
                radius: 30,
                backgroundColor: _isNightMode ? Colors.cyanAccent : Colors.pink,
                backgroundImage: _profilFotoYolu != null ? FileImage(File(_profilFotoYolu!)) : null,
                child: _profilFotoYolu == null ? const Icon(Icons.add_a_photo) : null,
              ),
            ),
            const SizedBox(width: 10),
            Text("Gülçin & Enes", style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: _textColor)),
          ],
        ),
        _buildMiniPlayer(),
      ],
    );
  }

  Widget _buildMiniPlayer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Row(
        children: [
          Icon(Icons.music_note, color: _isNightMode ? Colors.cyanAccent : Colors.pinkAccent, size: 20),
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
            color: _isNightMode ? Colors.cyanAccent : Colors.pink,
            onPressed: _muzigiAcKapat,
          )
        ],
      ),
    );
  }

  Widget _buildGlowButton() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (_isNightMode ? Colors.cyanAccent : Colors.pinkAccent).withOpacity(0.5),
                blurRadius: _glowAnimation.value * 1.5,
                spreadRadius: _glowAnimation.value / 2,
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(35),
              backgroundColor: _isNightMode ? const Color(0xFF240B36) : Colors.pinkAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: _seniSeviyorumDe,
            child: const Icon(Icons.favorite, size: 45),
          ),
        );
      },
    );
  }

  Widget _buildCounterCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: _isNightMode
              ? [const Color(0xFF0F0C29), const Color(0xFF302B63), const Color(0xFF24243E)]
              : [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
        ),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _sayacBirimi(_gun, "Gün"),
          _sayacBirimi(_saat, "Saat"),
          _sayacBirimi(_dakika, "Dk"),
          _sayacBirimi(_saniye, "Sn"),
        ],
      ),
    );
  }

  Widget _sayacBirimi(String deger, String etiket) {
    return Column(
      children: [
        Text(deger, style: GoogleFonts.bebasNeue(fontSize: 32, color: Colors.white, letterSpacing: 1)),
        Text(etiket, style: GoogleFonts.nunito(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildNoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _isNightMode ? Colors.cyanAccent.withOpacity(0.3) : Colors.black12),
      ),
      child: Text(
        _isNightMode && _gosterilenMetin.startsWith("Sana özel")
            ? "Gece çöktü sevgilim, rüyanda beni gör... ✨"
            : _gosterilenMetin,
        textAlign: TextAlign.center,
        style: GoogleFonts.caveat(fontSize: 26, fontWeight: FontWeight.bold, color: _textColor),
      ),
    );
  }

  Widget _buildMoodGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 2.1,
      children: [
        _modKarti("Mutlu 😊", Colors.orangeAccent, "Mutlu"),
        _modKarti("Özledim ❤️", Colors.pinkAccent, "Özlem"),
        _modKarti("Üzgün 😔", Colors.blueAccent, "Üzgün"),
        _modKarti("Yorgun 😴", Colors.brown, "Yorgun"),
        _modKarti("Gergin 😤", Colors.redAccent, "Gergin"),
      ],
    );
  }

  Widget _modKarti(String baslik, Color renk, String moodKey) {
    return InkWell(
      onTap: () => _aniGetir(moodKey),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: renk.withOpacity(_isNightMode ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: renk.withOpacity(0.4), width: 2),
        ),
        child: Center(
          child: Text(baslik, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold, color: _isNightMode ? Colors.white : renk)),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: _bgMain,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFfad0c4), Color(0xFFffd1ff)])),
            child: Center(child: Text("Sana Özel ❤️", style: GoogleFonts.pacifico(color: Colors.white, fontSize: 28))),
          ),
          _drawerItem(context, Icons.hourglass_bottom, "Zaman Kapsülü", Colors.blue, const ZamanKapsuluEkrani()),
          _drawerItem(context, Icons.card_giftcard, "Aşk Kuponları", Colors.purple, const AskKuponlari()),
          _drawerItem(context, Icons.map, "Bizim Haritamız", Colors.teal, const BizimHaritamiz()),
          _drawerItem(context, Icons.casino, "Karar Çarkı", Colors.orange, const KararCarki()),
          _drawerItem(context, Icons.quiz, "Beni Tanıyor Musun?", Colors.indigo, const AskTesti()),
          _drawerItem(context, Icons.photo_library, "Anı Duvarı", Colors.deepOrangeAccent, const AniDuvari()),
        ],
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String title, Color color, Widget page) {
    return ListTile(
      leading: Icon(icon, color: _isNightMode ? Colors.cyanAccent : color),
      title: Text(title, style: GoogleFonts.nunito(fontSize: 16, color: _textColor)),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
    );
  }
}
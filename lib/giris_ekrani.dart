import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Ana sayfaya geçiş için

class GirisEkrani extends StatefulWidget {
  const GirisEkrani({super.key});

  @override
  State<GirisEkrani> createState() => _GirisEkraniState();
}

class _GirisEkraniState extends State<GirisEkrani> {
  // Varsayılan ayarlar (Normal Gün)
  String _baslik = "Sana Özel...";
  String _altBaslik = "Girmek için kalbe dokun ❤️";
  String _animasyonDosyasi = "assets/kalp_animasyon.json";
  List<Color> _arkaPlanRenkleri = [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)];

  // Bildirim mesajı için değişken
  String? _ozelGunMesaji;

  @override
  void initState() {
    super.initState();
    _tarihiKontrolEt();
  }

  void _tarihiKontrolEt() {
    final bugun = DateTime.now();

    // --- SENARYO 1: DOĞUM GÜNÜ (21 OCAK) ---
    if (bugun.month == 1 && bugun.day == 21) {
      setState(() {
        _baslik = "İyi ki Doğdun!";
        _altBaslik = "Doğum günün kutlu olsun sevgilim 🎂";
        _animasyonDosyasi = "assets/dogum_gunu.json"; // Bu dosyayı indirmeyi unutma!
        _arkaPlanRenkleri = [const Color(0xFF84fab0), const Color(0xFF8fd3f4)]; // Daha canlı renkler
        _ozelGunMesaji = "İyi ki doğdun canım sevgilim. Seni Çok seviyorum ❤️";
      });
      _bildirimGoster(); // Uygulama açılınca mesaj fırlat
    }
    // --- SENARYO 2: SEVGİLİLER GÜNÜ (14 ŞUBAT) ---
    else if (bugun.month == 2 && bugun.day == 14) {
      setState(() {
        _baslik = "Bizim Günümüz!";
        _altBaslik = "Sevgililer günümüz kutlu olsun 🌹";
        _animasyonDosyasi = "assets/sevgililer_gunu.json"; // Bu dosyayı indirmeyi unutma!
        _arkaPlanRenkleri = [const Color(0xFFee9ca7), const Color(0xFFffdde1)]; // Romantik kırmızılar
        _ozelGunMesaji = "Sevgililer günümüz kutlu olsun canım sevgilim ❤️";
      });
      _bildirimGoster();
    }
  }

  // Uygulama açıldığı an ekrana fırlayan kutlama mesajı (Dialog)
  void _bildirimGoster() {
    // build tamamlandıktan hemen sonra çalışması için:
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("❤️ SÜRPRİİİZ! ❤️", textAlign: TextAlign.center, style: GoogleFonts.pacifico(color: Colors.red)),
          content: Text(
            _ozelGunMesaji ?? "",
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Seni Seviyorum"),
            )
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _arkaPlanRenkleri, // Tarihe göre değişen renk
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- BAŞLIK ---
            Text(
              _baslik,
              style: GoogleFonts.pacifico(
                fontSize: 45,
                color: Colors.white,
                shadows: [
                  const BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(2, 2))
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- ANİMASYON ---
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const KavanozEkrani()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.white.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)
                    ]
                ),
                child: Lottie.asset(
                  _animasyonDosyasi, // Tarihe göre değişen animasyon
                  width: 250,
                  height: 250,
                  fit: BoxFit.fill,
                ),
              ),
            ),

            const SizedBox(height: 60),

            // --- ALT YAZI ---
            Text(
              _altBaslik,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
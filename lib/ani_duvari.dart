import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'bizim_haritamiz.dart'; // AniNoktasi modeli için

class AniDuvari extends StatefulWidget {
  const AniDuvari({super.key});

  @override
  State<AniDuvari> createState() => _AniDuvariState();
}

class _AniDuvariState extends State<AniDuvari> {
  // FİREBASE VERİTABANI REFERANSI
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("harita_anilari");

  List<AniNoktasi> _anilar = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _anilariDinle();
  }

  // --- FİREBASE'DEN GERÇEK ZAMANLI VERİ OKUMA ---
  void _anilariDinle() {
    _dbRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        List<AniNoktasi> yuklenenAnilar = [];

        data.forEach((key, value) {
          final aniMap = Map<String, dynamic>.from(value);
          yuklenenAnilar.add(AniNoktasi.fromJson(aniMap, key.toString()));
        });

        if (mounted) {
          setState(() {
            _anilar = yuklenenAnilar;
            _yukleniyor = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _anilar = [];
            _yukleniyor = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
      appBar: AppBar(
        title: Text("Anı Duvarımız 📸", style: GoogleFonts.pacifico()),
        backgroundColor: Colors.purple.shade300,
        foregroundColor: Colors.white,
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : _anilar.isEmpty
          ? Center(
        child: Text(
          "Henüz haritaya fotoğraf eklememişsin dandiğim..",
          style: GoogleFonts.nunito(fontSize: 16),
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: _anilar.length,
        itemBuilder: (context, index) {
          final ani = _anilar[index];
          double rotation = (index % 2 == 0 ? 0.05 : -0.05);

          return Transform.rotate(
            angle: rotation,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    // --- İŞTE SİHRİN OLDUĞU YER ---
                    child: ani.fotoYolu != null
                        ? (ani.fotoYolu!.startsWith('http')
                    // Eğer internet linkiyse Firebase'den çek ve yüklenirken dönen bir ikon göster
                        ? Image.network(
                      ani.fotoYolu!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
                      },
                    )
                    // Değilse ve telefonun hafızasındaysa lokalden çek
                        : (File(ani.fotoYolu!).existsSync()
                        ? Image.file(File(ani.fotoYolu!), fit: BoxFit.cover, width: double.infinity)
                        : _varsayilanKutu()))
                        : _varsayilanKutu(),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ani.baslik,
                    style: GoogleFonts.caveat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "📍 ${ani.konum.latitude.toStringAsFixed(2)}, ${ani.konum.longitude.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Fotoğraf olmadığında gösterilecek boş kutu tasarımı
  Widget _varsayilanKutu() {
    return Container(
      color: Colors.pink.shade50,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite, color: Colors.pinkAccent, size: 40),
        ],
      ),
    );
  }
}
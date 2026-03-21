import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rxdart/rxdart.dart';

class KararCarki extends StatefulWidget {
  const KararCarki({super.key});

  @override
  State<KararCarki> createState() => _KararCarkiState();
}

class _KararCarkiState extends State<KararCarki> with TickerProviderStateMixin {
  late TabController _tabController;
  final StreamController<int> _selected = BehaviorSubject<int>();

  // --- KATEGORİLER VE SEÇENEKLER ---
  final List<String> _yemekler = ["Burger", "Pizza", "Sushi", "Lahmacun", "Tantuni", "Makarna", "Köfte"];
  final List<String> _aktiviteler = ["Sinema", "Yürüyüş", "Bowling", "Evde Film", "Lunapark", "Sahil", "Kahve İçme"];
  final List<String> _filmler = ["Romantik Komedi", "Korku", "Aksiyon", "Animasyon", "Bilim Kurgu", "Belgesel"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _selected.close();
    _tabController.dispose();
    super.dispose();
  }

  void _cevir(int listLength) {
    // Rastgele bir index seç
    final random = Fortune.randomInt(0, listLength);
    _selected.add(random);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Kararsızlık Çarkı 🎡", style: GoogleFonts.pacifico()),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.bold),
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Ne Yiyelim?"),
            Tab(text: "Ne Yapalım?"),
            Tab(text: "Ne İzleyelim?"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _carkSayfasi(_yemekler, Colors.orange),
          _carkSayfasi(_aktiviteler, Colors.blue),
          _carkSayfasi(_filmler, Colors.red),
        ],
      ),
    );
  }

  Widget _carkSayfasi(List<String> secenekler, Color temaRengi) {
    return Container(
      color: temaRengi.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Çarkı Çevir, Kaderine Razı Ol! 😎", style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            height: 350,
            child: FortuneWheel(
              selected: _selected.stream,
              animateFirst: false,
              items: [
                for (var it in secenekler)
                  FortuneItem(
                    child: Text(it, style: const TextStyle(fontWeight: FontWeight.bold)),
                    style: FortuneItemStyle(
                      color: Colors.primaries[secenekler.indexOf(it) % Colors.primaries.length],
                      borderColor: Colors.white,
                      borderWidth: 3,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: temaRengi,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: () => _cevir(secenekler.length),
            child: const Text("ÇEVİR", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
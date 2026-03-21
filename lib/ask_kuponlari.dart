import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
// FİREBASE PAKETİ
import 'package:firebase_database/firebase_database.dart';

class AskKuponlari extends StatefulWidget {
  const AskKuponlari({super.key});

  @override
  State<AskKuponlari> createState() => _AskKuponlariState();
}

class Kupon {
  final String baslik;
  final String aciklama;
  final IconData ikon;
  final Color renk;
  bool kullanildiMi;

  Kupon(this.baslik, this.aciklama, this.ikon, this.renk, {this.kullanildiMi = false});
}

class _AskKuponlariState extends State<AskKuponlari> {
  late ConfettiController _confettiController;

  // FİREBASE VERİTABANI REFERANSI
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("kuponlar");

  // Kupon Listemiz
  final List<Kupon> _kuponlar = [
    Kupon("Masaj Hakkı", "30 dakika kesintisiz omuz masajı!", Icons.spa, Colors.purpleAccent),
    Kupon("Film Seçimi", "Bugün filmi sen seçiyorsun, itiraz yok.", Icons.movie_filter, Colors.indigoAccent),
    Kupon("Kahvaltı Yatakta", "Kraliçelere layık bir sabah.", Icons.breakfast_dining, Colors.orange),
    Kupon("Trip Silici", "Yapılan hatayı anında affetme kartı.", Icons.cleaning_services, Colors.redAccent),
    Kupon("Bulaşık Bende", "Bugün ellerin suya değmeyecek güzelim.", Icons.water_drop, Colors.blue),
    Kupon("Sarılma Molası", "Ne yapıyorsak bırakıp 5 dk sarılıyoruz.", Icons.favorite, Colors.pink),
    Kupon("Fast Food Günü", "Diyet miyet yok, gömüyoruz!", Icons.fastfood, Colors.amber),
    Kupon("Haklısın Aşkım", "Tartışma biter, sen haklısın.", Icons.check_circle, Colors.green),
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _kuponlariDinle(); // Sayfa açılınca Firebase'i dinlemeye başla
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // --- FİREBASE'DEN VERİ OKUMA (GERÇEK ZAMANLI) ---
  void _kuponlariDinle() {
    _dbRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value;

        // Firebase bazen veriyi List, bazen Map olarak döndürebilir
        if (data is List) {
          for (int i = 0; i < data.length; i++) {
            if (data[i] != null && i < _kuponlar.length) {
              setState(() {
                _kuponlar[i].kullanildiMi = data[i] as bool;
              });
            }
          }
        } else if (data is Map) {
          data.forEach((key, value) {
            int index = int.tryParse(key.toString()) ?? -1;
            if (index != -1 && index < _kuponlar.length) {
              setState(() {
                _kuponlar[index].kullanildiMi = value == true;
              });
            }
          });
        }
      }
    });
  }

  // --- FİREBASE'E VERİ YAZMA ---
  void _kuponKullan(int index) {
    if (_kuponlar[index].kullanildiMi) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Kuponu Kullan? 🎫", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
        content: Text("${_kuponlar[index].baslik} kuponunu kullanmak istiyor musun? Enes göreve hazır bekliyor!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Önce diyaloğu kapat

              // FİREBASE GÜNCELLEMESİ YAPILIYOR
              // Hangi kupona tıklandıysa, onun index'ini (0, 1, 2...) Firebase'de 'true' yapıyoruz
              _dbRef.child(index.toString()).set(true);

              // --- KONFETİ VE BİLDİRİM ---
              _confettiController.play();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.pinkAccent,
                  behavior: SnackBarBehavior.floating,
                  content: Text("Kupon Onaylandı! 🫡", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
                ),
              );
            },
            child: const Text("Mühürle!"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Aşk Kuponları 🎫", style: GoogleFonts.pacifico()),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFFFFF0F5),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _kuponlar.length,
              itemBuilder: (context, index) {
                final kupon = _kuponlar[index];
                return GestureDetector(
                  onTap: () => _kuponKullan(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: Card(
                      elevation: kupon.kullanildiMi ? 1 : 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      color: kupon.kullanildiMi ? Colors.grey.shade200 : Colors.white,
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(kupon.ikon, size: 40, color: kupon.kullanildiMi ? Colors.grey : kupon.renk),
                                const SizedBox(height: 10),
                                Text(
                                  kupon.baslik,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.nunito(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: kupon.kullanildiMi ? Colors.grey : Colors.black87,
                                    decoration: kupon.kullanildiMi ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  kupon.aciklama,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          // --- MÜHÜR EFEKTİ ---
                          if (kupon.kullanildiMi)
                            Positioned.fill(
                              child: Center(
                                child: Transform.rotate(
                                  angle: -0.2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.red.withOpacity(0.7), width: 3),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      "ONAYLANDI",
                                      style: GoogleFonts.bebasNeue(
                                        color: Colors.red.withOpacity(0.7),
                                        fontSize: 24,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // --- KONFETİ WIDGET ---
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.pink, Colors.red, Colors.orange, Colors.purple, Colors.yellow],
            numberOfParticles: 20,
          ),
        ],
      ),
    );
  }
}
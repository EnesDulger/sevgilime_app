import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';

class AskTesti extends StatefulWidget {
  const AskTesti({super.key});

  @override
  State<AskTesti> createState() => _AskTestiState();
}

class _AskTestiState extends State<AskTesti> {
  // FİREBASE REFERANSI
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("ask_testi_sonuclari");

  int _soruIndex = 0;
  int _skor = 0;
  bool _testBasladi = false;
  bool _testBitti = false;
  DateTime? _baslangicZamani;
  List<Map<dynamic, dynamic>> _gecmisSonuclar = [];

  // --- SORULARIMIZ (Burayı kendi ilişkinize göre tamamen değiştirebilirsin!) ---
  final List<Map<String, dynamic>> _sorular = [
    {
      'soru': 'Bizim haritamızda işaretlediğimiz o özel yer neresiydi?',
      'secenekler': ['Nevşehir/Kapadokya', 'Aksaray', 'Kayseri', 'Ankara'],
      'cevap': 'Nevşehir/Kapadokya'
    },
    {
      'soru': 'Enes sinirlendiğinde veya yorulduğunda onu en iyi ne sakinleştirir?',
      'secenekler': ['Yalnız kalmak', 'Sarılmak', 'Oyun oynamak', 'Müzik dinlemek'],
      'cevap': 'Sarılmak'
    },
    {
      'soru': 'İlk buluşmamızda Enes ne renk giyinmişti?',
      'secenekler': ['Siyah', 'Beyaz', 'Mavi', 'Yeşil'],
      'cevap': 'Siyah'
    },
    {
      'soru': 'Enes\'in en sevdiği, asla hayır diyemeyeceği yemek hangisidir?',
      'secenekler': ['Mantı', 'İskender', 'Pizza', 'Kuru Fasulye'],
      'cevap': 'İskender'
    },
  ];

  @override
  void initState() {
    super.initState();
    _sonuclariDinle();
  }

  // --- FİREBASE'DEN GEÇMİŞ SONUÇLARI OKUMA ---
  void _sonuclariDinle() {
    _dbRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        List<Map<dynamic, dynamic>> sonuclar = [];

        data.forEach((key, value) {
          sonuclar.add(value);
        });

        // En son çözülen test en üstte çıksın diye tarihe göre sıralıyoruz
        sonuclar.sort((a, b) => b['tarih'].compareTo(a['tarih']));

        if (mounted) {
          setState(() {
            _gecmisSonuclar = sonuclar;
          });
        }
      }
    });
  }

  void _testiBaslat() {
    setState(() {
      _testBasladi = true;
      _testBitti = false;
      _soruIndex = 0;
      _skor = 0;
      _baslangicZamani = DateTime.now(); // Kronometreyi başlat
    });
  }

  void _cevapKontrol(String secilenCevap) {
    if (secilenCevap == _sorular[_soruIndex]['cevap']) {
      _skor += 25; // 4 soru olduğu için her doğru 25 puan (100 üzerinden)
    }

    if (_soruIndex < _sorular.length - 1) {
      setState(() {
        _soruIndex++;
      });
    } else {
      _testiBitir();
    }
  }

  // --- TEST BİTİNCE FİREBASE'E KAYDETME ---
  void _testiBitir() {
    final bitisZamani = DateTime.now();
    final gecenSure = bitisZamani.difference(_baslangicZamani!).inSeconds;

    setState(() {
      _testBitti = true;
    });

    // FİREBASE'E PUSH ET
    _dbRef.push().set({
      'skor': _skor,
      'sureSaniye': gecenSure,
      'tarih': bitisZamani.toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EAF6),
      appBar: AppBar(
        title: Text("Beni Tanıyor Musun? 🧐", style: GoogleFonts.pacifico()),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: !_testBasladi
          ? _buildGirisEkrani()
          : _testBitti
          ? _buildSonucEkrani()
          : _buildSoruEkrani(),
    );
  }

  // 1. EKRAN: GİRİŞ VE GEÇMİŞ SONUÇLAR
  Widget _buildGirisEkrani() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.quiz, size: 80, color: Colors.indigo),
            const SizedBox(height: 20),
            Text(
              "Bakalım beni ne kadar iyi tanıyorsun?",
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo.shade800),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: _testiBaslat,
              child: const Text("Testi Başlat!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),

            // LİDERLİK TABLOSU / GEÇMİŞ SONUÇLAR
            if (_gecmisSonuclar.isNotEmpty) ...[
              const Divider(color: Colors.indigo, thickness: 1),
              Text("Geçmiş Denemeler 📊", style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: _gecmisSonuclar.length,
                  itemBuilder: (context, index) {
                    final sonuc = _gecmisSonuclar[index];
                    final tarih = DateTime.parse(sonuc['tarih']);
                    final formatliTarih = "${tarih.day}/${tarih.month}/${tarih.year} - ${tarih.hour}:${tarih.minute.toString().padLeft(2, '0')}";

                    return Card(
                      color: Colors.white,
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: sonuc['skor'] >= 75 ? Colors.green : Colors.orange,
                          child: Text("${sonuc['skor']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(formatliTarih, style: const TextStyle(fontSize: 14)),
                        subtitle: Text("Süre: ${sonuc['sureSaniye']} saniye", style: const TextStyle(color: Colors.grey)),
                        trailing: Icon(
                          sonuc['skor'] >= 75 ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                          color: sonuc['skor'] >= 75 ? Colors.amber : Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              )
            ]
          ],
        ),
      ),
    );
  }

  // 2. EKRAN: SORU ÇÖZÜM ALANI
  Widget _buildSoruEkrani() {
    final soru = _sorular[_soruIndex];
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(
            value: (_soruIndex + 1) / _sorular.length,
            backgroundColor: Colors.indigo.shade100,
            color: Colors.indigo,
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 20),
          Text(
            "Soru ${_soruIndex + 1} / ${_sorular.length}",
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Center(
                child: Text(
                  soru['soru'],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo.shade900),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          ...List.generate(
            soru['secenekler'].length,
                (index) {
              final secenek = soru['secenekler'][index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo.shade50,
                    foregroundColor: Colors.indigo.shade900,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                    side: BorderSide(color: Colors.indigo.shade200, width: 2),
                  ),
                  onPressed: () => _cevapKontrol(secenek),
                  child: Text(secenek, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 3. EKRAN: TEST BİTİŞ VE SONUÇ
  Widget _buildSonucEkrani() {
    String mesaj = "";
    if (_skor == 100) mesaj = "Kusursuz! Beni benden daha iyi tanıyorsun aşkım. ❤️";
    else if (_skor >= 75) mesaj = "Harika! Sadece ufak tefek detaylar kaçmış. 👏";
    else if (_skor >= 50) mesaj = "Fena değil ama biraz daha çalışman lazım güzelim. 😅";
    else mesaj = "Eyvah eyvah... Bunu telafi etmemiz gerekecek! 😱";

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _skor >= 75 ? Icons.stars : Icons.error_outline,
              size: 100,
              color: _skor >= 75 ? Colors.amber : Colors.redAccent,
            ),
            const SizedBox(height: 20),
            Text("Test Bitti!", style: GoogleFonts.pacifico(fontSize: 32, color: Colors.indigo)),
            const SizedBox(height: 10),
            Text(mesaj, textAlign: TextAlign.center, style: GoogleFonts.nunito(fontSize: 20)),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.indigo.shade100, width: 3),
              ),
              child: Column(
                children: [
                  Text("Skorun", style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                  Text("$_skor / 100", style: GoogleFonts.bebasNeue(fontSize: 48, color: Colors.indigo)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                setState(() {
                  _testBasladi = false; // Ana ekrana geri dön
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Ana Ekrana Dön", style: TextStyle(fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}
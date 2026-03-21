import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// FİREBASE PAKETİ
import 'package:firebase_database/firebase_database.dart';

// --- VERİ MODELİ ---
class KapsulMektubu {
  String? id; // Firebase'deki benzersiz anahtarı tutmak için
  final String baslik;
  final String icerik;
  final DateTime acilmaTarihi;
  final int renkValue;

  KapsulMektubu({
    this.id,
    required this.baslik,
    required this.icerik,
    required this.acilmaTarihi,
    required this.renkValue,
  });

  // Firebase'e yazarken
  Map<String, dynamic> toJson() => {
    'baslik': baslik,
    'icerik': icerik,
    'acilmaTarihi': acilmaTarihi.toIso8601String(), // Tarihi metne çeviriyoruz
    'renkValue': renkValue,
  };

  // Firebase'den okurken
  factory KapsulMektubu.fromJson(Map<String, dynamic> json, String key) => KapsulMektubu(
    id: key,
    baslik: json['baslik'],
    icerik: json['icerik'],
    acilmaTarihi: DateTime.parse(json['acilmaTarihi']), // Metni tekrar tarihe çeviriyoruz
    renkValue: json['renkValue'],
  );
}

class ZamanKapsuluEkrani extends StatefulWidget {
  const ZamanKapsuluEkrani({super.key});

  @override
  State<ZamanKapsuluEkrani> createState() => _ZamanKapsuluEkraniState();
}

class _ZamanKapsuluEkraniState extends State<ZamanKapsuluEkrani> {
  // FİREBASE REFERANSI
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("zaman_kapsulu");

  List<KapsulMektubu> _mektuplar = [];
  bool _yukleniyor = true;

  @override
  void initState() {
    super.initState();
    _kapsulleriDinle(); // Sayfa açılınca Firebase'i dinlemeye başla
  }

  // --- FİREBASE'DEN GERÇEK ZAMANLI VERİ OKUMA ---
  void _kapsulleriDinle() {
    _dbRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        List<KapsulMektubu> yuklenenMektuplar = [];

        data.forEach((key, value) {
          final mektupMap = Map<String, dynamic>.from(value);
          yuklenenMektuplar.add(KapsulMektubu.fromJson(mektupMap, key.toString()));
        });

        // Kapsülleri açılma tarihine göre sıralayalım (Yakın tarih en üstte olsun)
        yuklenenMektuplar.sort((a, b) => a.acilmaTarihi.compareTo(b.acilmaTarihi));

        if (mounted) {
          setState(() {
            _mektuplar = yuklenenMektuplar;
            _yukleniyor = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _mektuplar = [];
            _yukleniyor = false;
          });
        }
      }
    });
  }

  // --- YENİ MEKTUP EKLEME (FİREBASE'E PUSH) ---
  void _mektupEkleDialog() {
    final baslikController = TextEditingController();
    final icerikController = TextEditingController();
    DateTime secilenTarih = DateTime.now().add(const Duration(days: 1));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text("Yeni Kapsül Oluştur ⏳", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: baslikController,
                    decoration: const InputDecoration(labelText: "Başlık (Örn: İlk Yıl Dönümümüz)")
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: icerikController,
                    decoration: const InputDecoration(labelText: "Geleceğe Notun..."),
                    maxLines: 4
                ),
                const SizedBox(height: 20),
                Text("Hangi Tarihte Açılsın?", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_month, color: Colors.deepPurple),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: secilenTarih,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) setStateDialog(() => secilenTarih = date);
                  },
                  label: Text(
                    DateFormat('dd MMMM yyyy').format(secilenTarih),
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              onPressed: () {
                if (baslikController.text.isNotEmpty && icerikController.text.isNotEmpty) {
                  // FİREBASE'E YAZMA İŞLEMİ
                  final yeniKapsulRef = _dbRef.push();
                  yeniKapsulRef.set({
                    'baslik': baslikController.text,
                    'icerik': icerikController.text,
                    'acilmaTarihi': secilenTarih.toIso8601String(),
                    'renkValue': Colors.pinkAccent.value,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text("Kapsülü Kilitle! 🔒"),
            ),
          ],
        ),
      ),
    );
  }

  // --- KAPSÜL SİLME ONAYI ---
  void _silmeOnayi(KapsulMektubu mektup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Kapsülü İmha Et?", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.red)),
        content: const Text("Bu zaman kapsülünü tamamen silmek istediğine emin misin? Tarih değiştirilemez!"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              if (mektup.id != null) {
                _dbRef.child(mektup.id!).remove(); // FİREBASE'DEN SİL
              }
              Navigator.pop(context);
            },
            child: const Text("Evet, Sil"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
      appBar: AppBar(
        title: Text("Zaman Kapsülü ⏳", style: GoogleFonts.pacifico()),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mektupEkleDialog,
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add_task, color: Colors.white),
        label: const Text("Yeni Kapsül", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
          : _mektuplar.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty, size: 60, color: Colors.grey),
            const SizedBox(height: 10),
            Text("Henüz geleceğe bir not bırakmadın...", style: GoogleFonts.nunito(fontSize: 16, color: Colors.grey.shade700)),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mektuplar.length,
        itemBuilder: (context, index) {
          final mektup = _mektuplar[index];
          final kilitliMi = mektup.acilmaTarihi.isAfter(DateTime.now());

          return Card(
            elevation: kilitliMi ? 2 : 6,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: kilitliMi ? Colors.grey.shade400 : Colors.deepPurple.shade200, width: 2),
            ),
            color: kilitliMi ? Colors.grey.shade200 : Colors.white,
            child: ListTile(
              contentPadding: const EdgeInsets.all(15),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kilitliMi ? Colors.grey.shade300 : Color(mektup.renkValue).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  kilitliMi ? Icons.lock : Icons.lock_open,
                  color: kilitliMi ? Colors.grey.shade600 : Color(mektup.renkValue),
                  size: 28,
                ),
              ),
              title: Text(
                mektup.baslik,
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: kilitliMi ? Colors.grey.shade600 : Colors.black87,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  kilitliMi
                      ? "🔒 ${DateFormat('dd MMMM yyyy').format(mektup.acilmaTarihi)} tarihinde açılacak"
                      : "Zamanı geldi! Okumak için dokun...",
                  style: TextStyle(
                    color: kilitliMi ? Colors.redAccent : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              onLongPress: () => _silmeOnayi(mektup),
              onTap: () {
                if (kilitliMi) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Hey! Henüz zamanı gelmedi, biraz daha sabret! 🔒"),
                      backgroundColor: Colors.red.shade400,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      title: Text(mektup.baslik, style: GoogleFonts.pacifico(color: Colors.deepPurple, fontSize: 24)),
                      content: Text(mektup.icerik, style: GoogleFonts.nunito(fontSize: 16)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Kapat ❤️", style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}
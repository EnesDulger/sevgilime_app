import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

// FİREBASE PAKETLERİ
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart'; // YENİ EKLENDİ

class BizimHaritamiz extends StatefulWidget {
  const BizimHaritamiz({super.key});

  @override
  State<BizimHaritamiz> createState() => _BizimHaritamizState();
}

class AniNoktasi {
  String? id;
  final String baslik;
  final String aciklama;
  final LatLng konum;
  final int ikonCode;
  final int renkValue;
  final String? fotoYolu; // Artık burası internet linki (URL) de tutabilecek

  AniNoktasi({
    this.id,
    required this.baslik,
    required this.aciklama,
    required this.konum,
    required this.ikonCode,
    required this.renkValue,
    this.fotoYolu,
  });

  Map<String, dynamic> toJson() => {
    'baslik': baslik,
    'aciklama': aciklama,
    'latitude': konum.latitude,
    'longitude': konum.longitude,
    'ikonCode': ikonCode,
    'renkValue': renkValue,
    'fotoYolu': fotoYolu,
  };

  factory AniNoktasi.fromJson(Map<String, dynamic> json, String key) {
    return AniNoktasi(
      id: key,
      baslik: json['baslik'],
      aciklama: json['aciklama'],
      konum: LatLng(json['latitude'], json['longitude']),
      ikonCode: json['ikonCode'],
      renkValue: json['renkValue'],
      fotoYolu: json['fotoYolu'],
    );
  }
}

class _BizimHaritamizState extends State<BizimHaritamiz> {
  // Haritayı açtığında sizin buraları (Kapadokya/Nevşehir taraflarını) göstersin
  final LatLng _merkez = const LatLng(38.6244, 34.7144);
  final MapController _mapController = MapController();

  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("harita_anilari");
  List<AniNoktasi> _anilar = [];

  @override
  void initState() {
    super.initState();
    _anilariDinle();
  }

  void _anilariDinle() {
    _dbRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        List<AniNoktasi> yuklenenAnilar = [];
        data.forEach((key, value) {
          final aniMap = Map<String, dynamic>.from(value);
          yuklenenAnilar.add(AniNoktasi.fromJson(aniMap, key.toString()));
        });
        if (mounted) setState(() => _anilar = yuklenenAnilar);
      } else {
        if (mounted) setState(() => _anilar = []);
      }
    });
  }

  List<Polyline> _rotalariOlustur() {
    if (_anilar.length < 2) return [];
    List<LatLng> rotaNoktalari = _anilar.map((ani) => ani.konum).toList();
    return [
      Polyline(
        points: rotaNoktalari,
        strokeWidth: 4.0,
        color: Colors.pinkAccent.withOpacity(0.8),
        isDotted: true,
        borderColor: Colors.white,
        borderStrokeWidth: 1.0,
      ),
    ];
  }

  Future<String?> _fotoSec() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70); // Yükleme hızlı olsun diye kaliteyi %70 yaptık
    return image?.path;
  }

  void _aniEkleDialog(LatLng tiklananKonum) {
    String girilenBaslik = "";
    String girilenAciklama = "";
    String? secilenFotoYolu;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text("Yeni Anı Ekle 📍", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.teal)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: "Başlık"),
                      onChanged: (val) => girilenBaslik = val,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      decoration: const InputDecoration(labelText: "Notun..."),
                      onChanged: (val) => girilenAciklama = val,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () async {
                        String? yol = await _fotoSec();
                        if (yol != null) {
                          setStateDialog(() => secilenFotoYolu = yol);
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.teal.shade200, width: 2),
                        ),
                        child: secilenFotoYolu == null
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 40, color: Colors.teal.shade300),
                            Text("Fotoğraf Ekle (Buluta Yüklenir)", style: GoogleFonts.nunito(color: Colors.teal, fontSize: 12)),
                          ],
                        )
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Image.file(File(secilenFotoYolu!), fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Vazgeç")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (girilenBaslik.isNotEmpty) {
                      // YÜKLEME EKRANI GÖSTERELİM Kİ UYGULAMA DONDU SANILMASIN
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (c) => const Center(child: CircularProgressIndicator(color: Colors.teal)),
                      );

                      String? firebaseIndirmeLinki;

                      // EĞER FOTOĞRAF SEÇİLDİYSE FİREBASE STORAGE'A YÜKLE
                      if (secilenFotoYolu != null) {
                        try {
                          final dosyaAdi = DateTime.now().millisecondsSinceEpoch.toString();
                          final storageRef = FirebaseStorage.instance.ref().child("harita_fotolari/$dosyaAdi.jpg");

                          // Dosyayı buluta it
                          final uploadTask = await storageRef.putFile(File(secilenFotoYolu!));
                          // İnternet linkini al
                          firebaseIndirmeLinki = await uploadTask.ref.getDownloadURL();
                        } catch (e) {
                          print("Fotoğraf yükleme hatası: $e");
                        }
                      }

                      // REALTIME DATABASE'E VERİLERİ YAZ
                      final yeniAniRef = _dbRef.push();
                      await yeniAniRef.set({
                        'baslik': girilenBaslik,
                        'aciklama': girilenAciklama,
                        'latitude': tiklananKonum.latitude,
                        'longitude': tiklananKonum.longitude,
                        'ikonCode': Icons.favorite.codePoint,
                        'renkValue': Colors.pink.value,
                        // Eğer link varsa linki kaydet, yoksa null geç
                        'fotoYolu': firebaseIndirmeLinki,
                      });

                      Navigator.pop(context); // Yükleme ekranını kapat
                      Navigator.pop(context); // Anı ekleme penceresini kapat
                    }
                  },
                  child: const Text("Haritaya Kazı!"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _aniGoster(AniNoktasi ani) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(ani.baslik, style: GoogleFonts.pacifico(fontSize: 28, color: Colors.teal))),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 30),
                    onPressed: () {
                      if (ani.id != null) _dbRef.child(ani.id!).remove();
                      // (Profesyonel not: İleride Storage'daki resmi de silmek için buraya kod eklenebilir)
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
              const Divider(),

              // RESİM GÖSTERME KISMI (İnternetten mi, Telefondan mı?)
              if (ani.fotoYolu != null)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    // Eğer path "http" ile başlıyorsa Firebase URL'sidir, internetten çek
                    child: ani.fotoYolu!.startsWith('http')
                        ? Image.network(
                      ani.fotoYolu!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: Colors.teal));
                      },
                    )
                    // Değilse eski anılardır (telefondadır), lokalden çek
                        : File(ani.fotoYolu!).existsSync()
                        ? Image.file(File(ani.fotoYolu!), fit: BoxFit.cover, width: double.infinity)
                        : const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                  ),
                )
              else
                const Expanded(child: Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 50, color: Colors.grey),
                    Text("Bu anı kalbimizde...", style: TextStyle(color: Colors.grey))
                  ],
                ))),

              const SizedBox(height: 20),
              Text(ani.aciklama, textAlign: TextAlign.center, style: GoogleFonts.nunito(fontSize: 18)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat")),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bizim Dünyamız 🌍", style: GoogleFonts.pacifico()),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _merkez,
              initialZoom: 10.0,
              onLongPress: (tapPosition, point) => _aniEkleDialog(point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.enes.sevgilime',
              ),
              PolylineLayer(polylines: _rotalariOlustur()),
              MarkerLayer(
                markers: _anilar.map((ani) {
                  return Marker(
                    point: ani.konum,
                    width: 50,
                    height: 50,
                    child: GestureDetector(
                      onTap: () => _aniGoster(ani),
                      child: const Icon(Icons.favorite, color: Colors.pink, size: 40),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          Positioned(
            top: 20, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.teal.withOpacity(0.3)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.teal),
                  SizedBox(width: 10),
                  Expanded(child: Text("Yeni bir anı eklemek için haritaya basılı tut!", style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  int _dogruSayisi = 0;
  int _yanlisSayisi = 0;
  bool _testBasladi = false;
  bool _testBitti = false;
  DateTime? _baslangicZamani;
  int _kaydedilenSureSaniye = 0;
  List<Map<dynamic, dynamic>> _gecmisSonuclar = [];

  // --- 80 SORULUK DEV LİSTE ---
  final List<Map<String, dynamic>> _sorular = [
    // TEMEL BİLGİLER
    {'soru': 'Doğum günüm tam olarak ne zaman?', 'secenekler': ['21 Ocak', '22 Ekim', '14 Şubat', '25 Aralık'], 'cevap': '25 Aralık'},
    {'soru': 'Ayakkabı numaram kaç?', 'secenekler': ['41', '42', '43', '44'], 'cevap': '44'},
    {'soru': 'Boyum tam olarak kaç?', 'secenekler': ['1.82', '1.84', '1.87', '1.85'], 'cevap': '1.85'},
    {'soru': 'Hangi burcum?', 'secenekler': ['Kova', 'Oğlak', 'Akrep', 'Aslan'], 'cevap': 'Oğlak'},
    {'soru': 'Göz rengim nedir?', 'secenekler': ['Kahverengi', 'Ela', 'Siyah', 'Yeşil'], 'cevap': 'Kahverengi'},
    {'soru': 'Doğduğum şehir neresi?', 'secenekler': ['Aksaray', 'Nevşehir', 'Ankara', 'Kayseri'], 'cevap': 'Nevşehir'},
    {'soru': 'En sevdiğim renk hangisi?', 'secenekler': ['Mavi', 'Siyah', 'Yeşil', 'Bordo'], 'cevap': 'Mavi'},
    {'soru': 'Şu anki kilom sence kaçtır?', 'secenekler': ['103', '100', '107', '105'], 'cevap': '105'},

    // YEMEK & İÇECEK
    {'soru': 'En sevdiğim yemek hangisi?', 'secenekler': ['Tavuk Pilav', 'İskender', 'Hamburger', 'Sarma'], 'cevap': 'Tavuk Pilav'},
    {'soru': 'Sabahları uyanınca ilk ne içerim?', 'secenekler': ['Su', 'Kahve', 'Çay', 'Portakal Suyu'], 'cevap': 'Su'},
    {'soru': 'Hangi tatlıya asla hayır diyemem?', 'secenekler': ['Fıstıklı Baklava', 'Cheesecake', 'Sütlaç', 'Künefe'], 'cevap': 'Künefe'},
    {'soru': 'Çayı nasıl içerim?', 'secenekler': ['Şekersiz', 'Tek şekerli', 'Çok şekerli', 'Limonlu'], 'cevap': 'Şekersiz'},
    {'soru': 'Pizza mı yoksa Hamburger mi?', 'secenekler': ['Pizza', 'Hamburger', 'İkisi de', 'Hiçbiri'], 'cevap': 'Hamburger'},
    {'soru': 'En sevdiğim meyve hangisidir?', 'secenekler': ['Elma', 'Muz', 'Çilek', 'Karpuz'], 'cevap': 'Karpuz'},
    {'soru': 'Acı yemekle aram nasıldır?', 'secenekler': ['Bayılırım', 'Hiç sevmem', 'Orta karar', 'Sadece isot yerim'], 'cevap': 'Orta karar'},
    {'soru': 'En sevdiğim içecek ?', 'secenekler': ['Kola', 'Ayran', 'Soğuk Çay', 'Meyve Suyu'], 'cevap': 'Soğuk Çay'},
    {'soru': 'Kahve seçimim genelde hangisidir?', 'secenekler': ['Türk Kahvesi', 'Latte', 'Americano', 'Filtre Kahve'], 'cevap': 'Latte'},
    {'soru': 'Sence en iyi yaptığım yemek nedir?', 'secenekler': ['Yumurta', 'Makarna', 'Menemen', 'Tavuk Sote'], 'cevap': 'Menemen'},

    // İLİŞKİ & ANILAR
    {'soru': 'Seni telefonuma ne diye kaydettim?', 'secenekler': ['Aşkım', 'MyLove🌸', 'Gülçin', 'Sevgilim'], 'cevap': 'MyLove🌸'},
    {'soru': 'En çok hangi özelliğini seviyorum?', 'secenekler': ['Gülüşün', 'Gözlerin', 'Zekan', 'Hepsi'], 'cevap': 'Gülüşün'},
    {'soru': 'Seninle en çok ne yapmayı seviyorum?', 'secenekler': ['Film izlemek(Öpmek)', 'Yürümek', 'Sohbet etmek', 'Yemek yemek'], 'cevap': 'Film izlemek(Öpmek)'},

    // KİŞİSEL ZEVKLER
    {'soru': 'En sevdiğim film türü nedir?', 'secenekler': ['Korku', 'Bilim Kurgu', 'Romantik Komedi', 'Aksiyon'], 'cevap': 'Bilim Kurgu'},
    {'soru': 'Hangi takımı tutuyorum?', 'secenekler': ['Galatasaray', 'Fenerbahçe', 'Beşiktaş', 'Takım tutmuyorum'], 'cevap': 'Beşiktaş'},
    {'soru': 'Piyangodan büyük ikramiye çıksa ilk ne alırım?', 'secenekler': ['Araba', 'Ev', 'Dünya Turu', 'Piyango almam haram'], 'cevap': 'Piyango almam haram'},
    {'soru': 'Hangi şehirde yaşamak isterim?', 'secenekler': ['İstanbul', 'İzmir', 'Yurtdışı', 'Topakkaya'], 'cevap': 'Topakkaya'},
    {'soru': 'En çok kullandığım kelime hangisi?', 'secenekler': ['Aynen', 'Zaten', 'Hallederiz', 'Bilmem'], 'cevap': 'Zaten'},
    {'soru': 'Favori oyunum hangisidir?', 'secenekler': ['Cs', 'GTA 5', 'Fifa', 'Red Dead Redemption 2'], 'cevap': 'Fifa'},
    {'soru': 'Hangi müzik türünü daha çok dinlerim?', 'secenekler': ['Pop', 'Rap', 'Rock', 'Arabesk'], 'cevap': 'Rap'},
    {'soru': 'Sence ben sabah insanı mıyım akşam mı?', 'secenekler': ['Sabah', 'Akşam', 'Gece kuşu', 'Hep uykulu'], 'cevap': 'Hep uykulu'},
    {'soru': 'Dışarı çıkmak mı evde oturmak mı?', 'secenekler': ['Dışarı', 'Evde oturmak', 'Seninle her yer', 'Uyuyalım'], 'cevap': 'Seninle her yer'},

    // DUYGUSAL
    {'soru': 'Enes sinirlendiğinde onu ne sakinleştirir?', 'secenekler': ['Yalnız kalmak', 'Sarılmak', 'Oyun oynamak', 'Müzik dinlemek'], 'cevap': 'Sarılmak'},
    {'soru': 'En büyük fobim ne?', 'secenekler': ['Yükseklik', 'Karanlık', 'Böcek', 'Yalnızlık'], 'cevap': 'Yükseklik'},
    {'soru': 'Kodum çalışmadığında genelde ne yaparım?', 'secenekler': ['Bilgisayarı kırarım', 'Sakince ararım', 'Sana sarılırım', 'Uyurum'], 'cevap': 'Sana sarılırım'},
    {'soru': 'Sence ben kıskanç mıyım?', 'secenekler': ['Evet', 'Hayır', 'Yerine göre', 'Asla'], 'cevap': 'Yerine göre'},
    {'soru': 'Yalan söylerken ne yaparım?', 'secenekler': ['Gülerim', 'Göz kaçırırım', 'Burnumu kaşırım', 'Yalan söylemem'], 'cevap': 'Yalan söylemem'},
    {'soru': 'En nefret ettiğim insan tipi?', 'secenekler': ['Yalancı', 'Saygısız', 'Cimri', 'Çok konuşan'], 'cevap': 'Saygısız'},
    {'soru': 'Bir tartışmada genelde nasılımdır?', 'secenekler': ['Çok bağırırım', 'Susarım', 'Mantıklı konuşurum', 'Biraz kızarım'], 'cevap': 'Biraz kızarım'},
    {'soru': 'Sence en zayıf noktam nedir?', 'secenekler': ['Ailem', 'Sen', 'Gelecek kaygısı', 'Yemek'], 'cevap': 'Sen'},
    {'soru': 'Küçükken ne olmak isterdim?', 'secenekler': ['Astronot', 'Özel Harekat Polisi', 'Futbolcu', 'Mühendis'], 'cevap': 'Özel Harekat Polisi'},
    {'soru': 'Hayattaki en büyük hayalim nedir?', 'secenekler': ['Zengin olmak', 'Başarılı bir mühendis olmak', 'Seninle yaşlanmak', 'Dünyayı gezmek'], 'cevap': 'Seninle yaşlanmak'},

    // TEKNOLOJİ
    {'soru': 'Windows mu macOS mu?', 'secenekler': ['Windows', 'macOS', 'Linux', 'Android'], 'cevap': 'Windows'},
    {'soru': 'Bilgisayar başında en çok ne yaparım?', 'secenekler': ['Kod yazarım', 'Oyun oynarım', 'Video izlerim', 'Sana bakarım'], 'cevap': 'Kod yazarım'},
    {'soru': 'Günde kaç saat bilgisayara bakıyorumdur?', 'secenekler': ['2-4', '5-8', '10+', 'Hiç'], 'cevap': '5-8'},


    // TATİL & MEVSİM
    {'soru': 'Deniz tatili mi Kültür turu mu?', 'secenekler': ['Deniz', 'Kültür', 'Dağ evi', 'Evimiz'], 'cevap': 'Dağ evi'},
    {'soru': 'Kış mı Yaz mı?', 'secenekler': ['Kış', 'Yaz', 'Bahar', 'Hepsi'], 'cevap': 'Bahar'},
    {'soru': 'En sevdiğim hayvan?', 'secenekler': ['Kedi', 'Köpek', 'Aslan', 'Kuş'], 'cevap': 'Kedi'},
    {'soru': 'Gece mi Gündüz mü?', 'secenekler': ['Gece', 'Gündüz', 'Şafak vakti', 'Alacakaranlık'], 'cevap': 'Gündüz'},
    {'soru': 'En sevdiğim mevsim?', 'secenekler': ['İlkbahar', 'Yaz', 'Sonbahar', 'Kış'], 'cevap': 'İlkbahar'},
    {'soru': 'Issız bir adaya düşsem yanıma alacağım ilk şey?', 'secenekler': ['Bilgisayar', 'Sen', 'Yemek', 'Bıçak'], 'cevap': 'Sen'},

    // GELECEK
    {'soru': 'Kaç çocuğumuz olsun isterdim?', 'secenekler': ['1', '2', '3', 'Kedi alalım'], 'cevap': '2'},
    {'soru': 'Düğünümüz nerede olsun isterim?', 'secenekler': ['Kır düğünü', 'Otel', 'Sahil', 'Sade bir nikah'], 'cevap': 'Kır düğünü'},
    {'soru': 'Gelecekteki arabamın markası ne olsun?', 'secenekler': ['Tesla', 'BMW', 'Audi', 'Mercedes'], 'cevap': 'Audi'},
    {'soru': 'Yaşlanınca nerede yaşayalım?', 'secenekler': ['Köyde(Topakkaya)', 'Sahil kasabasında', 'Yurtdışında', 'Aynı yerimizde'], 'cevap': 'Köyde(Topakkaya)'},
    {'soru': 'Emeklilik hayalim nedir?', 'secenekler': ['Bahçe işleri', 'Dünya turu', 'Kod yazmaya devam', 'Seninle huzur'], 'cevap': 'Seninle huzur'},

    // KARMA
    {'soru': 'En sevdiğim çiçek hangisidir?', 'secenekler': ['Gül', 'Papatya', 'Lale', 'Orkide'], 'cevap': 'Orkide'},
    {'soru': 'Sence ben sabırlı biri miyim?', 'secenekler': ['Evet', 'Hayır', 'Sana karşı evet', 'Bazen'], 'cevap': 'Evet'},
    {'soru': 'En sevdiğim aksesuarım?', 'secenekler': ['Saat', 'Yüzük', 'Zincir Kolye', 'Gözlük'], 'cevap': 'Zincir Kolye'},
    {'soru': 'En son hangi tür kitap okudum?', 'secenekler': ['Roman', 'Teknik Kitap', 'Kişisel Gelişim', 'Okumadım'], 'cevap': 'Okumadım'},
    {'soru': 'En güçlü yönüm nedir?', 'secenekler': ['Zekam', 'Merhametim', 'Azmim', 'Sakinliğim'], 'cevap': 'Sakinliğim'},
    {'soru': 'Hangi parfüm kokusunu severim?', 'secenekler': ['Odunsu', 'Şekerli', 'Ferah', 'Baharatlı'], 'cevap': 'Ferah'},
    {'soru': 'Uykum gelince ne yaparım?', 'secenekler': ['Huysuzlaşırım', 'Hemen uyurum', 'Daha çok konuşurum', 'Sana sarılırım'], 'cevap': 'Sana sarılırım'},
    {'soru': 'Sence en büyük yeteneğim ne?', 'secenekler': ['Kod yazmak', 'Problem çözmek', 'Seni sevmek', 'Hepsi'], 'cevap': 'Hepsi'},
    {'soru': 'En sevdiğim dizi hangisi?', 'secenekler': ['Breaking Bad', 'Prison Break', 'Behzat Ç', 'Kurtlar Vadisi'], 'cevap': 'Kurtlar Vadisi'},
    {'soru': 'Seni ne kadar çok seviyorum?', 'secenekler': ['Çok', 'Dünyalar kadar', 'Sonsuza kadar', 'Kelimeler yetmez'], 'cevap': 'Kelimeler yetmez'},
    {'soru': 'Hangi konuda genelde senin fikrine güvenir, senden yardım isterim?', 'secenekler': ['Giyim ve Kombin', 'Kod yazma', 'Matematik', 'Bilgisayar toplama'], 'cevap': 'Giyim ve Kombin'},
    {'soru': 'Benim gözümde senin en tatlı halin hangisidir?', 'secenekler': ['Bana içten gülerkenki halin', 'Süslenip püslendiğin halin', 'Uyeni uyandığın halin', 'Bana sinirlendiğin halin'], 'cevap': 'Bana içten gülerkenki halin'},
    {'soru': 'Sabah alarm ilk çaldığında genelde ne yaparım?', 'secenekler': ['Hemen uyanırım', '5 dakika daha diye ertelerim', 'Alarmı kapatıp uyumaya devam ederim', 'Duvara fırlatırım'], 'cevap': '5 dakika daha diye ertelerim'},
    {'soru': 'Hasta olduğumda ne kadar nazlıyımdır?', 'secenekler': ['Hiç nazlanmam', 'Biraz ilgi beklerim', 'Dünyanın sonu gelmiş gibi davranırım', 'Sadece sen varsan nazlanırım'], 'cevap': 'Sadece sen varsan nazlanırım'},
    {'soru': 'Gece uyumadan önce yatakta en son ne yaparım?', 'secenekler': ['Sosyal medyada gezinirim', 'Tavana bakıp hayatı sorgularım', 'Sana iyi geceler yazarım', 'Alarmı 10 kere kontrol ederim'], 'cevap': 'Sana iyi geceler yazarım'},
    {'soru': 'Eğer bir günlüğüne bir süper gücüm olsaydı hangisini seçerdim?', 'secenekler': ['Uçmak', 'Görünmez olmak', 'Zamanı durdurmak (özellikle seninleyken)', 'Zihin okumak'], 'cevap': 'Zamanı durdurmak (özellikle seninleyken)'},
    {'soru': 'Birlikte uzun bir yolculuğa çıksak arabada müzik seçimini kim yapar?', 'secenekler': ['Kesinlikle ben', 'Sen ne istersen o çalar', 'Radyo dinleriz', 'Sırayla açarız'], 'cevap': 'Radyo dinleriz'},
  ];

  @override
  void initState() {
    super.initState();
    _sonuclariDinle();
    _yarimKalanTestiKontrolEt();
  }

  // --- KESİNTİYE UĞRAYAN TEST KONTROLÜ ---
  Future<void> _yarimKalanTestiKontrolEt() async {
    final prefs = await SharedPreferences.getInstance();
    final kayitliIndex = prefs.getInt('soruIndex') ?? 0;

    if (kayitliIndex > 0 && kayitliIndex < _sorular.length) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Yarım Kalan Test 🧐", style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.indigo)),
          content: Text("Daha önce ${kayitliIndex + 1}. soruda kalmışsın. Kaldığın yerden mi devam etmek istersin, yoksa baştan mı başlayalım?"),
          actions: [
            TextButton(
              onPressed: () {
                _hafizayiTemizle();
                Navigator.pop(context);
              },
              child: const Text("Baştan Başla", style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                setState(() {
                  _soruIndex = kayitliIndex;
                  _dogruSayisi = prefs.getInt('dogruSayisi') ?? 0;
                  _kaydedilenSureSaniye = prefs.getInt('gecenSure') ?? 0;
                  _testBasladi = true;
                  _baslangicZamani = DateTime.now(); // Kronometreyi yeniden başlat
                });
                Navigator.pop(context);
              },
              child: const Text("Devam Et", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _ilerlemeyiKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('soruIndex', _soruIndex);
    await prefs.setInt('dogruSayisi', _dogruSayisi);

    // Geçen süreyi de kaydedelim ki geri döndüğünde süre sıfırlanmasın
    if (_baslangicZamani != null) {
      final anlikSure = DateTime.now().difference(_baslangicZamani!).inSeconds;
      await prefs.setInt('gecenSure', _kaydedilenSureSaniye + anlikSure);
    }
  }

  Future<void> _hafizayiTemizle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('soruIndex');
    await prefs.remove('dogruSayisi');
    await prefs.remove('gecenSure');
  }

  void _sonuclariDinle() {
    _dbRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        List<Map<dynamic, dynamic>> sonuclar = [];
        data.forEach((key, value) => sonuclar.add(value));
        sonuclar.sort((a, b) => b['tarih'].compareTo(a['tarih']));
        if (mounted) setState(() => _gecmisSonuclar = sonuclar);
      }
    });
  }

  void _testiBaslat() {
    _hafizayiTemizle(); // Yeni teste başlarken eski kalıntıları sil
    setState(() {
      _testBasladi = true;
      _testBitti = false;
      _soruIndex = 0;
      _dogruSayisi = 0;
      _yanlisSayisi = 0;
      _skor = 0;
      _kaydedilenSureSaniye = 0;
      _baslangicZamani = DateTime.now();
    });
  }

  void _cevapKontrol(String secilenCevap) {
    if (secilenCevap == _sorular[_soruIndex]['cevap']) {
      _dogruSayisi++;
    }

    if (_soruIndex < _sorular.length - 1) {
      setState(() => _soruIndex++);
      _ilerlemeyiKaydet(); // Her soruda ilerlemeyi local'e kaydet
    } else {
      _testiBitir();
    }
  }

  void _testiBitir() {
    final bitisZamani = DateTime.now();
    final sonOturumSuresi = bitisZamani.difference(_baslangicZamani!).inSeconds;
    final toplamSure = _kaydedilenSureSaniye + sonOturumSuresi;

    _yanlisSayisi = _sorular.length - _dogruSayisi;
    _skor = ((_dogruSayisi / _sorular.length) * 100).round();

    setState(() => _testBitti = true);
    _hafizayiTemizle(); // Test tamamen bitti, hafızayı temizle

    _dbRef.push().set({
      'skor': _skor,
      'dogruSayisi': _dogruSayisi,
      'yanlisSayisi': _yanlisSayisi,
      'toplamSoru': _sorular.length,
      'sureSaniye': toplamSure,
      'tarih': bitisZamani.toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("Beni Tanıyor Musun? 🧐", style: GoogleFonts.pacifico()),
        centerTitle: true,
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: !_testBasladi
          ? _buildGirisEkrani()
          : _testBitti
          ? _buildSonucEkrani()
          : _buildSoruEkrani(),
    );
  }

  Widget _buildGirisEkrani() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.favorite, size: 80, color: Colors.redAccent),
            const SizedBox(height: 20),
            Text(
              "Hoş Geldin Gülçin!",
              style: GoogleFonts.nunito(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 10),
            Text(
              "Tam ${_sorular.length} soruluk dev maratona hazır mısın?",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: _testiBaslat,
              child: const Text("Maratonu Başlat ❤️", style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
            const SizedBox(height: 30),
            const Divider(),
            Text("Geçmiş Performansların 📊", style: GoogleFonts.nunito(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: _gecmisSonuclar.isEmpty
                  ? const Center(child: Text("Henüz test çözülmedi. İlkini sen yap!"))
                  : ListView.builder(
                itemCount: _gecmisSonuclar.length,
                itemBuilder: (context, index) {
                  final s = _gecmisSonuclar[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: s['skor'] > 80 ? Colors.green : Colors.orange,
                        child: Text("${s['skor']}", style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      title: Text("${s['dogruSayisi']} Doğru, ${s['yanlisSayisi'] ?? 0} Yanlış"),
                      subtitle: Text(s['tarih'].toString().substring(0, 16).replaceAll("T", " ")),
                      trailing: Text("${s['sureSaniye']} sn"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoruEkrani() {
    final soru = _sorular[_soruIndex];
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Soru ${_soruIndex + 1} / ${_sorular.length}", style: const TextStyle(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(10)),
                child: Text("Kayıtlı ✔️", style: TextStyle(color: Colors.indigo.shade300, fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (_soruIndex + 1) / _sorular.length,
            color: Colors.indigo,
            backgroundColor: Colors.indigo.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 40),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.1), blurRadius: 10)],
              ),
              child: SingleChildScrollView(
                child: Text(
                  soru['soru'],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          ...List.generate(soru['secenekler'].length, (index) {
            final secenek = soru['secenekler'][index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Colors.indigo, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                onPressed: () => _cevapKontrol(secenek),
                child: Text(secenek, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSonucEkrani() {
    String finalMesaj = _skor == 100
        ? "İNANILMAZ! Beni benden daha iyi tanıyorsun. Tapu benim üzerime ama kalp senin! ❤️"
        : _skor >= 80
        ? "Harikasın! Ufak detayları da yakalarsan tam bir uzman olacaksın. 😘"
        : "Fena değil, ama biraz daha çalışman lazım güzelim. Gel bir sarılalım! 🤗";

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Test Tamamlandı! 🎉", style: GoogleFonts.pacifico(fontSize: 28, color: Colors.indigo)),
            const SizedBox(height: 30),

            // SKOR KARTI
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Text("BAŞARI YÜZDESİ", style: TextStyle(color: Colors.grey.shade600, letterSpacing: 2)),
                  Text("%$_skor", style: GoogleFonts.bebasNeue(fontSize: 60, color: Colors.indigo)),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 30),
                          const SizedBox(height: 5),
                          Text("$_dogruSayisi Doğru", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.cancel, color: Colors.redAccent, size: 30),
                          const SizedBox(height: 5),
                          Text("$_yanlisSayisi Yanlış", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),
            Text(
              finalMesaj,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text("Ana Sayfaya Dön"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () => setState(() => _testBasladi = false),
            ),
          ],
        ),
      ),
    );
  }
}
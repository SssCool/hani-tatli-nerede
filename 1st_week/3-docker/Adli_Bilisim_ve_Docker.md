# Adli Bilişimde Konteyner Teknolojisinin Yeri

Docker ve konteyner teknolojileri, sadece yazılım geliştiriciler için değil, siber güvenlik uzmanları ve adli bilişim analistleri için de oyunun kurallarını değiştiren yetenekler sunar. Bu alandaki kullanım, "Yazılım Dağıtımı"ndan ziyade "Güvenli ve İzole Analiz" odaklıdır.

## 1. Zararlı Yazılım Analizi (Malware Analysis) ve İzolasyon

Şüpheli bir dosyanın (Malware) analiz edilmesi, yüksek riskli bir işlemdir. Zararlı yazılım, çalıştığı sistemi enfekte edebilir, verileri şifreleyebilir veya kendini ağ üzerinden yayabilir.

### Geleneksel Yöntem (Sanal Makine)
Eskiden her analiz için sıfır bir Sanal Makine (VM) imajı geri yüklenirdi. Bu işlem hem diskte çok yer kaplar hem de geri yükleme süresi (Snapshot Restore) zaman alırdı.

### Konteyner Yöntemi (Sandbox)
Docker konteynerleri, saniyeler içinde ayağa kalkan ve işi bitince tamamen yok edilebilen izole ortamlar sağlar.
*   **Atılabilir Ortamlar (Disposable):** Analiz scripti çalışır, rapor üretilir ve konteyner kapatıldığı anda her şey silinir. Bir sonraki analiz yine %100 temiz bir ortamda başlar.
*   **Ağ İzolasyonu:** Konteynerin ağ erişimi tamamen kapatılabilir (`network: none`) veya sadece belirli portlara izin verilerek zararlının dışarıya (Command & Control sunucusuna) sinyal göndermesi izlenebilir/engellenebilir.

---

## 2. Kanıt Bütünlüğü ve Tekrarlanabilirlik

Adli bilişimde en önemli ilke, elde edilen bulguların "tekrarlanabilir" olmasıdır. Yani A uzmanı bir analiz yaptığında hangi sonucu buluyorsa, B uzmanı da (veya mahkeme bilirkişisi de) aynı araçlarla aynı sonucu bulabilmelidir.

*   **Versiyon Kaosu:** Geleneksel yöntemlerde, analistin bilgisayarındaki Python sürümü, kütüphane versiyonu veya işletim sistemi güncellemesi, analiz aracının sonucunu değiştirebilir.
*   **Konteyner Çözümü:** Analiz araçları (Volatility, Autopsy, Plaso) bir kez Docker İmajı olarak paketlendiğinde, "Değiştirilemez" (Immutable) olur. Bu imaj 5 yıl sonra da çalıştırılsa, dünyanın öbür ucunda da çalıştırılsa, bit-bit aynı kütüphaneleri kullanır ve aynı sonucu üretir. Bu, mahkemede delil güvenilirliği açısından kritik bir argümandır.

---

## 3. Taşınabilir Olay Müdahale Kitleri (Forensics-in-a-Box)

Siber olay müdahale ekipleri (SOME), genellikle olay yerine (müşteri, şube, veri merkezi) gitmek zorundadır.

*   **Sorun:** Olay yerindeki bilgisayarlara analiz yazılımı kurmak zaman alır, sistemde iz bırakır (Artifact) ve bazen internet erişimi veya yetki kısıtlamaları nedeniyle mümkün olmaz.
*   **Çözüm:** Analist, yanında getirdiği USB bellekte veya taşınabilir diskte önceden hazırlanmış Docker imajlarını (Toolkit) bulundurur. Olay yerindeki herhangi bir makinede (Docker yüklü olması yeterlidir) tek komutla tüm laboratuvar ortamını ayağa kaldırabilir. Hiçbir kurulum yapmadan, sistem kütüphanelerini kirletmeden analiz yapabilir.

---

## 4. Büyük Veri ve Ölçeklenebilir Tarama (OSINT)

Açık Kaynak İstihbaratı (OSINT) veya Dark Web taramalarında milyonlarca veri noktasının (Web sitesi, IP, Forum girdisi) taranması gerekir.

*   **Sorun:** Tek bir bilgisayarın işlem gücü ve bant genişliği bu taramalar için yetersizdir.
*   **Çözüm (Orkestrasyon):** Tarama botları konteyner haline getirilir. Kubernetes gibi bir orkestrasyon aracı ile yüzlerce, hatta binlerce "Bot Konteyner" aynı anda başlatılır. İş yükü parçalanır ve paralel olarak işlenir. Bu sayede aylar sürecek bir veri toplama işi saatler içinde tamamlanabilir.

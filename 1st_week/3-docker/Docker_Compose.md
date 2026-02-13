# Docker Compose ve Orkestrasyon Mantığı

Modern uygulamalar nadiren tek bir parçadan oluşur. Genellikle bir web arayüzü, bir veritabanı, bir önbellek (cache) sunucusu ve belki bir mesaj kuyruğu servisi birlikte çalışır. Docker CLI (`docker run`) ile bu kadar çok parçayı tek tek yönetmek, ağlarını bağlamak ve sıralı başlatmak operasyonel bir kabustur.

**Docker Compose**, çoklu konteyner (Multi-Container) uygulamalarını tanımlamak ve çalıştırmak için kullanılan bir araçtır.

## 1. Bildirimsel (Declarative) Yönetim
Compose, "Nasıl yapılacak?" yerine "Ne istiyorum?" mantığıyla çalışır. Tüm sistem mimarisi `docker-compose.yml` adlı bir dosyada tarif edilir. Siz sadece "Sistemi ayağa kaldır" dersiniz, Compose gerekli tüm ağları, diskleri ve konteynerleri doğru sırayla oluşturur.

---

## 2. YAML Dosya Yapısı ve Bileşenleri
Compose dosyası hiyerarşik bir yapıya sahiptir ve üç ana bölümden oluşur:

### A. Servisler (Services)
Uygulamanın çalışan parçalarıdır (Konteynerler). Her servis için şunlar tanımlanır:
*   **Build/Image:** Hangi imajın kullanılacağı veya Dockerfile'ın nerede olduğu.
*   **Networks:** Hangi sanal ağlara bağlanacağı.
*   **Volumes:** Verilerin nerede saklanacağı.
*   **Environment:** Veritabanı şifresi gibi ortam değişkenleri.
*   **Depends_on:** Başlatma sırası. "Veritabanı başlamadan Web servisini başlatma" gibi kurallar burada yazılır.

### B. Ağlar (Networks)
Servislerin birbirleriyle nasıl konuşacağını belirler.
*   Compose, varsayılan olarak proje için özel bir sanal ağ oluşturur ve tüm servisleri buraya ekler. Bu sayede servisler birbirlerine IP adresi yerine **isimleriyle** (DNS Resolution) ulaşabilirler.
*   Örneğin; Web servisi, veritabanına bağlanmak için IP aramaz, sadece `db_server` ismini kullanır.

### C. Depolama (Volumes)
Verilerin kalıcılığını yönetir. Konteyner silinse bile veritabanı dosyalarının kaybolmaması için, verilerin sunucu (Host) tarafında saklanacağı alanlar burada tanımlanır.

---

## 3. Yaşam Döngüsü Yönetimi
Docker Compose, uygulamanın tüm yaşam döngüsünü tek komutlarla yönetmeyi sağlar:

*   **Başlatma (Up):** İmajları indirir/oluşturur, ağları kurar, disk alanlarını bağlar ve konteynerleri başlatır.
*   **Durdurma (Stop):** Konteynerleri nazikçe kapatır (SIGTERM) ama silmez.
*   **İndirme (Down):** Konteynerleri durdurur ve **siler**. Ayrıca oluşturduğu sanal ağları da temizler. (Varsayılan olarak verileri/Volume'ları silmez).
*   **Yeniden Oluşturma (Recreate):** Eğer konfigürasyonda bir değişiklik yaptıysanız, Compose sadece değişen servisi tespit eder ve onu günceller; diğerlerine dokunmaz.

Bu yapı, özellikle geliştirme ortamlarında ve test süreçlerinde büyük hız kazandırır. Karmaşık bir mikroservis mimarisini tek bir dosya ile herkesin bilgisayarında birebir aynı şekilde (reproducible) ayağa kaldırmak mümkündür.

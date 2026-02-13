# Docker Temelleri ve Konteyner Mimarisi

## 1. Konteyner Teknolojisinin Özü
Konteynerleştirme, bir uygulamanın çalışması için gereken kod, kütüphane, sistem araçları ve ayarların tek bir paket (Image) haline getirilmesidir. Bu teknoloji, yazılımın bir bilgisayardan diğerine taşındığında güvenilir bir şekilde çalışmasını garanti altına alır.

### Sanal Makine (VM) ile Temel Farklar
Geleneksel sanallaştırmada (VM), her bir sanal makine donanımı sanallaştırır ve üzerinde tam teşekküllü bir İşletim Sistemi (Guest OS) barındırır. Bu durum, her uygulama için GB'larca disk alanı ve ciddi RAM/CPU rezervasyonu gerektirir.

Docker konteynerleri ise **İşletim Sistemi Çekirdeğini (Kernel)** paylaşır. Donanımı değil, işletim sistemini sanallaştırır.
*   **Hafiflik:** Konteynerler MB'lar seviyesindedir çünkü içlerinde Windows veya Linux çekirdeği yoktur; sunucunun çekirdeğini ödünç kullanırlar.
*   **Hız:** Bir İşletim Sistemi önyüklemesi (Boot) gerekmediği için saniyeler içinde başlarlar. Sadece uygulamanın süreci (Process) başlatılır.

---

## 2. Docker Mimarisi ve Bileşenleri
Docker, istemci-sunucu (Client-Server) mimarisini temel alır. Bu yapı, geliştiricinin komut verdiği yer ile işin yapıldığı yeri ayırır.

### A. Docker Daemon (Dockerd)
Sistemin kalbidir. Arka planda sürekli çalışan bir servistir. Docker API isteklerini dinler ve imajları, konteynerleri, ağları yönetir. Tüm ağır işçiliği bu servis yapar.

### B. Docker Client (CLI)
Kullanıcıların Docker ile etkileşime girdiği komut satırı aracıdır (`docker run`, `docker build`). İstemci, kullanıcının komutlarını Docker API formatına çevirir ve Daemon'a iletir.

### C. Docker Registry (Kayıt Defteri)
İmajların saklandığı ve dağıtıldığı depolardır. GitHub'ın kod saklaması gibi, Docker Registry de imaj saklar.
*   **Docker Hub:** Dünyadaki en büyük halka açık kütüphanedir.
*   **Private Registry:** Kurumların kendi iç ağlarında barındırdıkları, dışarıya kapalı depolardır (Adli bilişim araçları burada tutulur).

---

## 3. Temel Yapı Taşları

### A. İmaj (Image): Değiştirilemez Şablon
İmaj, bir uygulamanın "dondurulmuş" halidir. Salt okunurdur (Read-Only). İçinde kod, kütüphaneler, ortam değişkenleri ve yapılandırma dosyaları katmanlar (Layers) halinde bulunur.
*   Bir imaj, nesne tabanlı programlamadaki **Sınıf (Class)** yapısına benzer.
*   Bir kez oluşturulduğunda içeriği değiştirilemez. Değişiklik yapmak için yeni bir versiyonunun (Build) oluşturulması gerekir.

### B. Konteyner (Container): Çalışan Örnek
Konteyner, imajın çalıştırılabilir, canlı halidir. İmajın üzerine ince bir "yazılabilir katman" (Read-Write Layer) eklenerek oluşturulur.
*   Bir imajdan sınırsız sayıda konteyner türetilebilir.
*   Konteyner silindiğinde, eğer kalıcı bir depolama alanı (Volume) tanımlanmadıysa, içinde üretilen tüm geçici veriler kaybolur.

### C. İzolasyon Teknolojileri (Under the Hood)
Docker'ın güvenli ve izole çalışmasını sağlayan iki temel Linux çekirdek özelliği vardır:

1.  **Namespaces (İsim Alanları):** Görünürlüğü kısıtlar. Konteyner içindeki bir süreç, sanki sunucudaki tek süreçmiş gibi hisseder. Kendi işlem numaralarına (PID), kendi ağ arayüzüne (Network) ve kendi dosya sistemine (Mount) sahiptir. Yanındaki konteyneri veya sunucuyu göremez.
2.  **Cgroups (Control Groups):** Kaynak kullanımını kısıtlar. Bir konteynerin sunucunun RAM'inin tamamını veya CPU'sunun %100'ünü kullanmasını engeller. Bu sayede "gürültülü komşu" (Noisy Neighbor) problemi önlenir.

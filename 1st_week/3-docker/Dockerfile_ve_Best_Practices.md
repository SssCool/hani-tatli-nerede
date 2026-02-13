# Dockerfile Yapısı ve İmaj Oluşturma Mantığı

Dockerfile, bir uygulamanın sıfırdan nasıl kurulacağını, hangi kütüphanelere ihtiyaç duyduğunu ve nasıl çalıştırılacağını adım adım tarif eden metin tabanlı bir reçetedir. Docker motoru bu dosyayı satır satır okuyarak otomatik olarak bir İmaj (Image) üretir.

## 1. Temel Talimatlar ve Anlamları

### BAŞLANGIÇ: "Neyin Üzerine İnşa Ediyoruz?" (`FROM`)
Her Docker imajı, başka bir temel imajın üzerine kurulur. Bu, işletim sisteminin çekirdeği değil, kullanıcı alanı (Userland) dosyalarıdır.
*   Örnek: `FROM python:3.9` dediğimizde, içinde Linux dosya sistemi ve Python kurulu hazır bir ortamı taban alırız.

### HAZIRLIK: "Ortamı Ayarlama" (`WORKDIR`, `COPY`, `ADD`)
*   **WORKDIR:** Tıpkı `cd` komutu gibi, konteyner içinde çalışılacak klasörü belirler. Sonraki tüm komutlar bu klasör içinde çalışır.
*   **COPY:** Kendi bilgisayarımızdaki dosyaları (kaynak kodları), imajın içine kopyalar.
*   **ADD:** COPY ile benzerdir ancak yetenekleri fazladır; internetten dosya indirebilir veya sıkıştırılmış (tar.gz) dosyaları otomatik açabilir. Güvenlik ve öngörülebilirlik açısından genellikle `COPY` tercih edilir.

### KURULUM: "Bağımlılıkları Yükleme" (`RUN`)
İmaj oluşturulurken (Build time) çalıştırılan komutlardır. Kütüphane yüklemek (`apt-get install`, `pip install`) veya dosya izinlerini değiştirmek için kullanılır.
*   Her `RUN` komutu imaj üzerinde kalıcı bir katman oluşturur. Bu yüzden komutlar genellikle `&&` ile birleştirilerek tek satırda yazılır (Katman sayısını azaltmak için).

### ÇALIŞTIRMA: "Konteyner Başlayınca Ne Olsun?" (`CMD` vs `ENTRYPOINT`)
Bu komutlar imaj oluşturulurken DEĞİL, imajdan bir konteyner başlatıldığında (Runtime) çalışır.
*   **CMD (Command):** Varsayılan çalıştırma komutudur. Kullanıcı isterse konteyneri başlatırken bu komutu ezebilir (Override). Genellikle web sunucusunu başlatmak için kullanılır.
*   **ENTRYPOINT:** Konteynerin ana karakterini belirler. Kullanıcı ne parametre girerse girsin bu komut çalışır, kullanıcının girdisi argüman olarak eklenir. Konteyneri bir "komut satırı aracı" (CLI Tool) gibi tasarlamak isterseniz bu kullanılır.

---

## 2. Katmanlı Dosya Sistemi (Layered Architecture)
Docker'ın en güçlü özelliklerinden biri katmanlı yapısıdır. Dockerfile içindeki her komut yeni bir katman oluşturur.
*   **Değişmezlik:** Oluşan katmanlar salt okunurdur.
*   **Önbellek (Caching):** Bir imajı tekrar oluştururken, Docker değişmeyen satırları (katmanları) tekrar çalıştırmaz, hafızadan getirir. Bu sayede 10 dakikalık derleme süresi saniyelere iner.
*   **Strateji:** Bu yüzden Dockerfile yazarken "az değişen" komutlar (Sistem kütüphaneleri) üste, "çok değişen" komutlar (Kaynak kodlar) alta yazılır.

## 3. Çok Aşamalı İnşa (Multi-Stage Build)
Prodüksiyon ortamları için imaj boyutunu küçültmek hayati önem taşır. Derleme gerektiren dillerde (Go, Java, C++) kaynak kod ve derleyici araçları (Compiler) sadece "inşa" aşamasında gereklidir; çalışan uygulamada bunlara ihtiyaç yoktur.

Multi-Stage Build, tek bir Dockerfile içinde birden fazla geçici imaj kullanmamızı sağlar:
1.  **Builder Aşaması:** Tüm derleme araçlarını içeren büyük bir imaj kullanılır. Kod derlenir (`app.exe` oluşur).
2.  **Runner Aşaması:** Çok küçük (Alpine gibi) bir imaj seçilir. Sadece ilk aşamada üretilen `app.exe` dosyası buraya kopyalanır.
3.  **Sonuç:** Kaynak kodların ve derleyicilerin olmadığı, sadece çalışan uygulamanın olduğu, 1 GB yerine 20 MB'lık güvenli ve hafif bir imaj elde edilir.

# CI/CD: Modern Yazılım Üretim Bandı

Yazılım geliştirme süreci artık sanayi devrimindeki "Üretim Bandı" (Assembly Line) mantığına evrilmiştir. Bu bandın adı **Pipeline**'dır.

## 1. Kavramsal Derinlik: CI ve CD

### Continuous Integration (Sürekli Entegrasyon)
"Entegrasyon Cehennemi"ni (Integration Hell) önlemek için icat edilmiştir. Eskiden geliştiriciler haftalarca kendi bilgisayarlarında (Local) çalışır, ay sonunda kodlarını birleştirmeye çalışırlardı. Sonuç: Çakışan dosyalar, patlayan sistemler.

**CI'ın Kuralları:**
1.  **Tek Kaynak:** Herkes kodunu `Main` (veya Master) dalına günde en az bir kez gönderir.
2.  **Otomasyon:** Her `push` işlemi bir "Build" ve "Test" sürecini tetikler.
3.  **Hızlı Geri Bildirim:** Eğer kod bozuksa, sistem 5 dakika içinde geliştiriciye "Kodu Bozdun!" diye bağırır (Mail/Slack).

**CI Pipeline Çıktısı (Artifact):**
CI süreci başarılı olursa elinizde "çalıştığı kanıtlanmış" bir paket olur. Bu bir `.jar` dosyası, bir `.exe` veya modern dünyada bir **Docker Image**'ıdır.

### Continuous Delivery vs Deployment
Bu iki kavram sıkça karıştırılır. Farkı "İnsan Faktörü"dür.

1.  **Continuous Delivery (Teslimat):**
    *   Kod, CI sürecinden geçer.
    *   Test ortamına (Staging) otomatik yüklenir.
    *   Canlı ortama (Production) yüklenmeye **Hazen** durumdadır.
    *   **Ancak:** Bir yönetici "Deploy" butonuna basmadan canlıya gitmez. (Bizim kuracağımız yapı genelde budur).

2.  **Continuous Deployment (Dağıtım):**
    *   Fren yoktur. Testleri geçen kod, saniyeler içinde müşterinin önüne çıkar.
    *   Facebook, Netflix, Amazon bu yöntemi kullanır. Günde binlerce kez canlıya çıkarlar.

---

## 2. Pipeline Mimarisi ve Geri Bildirim Döngüsü

İyi bir Pipeline sadece "iş yapan" değil, aynı zamanda "haber veren" bir yapıdır.

**GitLab <-> Jenkins Dansı:**
1.  **Trigger (Tetik):** Geliştirici GitLab'a kodu yazar (`git push`).
2.  **Webhook:** GitLab, Jenkins'e "Hey, yeni kod geldi!" diye bir HTTP isteği atar.
3.  **Checkout:** Jenkins kodu kendi üzerine çeker.
4.  **Feedback (Running):** Jenkins, GitLab'a dönüp "İşi aldım, çalışıyorum" der. GitLab'da commit'in yanında sarı bir daire döner.
5.  **Execution:** Testler, Güvenlik Taramaları, Build işlemleri yapılır.
6.  **Feedback (Success/Fail):**
    *   İşlem bittiğinde Jenkins GitLab'a "Başarılı" (Yeşil Tik) veya "Hatalı" (Kırmızı Çarpı) bilgisini döner.
    *   Geliştirici GitLab arayüzünden hatayı görür ve düzeltir.

---

## 3. Deployment Stratejileri

Pipeline'ın son aşaması olan "Deploy" (Dağıtım) için farklı stratejiler vardır:

*   **Recreate:** Eski konteyneri sil, yenisini başlat. (Kesinti olur, ama basittir). Bizim `backend-push` projesinde kullanacağımız yöntem budur.
*   **Rolling Update:** 10 sunucun varsa, sırayla birini indirip yenisini kur. Hizmet kesilmez. (Kubernetes varsayılanı).
*   **Blue/Green:** Canlı sistemin (Blue) aynısından bir tane daha (Green) kur. Trafiği bir anda Green'e yönlendir. Hata varsa Blue'ya geri dön.

# Git Stratejileri: Branching, Merge ve Çatışma Yönetimi

## 1. Branching Stratejileri (Akış Modelleri)

### A. GitHub Flow (Basit & Hızlı)
Genellikle CI/CD süreçlerinin hızlı olduğu modern ekiplerde kullanılır.
1.  `main` dalı her zaman deploy edilebilir durumdadır.
2.  Yeni iş için daldan ayrıl (`feature/login`).
3.  Commitler at, işi bitir.
4.  Pull Request aç, onay al.
5.  `main` dalına merge et ve **hemen deploy et**.

### B. Git Flow (Geleneksel & Katı)
Daha kontrollü sürümler (Release) çıkaran projeler için.
*   `master`: Sadece ürün (Production) sürümleri.
*   `develop`: Geliştirme dalı, özellikler burada birleşir.
*   `feature/*`: Develop'tan ayrılır, Develop'a döner.
*   `release/*`: Sürüm hazırlığı (v1.0).
*   `hotfix/*`: Acil üretim hataları için master'dan çıkıp master'a döner.

---

## 2. Merge Türleri (Birleştirme Mantığı)

### A. Merge Commit (Standart)
Tarihçeyi olduğu gibi korur. "Burada bir birleşme oldu" diye ek bir commit atar.
*   **Artısı:** Gerçek tarihçeyi (kim ne zaman ne yaptı) tam gösterir.
*   **Eksisi:** Tarihçe çok kalabalık ve "kirli" görünebilir.

### B. Squash and Merge (Temiz Tarihçe)
Feature dalındaki 50 tane "typo fix", "wip", "fix" commitini tek bir commit yapar ("Login özelliği eklendi") ve ana dala ekler.
*   **Artısı:** Ana dal tertemiz kalır. Her commit çalışan bir özelliktir.
*   **Eksisi:** Ara commitlerin detayları kaybolur.

### C. Rebase and Merge
Tarihçeyi "yeniden yazar". Sanki feature dalı hiç ayrılmamış, işler sırayla yapılmış gibi commitleri ana dalın ucuna ekler. Düz bir çizgi (Linear History) oluşturur.

---

## 3. Merge Conflict (Çatışma) Çözümü
İki kişi aynı dosyanın aynı satırını değiştirirse Git karar veremez ve "Conflict" verir.

1.  **Tespit:** Git "CONFLICT (content)" der ve dosyayı işaretler.
2.  **İnceleme:** Dosyayı açtığınızda şöyle görünür:
    ```
    <<<<<<< HEAD
    print("Merhaba Dünya")
    =======
    print("Hello World")
    >>>>>>> feature/english
    ```
3.  **Karar:** Hangi satırı tutacağına karar ver (veya ikisini birleştir) ve okları sil.
4.  **Uygulama:**
    ```bash
    git add dosya.py
    git commit -m "Conflict çözüldü"
    ```

---

## 4. Code Review Kontrol Listesi
Bir Pull Request'i incelerken nelere bakmalısınız? (Junior -> Senior Bakışı)
1.  **Mantık:** Kod istenen işi yapıyor mu?
2.  **Güvenlik:** SQL Injection, XSS açığı var mı? Şifreler kodda unutulmuş mu?
3.  **Performans:** Gereksiz döngüler, veritabanı yoran sorgular var mı?
4.  **Okunabilirlik:** Değişken isimleri anlaşılır mı? Yorum satırı var mı?
5.  **Test:** Bu değişikliği doğrulayan bir test yazılmış mı?

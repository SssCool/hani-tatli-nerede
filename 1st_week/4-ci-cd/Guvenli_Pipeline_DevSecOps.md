# DevSecOps: Güvenliği Sola Kaydırmak (Shift Left)

Geleneksel modelde güvenlik, yazılım bittikten sonra yapılan bir "Son Kontrol"dü. DevSecOps ise güvenliği, geliştirme sürecinin (Pipeline) tam ortasına, hatta başına koyar. Buna "Shift Left" (Süreci zaman çizelgesinde sola, yani başa kaydırma) denir.

## 1. Güvenlik Taramalarının Türleri

Pipeline içine entegre edilecek güvenlik araçları, neyi aradıklarına göre sınıflandırılır:

### A. Secret Scanning (Sır Taraması)
En sinsi açık türüdür. Geliştirici `config.py` dosyasına `AWS_ACCESS_KEY=AKIA...` yazar ve commit eder. Hackerlar GitHub'ı tarayan botlarla bunu saniyeler içinde bulur.
*   **Araç:** **TruffleHog**, **GitLeaks**.
*   **Nasıl Çalışır:** Regex (Düzenli İfade) ve Entropi (Karmaşıklık) analizi yaparak şifreye benzeyen metinleri yakalar. Commit geçmişini (History) de tarar.

### B. SAST (Static Application Security Testing)
Kodun "çalışmadan" analiz edilmesidir. Kodun röntgenini çekmek gibidir.
*   **Araç:** **Semgrep**, **SonarQube**.
*   **Neleri Bulur:**
    *   SQL Injection (`SELECT * FROM users WHERE name = '` + input + `'`)
    *   XSS (Cross Site Scripting)
    *   Güvensiz fonksiyon kullanımları (`eval()`, `exec()`)
    *   Hardcoded IP adresleri.

### C. SCA (Software Composition Analysis)
Sizin kodunuz güvenli olabilir, peki ya kullandığınız kütüphane? Modern yazılımların %80'i açık kaynak kütüphanelerden oluşur.
*   **Örnek:** `log4j` kütüphanesindeki açık yüzünden tüm dünya alarma geçti.
*   **Araç:** **OWASP Dependency Check**, **Trivy**, **Snyk**.
*   **İşlev:** `package.json` veya `requirements.txt` dosyanızı okur ve "Kullandığın Flask 1.0 sürümünde Kritik Açık var, 2.0'a geç" der.

### D. DAST (Dynamic Application Security Testing)
Uygulama çalışırken dışarıdan yapılan saldırı simülasyonudur.
*   **Araç:** **OWASP ZAP**.
*   **Nasıl Çalışır:** Web sitesine girer, formlara garip karakterler basar, URL'leri kurcalar ve sistemin tepkisini ölçer.

---

## 2. DevSecOps Pipeline Mimarisi

Bizim kuracağımız **Secure Pipeline** şu mantıkla çalışır:

1.  **Pre-Build:** Kod depoya geldiği anda (Build almadan önce) taranır.
    *   *TruffleHog*: Şifre var mı? Varsa **DUR**. (Fail).
2.  **SAST:** Kod analiz edilir.
    *   *Semgrep*: Kritik mantık hatası var mı? Varsa **DUR**.
3.  **Build:** Güvenli olduğu onaylanan koddan Docker İmajı üretilir.
4.  **Container Scan:** (Opsiyonel) Üretilen imajın içindeki Linux paketleri taranır.

## 3. "Verified" ve "False Positive" Kavramları

*   **False Positive:** Güvenlik aracının hata olmayan bir şeyi hata sanmasıdır. (Örn: Test için yazılmış rastgele bir stringi şifre sanması).
*   **Verified Secret:** TruffleHog gibi gelişmiş araçlar, buldukları API anahtarını gerçekten internete gidip denerler (Örn: AWS API'sine istek atar). Eğer anahtar çalışıyorsa buna "Verified Secret" denir. Bu çok kritik bir durumdur.

## 4. Raporlama ve Engel Olma

DevSecOps'un amacı rapor üretip kenara koymak değildir. Amacı **Pipeline'ı Kırmaktır (Break the Build).**
*   Eğer **Kritik** bir açık varsa, o yazılımın canlıya çıkması fiziksel olarak engellenmelidir. Pipeline kırmızıya döner ve süreç durur.

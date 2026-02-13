# Infrastructure as Code (IaC) ve Modern Konfigürasyon Yönetimi

Eskiden sunucular "Evcil Hayvan" (Pets) gibiydi. İsimleri vardı (Zeus, Mars), hastalandıklarında iyileştirmek için saatlerce uğraşırdık. Modern dünyada ise sunucular "Büyükbaş Hayvan" (Cattle) gibidir; numaraları vardır ve sorun çıkarınca yenisiyle değiştirilir.

Bu dönüşümü sağlayan teknoloji **Infrastructure as Code (IaC)**'dur.

---

## 1. IaC Nedir?

En basit tanımıyla; altyapının (Sunucular, Ağlar, Veritabanları) manuel işlemlerle değil, **kod dosyaları** (YAML, HCL, JSON) ile yönetilmesidir.

### Temel Avantajları
*   **Hız:** 100 sunucuyu kurmak, 1 sunucuyu kurmakla aynı süreyi alır.
*   **Tutarlılık:** "Benim makinemde çalışıyor" sorununu bitirir. Test ortamı neyse Canlı ortam da odur.
*   **Versiyonlama:** Altyapı kodunuzu Git'te saklayabilirsiniz. Yaptığınız hatayı `git revert` ile geri alabilirsiniz.

### Derinlemesine Bakış: Felsefi Temeller

#### A. Mutable vs Immutable Infrastructure (Değişken vs Değişmez)
*   **Mutable (Değişken - Geleneksel):** Sunucuyu kurarsınız, sonra SSH ile girip güncellersiniz. Zamanla sunucu kirlenir ("Configuration Drift"). Ansible genelde bozuk sunucuyu düzeltmek (Mutable) için kullanılır.
*   **Immutable (Değişmez - Modern):** Sunucu kurulur ve **asla** değiştirilmez. Güncelleme mi lazım? Eskisi silinir, sıfırdan yenisi kurulur. (Docker/Kubernetes mantığı).

#### B. GitOps (Tek Doğruluk Kaynağı)
Altyapının "gerçeği" sunucudaki durum değil, Git deposundaki koddur.
*   "Port 80 açık mı?" diye sunucuya bakılmaz -> Koda bakılır.
*   Kodda açıksa, sunucuda da açık olmalıdır. Değilse, otomasyon (Ansible) bunu zorla düzeltir.

---

## 2. IaC Araçları Karşılaştırması

| Özellik | **Ansible** | **Terraform** | **Puppet / Chef** |
| :--- | :--- | :--- | :--- |
| **Odak** | **Konfigürasyon Yönetimi** (Sunucu içi ayarlar) | **Provisioning** (Sunucu yaratma) | Konfigürasyon |
| **Mimari** | **Agentless** (Ajan gerektirmez, SSH kullanır) | Agentless (API kullanır) | **Agent** gerektirir |
| **Dil** | **YAML** (İnsan okuyabilir) | HCL (HashiCorp Config Language) | Ruby / DSL |
| **Durum** | Stateless (Her seferinde çalışır) | Statefull (`tfstate` dosyası tutar) | Statefull |

---

## 3. Ansible Mimarisi ve Bileşenleri

Ansible, **Control Node** (Sizin bilgisayarınız) üzerinden **Managed Nodes** (Yönetilen Sunucular) ile SSH üzerinden konuşur.

### Temel Bileşenler
1.  **Inventory (Envanter):** Hangi sunuculara bağlanılacak? (IP listesi).
2.  **Playbook (Senaryo):** Ne yapılacak? (Adım adım talimatlar).
3.  **Module (Modül):** Nasıl yapılacak? (apt, yum, copy, service, user modülleri).

**Örnek Akış:**
`Siz` -> `Playbook ("Nginx Yükle")` -> `Ansible` -> `SSH` -> `Sunucu 1, Sunucu 2`

---

### Derinlemesine Bakış: Neden Ansible?

#### A. Agentless & Push Model
Diğer araçların (Puppet/Chef) aksine, yönetilen sunuculara hiçbir şey ("Agent") kurmanız gerekmez.
*   **Gereksinim:** Sadece SSH ve Python olmalıdır.
*   **Push Model:** Ansible kodu kendi üzerinde derler, sunucuya küçük Python scriptleri gönderir, çalıştırır ve siler. Sunucuda kalıcı iz bırakmaz.

#### B. Envanter Çeşitleri (Static vs Dynamic)
*   **Static Inventory:** IP'leri elle `hosts.ini` dosyasına yazarız. Sabit sunucular için idealdir.
*   **Dynamic Inventory:** AWS, Azure gibi bulut ortamlarında sunucular sürekli değişir. Ansible, bir script (Cloud Plugin) ile canlı sunucu listesini otomatik çeker. Elle IP yazmaya gerek kalmaz.

#### C. Idempotency (Tekrarlanabilirlik)
Ansible'ın en kritik özelliğidir.
*   **Shell Script:** `mkdir /tmp/test` komutunu iki kere çalıştırırsanız, ikinci seferde "File exists" hatası alırsınız.
*   **Ansible Modülü:** `file: path=/tmp/test state=directory` görevini 1000 kere çalıştırırsanız, ilkinde klasörü yaratır (**Changed**), sonraki 999 seferde "Zaten var" der ve hiçbir şey yapmaz (**Ok**). Sistemi bozmaz.

#### D. Ad-Hoc vs Playbooks
*   **Ad-Hoc:** Tek seferlik acil işler. (Örn: `ansible all -a "/sbin/reboot"`)
*   **Playbook:** Kayıtlı, versiyonlanabilir prosedürler. (Örn: Web Sunucusu Kurulumu, Kullanıcı Yönetimi).

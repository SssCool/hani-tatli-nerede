# 🎓 General Overview

Bu doküman, `1st week` ve `2nd week` içeriklerinin derinlemesine teknik incelemesi, özetlenmesi ve sentezlenmesiyle oluşturulmuştur.

---

# 📅 1. Hafta: Temeller ve Kültür (Foundations)

Birinci hafta, DevOps kültürünün anlaşılması ve modern altyapı araçlarının (Git, Docker, Jenkins, Ansible) temellerinin atılmasına odaklanmıştır.

## 🧠 1. DevOps Felsefesi (Culture)
DevOps bir araç seti değil, bir kültürdür. Yazılım Geliştirme (Dev) ve Operasyon (Ops) ekiplerinin arasındaki duvarları yıkarak, **hızlı**, **kaliteli** ve **güvenli** yazılım teslimatını amaçlar.

*   **Silo Mentalitesi vs DevOps:** Eskiden "Benim bilgisayarımda çalışıyor" (Dev) ve "Sunucuda çalışmıyor" (Ops) çatışması vardı. Şimdi ise "Bizim ürünümüz" yaklaşımı var.
*   **Temel Değerler (C.A.L.M.S):**
    *   **Culture:** İş birliği ve iletişim.
    *   **Automation:** Tekrarlayan işleri (Build, Test, Deploy) makinelere bırakmak.
    *   **Lean:** Süreçlerdeki israfı (bekleme süreleri, gereksiz onaylar) azaltmak.
    *   **Measurement:** Süreci verilerle (Hız, Hata oranı, MTTR) ölçmek.
    *   **Sharing:** Bilgiyi ve sorunları paylaşmak.

---

## Versioning: Git (Source Control)
Yazılımın tarihçesini tutan ve ekip çalışmasını sağlayan temel araçtır.
*   **Dağıtık Yapı:** Her geliştiricide projenin tam bir kopyası bulunur.
*   **Yaşam Döngüsü:** Working Directory -> Staging Area (`git add`) -> Local Repo (`git commit`) -> Remote Repo (`git push`).
*   **Konfigürasyon (Scopes):** System, Global (`~/.gitconfig`), Local (`.git/config`).

---

## 🐳 Containerization: Docker
Uygulamayı, bağımlılıklarıyla (kütüphaneler, ayarlar) birlikte paketleyerek her ortamda aynı şekilde çalışmasını sağlar.

### VM vs Container
*   **Sanal Makine (VM):** Donanımı sanallaştırır. Her VM'in kendi İşletim Sistemi (Guest OS) vardır. Ağır ve yavaştır (GB'larca boyut, dk'larca boot süresi).
*   **Container:** İşletim Sistemi Çekirdeğini (Kernel) paylaşır. Sadece uygulamayı ve kütüphaneleri içerir. Hafif ve hızlıdır (MB'larca boyut, sn'lerce boot süresi).

### Docker Mimarisi
*   **Daemon (Dockerd):** Arka planda çalışan, işi yapan motor.
*   **Client (CLI):** Kullanıcının komut verdiği arayüz.
*   **Registry:** İmaj deposu (Docker Hub).
*   **Image:** Read-Only şablon (Class).
*   **Container:** Çalışan örnek (Object).

### İzolasyon (Under the Hood)
Linux Kernel özelliklerini kullanır:
*   **Namespaces:** Görünürlüğü kısıtlar (Process, Network, Mount). "Ben tek başımayım" hissi verir.
*   **Cgroups:** Kaynak kullanımını kısıtlar (CPU, RAM). "Komşunu rahatsız etme" kuralı.

---

## 🚀 CI/CD: Pipeline (Otomasyon)
Yazılım üretim bandıdır. "Commit"ten "Production"a kadar olan yolculuğun otomasyonudur.

*   **Continuous Integration (CI):** Kodun sık sık (günde en az 1 kez) ana dalda birleştirilmesi. Her birleşmede otomatik Build ve Test çalışır. Amaç: Hataları erken yakalamak.
*   **Continuous Delivery (CD):** Testten geçen kodun otomatik olarak Staging ortamına atılması ve Production için "Hazır" beklemesi. (Manuel onay ile Deploy).
*   **Continuous Deployment:** Manuel onay olmadan, testleri geçen her kodun müşteriye sunulması.

**Pipeline Akışı:**
Checkout -> Secret Scan (TruffleHog) -> Build (Docker) -> Push (Registry) -> Deploy (K8s/Server).

---

## 🏗️ IaC: Infrastructure as Code (Ansible)
Sunucuların (Altyapının) manuel değil, kod ile yönetilmesidir.
*   **Immutable Infrastructure:** Sunucuyu düzeltmekle uğraşma, sil ve yenisini kur.
*   **Ansible:** Agentless (Ajan gerektirmez, SSH kullanır), Push-based, YAML tabanlıdır.
*   **Idempotency:** Bir komutu 1000 kere çalıştırsan da sonuç değişmez. (Örn: "Klasör yoksa oluştur". İkinci çalıştırmada hata vermez, "zaten var" der).

---

# 📅 2. Hafta: Kubernetes (Orchestration)

İkinci hafta, tekil konteyner yönetiminden (Docker) çoklu konteyner orkestrasyonuna (Kubernetes) geçiş yapılmıştır.

## ☸️ Kubernetes Mimarisi
Konteynerize uygulamaları yöneten, ölçekleyen ve iyileştiren (self-healing) platform.

### Control Plane (Beyin)
1.  **API Server:** Cluster'ın giriş kapısı. Tüm emirler buradan geçer. (Resepsiyon).
2.  **etcd:** Cluster'ın hafızası. Tüm veriler burada tutulur. (Kara Kutu).
3.  **Scheduler:** Yeni podlar için en uygun Node'u seçer. (İK Müdürü).
4.  **Controller Manager:** İstenen durum (Desired) ile Mevcut durum (Current) arasındaki farkı kapatır. (Termostat).

### Worker Node (Kas Gücü)
1.  **Kubelet:** Node'un kaptanı. API Server'dan emir alır, konteyneri çalıştırır. (Ustabaşı).
2.  **Kube-proxy:** Ağ kurallarını yönetir. (Trafik Polisi).
3.  **Container Runtime:** Konteyneri çalıştıran motor (containerd, CRI-O).

---

## 🧱 Temel Kaynaklar (Basic Resources)

### 1. Pod
*   Kubernetes'in en küçük birimidir.
*   İçinde genelde 1 konteyner bulunur.
*   Ölümlüdür (Ephemeral). Ölen pod geri gelmez.

### 2. Deployment
*   Podların yöneticisidir.
*   **Self-healing:** Pod ölürse yenisini açar.
*   **Scaling:** İstenen kopya sayısını (Replicas) yönetir.
*   **Updates:** Kesintisiz (Rolling Update) sürüm geçişi sağlar.

### 3. Service
*   Podlara **sabit IP (ClusterIP)** ve **DNS ismi** sağlar.
*   Ölen podun yerine gelen yeni podun IP'si değişse bile Service IP'si sabit kalır.
*   **Türleri:**
    *   **ClusterIP:** Sadece iç erişim (Varsayılan).
    *   **NodePort:** Node IP'si ve Portu üzerinden dış erişim. (Geliştirme için).
    *   **LoadBalancer:** Cloud Provider'dan Public IP alır. (Production için).

---

## 🔧 İleri Seviye Kaynaklar (Advanced Resources)

### 1. ConfigMap & Secret
*   **ConfigMap:** Konfigürasyon verilerini (db_host, renk, dil) tutar.
*   **Secret:** Hassas verileri (Şifre, API Key) Base64 kodlu tutar.
*   **Amaç:** "Build one, deploy anywhere". İmajı değiştirmeden ortamı (Dev/Test/Prod) değiştirebilmek.

### 2. Storage (Persistence)
*   **PV (Persistent Volume):** Fiziksel depo (Disk).
*   **PVC (Persistent Volume Claim):** Yazılımcının disk talebi (Fiş).
*   Pod, PVC'yi kullanır; PVC, PV'ye bağlanır. Bu sayede Pod, fiziksel disk detayını bilmez.

### 3. StatefulSet
*   Veritabanları gibi "Durumlu" (Stateful) uygulamalar için kullanılır.
*   Pod isimleri sabittir (`mysql-0`, `mysql-1`).
*   Diskleri kalıcıdır ve pod'a yapışıktır.
*   **Headless Service** (`ClusterIP: None`) kullanır, böylece her poda doğrudan DNS ile erişilebilir (`mysql-0.mysql`).

### 4. DaemonSet
*   Her Node üzerinde **tek bir kopya** çalışmasını garanti eder.
*   Kullanım: Log toplayıcılar, Monitoring ajanları.

---

## 🔌 Notlar ve Pratik Bilgiler
*   **Imperative vs Declarative:**
    *   *Imperative:* `kubectl run pod ...` (Anlık işler).
    *   *Declarative:* YAML yazıp `kubectl apply -f ...` (Önerilen, Yönetilebilir).
*   **Namespace:** Cluster'ı sanal odalara böler. Kaynakları ve erişimi izole eder.
*   **Labels & Selectors:** Kubernetes'in "birbirini bulma" mekanizmasıdır. Service, Pod'u etiketiyle bulur.

---


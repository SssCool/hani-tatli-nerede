# 🔥 Bölüm 5 Challenge: Kubernetes ile Uçtan Uca CI/CD

Tebrikler! Docker, Kubernetes temelleri ve Jenkins ile CI/CD konularını geride bıraktın. Şimdi tüm bu öğrendiklerini birleştirme zamanı.

> **⚠️ Kural:** Adım adım reçete yok! Sadece hedefler ve ipuçları var. 1. haftadaki notlarınıza ve önceki Kubernetes örneklerine bakmak serbest.

---

## 🎯 Hedef Mimari

Sisteminiz şu 3 ana parçadan oluşmalı ve Kubernetes üzerinde çalışmalı:

1.  **Frontend:** Kullanıcının gördüğü arayüz. (Dış dünyaya açık olmalı)
2.  **Backend:** İş mantığının döndüğü API. (Sadece Frontend erişebilmeli)
3.  **Database (MySQL):** Verilerin tutulduğu yer. (Kalıcı depolama olmalı)

---

## 📋 Görev 1: Uygulamaları Hazırlama (Review)

Elinizde `frontend` ve `backend` kodları var.
1.  Bu uygulamaların **Dockerfile**'larını kontrol edin (veya baştan yazın).
2.  Backend artık `users.json` yerine **MySQL** kullanacak şekilde güncellendi. Kod içinde DB bağlantı bilgilerinin **Environment Variable**'dan geldiğinden emin olun.

> **💡 İpucu:** Backend kodunda `host`, `user`, `password` gibi bilgilerin kodun içine gömülü (hardcoded) olmaması neden önemliydi?

---

## 📋 Görev 2: Kubernetes Manifestleri

Uygulamaları ayağa kaldırmak için gerekli YAML dosyalarını yazın yada mevcutları düzenleyin.

### 2.1 Database (MySQL)
*   Veri tabanı pod'u ölse bile veriler **kaybolmamalı**. Hangi Kubernetes kaynağı (Resource) buna uygun? (Deploymet vs StatefulSet?)
*   MySQL şifreleri (root password, user password) açık açık YAML içinde yazmamalı.
*   Diğer pod'lar veritabanına sabit bir isimle ulaşabilmeli.

> **💡 İpucu:** `Kind: Secret` ve `Kind: ConfigMap` ne işe yarıyordu?
> **💡 İpucu:** StatefulSet kullanırken "Headless Service" kavramını hatırlıyor musunuz?

### 2.2 Backend
*   Backend uygulaması, veritabanına bağlanmak için şifrelere ihtiyaç duyacak. Bu şifreleri pod'un içine nasıl güvenli bir şekilde aktarırsınız?
*   Backend'in önünde bir servis olmalı ki Frontend ona ulaşabilsin. Ama bu servisin dış dünyaya (internet) açık olmasına gerek var mı?

> **💡 İpucu:** Kubernetes servis tiplerini hatırla..

### 2.3 Frontend
*   Frontend uygulaması kullanıcıya hizmet verecek. Hangi **Service Type** kullanılmalı? (ClusterIP, NodePort, LoadBalancer?)
*   Frontend, Backend'e istek atarken hangi adresi kullanacak?

---

## 📋 Görev 3: Jenkins Pipelines (CI/CD)

Her uygulama (Frontend, Backend, Database) için otomatik dağıtım kurgulamanız gerekiyor. 1. haftada yaptığımız "Güvenli Pipeline" yapısını buraya uyarlayın.

### 3.1 Ön Hazırlık (Kritik!)

Jenkins container'ının içinde `kubectl` komutu varsayılan olarak yüklü değildir. Pipeline'ın Kubernetes ile konuşabilmesi için bunu sizin yüklemeniz gerekir.

Host makinenizde (terminalde) şu komutu çalıştırın (Apple Silicon için):
```bash
docker exec -u 0 -it jenkins bash -c 'curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl" && chmod +x kubectl && mv kubectl /usr/local/bin/'
```

### 3.2 CI Pipeline (Build & Push)
*   Kod GitLab'a push edildiğinde tetiklenmeli.
*   **Güvenlik Taramaları:**
    *   Kodun içinde unutulmuş şifre var mı? (TruffleHog)
    *   Kodda güvenlik açığı var mı? (Semgrep)
*   Docker imajı build edilip Registry'e gönderilmeli.

### 3.2 CD Pipeline (Deploy)
*   CI pipeline'ı başarıyla biterse tetiklenmeli.
*   Kubernetes cluster'ına bağlanıp yeni versiyonu deploy etmeli.
*   **Önemli:** Jenkins, Kubernetes ile konuşurken `kubectl` komutlarını nasıl çalıştıracak?

> **💡 İpucu:** Jenkins üzerinde `kubectl` komutu çalıştırmak için bir "kubeconfig" dosyasına ihtiyacınız olabilir.
> **💡 İpucu:** Jenkins üzerinde `kubectl` komutu çalıştırmak için bir "kubeconfig" dosyasına ihtiyacınız olabilir. (`withKubeConfig` kullanımı)

---

## ✅ Kabul Kriterleri (Definition of Done)

1.  GitLab'da bir kod değişikliği yaptığımda (örneğin Frontend başlığını değiştirince), Jenkins otomatik çalışmalı.
2.  Tüm podlar `Running` statüsünde olmalı.
3.  Tarayıcıdan Frontend'e girdiğimde sayfa açılmalı ve "Kayıt Ol" dediğimde veriler MySQL'e yazılmalı.
4.  Database pod'unu silip (`kubectl delete pod ...`) geri geldiğinde verilerin hala orada olduğunu ispatlamalısınız.

Kolay gelsin! 🚀

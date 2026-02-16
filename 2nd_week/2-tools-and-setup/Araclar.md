# 2. Gün: Kubernetes Temel Araçları ve Kurulum

## Öğrenme Hedefleri
- **kubectl**, **kubeadm** ve **kubelet** arasındaki farkları anlamak.
- Kubernetes kümesi (cluster) kurmak için gereken ön şartları öğrenmek.
- Container Runtime Interface (CRI) kavramına aşina olmak.

---

## 1. Temel Araçlar Üçlüsü

Kubernetes dünyasında sürekli karşılaşacağınız üç ana komut satırı aracı vardır. Bunların her birinin görevi farklıdır.

### A. Kubectl (The Commander)
- **Nedir?** Kubernetes kümesiyle (API Server) konuşmanızı sağlayan komut satırı aracıdır (CLI).
- **Kim Kullanır?** Siz (Developer/DevOps Engineer).
- **Ne Yapar?** "Pod oluştur", "Logları göster", "Node'ları listele" gibi emirleri verirsiniz.
- **Nasıl Çalışır?** `~/.kube/config` dosyasındaki yetki sertifikalarını kullanarak API Server'a HTTPS istekleri atar.
- **Örnek Komut:** `kubectl get pods`

### B. Kubeadm (The Bootstrapper)
- **Nedir?** Bir sunucuyu Kubernetes node'una dönüştüren kurulum aracıdır.
- **Kim Kullanır?** Cluster yöneticisi (Kurulum aşamasında).
- **Ne Yapar?**
    - `kubeadm init`: Control Plane'i (Master) başlatır. Sertifikaları üretir, etcd'yi ve API server'ı ayağa kaldırır.
    - `kubeadm join`: Bir worker node'u cluster'a dahil eder.
- **Önemli:** *Kubeadm*, cluster kurulduktan sonra pek kullanılmaz (versiyon upgrade hariç), *kubectl* ise her gün kullanılır.

### C. Kubelet (The Agent)
- **Nedir?** Her sunucuda (node) çalışan, systemd tarafından yönetilen bir servistir (daemon).
- **Görev:** "Ben bu sunucunun bekçisiyim". API Server'dan emir bekler. "Şu konteyneri çalıştır" emri gelince Container Runtime'a (containerd) "Çalıştır şunu" der.
- **Örnek:** `systemctl status kubelet` ile durumuna bakılır.

---

## 2. Kurulum Öncesi Hazırlık (Prerequisites)

Bir Kubernetes cluster (v1.30.x) kurmadan önce sunucuların şu şartları sağlaması gerekir:

1.  **İşletim Sistemi:** Linux (Örn: Ubuntu 22.04 LTS).
2.  **Kaynak:**
    - Master: En az 2 CPU, 2GB RAM.
    - Worker: En az 1 CPU, 1GB RAM (Lab için).
3.  **Ağ:**
    - Sunucular birbirini ağ üzerinden görmeli.
    - Benzersiz Hostname, MAC adresi ve product_uuid.
4.  **Swap Kapalı Olmalı:** Kubernetes, memory yönetimini kendisi yapmak ister. Swap açıksa *kubelet* çalışmaz.
    - Kapatmak için: `sudo swapoff -a`
5.  **Container Runtime:** Docker yerine artık doğrudan **containerd** veya **CRI-O** kullanıyoruz. (Docker Engine deprecated oldu, ama containerd hala standardın kalbidir).

---

## 3. Kurulum Yöntemleri

- **kubeadm:** Standart, sertifikasyon sınavlarında (CKA) kullanılan yöntem. (Biz bunu kullanacağız).
- **Minikube / Kind:** Tek bilgisayarda (laptop) deneme amaçlı sanal cluster.
- **Managed K8s (EKS, GKE, AKS, DigitalOcean K8s):** Bulut sağlayıcının yönettiği, sizin sadece worker node'larla veya sadece podlarla ilgilendiğiniz hizmet.

> **Sıradaki Adım:** Şimdi "Hands-on" bölümüne geçiyoruz. Ubuntu sunucularımızda `kubeadm` ile sıfırdan bir cluster kuracağız.

# 2. Gün Lab: Ubuntu Üzerinde Kubernetes Kurulumu (v1.30.x)

## Amaç
Ubuntu 22.04 sunucular üzerinde `kubeadm` kullanarak tek Control Plane ve (opsiyonel) Worker Node'lardan oluşan bir cluster kurmak.

## Ön Hazırlık
Bu adımları tüm sunucularda (Master ve Worker) uygulayın.

### 1. Sistem Güncelleme ve Temel Paketler
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
```

### 2. Swap Kapatma (Kritik!)
```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

### 3. Kernel Modülleri ve Ağ Ayarları
Kubernetes network trafiğini (bridge) doğru yönetebilmek için çekirdek modüllerini yükleyin:
```bash
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Sysctl ayarları (IP Forwarding şart)
cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system
```

### 4. Container Runtime Kurulumu (containerd)
```bash
# Docker repo'sundan containerd kuruyoruz (daha güncel)
sudo apt update
sudo apt install -y containerd.io

# Default konfigürasyon ve Systemd Cgroup ayarı
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

sudo systemctl restart containerd
sudo systemctl enable containerd
```

### 5. Kubernetes Reposunun Eklenmesi (v1.30)
```bash
# 1.30 versiyonu için GPG Key ve Repo
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl # Versiyonun otomatik güncellenmesini engelle
```

---

## Cluster Kurulumu (Sadece Master Node'da)

Bu adımları **SADECE Control Plane** sunucusunda yapın.

### 6. Cluster'ı Başlatma (Init)
```bash
sudo kubeadm init --pod-network-cidr=192.168.0.0/16
```
> **Not:** `192.168.0.0/16` Calico Network Plugin için varsayılan CIDR'dır.

### 7. Kubectl Ayarları (Kendi kullanıcınız için)
Init işlemi bitince ekranda çıkan komutları çalıştırın:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### 8. Network Plugin (CNI) Kurulumu
Pod'ların haberleşmesi için bir ağ eklentisi şarttır. Calico kuralım:
```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml
```

---

## Worker Node Ekleme (Opsiyonel)

Eğer işçi sunucularınız varsa, Master node'da `kubeadm init` çıktısında verilen `kubeadm join ...` komutunu Worker sunucularda çalıştırın.

Komutu kaybettiyseniz Master sunucuda tekrar üretmek için:
```bash
kubeadm token create --print-join-command
```

---

## Doğrulama
Master sunucuda:
```bash
kubectl get nodes
kubectl get pods -A
```
Tüm Pod'lar (özellikle core-dns ve calico) *Running* durumuna geçtiyse kurulum başarılıdır! 🚀

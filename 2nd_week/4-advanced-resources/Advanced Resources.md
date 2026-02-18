# 4. Gün: İleri Seviye Kaynaklar (Advanced Resources)

Bu bölümde stateless (durumsuz) uygulamaların ötesine geçerek, stateful (durumlu), sistem seviyesinde ve konfigürasyon odaklı kaynakları inceleyeceğiz.

---

## 1. DaemonSet (Her Node'a Bir Ajan)

### Nedir?
Deployment'a benzer, ama amacı farklıdır. DaemonSet, "Cluster'daki **HER** (veya belirli) Node üzerinde bu Pod'un **BİR** kopyası mutlaka çalışsın" der.

### Kullanım Alanları
- **Log Toplayıcılar:** Fluentd, Logstash (Her sunucunun logunu toplamak için).
- **Monitoring Ajanları:** Prometheus Node Exporter (Her sunucunun CPU/RAM bilgisini çekmek için).
- **Network Eklentileri:** Calico, Flannel, Kube-proxy.

### DaemonSet YAML Analizi
```yaml
apiVersion: apps/v1
kind: DaemonSet             # TÜR: DaemonSet
metadata:
  name: fluentd-logging
  namespace: kube-system    # Genelde sistem namespace'inde çalışırlar
spec:
  selector:
    matchLabels:
      name: fluentd
  template:
    metadata:
      labels:
        name: fluentd
    spec:
      tolerations:          # ÖNEMLİ: Master node dahil her yere konabilmesi için tolerans.
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: fluentd
        image: fluentd:v1
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 100m
            memory: 200Mi
```
**Fark:** `replicas` alanı yoktur! Çünkü kopya sayısı Node sayısına eşittir.

---

## 2. StatefulSet (Durumlu Uygulamalar)

### Nedir?
Deployment, podları "birbirinin aynısı ve değiştirilebilir" (cattle/pets) olarak görür. StatefulSet ise podlara **kimlik** kazandırır.
- Pod isimleri sabittir: `mysql-0`, `mysql-1`, `mysql-2` (Deployment'taki gibi rastgele değil `mysql-xh512`).
- Sıralı başlar ve sıralı kapanır (0 -> 1 -> 2).
- Kalıcı diskleri (PVC) sabittir. Pod yeniden başlasa bile aynı diske bağlanır.

### Kullanım Alanları
- Veritabanları (PostgreSQL, MySQL, MongoDB).
- Kafka, Zookeeper, Elasticsearch.

### Kritik Bileşenler (Koltuk Değnekleri)

#### A. Headless Service (Beyinsiz Servis)
- **Nedir?** `ClusterIP: None` olarak tanımlanan özel bir servistir.
- **Farkı:** Normal servisler size tek bir IP (VIP) verir ve trafiği arkadaki podlara rastgele dağıtır (Load Balancing). Headless service ise yük dağıtmaz. DNS sorgusu yaptığınızda size arkadaki Pod'ların IP adreslerini **doğrudan** listeler.
- **Neden Lazım?** StatefulSet podlarının her biri özeldir (biri Master, biri Slave olabilir). Uygulamanın "Bana herhangi bir pod ver" demesi yetmez, "Bana `mysql-0` (Master) lazım" demesi gerekir. Headless service, `mysql-0.service-name` gibi kararlı DNS kayıtları oluşturur.

#### B. StorageClass (Otomatik Disk Tedariki)
- **Sorun:** 100 replikalı bir StatefulSet kurarken, elle 100 tane PV (Disk) oluşturmak imkansızdır.
- **Çözüm:** **StorageClass** (Dynamic Provisioning).
- **Nasıl Çalışır?** Siz sadece şablonu (`volumeClaimTemplates`) verirsiniz: "Bana `standard` sınıfında 10GB disk lazım." Kubernetes gider, bulut sağlayıcısında (AWS EBS, Google Disk) diski yaratır (PV), talebi oluşturur (PVC) ve podunuza bağlar. Her pod için bunu ayrı ayrı yapar.

### StatefulSet YAML Analizi
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  serviceName: "nginx"      # Headless Service (ClusterIP: None) gerektirir!
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  
  volumeClaimTemplates:     # ÖNEMLİ: Her pod için ayrı bir PVC oluşturur.
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "standard"
      resources:
        requests:
          storage: 1Gi
```

---

## 3. Persistent Volume (PV) ve Persistent Volume Claim (PVC)

Kalıcı depolama (Storage) yönetimi Kubernetes'te iki katmana ayrılır.

### A. Persistent Volume (PV) - Deponun Kendisi
- **Nedir?** Fiziksel veya bulut tabanlı depolama alanıdır (NFS, AWS EBS, Google Disk).
- **Kim Yönetir?** Sistem Yöneticisi (Admin).
- **Ömür:** Pod'dan bağımsızdır.

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: task-pv-volume
spec:
  storageClassName: manual
  capacity:
    storage: 10Gi           # Kapasite
  accessModes:
    - ReadWriteOnce         # Erişim Modu (RWO: Tek node, RWX: Çoklu node)
  hostPath:                 # Depolama Tipi (Örn: HostPath, NFS, AWS EBS)
    path: "/mnt/data"
```

### B. Persistent Volume Claim (PVC) - Talep Fişi
- **Nedir?** Yazılımcının (Developer) "Bana 5GB disk lazım" talebidir.
- **Kim Yönetir?** Yazılımcı.
- **Nasıl Çalışır?** PVC oluşturulunca, Kubernetes uygun bir PV bulup bunları birbirine **bağlar (bind)**.

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: task-pv-claim
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi          # İstenen Boyut
```
**Pod İçinde Kullanımı:**
Pod, PV'yi bilmez. Sadece PVC'yi bilir (`claimName: task-pv-claim`).

---

## 4. ConfigMap (Konfigürasyon Yönetimi)

### Nedir?
Uygulama kodunu (Image), konfigürasyondan ayırmak için kullanılır. `db_host`, `theme_color` gibi ayarları imajın içine gömmek yerine ConfigMap'te tutarız.

### ConfigMap YAML Analizi
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: game-demo
data:                       # Veriler (Key-Value)
  player_lives: "3"
  ui_properties_file_name: "user-interface.properties"
  game.properties: |        # Dosya içeriği de koyabiliriz
    enemy.types=aliens,monsters
    player.maximum-lives=5    
```

### Pod İçinde Kullanımı
1.  **Env Var Olarak:** `valueFrom: configMapKeyRef`
2.  **Volume Olarak:** ConfigMap'i dosya gibi `/etc/config` altına mount ederiz.

---

## 5. Secret (Gizli Veri Yönetimi)

### Nedir?
ConfigMap gibidir ama **Hassas Veriler** (Şifreler, API Key'ler, SSH anahtarları) için kullanılır.
- Veriler **Base64** ile kodlanır (Şifrelenmez, sadece kodlanır!).
- Etcd üzerinde (ayarlanırsa) şifreli durur.
- Pod içine RAM disk (tmpfs) olarak mount edilir, diske yazılmaz.

### Secret YAML Analizi
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque                # Varsayılan tip
data:
  username: YWRtaW4=        # "admin" (Base64)
  password: MWYyZDFlMmU2N2Rm # "1f2d1e2e67df" (Base64)
```

**Dikkat:** YAML dosyasına elle Base64 yazmak yerine genelde `kubectl create secret` komutu veya şifreli repolar (SealedSecrets) kullanılır.

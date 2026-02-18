# 4. Gün: Uzmanlaşma Egzersizleri (Deep Dive)

Bu dokümanda, öğrendiğimiz tüm ileri seviye kaynakları (DaemonSet, StatefulSet, PVC, ConfigMap, Secret, Deployment) bir arada ve **detaylı özellikleriyle** (InitContainers, Lifecycle Hooks, Tolerations, Projected Volumes) kullanacağız.

---

## Egzersiz 1: "Stateful" Canavar (InitContainer + Headless + PVC + Secret)
**Senaryo:** Bir veritabanı kümesi kuracağız. Ancak bu küme ayağa kalkmadan önce bir "Hazırlık" aşamasından geçmeli (InitContainer). Ayrıca şifreler Secret'tan, başlangıç scriptleri ConfigMap'ten gelmeli.

### 1. Hazırlık (ConfigMap & Secret)
Veritabanı başlatılmadan önce çalışacak bir `init.sh` scriptini ConfigMap içine gömelim.

```yaml
# 1-complex-sts-prep.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: db-init-script
data:
  setup.sh: |
    #!/bin/sh
    echo "Veritabani hazirliklari yapiliyor..."
    echo "Disk kontrolu: OK"
    echo "Konfigurasyon dosyalari kopyalaniyor..."
    cp /config/my.cnf /etc/mysql/my.cnf
    echo "Hazirlik tamamlandi!"
  my.cnf: |
    [mysqld]
    bind-address=0.0.0.0
---
apiVersion: v1
kind: Secret
metadata:
  name: db-creds
type: Opaque
data:
  # Şifre: "SüperGizliSifre" (Base64)
  ROOT_PASSWORD: U3VwZXJHaXpsaXNpZnJl
```
**Komut:** `kubectl apply -f 1-complex-sts-prep.yaml`

### 2. Manuel PV (Strictly No StorageClass)
Ortamda hiç StorageClass yoksa veya Dynamic Provisioning istenmiyorsa, `storageClassName: ""` (boş string) kullanarak Kubernetes'i "Otomatik yapma, benim verdiğim diskleri kullan" moduna zorlarız.

```yaml
# 2-complex-pvs.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-complex-0
  labels:
    type: local         # Eşleşme için etiket
spec:
  storageClassName: ""  # DİKKAT: Boş bırakarak Default SC'yi engelliyoruz.
  capacity:
    storage: 500Mi
  accessModes: ["ReadWriteOnce"]
  hostPath:
    path: "/tmp/db-data-0"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-complex-1
  labels:
    type: local
spec:
  storageClassName: ""
  capacity:
    storage: 500Mi
  accessModes: ["ReadWriteOnce"]
  hostPath:
    path: "/tmp/db-data-1"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-complex-2
  labels:
    type: local
spec:
  storageClassName: ""
  capacity:
    storage: 500Mi
  accessModes: ["ReadWriteOnce"]
  hostPath:
    path: "/tmp/db-data-2"
```
**Komut:** `kubectl apply -f 2-complex-pvs.yaml`

### 3. StatefulSet (InitContainers ile)
```yaml
# 3-complex-sts.yaml
apiVersion: v1
kind: Service
metadata:
  name: db-headless
spec:
  ports:
  - port: 3306
  clusterIP: None
  selector:
    app: complex-db
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: db
spec:
  serviceName: "db-headless"
  replicas: 3
  selector:
    matchLabels:
      app: complex-db
  template:
    metadata:
      labels:
        app: complex-db
    spec:
      # --- ÖZELLİK 1: InitContainer ---
      # Asıl pod (mysql) başlamadan önce bu çalışır ve biter.
      # Eğer bu hata verirse, Pod "Init:Error" durumunda kalır ve açılmaz.
      initContainers:
      - name: init-db
        image: busybox
        command: ['sh', '/scripts/setup.sh']
        volumeMounts:
        - name: script-vol
          mountPath: /scripts
        - name: config-vol
          mountPath: /config
      
      containers:
      - name: mysql
        image: mysql:5.7
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-creds
              key: ROOT_PASSWORD
        # --- ÖZELLİK 2: Liveness Probe ---
        livenessProbe:
          exec:
            command: ["mysqladmin", "ping", "-pSüperGizliSifre"]
          initialDelaySeconds: 30
          periodSeconds: 10
        volumeMounts:
        - name: data-storage    # PVC'den gelen disk
          mountPath: /var/lib/mysql
  
      volumes:
      - name: script-vol
        configMap:
          name: db-init-script
          defaultMode: 0777     # Çalıştırılabilir yap (chmod +x)
      - name: config-vol
        configMap:
          name: db-init-script
  
  # --- KRİTİK ANALİZ: Manuel Binding Mekanizması ---
  # Ortamda StorageClass (SC) YOKSA, eşleşme şöyle olur:
  # 1. StatefulSet her pod için bir PVC oluşturur (örn: data-storage-db-0).
  # 2. PVC şablonunda `storageClassName: ""` (boş) olduğu için Dynamic Provisioning devre dışı kalır.
  # 3. Kubernetes, şu 3 şartı sağlayan PV arar:
  #    a) storageClassName: "" (Boş olmalı)
  #    b) capacity >= 500Mi
  #    c) accessModes: ReadWriteOnce
  # 4. Bizim oluşturduğumuz pv-complex-0,1,2 bu şartları sağlar.
  # 5. Controller bu boşta duran (Available) PV'leri bulur ve PVC'lere bağlar (Bound).
  volumeClaimTemplates:
  - metadata:
      name: data-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: ""      # BOŞ: Dynamic Provisioning İSTEMİYORUM!
      resources:
        requests:
          storage: 500Mi
```
**Komut:** `kubectl apply -f 3-complex-sts.yaml`

---

## Egzersiz 2: Sistem Bekçisi (DaemonSet + Tolerations + HostPath)
**Senaryo:** Cluster'daki **Master Node (Control Plane)** dahil tüm makinelerin `/var/log` klasörünü okuyan ve sadece "ERROR" satırlarını ekrana basan bir log ajanı yazın.

### 1. DaemonSet Tanımı
```yaml
# 4-sys-logger.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: sys-logger
  namespace: kube-system    # Sistem podu gibi davranması için
spec:
  selector:
    matchLabels:
      name: sys-logger
  template:
    metadata:
      labels:
        name: sys-logger
    spec:
      # --- ÖZELLİK 1: Tolerations ---
      # Master node üzerinde "NoSchedule" lekesi (taint) vardır.
      # Bunu tolere etmezsek ajan oraya kurulmaz.
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      - key: node-role.kubernetes.io/master # Eski versiyonlar için
        operator: Exists
        effect: NoSchedule
      
      containers:
      - name: logger
        image: busybox
        # --- ÖZELLİK 2: HostPath (Read-Only) ---
        # Node'un diskine sadece okuma izni ile eriş.
        volumeMounts:
        - name: varlog
          mountPath: /host-logs
          readOnly: true
        # Logları filtrele
        command: ["sh", "-c", "tail -f /host-logs/syslog | grep 'ERROR'"]
      
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
```
**Komut:** `kubectl apply -f 4-sys-logger.yaml`
**Analiz:** `kubectl get pods -n kube-system -o wide` ile Master node üzerinde çalışıp çalışmadığını kontrol edin.

---

## Egzersiz 3: Hepsi Bir Arada Deployment (Lifecycle + Projected Volumes)
**Senaryo:** Nginx uygulaması çalışsın. Ancak:
1.  Uygulama başlamadan hemen sonra (PostStart) bir "index.html" oluştursun.
2.  Kapanmadan hemen önce (PreStop) "Güle güle" logu bassın ve graceful shutdown için beklesin.
3.  Hem ConfigMap hem Secret tek bir klasöre (`/run/secrets`) dosyalar halinde gelsin (Projected Volume).

```yaml
# 5-all-in-one.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: all-in-one-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-pro
  template:
    metadata:
      labels:
        app: web-pro
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        
        # --- ÖZELLİK 1: Lifecycle Hooks ---
        lifecycle:
          postStart:
            exec:
              command: ["/bin/sh", "-c", "echo '<h1>Merhaba Kubernetes</h1>' > /usr/share/nginx/html/index.html"]
          preStop:
            exec:
              # Pod öldürülme sinyali (SIGTERM) geldiğinde önce burası çalışır.
              # Trafiğin kesilmesi için süre tanır.
              command: ["/bin/sh", "-c", "echo 'Kapatiliyor...' > /proc/1/fd/1; sleep 5"]

        # --- ÖZELLİK 2: Projected Volumes ---
        # Birden fazla kaynağı (CM, Secret) tek klasöre map eder.
        volumeMounts:
        - name: all-configs
          mountPath: /run/config-files
          readOnly: true
      
      volumes:
      - name: all-configs
        projected:
          sources:
          - configMap:
              name: db-init-script
              items:
                - key: my.cnf
                  path: mysql-conf.cnf
          - secret:
              name: db-creds
              items:
                - key: ROOT_PASSWORD
                  path: db-password.txt
```
### 2. NodePort Service
Bu deployment'a dışarıdan erişmek için NodePort servisi tanımlayalım.

```yaml
# 6-all-in-one-svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: demo-nodeport
spec:
  type: NodePort
  selector:
    app: web-pro
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30009         # Statik Port
```
**Komut:** `kubectl apply -f 6-all-in-one-svc.yaml`

### 3. Analiz ve Doğrulama
1.  **Tarayıcı Testi:** Tarayıcınızdan `http://<NODE-IP>:30009` adresine gidin.
    *   `Merhaba Kubernetes` yazısını (PostStart hook ile oluştu) görmelisiniz.
    *   Node IP'sini öğrenmek için: `kubectl get nodes -o wide`
2.  **Dosya Kontrolü:** `kubectl exec -it <pod-name> -- ls -R /run/config-files` komutuyla hem secret hem configmap dosyalarının aynı klasörde (Projected Volume) olduğunu doğrulayın.
3.  **Graceful Shutdown:** Podu silerken (`kubectl delete pod ...`) terminalde logları izleyin (`kubectl logs -f ...`). Pod kapanmadan önce beklendiğini veya preStop hook'un çalıştığını (events üzerinden) gözlemleyebilirsiniz.

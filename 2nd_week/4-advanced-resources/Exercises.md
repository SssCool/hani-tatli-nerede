# 4. Gün Egzersizleri: İleri Seviye Kaynaklar

Bu egzersizlerde Kubernetes'in "stateful" (durumlu) ve "stateless" (durumsuz) uygulamaları nasıl yönettiğini, veri kaybı ve veri kalıcılığı kavramlarını deneyimleyerek öğreneceğiz.

---

## Senaryo 1: DaemonSet ile Monitoring (ConfigMap & Secret)

**Amaç:** Cluster'daki her node üzerinde çalışacak bir "ajan" (agent) simülasyonu yapmak. Bu ajan, ayarlarını ConfigMap'ten, gizli anahtarını Secret'tan alacak.

### 1. Hazırlık: ConfigMap ve Secret
Ajanımızın çalışması için gereken konfigürasyonları oluşturuyoruz.

```yaml
# 1-agent-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: monitor-config
data:
  INTERVAL: "10s"
  LOG_LEVEL: "INFO"
---
apiVersion: v1
kind: Secret
metadata:
  name: monitor-secret
type: Opaque
data:
  API_KEY: c3VwZXJTZWNyZXQ= # "superSecret" (Base64)
```
**Uygula:** `kubectl apply -f 1-agent-config.yaml`

### 2. DaemonSet Tanımı
```yaml
# 2-daemon-agent.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-monitor
spec:
  selector:
    matchLabels:
      app: monitor-agent
  template:
    metadata:
      labels:
        app: monitor-agent
    spec:
      tolerations:
      - key: node-role.kubernetes.io/control-plane
        operator: Exists
        effect: NoSchedule
      containers:
      - name: agent
        image: busybox
        env:
        - name: CHECK_INTERVAL
          valueFrom:
            configMapKeyRef:
              name: monitor-config
              key: INTERVAL
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: monitor-secret
              key: API_KEY
        # ConfigMap'ten gelen sürede bir log basan script
        command: ["sh", "-c", "while true; do echo \"[$(hostname)] Monitoring... Interval: $CHECK_INTERVAL, Key: $API_KEY\"; sleep 10; done"]
```
**Uygula:** `kubectl apply -f 2-daemon-agent.yaml`
**Doğrula:** `kubectl get pods -o wide` (Her node için 1 pod görmelisiniz).

---

## Senaryo 2: Deployment ve Veri Kaybı (Stateless)

**Amaç:** Podların "geçici" (ephemeral) olduğunu ispatlamak. Bir podun içine veri yazacağız, podu silip yenisi geldiğinde verinin **kaybolduğunu** göreceğiz.

### 1. Deployment Tanımı (Geçici Disk - emptyDir)
```yaml
# 3-data-loss-demo.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ephemeral-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ephemeral
  template:
    metadata:
      labels:
        app: ephemeral
    spec:
      containers:
      - name: app
        image: busybox
        command: ["sh", "-c", "sleep 3600"]
        volumeMounts:
        - name: temp-storage
          mountPath: /data
      volumes:
      - name: temp-storage
        emptyDir: {}       # Pod ölünce silinen disk tipi
```
**Uygula:** `kubectl apply -f 3-data-loss-demo.yaml`

### 2. Deney Adımları
1.  **Veri Yaz:** Podun içine girip bir dosya oluşturun.
    ```bash
    # Pod ismini al
    POD_NAME=$(kubectl get pods -l app=ephemeral -o name)
    
    # Dosya oluştur
    kubectl exec $POD_NAME -- sh -c "echo 'Bunu kaybedeceksin' > /data/önemli.txt"
    
    # Kontrol et
    kubectl exec $POD_NAME -- cat /data/önemli.txt
    ```
2.  **Podu Öldür:** Deployment podu yeniden başlatacaktır.
    ```bash
    kubectl delete $POD_NAME
    ```
3.  **Veri Kontrolü:** Yeni pod geldiğinde veriye bakın.
    ```bash
    NEW_POD=$(kubectl get pods -l app=ephemeral -o name)
    kubectl exec $NEW_POD -- ls /data/
    # HATA: Dosya yok! (emptyDir pod ile birlikte silindi).
    ```

---

## Senaryo 3: StatefulSet ve Veri Kalıcılığı (Stateful)

**Amaç:** Pod silinse bile verinin korunduğunu ispatlamak. Manuel Persistent Volume (PV) kullanarak veriyi node üzerindeki bir klasöre sabitleyeceğiz.

### 1. Manuel Kalıcı Disk (Persistent Volume)
Dynamic Provisioning olmayan ortamlar için (Minikube/Kind harici) elle disk tanımlıyoruz.

```yaml
# 4-manual-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-mysql-0          # Özel İsim (StatefulSet sırasıyla eşleşmesi için)
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data-0"     # Node üzerindeki gerçek klasör
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-mysql-1
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data-1"
```
**Uygula:** `kubectl apply -f 4-manual-pv.yaml`

### 2. StatefulSet Tanımı (MySQL)
Veritabanı şifresini Secret'tan alacağız.

```yaml
# 5-stateful-app.yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-hl
spec:
  ports:
  - port: 3306
  clusterIP: None           # Headless Service
  selector:
    app: mysql-db
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql-sts
spec:
  serviceName: "mysql-hl"
  replicas: 1               # Tek kopya yeterli (Test için)
  selector:
    matchLabels:
      app: mysql-db
  template:
    metadata:
      labels:
        app: mysql-db
    spec:
      containers:
      - name: mysql
        image: mysql:5.7
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: monitor-secret  # Önceki secret'ı kullanalım
              key: API_KEY
        volumeMounts:
        - name: data-vol
          mountPath: /var/lib/mysql
  
  volumeClaimTemplates:     # PVC Şablonu
  - metadata:
      name: data-vol
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "manual" # Yukarıdaki PV ile eşleşir
      resources:
        requests:
          storage: 1Gi
```
**Uygula:** `kubectl apply -f 5-stateful-app.yaml`

### 3. Deney Adımları (Kalıcılık Testi)
1.  **Veri Yaz:** MySQL'e bağlanıp tablo oluşturun.
    ```bash
    # Pod içine gir
    kubectl exec -it mysql-sts-0 -- mysql -p
    # Şifre: superSecret (Base64 decode ederseniz)
    
    # SQL Komutları:
    > create database testdb;
    > use testdb;
    > create table users (id int, name varchar(20));
    > insert into users values (1, 'Ali');
    > select * from users;
    > exit
    ```
2.  **Podu Öldür:**
    ```bash
    kubectl delete pod mysql-sts-0
    ```
3.  **İzle:** StatefulSet hemen `mysql-sts-0` isminde YENİ bir pod başlatır.
    ```bash
    kubectl get pods -w
    ```
4.  **Veri Kontrolü:** Yeni pod açılınca tekrar bağlanın.
    ```bash
    kubectl exec -it mysql-sts-0 -- mysql -p
    > use testdb;
    > select * from users;
    # SONUÇ: 'Ali' kaydı orada duruyor!
    ```

**Tebrikler!** Deployment kullanınca verinin nasıl kaybolduğunu, StatefulSet ve PV/PVC kullanınca verinin nasıl korunduğunu deneyimlediniz.

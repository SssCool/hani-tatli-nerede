# 🗝️ Challenge Cevap Anahtarı (Detailed Solution Key)

Bu dosya, Challenge 5'teki görevlerin **tam ve detaylı** çözüm adımlarını içerir. Aşağıdaki YAML dosyaları, projenin çalışan halinden birebir alınmıştır.

---

## 🏗️ Bölüm 1: Database (MySQL)

Veritabanı en kritik bileşendir. Veri kalıcılığı (Persistence) ve güvenli parola yönetimi şarttır.

### 1.1 Secret (`database/k8s/secret.yaml`)
Hassas verileri (şifreler) asla açık açık yazmayız. Base64 encoded olarak `Secret` objesinde tutarız.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
type: Opaque
data:
  # Decoded: rootpassword
  mysql-root-password: cm9vdHBhc3N3b3Jk
  # Decoded: tatli_user
  mysql-user: dGF0bGlfdXNlcg==
  # Decoded: tatli_password
  mysql-password: dGF0bGlfcGFzc3dvcmQ=
  # Decoded: tatli_db
  mysql-database: dGF0bGlfZGI=
```

### 1.2 ConfigMap (`database/k8s/configmap.yaml`)
Veritabanı konfigürasyonlarını (örn: `my.cnf`) burada tutarız. Environment variable'dan faklı olarak, dosya tabanlı konfigürasyonları pod içine "mount" etmek için idealdir.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-config
data:
  my.cnf: |
    [mysqld]
    default-authentication-plugin=mysql_native_password
```

### 1.3 Service (`database/k8s/service.yaml`)
StatefulSet podlarına stabil ağ kimliği kazandırmak için **Headless Service** (`clusterIP: None`) kullanılır. Bu sayede `mysql-0.mysql` gibi doğrudan pod'a giden DNS kayıtları oluşur.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql
  labels:
    app: mysql
spec:
  ports:
  - port: 3306
  clusterIP: None
  selector:
    app: mysql
```

### 1.4 StatefulSet (`database/k8s/statefulset.yaml`)
Deployment yerine **StatefulSet** kullanıyoruz çünkü:
1.  Pod isimleri sabittir (`mysql-0`).
2.  Her pod'un kendine ait kalıcı diski (`PersistenVolumeClaim`) olur. Pod silinip gelse bile diski kaybolmaz.

**Dikkat:** Env variable'ları `valueFrom: secretKeyRef` ile Secret'tan çekiyoruz.

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: "mysql"
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:5.7
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: mysql-root-password
        - name: MYSQL_DATABASE
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: mysql-database
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: mysql-user
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: mysql-password
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: mysql-persistent-storage
          mountPath: /var/lib/mysql
        - name: config-vol
          mountPath: /etc/mysql/conf.d
      volumes:
      - name: config-vol
        configMap:
          name: mysql-config
  volumeClaimTemplates:
  - metadata:
      name: mysql-persistent-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "" # Local PV veya default class için
      resources:
        requests:
          storage: 1Gi
```

---

## 🏗️ Bölüm 2: Backend (Python Flask)

Backend uygulaması "Stateless"dir (durumsuz). Yani pod silinirse yerine yenisi gelir, veri kaybetme derdi yoktur. Bu yüzden **Deployment** kullanırız.

### 2.1 ConfigMap (`backend/k8s/configmap.yaml`)
Backend'in veritabanına bağlanırken kullanacağı **Host** ve **DB Name** bilgileri hassas değildir, bu yüzden ConfigMap'te tutulabilir. `db-host` olarak `mysql-0.mysql` (Servis Adı) kullanıldığına dikkat edin.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: backend-config
data:
  db-host: "mysql-0.mysql"
  db-name: "tatli_db"
```

### 2.2 Secret (`backend/k8s/secret.yaml`)
Backend'in veritabanına bağlanırken kullanacağı **Kullanıcı Adı** ve **Şifre** hassastır. Bunları Secret'ta tutuyoruz. (Değerler Base64 encoded)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: backend-secret
type: Opaque
data:
  # Decoded: tatli_user
  db-user: dGF0bGlfdXNlcg==
  # Decoded: tatli_password
  db-password: dGF0bGlfcGFzc3dvcmQ=
```

### 2.3 Deployment (`backend/k8s/deployment.yaml`)
Burada `env` bloğu çok önemlidir.
*   `DB_HOST` ve `DB_NAME` değerlerini **ConfigMap**'ten (`configMapKeyRef`) okuyoruz.
*   `DB_USER` ve `DB_PASSWORD` değerlerini **Secret**'tan (`secretKeyRef`) okuyoruz.
Bu sayede kodun içine (Image'a) şifre gömmemiş oluyoruz.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: kocakabdussamed/sbr-backend:samed-latest
        imagePullPolicy: Always
        env:
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: backend-config
              key: db-host
        - name: DB_NAME
          valueFrom:
            configMapKeyRef:
              name: backend-config
              key: db-name
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: backend-secret
              key: db-user
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: backend-secret
              key: db-password
        ports:
        - containerPort: 8090
```

### 2.4 Service (`backend/k8s/service.yaml`)
Backend'e sadece Frontend ulaşacağı için (Dış dünya erişimi yok), `ClusterIP` (varsayılan) yeterlidir.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  selector:
    app: backend
  ports:
  - protocol: TCP
    port: 8090
    targetPort: 8090
```

---

## 🏗️ Bölüm 3: Frontend (Web UI)

### 3.1 Deployment (`frontend/k8s/deployment.yaml`)
Frontend'in Backend'e ulaşabilmesi için `BACKEND_URL` ortam değişkenine ihtiyacı vardır. Bunu doğrudan `value` olarak verebiliriz çünkü gizli bir bilgi değildir (Cluster içi DNS ismi).

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: kocakabdussamed/sbr-frontend:samed-latest
        imagePullPolicy: Always
        env:
        - name: BACKEND_URL
          value: "http://backend-service:8090"
        ports:
        - containerPort: 8080
```

### 3.2 Service (`frontend/k8s/service.yaml`)
Frontend'e kullanıcılar (biz) erişeceği için dışarıya kapı açmamız lazım. **NodePort** kullanarak 30000-32767 aralığında bir porttan (örn: 30080) erişim sağlıyoruz.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: NodePort
  selector:
    app: frontend
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8080
    nodePort: 30080
```

---

## ⛓️ Görev 4: Jenkins Pipelines (CI/CD)

### 4.1 Ön Hazırlık: Jenkins'e Kubectl Kurulumu (Önemli!)

`Kubernetes CLI Plugin` sadece config dosyasını yönetir (`k8s-kubeconfig`). Ancak `kubectl` komutunun çalışabilmesi için, **Jenkins container'ının içinde** `kubectl` binary'sinin yüklü olması gerekir. Varsayılan Jenkins imajında bu yoktur.

Aşağıdaki komutu host makinenizde (terminalde) çalıştırarak Jenkins'e kubectl yükleyin (Apple Silicon/M1/M2 için):

```bash
docker exec -u 0 -it jenkins bash -c 'curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl" && chmod +x kubectl && mv kubectl /usr/local/bin/'

```

*(Intel işlemci kullanıyorsanız `linux/arm64` yerine `linux/amd64` indirmeniz gerekir.)*

### 4.2 CI Pipeline (Build & Push)

**withKubeConfig Yöntemi (Credential Injection):**

Deployment işlemi için **Kubernetes CLI Plugin** (`withKubeConfig`) kullanılır. Bu yöntem, Kubeconfig dosyasını Jenkins Credentials ("Secret File") içinden geçici olarak alıp `kubectl` komutlarına yetki verir.

*   Jenkins'te `k8s-kubeconfigfile` ID'li bir **Secret File** credential tanımlı olmalıdır.
*   Pipeline şu formatta olmalıdır:

    ```groovy
    withKubeConfig([credentialsId: 'k8s-kubeconfigfile']) {
        sh 'kubectl apply -f frontend/k8s/ --validate=false'
        sh 'kubectl rollout restart deployment/frontend'
        
        // Verification adımı da burada olmalı (Authentication için)
        sh 'kubectl rollout status deployment/frontend --timeout=60s'
    }
    ```



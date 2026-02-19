# 🗝️ Challenge Cevap Anahtarı (Detailed Architect's Guide)

Bu dosya, Challenge 5'teki görevlerin **tam, detaylı ve mimari açıklamalı** çözüm adımlarını içerir. Sadece "nasıl" yapıldığını değil, "neden" böyle yapıldığını da anlatır.

---

## 🏗️ 1. Genel Mimari ve Akış (Architecture Overview)

Aşağıdaki diyagram, bu projede kurduğumuz yapının kuş bakışı görünümüdür.

```text
[Kullanıcı] 
    │
    ▼
[Service: nodeport] (Port: 30080)
    │
    ▼
[Pod: Frontend] (Port: 8080)
    │
    │ (HTTP Request)
    ▼
[Service: backend-service] (ClusterIP)
    │
    ▼
[Pod: Backend] (Port: 8090)
    │
    │ (Kimlik Doğrulama & Veri)
    ▼
[Service: mysql] (Headless)
    │
    ▼
[Pod: MySQL-0] (Port: 3306)
    │
    ▼
[PVC: Disk] (Kalıcı Veri)
```

### 🔄 Veri Akışı
1.  **Kullanıcı** (User), tarayıcıdan `http://<node-ip>:30080` adresine gider.
2.  **Frontend** karşılar. Backend'den veri almak için `http://backend-service:8090` adresine istek atar.
    *   *Not:* `backend-service` ismi Kubernetes Cluster DNS tarafından çözümlenir.
3.  **Backend**, gelen isteği işler. Veritabanına yazmak veya okumak için `mysql-0.mysql` adresine bağlanır.
4.  **Database** (MySQL), veriyi diskte (`PVC`) kalıcı olarak saklar.

---

## 🏗️ Bölüm 2: Database

Veritabanı en kritik bileşendir. Veri kalıcılığı (Persistence) ve güvenli parola yönetimi şarttır. **StatefulSet** kullanımı burada kilit noktadır.

### 2.1 Secret (`database/k8s/secret.yaml`)
Hassas verileri (şifreler) asla açık açık YAML dosyasına yazmayız. Base64 encoded olarak `Secret` objesinde tutarız.

*   **Neden?** Kodunuzu Git'e attığınızda şifreleriniz ifşa olmasın diye.
*   **İpucu:** Base64 bir şifreleme değildir, sadece kodlamadır (`echo -n "sifre" | base64`).

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

### 2.2 ConfigMap (`database/k8s/configmap.yaml`)
Veritabanı konfigürasyonlarını (örn: `my.cnf`) burada tutarız.

*   **Neden?** Image'ı yeniden build etmeden konfigürasyonu değiştirebilmek için.
*   **Kullanımı:** Bu ConfigMap, pod içinde bir dosya (`/etc/mysql/conf.d/my.cnf`) olarak "mount" edilecektir.

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

### 2.3 Service (`database/k8s/service.yaml`) - Headless Service!
StatefulSet podlarına stabil ağ kimliği kazandırmak için **Headless Service** (`clusterIP: None`) kullanılır.

*   **Normal Service vs Headless Service:**
    *   *Normal Service*: Rastgele bir IP verir, yükü podlara dağıtır (Load Balancing).
    *   *Headless Service*: IP vermez. DNS sorgusunda doğrudan Pod'un IP'sini döner.
    *   **Önemli:** StatefulSet ile `mysql-0.mysql` gibi **tahmin edilebilir** DNS isimleri oluşturulmasını sağlar.

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
  clusterIP: None # <-- İŞTE BURASI ÖNEMLİ
  selector:
    app: mysql
```

### 2.4 StatefulSet (`database/k8s/statefulset.yaml`)
Deployment yerine **StatefulSet** kullanıyoruz.

*   **Neden Deployment Değil?**
    1.  **Sıralı Başlatma:** Podlar rastgele değil, `mysql-0`, `mysql-1` sırasıyla açılır.
    2.  **Kalıcı Kimlik:** Pod silinip gelse bile adı hep `mysql-0` kalır.
    3.  **Kalıcı Disk:** Her pod'un kendine ait kalıcı diski (`PersistenVolumeClaim`) olur. Pod silinip başka node'da başlasa bile, Kubernetes o diski bulur ve yeni pod'a bağlar (Attach).

*   **VolumeClaimTemplates:** Bu kısım, her replica için otomatik olarak bir PVC (Persistent Volume Claim) oluşturur.

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
        # Secret'tan Environment Variable Olarak Okuma
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
          mountPath: /var/lib/mysql # Verinin yazıldığı yer
        - name: config-vol
          mountPath: /etc/mysql/conf.d # ConfigMap'in mount edildiği yer
      volumes:
      - name: config-vol
        configMap:
          name: mysql-config
  volumeClaimTemplates:
  - metadata:
      name: mysql-persistent-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: "" # Local PV kullanıyorsanız boş bırakmak gerekebilir
      resources:
        requests:
          storage: 1Gi
```

---

## 🏗️ Bölüm 3: Backend

Backend uygulaması "Stateless" (durumsuz) bir yapıdır. Yani pod silinirse yerine yenisi gelir, veri kaybetme derdi yoktur. Bu yüzden **Deployment** kullanırız.

### 3.1 & 3.2 ConfigMap ve Secret
*   **ConfigMap:** Veritabanı adresi (`mysql-0.mysql`) gibi gizli olmayan ayarlar.
*   **Secret:** Veritabanı şifresi gibi gizli ayarlar.

### 3.3 Deployment (`backend/k8s/deployment.yaml`)
Burada **Environment Variable Injection** tekniğini görüyoruz. Kubernetes, Secret ve ConfigMap'teki değerleri alır, konteyner başlarken ona "ortam değişkeni" olarak enjekte eder. Uygulama (Python kodu) bu değerleri `os.environ.get('DB_PASSWORD')` ile okur.

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
        imagePullPolicy: Always # Her seferinde güncel image'ı çek (önemli!)
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

### 3.4 Service (`backend/k8s/service.yaml`)
Backend'e dışarıdan erişilmesine gerek yoktur. Sadece Frontend (cluster içinden) erişecektir. Bu yüzden varsayılan servis tipi olan **ClusterIP** yeterlidir. `backend-service` ismiyle içeriden erişilebilir.

---

## 🏗️ Bölüm 4: Frontend 

### 4.1 Deployment (`frontend/k8s/deployment.yaml`)
Frontend'in Backend'e ulaşabilmesi için `BACKEND_URL`'e ihtiyacı var. React uygulamaları genelde tarayıcıda (client-side) çalışır, ancak burada Docker build aşamasında veya runtime'da bu değişkenin nasıl ele alındığına dikkat etmek gerekir (genelde Nginx reverse proxy veya build-time env var kullanılır).

```yaml
        env:
        - name: BACKEND_URL
          value: "http://backend-service:8090" # Cluster içi DNS adresi
```

### 4.2 Service (`frontend/k8s/service.yaml`) - NodePort
Frontend'e kullanıcılar (bizim bilgisayarımız) erişeceği için dışarıya kapı açmamız lazım.

*   **NodePort:** Her Kubernetes Node'unun (sanal makinenin) belirtilen portunu (örneğin 30080) dışarı açar.
*   Farklı servis tipleri:
    *   `ClusterIP`: Sadece iç erişim.
    *   `NodePort`: IP:Port ile dış erişim (Geliştirme için ideal).
    *   `LoadBalancer`: Cloud provider'dan (AWS/Google) gerçek IP alır (Production için ideal).

```yaml
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  type: NodePort # <-- Dışa açıyoruz
  selector:
    app: frontend
  ports:
  - protocol: TCP
    port: 8080       # Servisin kendi portu
    targetPort: 8080 # Pod'un içindeki port
    nodePort: 30080  # Dışarıdan erişilecek port
```

---

## ⛓️ Bölüm 5: Jenkins Pipelines (CI/CD)

Bu projede Jenkins "SCM Plugin" (Multibranch Pipeline olsa bile) yerine, **Pipeline Script** içinde manuel `git clone` komutları kullanılmıştır.

#### **Neden Manuel Git Checkout?**
Normalde Jenkins "Pipeline from SCM" seçildiğinde kodu otomatik çeker. Ancak biz `script` bloğu içinde manuel `git` komutu kullandık.
*   **Tam Kontrol:** Hangi repo'nun hangi branch'inin çekileceğini pipeline içinde dinamik olarak belirlemek istedik.
*   **Hata Yönetimi:** Git işlemi başarısız olursa `gitlabCommitStatus` ile GitLab'a anında "failed" bilgisi dönebilmek için `try-catch` benzeri bloklar (script içi kontroller) kullandık.

### 5.1 Jenkins'e kubectl Kurulumu (Önemli!)
`Kubernetes CLI Plugin` sadece config dosyasını yönetir (`k8s-kubeconfig`). Ancak `kubectl` komutu Jenkins container'ında yüklü değildir. Manuel yüklenmelidir:
```bash
docker exec -u 0 -it jenkins bash -c 'curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl" && chmod +x kubectl && mv kubectl /usr/local/bin/'
```

### 5.2 Build Pipeline (Örn: `backend/Jenkinsfile.build`)
Bu pipeline, kodu derler, test eder ve Docker imajını oluşturup Registry'e atar.

1.  **Stage: Clone Code**
    Kodun en güncel halini GitLab'dan çekeriz.
    ```groovy
        stage('Clone Code') {
            steps {
                script {
                    // GitLab arayüzünde "running" ikonu çıkar
                    updateGitlabCommitStatus(name: OVERALL_STATUS, state: 'running')
                    
                    // GitLab'dan kodu çeker (Main branch)
                    git branch: 'main', 
                        url: 'http://192.168.64.2/abdussamed/backend.git',
                        credentialsId: 'gitlab-user-password'
                }
            }
        }
    ```

2.  **Stage: Security Scans (Güvenlik Taraması)**
    Kodun içinde unutulmuş şifre (secret) var mı diye bakar.
    *   **TruffleHog:** Dosya sistemini tarayarak API Key, Password gibi hassas verileri arar. Eğer bulursa pipeline'ı patlatır (`--fail`).
    ```groovy
        stage('Secret Scan (TruffleHog)') {
             sh "docker run --rm -v ${HOST_WORKSPACE}/backend:/pwd trufflesecurity/trufflehog:latest filesystem /pwd --fail --no-update"
        }
    ```

3.  **Stage: Build Docker Image**
    `Dockerfile` kullanılarak imaj oluşturulur. İki etiket (tag) basılır:
    *   `samed-<build-num>`: Her build için benzersiz (Unique) sürüm.
    *   `samed-latest`: En son sürümü belirtmek için.
    ```groovy
        sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} -t ${DOCKER_IMAGE}:samed-latest ."
    ```

4.  **Stage: Push Docker Image**
    Oluşturulan imajlar Docker Hub'a gönderilir. `withCredentials` ile güvenli giriş yapılır.
    ```groovy
        withCredentials([usernamePassword(credentialsId: 'dockerhub-pat', ...)]) {
            sh 'docker push ...'
        }
    ```

### 5.3 Deploy Pipeline (Örn: `backend/Jenkinsfile.deploy`)
Bu pipeline, *Build Pipeline* bittikten sonra çalışır (veya manuel tetiklenir) ve yeni imajı Kubernetes'e yükler.

1.  **Stage: Deploy to Kubernetes**
    Burada `withKubeConfig` kullanarak Kubernetes Cluster'ına erişim yetkisi alırız.
    
    *   **Adımlar:**
        1.  Secrets, ConfigMaps, Deployment ve Service dosyaları (`kubectl apply`) ile güncellenir.
        2.  `kubectl rollout restart` ile podların yeniden başlatılması ve yeni imajı (`Always` pull policy sayesinde) çekmesi sağlanır.
    
    ```groovy
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    withKubeConfig([credentialsId: 'k8s-kubeconfigfile']) {
                        sh "kubectl apply -f k8s/secret.yaml --validate=false"
                        sh "kubectl apply -f k8s/deployment.yaml --validate=false"
                        // ... diğer dosyalar ...
                        
                        // Podları yeniden başlat (Yeni image'ı çekmesi için kritik!)
                        sh "kubectl rollout restart deployment/backend"
                    }
                }
            }
        }
    ```

2.  **Stage: Verification (Smoke Test)**
    Deployment'ın gerçekten başarılı olup olmadığını kontrol ederiz. Komut bitene kadar pipeline bekler. Eğer podlar ayağa kalkamazsa (CrashLoopBackOff vb.), bu adım timeout olur ve pipeline başarısız sayılır.
    ```groovy
        sh "kubectl rollout status deployment/backend --timeout=60s"
    ```

---

## ❓ Sorun Giderme (Troubleshooting)

Eğer işler yolunda gitmezse ilk bakılacak yerler:

1.  **CrashLoopBackOff Hatası:** Pod sürekli açılıp kapanıyor.
    *   **Çözüm:** Loglara bakın: `kubectl logs <pod-adı>`
    *   Genelde veritabanı bağlantı hatası veya eksik environment variable yüzündendir.

2.  **ErrImagePull / ImagePullBackOff:**
    *   Image ismi yanlış olabilir veya Docker Hub'da o tag yoktur.
    *   Manual olarak `docker pull kocakabdussamed/sbr-backend:samed-latest` yapmayı deneyin.

3.  **Veritabanına Bağlanamıyor:**
    *   Backend podunun içine girip ping atın:
        `kubectl exec -it <backend-pod> -- /bin/sh`
        Sonra içeride: `ping mysql-0.mysql`
    *   Eğer ping gitmiyorsa DNS veya Service problemidir.

4.  **Frontend Backend'i Görmüyor:**
    *   Frontend podu deploylenirken `BACKEND_URL` doğru set edilmiş mi kontrol edin:
        `kubectl describe pod <frontend-pod>`

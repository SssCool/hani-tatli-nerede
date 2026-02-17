# 3. Gün Egzersizleri: Pod ve Deployment (Cevap Anahtarlı)

Aşağıdaki egzersizlerin önce **Imperative (Komut)** çözümünü inceleyin, ardından **Declarative (YAML)** dosyasını yazarak uygulayın. YAML içindeki açıklamaları dikkatlice okuyun.

> **Önemli Not:** Declarative (YAML) örneklerinde kaynak isimlerinin sonuna `-2` ekledim (örn: `my-redis-2`). Böylece önce Imperative komutları çalıştırıp sonra YAML dosyasını uygularsanız "Already Exists" hatası almazsınız.

---

## Bölüm 1: Pod Egzersizleri

### Egzersiz 1 (Kolay): Merhaba Pod
**Görev:** `redis` imajını kullanan basit bir Pod oluşturun.

#### A. Imperative Yöntem (Hızlı Çözüm)
```bash
# Pod oluşturur (İsim: my-redis)
kubectl run my-redis --image=redis

# Pod oluştu mu kontrol et
kubectl get pods
```

#### B. Declarative Yöntem (YAML - Önerilen)
```yaml
# 1-basic-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-redis-2          # FARKLI İSİM: Imperative ile çakışmasın diye -2 ekledik
  labels:
    app: redis-db           # İleride Service ile bağlamak için etiket
spec:
  containers:
  - name: redis-container   # Konteyner adı
    image: redis:latest     # Kullanılacak imaj
    ports:
    - containerPort: 6379   # Redis'in varsayılan portu
```
**Uygula:** `kubectl apply -f 1-basic-pod.yaml`

---

### Egzersiz 2 (Orta): Etiketler ve Kaynaklar
**Görev:** `nginx` imajlı, etiketli ve kaynak kısıtlamalı bir Pod.

#### A. Imperative Yöntem
```bash
# Resource limiti vermek zordur, genelde YAML tercih edilir.
kubectl run nginx-limited --image=nginx --labels="env=prod,tier=frontend"
```

#### B. Declarative Yöntem
```yaml
# 2-resource-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-limited-2     # FARKLI İSİM
  labels:
    environment: production # İstenen etiket 1
    tier: frontend          # İstenen etiket 2
spec:
  containers:
  - name: nginx-web
    image: nginx:1.27
    resources:
      requests:             # Kubernetes'e ipucu: "Bana en az bu kadar yer ayır"
        memory: "64Mi"
        cpu: "100m"         # 0.1 CPU
      limits:               # Kubernetes'e emir: "Asla bunu geçmesine izin verme"
        memory: "128Mi"
        cpu: "200m"         # 0.2 CPU
```

---

### Egzersiz 3 (Zor): Multi-Container (Sidecar Pattern)
**Görev:** Aynı pod içinde `nginx` ve `busybox` çalıştır.

#### A. Imperative Yöntem
*Bu senaryo tek bir komutla yapılamaz. Mecburen YAML yazmalısınız.*

#### B. Declarative Yöntem
```yaml
# 3-multi-container.yaml
apiVersion: v1
kind: Pod
metadata:
  name: sidecar-demo-2      # FARKLI İSİM
spec:
  containers:
  # Ana Uygulama (Main Container)
  - name: web
    image: nginx
    ports:
    - containerPort: 80
  
  # Yardımcı Uygulama (Sidecar Container)
  - name: sidecar
    image: busybox
    # Sonsuz döngüde ekrana (stdout) yazı yazar
    command: ["sh", "-c", "while true; do echo 'Sidecar calisiyor!'; sleep 5; done"]
```
**Kontrol:** `kubectl logs sidecar-demo-2 -c sidecar`

---

### Egzersiz 4 (Yeni): Ortam Değişkenleri (Environment Variables)
**Görev:** `env-demo` isminde bir pod oluşturun ve içine `APP_COLOR=blue` değişkenini gömün.

#### A. Imperative Yöntem
```bash
kubectl run env-demo --image=nginx --env="APP_COLOR=blue"
# Kontrol:
kubectl exec env-demo -- printenv APP_COLOR
```

#### B. Declarative Yöntem
```yaml
# 4-env-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: env-demo-2          # FARKLI İSİM
spec:
  containers:
  - name: nginx
    image: nginx
    env:                    # Ortam Değişkenleri
    - name: APP_COLOR       # Değişken Adı
      value: "blue"         # Değer
```
**Kontrol:** `kubectl exec env-demo-2 -- printenv APP_COLOR`

---

## Bölüm 2: Deployment Egzersizleri

### Egzersiz 1 (Kolay): Web Sunucusu Kümesi
**Görev:** 3 kopyalı bir Apache sunucusu.

#### A. Imperative Yöntem
```bash
# Deployment oluşturur
kubectl create deployment apache-deployment --image=httpd:alpine --replicas=3

# Replikaları izle
kubectl get deployment
kubectl get pods
```

#### B. Declarative Yöntem
```yaml
# 5-apache-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache-deployment-2 # FARKLI İSİM
spec:
  replicas: 3               # Kaç tane olsun? -> 3
  selector:                 # Deployment, çocuklarını (podlarını) nasıl tanısın?
    matchLabels:
      app: apache-web-2     # ETIKET de farklı olsun ki diğer deployment ile karışmasın
  template:                 # Pod Şablonu (Kalıp)
    metadata:
      labels:               # BU ETİKET, YUKARIDAKİ SELECTOR İLE AYNI OLMALI!
        app: apache-web-2
    spec:
      containers:
      - name: apache
        image: httpd:alpine
        ports:
        - containerPort: 80
```

---

### Egzersiz 2 (Orta): Ölçekleme ve Güncelleme
**Görev:** Replicayı 5 yap, imajı güncelle.

#### A. Imperative Yöntem
```bash
# 1. Ölçekle (Scale)
kubectl scale deployment apache-deployment --replicas=5

# 2. İmajı Değiştir (Set Image)
kubectl set image deployment/apache-deployment apache=httpd:2.4

# 3. Durumu İzle (Rollout Status)
kubectl rollout status deployment/apache-deployment
```

#### B. Declarative Yöntem
*YAML dosyasındaki (5-apache-deployment.yaml) `replicas: 3` kısmını `5` yapın.*
*`image: httpd:alpine` kısmını `httpd:2.4` yapın.*
*Sonra tekrar uygulayın:*
```bash
kubectl apply -f 5-apache-deployment.yaml
# Sistem aradaki farkı anlar ve sadece gerekeni yapar (Diff).
```

---

### Egzersiz 3 (Zor): Rolling Update Stratejisi
**Görev:** Güncelleme hızını ve güvenliğini ayarla.

#### A. Imperative Yöntem
*Strateji ayarları komut satırından çok karmaşıktır. YAML kullanın.*

#### B. Declarative Yöntem
```yaml
# 6-deployment-strategy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: strategy-demo-2     # FARKLI İSİM
spec:
  replicas: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 2     # Güncelleme sırasında en fazla 2 pod kapalı olabilir.
      maxSurge: 3           # Güncelleme sırasında limiti 3 pod aşabiliriz.
  selector:
    matchLabels:
      app: strategy-test-2
  template:
    metadata:
      labels:
        app: strategy-test-2
    spec:
      containers:
      - name: nginx
        image: nginx:1.27
```

---

### Egzersiz 4 (Yeni): Rollback (Geri Alma)
**Görev:** Hatalı bir imaj deployment'ı yapın (`nginx:typo`), hatayı görün ve geri alın.

#### A. Imperative Yöntem
```bash
# 1. Deployment oluştur
kubectl create deployment rollback-demo --image=nginx:1.27 --replicas=3

# 2. Hatalı imaj güncellemesi yap (Bozuk imaj)
kubectl set image deployment/rollback-demo nginx=nginx:typo

# 3. Durumu gör (Hata verecektir: ErrImagePull veya ImagePullBackOff)
kubectl get pods

# 4. Geri Al (Undo)
kubectl rollout undo deployment/rollback-demo

# 5. Kontrol et
kubectl rollout status deployment/rollback-demo
```

#### B. Declarative Yöntem
```yaml
# 7-bad-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rollback-demo-2     # FARKLI İSİM
spec:
  replicas: 3
  selector:
    matchLabels:
      app: rollback-test-2
  template:
    metadata:
      labels:
        app: rollback-test-2
    spec:
      containers:
      - name: nginx
        image: nginx:typo   # BOZUK İMAJ
```
**Adımlar:**
1. `kubectl apply -f 7-bad-deployment.yaml` (Podlar hata verecek).
2. Dosyadaki imajı `nginx:1.27` olarak düzeltin.
3. `kubectl apply -f 7-bad-deployment.yaml` (Sistem düzeltecek).

# 3. Gün Ek Egzersizler: Service ile Erişim (Networking)

Bu egzersiz dosyasında Pod ve Deployment'ları dış dünyaya (External) veya cluster içine (Internal) nasıl açacağımızı öğreneceğiz.

---

## Egzersiz 1: Pod ve ClusterIP (Dahili Erişim)
**Senaryo:** `PostgreSQL` veritabanı içeren tek bir Pod oluşturun. Bu veritabanına sadece içeriden erişilsin.

### 1. Pod Tanımı (db-pod.yaml)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: postgres-pod
  labels:
    app: database           # 1. Etiket: Service bunu hedefleyecek
    tier: backend
spec:
  containers:
  - name: postgres
    image: postgres:15
    env:
    - name: POSTGRES_PASSWORD
      value: "mysecretpassword"
    ports:
    - containerPort: 5432   # 2. Port: Uygulamanın dinlediği port
```
**Komut:** `kubectl apply -f db-pod.yaml`

### 2. Service Tanımı (db-service.yaml)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: internal-db-service # 3. DNS Adı: internal-db-service
spec:
  type: ClusterIP           # 4. Tür: Sadece içeriden erişim
  selector:
    app: database           # 5. Seçici: Yukarıdaki Pod etiketini bulmalı!
  ports:
    - protocol: TCP
      port: 5432            # 6. Service Portu (Diğer podlar buraya bağlanır)
      targetPort: 5432      # 7. Hedef Port (Pod üzerindeki port)
```
**Komut:** `kubectl apply -f db-service.yaml`

### 3. Doğrulama (Verification)
Bu servise dışarıdan (tarayıcıdan) erişemezsiniz. Test etmek için cluster içinde geçici bir pod açın:
```bash
# Geçici (Ephemeral) bir pod başlatıp içine girin
kubectl run -it --rm test-client --image=busybox -- sh

# İçeride şu komutu çalıştırın (telnet veya nc ile port kontrolü):
# Service DNS adını kullanıyoruz:
telnet internal-db-service 5432

# Çıktı şu şekilde olmalı (Connected to ...):
# Connected to internal-db-service
```

---

## Egzersiz 2: Pod ve NodePort (Harici Erişim)
**Senaryo:** Basit bir `Nginx` web sunucusu içeren bir Pod oluşturun. Bu podun kendisine node'un IP adresi üzerinden dışarıdan erişilsin.

### 1. Pod Tanımı (web-pod.yaml)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: simple-web-pod
  labels:
    component: web-ui       # Service bunu hedefleyecek
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    ports:
    - containerPort: 80
```
**Komut:** `kubectl apply -f web-pod.yaml`

### 2. Service Tanımı (web-nodeport.yaml)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-web-service
spec:
  type: NodePort            # TÜR: Dışarıdan erişim (NodeIP:Port)
  selector:
    component: web-ui       # Pod etiketiyle eşleşmeli
  ports:
    - protocol: TCP
      port: 80              # Cluster içi port
      targetPort: 80        # Pod portu
      nodePort: 30005       # STATİK PORT: 30005 (Dışarıdan buraya geleceğiz)
```
**Komut:** `kubectl apply -f web-nodeport.yaml`

### 3. Doğrulama (Verification)
Tarayıcınızı veya terminalinizi açın.
*   **Node IP:** `kubectl get nodes -o wide` ile node IP'sini öğrenin (Sanal makine IP'si).
*   **Test:** `curl http://<NODE-IP>:30005` veya tarayıcıdan `http://<NODE-IP>:30005` adresine gidin.
*   **Sonuç:** "Welcome to nginx!" sayfasını görmelisiniz.

---

## Egzersiz 3: Deployment ve ClusterIP (Mikroservis Mimarisi)
**Senaryo:** `Redis` önbellek (cache) sunucularından oluşan 3 kopyalı bir deployment yapın. Uygulama sadece içeriden erişilebilir olsun.

### 1. Deployment Tanımı (redis-backend.yaml)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis-backend
spec:
  replicas: 3               # 3 Adet Pod
  selector:
    matchLabels:
      app: cache-layer      # Deployment, bu etikete sahip podları yönetir
  template:
    metadata:
      labels:
        app: cache-layer    # Pod etiketi (Service bunu hedefleyecek)
    spec:
      containers:
      - name: redis
        image: redis:6.2
        ports:
        - containerPort: 6379
```
**Komut:** `kubectl apply -f redis-backend.yaml`

### 2. Service Tanımı (redis-svc.yaml)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: cache-service       # Diğer uygulamalar bu ismi kullanacak
spec:
  type: ClusterIP           # Dahili Erişim
  selector:
    app: cache-layer        # Deployment'taki pod etiketlerini seç
  ports:
    - port: 6379            # Service Port
      targetPort: 6379      # Pod Port
```
**Komut:** `kubectl apply -f redis-svc.yaml`

### 3. Doğrulama (Verification)
Load Balancing testini yapalım. `nslookup` ile servisin IP'sini çözün.
```bash
kubectl run -it --rm debug-pod --image=busybox:1.28 -- nslookup cache-service
# Çıktıda servisin ClusterIP'sini (10.x.x.x) görmelisiniz.
```
*Not: Service tek bir IP verir (VIP), ama trafiği arkadaki 3 poda dağıtır.*

---

## Egzersiz 4: Deployment ve NodePort (Production Simülasyonu)
**Senaryo:** `Apache` Web Server uygulamasını 5 kopya (replica) olarak dağıtın ve dış dünyaya 30010 portundan açın.

### 1. Deployment Tanımı (apache-app.yaml)
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache-prod
spec:
  replicas: 5               # Yüksek erişilebilirlik (5 kopya)
  selector:
    matchLabels:
      app: prod-web
  template:
    metadata:
      labels:
        app: prod-web       # Etiket
    spec:
      containers:
      - name: httpd
        image: httpd:2.4
        ports:
        - containerPort: 80
```
**Komut:** `kubectl apply -f apache-app.yaml`

### 2. Service Tanımı (apache-public.yaml)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: public-apache
spec:
  type: NodePort
  selector:
    app: prod-web           # Deployment etiketini yakala
  ports:
    - port: 80              # Service Port (80)
      targetPort: 80        # Pod Port (80)
      nodePort: 30010       # Dış Port (30010)
```
**Komut:** `kubectl apply -f apache-public.yaml`

### 3. Doğrulama (Verification)
Herhangi bir pod silinse bile servisin çalışmaya devam ettiğini görelim.
1.  Tarayıcıdan `http://<NODE-IP>:30010` adresini açın -> "It works!" yazısını görün.
2.  Bir terminalde `watch kubectl get pods` çalıştırın.
3.  Başka bir terminalde deployment podlarından birini silin: `kubectl delete pod apache-prod-xxxxx`.
4.  Yeni pod hemen açılacaktır. Tarayıcıyı yenileyin, kesinti olmadığını (veya hemen geldiğini) doğrulayın.

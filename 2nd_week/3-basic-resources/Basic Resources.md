# 3. Gün: Kubernetes Temel Kaynakları (Basic Resources)

## 1. Imperative vs Declarative Yaklaşım

Kubernetes'i yönetmenin iki temel yolu vardır. Bu farkı anlamak, "Neden YAML yazıyoruz?" sorusunun cevabıdır.

### A. Imperative (Emir Kipi)
- **Nedir?** Sisteme **nasıl** yapacağını adım adım söylersiniz.
- **Odak:** İşlem (Action).
- **Yöntem:** `kubectl` komutlarını parametrelerle kullanmak.
- **Örnek:** "Git marketten 2 ekmek al."
    ```bash
    kubectl run nginx-pod --image=nginx --port=80
    kubectl scale deployment my-app --replicas=3
    ```
- **Avantajı:** Hızlıdır, tek seferlik işler ve denemeler için harikadır.
- **Dezavantajı:** Geçmişi takip edilemez. Bir pod'u kimin, ne zaman, hangi parametreyle açtığını hatırlayamazsınız. "Infrastructure as Code" mantığına uymaz.

### B. Declarative (Bildirimsel / Tanımsal)
- **Nedir?** Sisteme **ne** istediğinizi (Arzu Edilen Durum / Desired State) söylersiniz. Nasıl yapacağı sistemin sorunudur.
- **Odak:** Sonuç (Result).
- **Yöntem:** YAML dosyaları oluşturup `kubectl apply` demek.
- **Örnek:** "Evde her zaman 2 ekmek bulunsun." (Biri yenirse, sistem gidip yenisini alır).
    ```bash
    kubectl apply -f my-deployment.yaml
    ```
- **Avantajı:** Yönetilebilir, versiyonlanabilir (GitOps), tekrar edilebilir ve otomatize edilebilir.
- **Önerilen:** Production ortamlarında %99 Declarative yaklaşım kullanılır.

---

## 2. Pod (En Küçük Yapı Taşı)

- **Nedir?** Kubernetes'in yönetebildiği, deploy edebildiği en küçük birimdir.
- **Özellik:**
    - Bir Pod içinde genelde **tek bir konteyner** çalışır (Best Practice).
    - Nadiren, birbirine sıkı sıkıya bağlı (tightly coupled) birden fazla konteyner (Sidecar) aynı podda olabilir.
    - Pod içindeki konteynerler aynı **IP adresini** (localhost üzerinden haberleşirler) ve aynı **Depolama Alanını** (Volume) paylaşırlar.
- **Ömür:** Pod'lar **ölümlüdür (ephemeral)**. Bir pod öldüğünde (CrashLoopBackOff, Node failure vb.) kendi kendine dirilmez. Onu yöneten bir üst akıl (Controller) yoksa, o pod sonsuza kadar kaybolur.

### Pod YAML Analizi (Detaylı)
Aşağıdaki YAML dosyasında bir Pod'un alabileceği en temel ve orta seviye parametreleri göreceksiniz. Her satırın ne işe yaradığını yorumlarda açıkladım.

```yaml
# pod-advanced.yaml
apiVersion: v1              # 1. API Sürümü: "v1" (Core/Stable)
kind: Pod                   # 2. Kaynak Türü: Pod
metadata:                   # 3. Üst Veri (Meta Bilgiler)
  name: advanced-pod        #    - Pod'un benzersiz adı.
  labels:                   #    - Etiketleme (Service ve Deployment bununla bulur).
    app: backend
    env: production
    tier: api
  annotations:              #    - Notlar (Sistem değil, insanlar veya araçlar okur).
    built-by: "Team-A"
    version: "1.2.0"
spec:                       # 4. Spesifikasyon (Arzu Edilen Durum)
  restartPolicy: Always     #    - Konteyner kapanırsa ne yapayım? (Always/OnFailure/Never)
  nodeSelector:             #    - Bu pod hangi sunucuda çalışmalı?
    disktype: ssd           #      - Sadece "disktype=ssd" etiketine sahip Node'a git.
  
  volumes:                  #    - Depolama Alanları (Disk Tanımları)
  - name: log-volume        #      - Volume 1: Geçici Disk (Pod ölünce silinir).
    emptyDir: {}            
  
  - name: node-root         #      - Volume 2: HostPath (Node'un diskine erişim).
    hostPath:               #        - DİKKAT: Güvenlik riski oluşturur ve podu node'a bağımlı kılar.
      path: /pod-data       #        - Node üzerindeki klasör.
      type: DirectoryOrCreate #      - Yoksa oluştur.

  containers:               #    - Konteyner Listesi (Birden fazla olabilir)
  - name: main-app          #      - Konteyner Adı.
    image: nginx:1.27       #      - Kullanılacak İmaj.
    imagePullPolicy: IfNotPresent # - İmaj ne zaman indirilsin? (Always/IfNotPresent/Never)
    
    command: ["/bin/sh"]    #      - Docker ENTRYPOINT'i ezer.
    args: ["-c", "nginx"]   #      - Docker CMD'yi ezer.
    
    ports:                  #      - Ağ Port Tanımları
    - containerPort: 80     #        - Konteyner içi port.
      name: http            #        - Port'a isim verme (Servislerde isimle çağrılabilir).
      protocol: TCP
    
    env:                    #      - Ortam Değişkenleri (Environment Variables)
    - name: DB_HOST         #        - Değişken Adı
      value: "10.0.0.5"     #        - Değer
    
    resources:              #      - Kaynak Yönetimi (CPU/RAM)
      requests:             #        - "En az bu kadar yer ayır" (Garanti edilen).
        memory: "64Mi"
        cpu: "250m"         #          - 250 millicore (Çeyrek çekirdek).
      limits:               #        - "Bunu aşarsa müdahale et" (Tavan).
        memory: "128Mi"     #          - Aşarsa OOMKilled (Öldürülür).
        cpu: "500m"         #          - Aşarsa Throttled (Yavaşlatılır).
    
    volumeMounts:           #      - Diskleri Konteynere Bağlama
    - name: log-volume      #        - Yukarıdaki 'volumes' kısmındaki isim.
      mountPath: /var/log   #        - Konteyner içinde nereye takılsın?
    - name: node-root       #        - HostPath'i bağlamak.
      mountPath: /host-fs   #        - Konteyner içinde /host-fs olarak görünür.
      readOnly: true        #        - (Opsiyonel) Sadece okuma izni verilebilir.

    livenessProbe:          #      - Sağlık Kontrolü: "Yaşıyor musun?"
      httpGet:              #        - HTTP isteği atarak kontrol et.
        path: /healthz      #          - Bu adrese git.
        port: 80
      initialDelaySeconds: 5 #       - Konteyner başladıktan kaç saniye sonra başla?
      periodSeconds: 10     #        - Kaç saniyede bir kontrol et?
    
    readinessProbe:         #      - Hazırlık Kontrolü: "Trafik almaya hazır mısın?"
      tcpSocket:            #        - TCP bağlantısı kurarak deneme.
        port: 80
      initialDelaySeconds: 15 #      - 15 sn bekle, belki uygulama geç açılıyordur.
```

---

## 3. Deployment (Pod Yöneticisi)

- **Challenge:** Pod'lar ölümlüdür dedik. Peki Production'da pod ölünce ne olacak? Veya versiyon güncellerken kesinti olacak mı?
- **Çözüm:** **Deployment**.
- **Nedir?** Pod'ların yaşam döngüsünü yöneten, ölçekleyen (scaling) ve güncellemeleri (rolling update) yöneten bir Controller'dır.
- **Hiyerarşi:** `Deployment` -> `ReplicaSet` -> `Pod`.
    - Siz Deployment'a "Bana 3 kopya Nginx ver" dersiniz.
    - Deployment, ReplicaSet'e "3 kopya sağla" der.
    - ReplicaSet, 3 tane Pod oluşturur ve sürekli sayıyı 3'te tutmaya çalışır (Self-healing).

### Deployment YAML Analizi (Detaylı)

Deployment, Pod'ları yöneten bir üst katmandır. Pod şablonunun yanı sıra güncelleme stratejilerini de içerir.

```yaml
# deployment-advanced.yaml
apiVersion: apps/v1                 # 1. API: Deployment, ReplicaSet, StatefulSet "apps" grubundadır.
kind: Deployment                    # 2. Tür
metadata:
  name: my-app                      # 3. İsim
  labels:
    app: my-app
spec:
  replicas: 3                       # 4. Kopya Sayısı (Desired State)
  
  revisionHistoryLimit: 5           #    - Geri almak (Rollback) için kaç eski versiyon saklansın? (Default: 10)
  progressDeadlineSeconds: 600      #    - Deployment 10 dk içinde tamamlanmazsa "Failed" olarak işaretle.
  paused: false                     #    - (True) yapılırsa, template değişse bile rollout başlamaz (Maintenance).
  minReadySeconds: 10               #    - Pod "Ready" olduktan sonra, gerçekten hazır sayılması için kaç sn bekleyeyim?
                                    #      (Traffic almadan önce ısınma süresi veya crash olup olmadığını görmek için).
  
  strategy:                         # 5. Güncelleme Stratejisi (Nasıl update yapayım?)
    type: RollingUpdate             #    - Kesintisiz geçiş (Varsayılan). (Diğeri: Recreate - kapatıp açar).
    rollingUpdate:
      maxUnavailable: 1             #      - Güncelleme sırasında en fazla kaç pod kapalı olabilir? (%25 veya sayı).
      maxSurge: 2                   #      - Güncelleme sırasında hedeflenen sayının (3) üzerine en fazla kaç çıkılabilir?
  
  selector:                         # 6. Etiket Seçici (Pod ile Bağlantı Noktası - ÇOK ÖNEMLİ)
    matchLabels:                    #    - "Ben şu etiketlere sahip podların sahibiyim" der.
      app: my-app                   #      - Aşağıdaki template.metadata.labels içindekiyle BİREBİR aynı olmalı.
      tier: frontend
  
  template:                         # 7. Pod Şablonu (Buradan sonrası POD spec'idir)
    metadata:
      labels:                       #    - Oluşturulacak Pod'lara basılacak etiketler.
        app: my-app
        tier: frontend
    spec:                           #    - Pod'un teknik detayları (Yukarıdaki Pod örneğiyle aynıdır).
      containers:
      - name: nginx
        image: nginx:1.27
        ports:
        - containerPort: 80
        resources:
          limits:
            memory: "128Mi"
            cpu: "200m"
```

---

## 4. Service (Ağ Erişim Noktası / Santral)

- **Challenge:** Pod'lar ölümlüdür. Bir Deployment'taki pod ölüp yenisi açılınca IP adresi değişir. Peki istemciler (Frontend, Mobile App) veya diğer mikroservisler arka kısımdaki (Backend) podlara nasıl ulaşacak? Sürekli değişen IP adreslerini takip etmek imkansızdır.
- **Çözüm:** **Service**.
- **Nedir?** Pod gruplarına **sabit bir IP (ClusterIP)** ve **sabit bir DNS ismi** sağlayan mantıksal bir katmandır.
- **Görevi (Load Balancing):** Gelen trafiği arkasındaki sağlıklı Pod'lar arasında dağıtır. Siz Service IP'sine gidersiniz, o sizi arkadaki Pod-1, Pod-2 veya Pod-3'e yönlendirir.

### Nasıl Çalışır? (Labels & Selectors)
Service, hangi podlara trafik göndereceğini **Etiketler (Labels)** sayesinde bilir.
- Service Tanımı: "Bana `app: backend` etiketine sahip tüm podları bul."
- Sonuç: Service, bu etikete sahip podların IP adreslerini dinamik olarak takip eder ve bir **Endpoints** listesi oluşturur. Pod ölürse listeden çıkar, yeni gelirse listeye eklenir.

### Service Türleri (ServiceTypes)

1.  **ClusterIP (Varsayılan - Default):**
    - **Erişim:** Sadece cluster **içinden** erişilebilir. Dış dünyaya kapalıdır.
    - **Kullanım:** Veritabanları, backend servisleri, sadece içeride konuşan mikroservisler.
    - **Metafor:** Şirket içi dahili telefon hattı. Dışarıdan kimse arayamaz, sadece çalışanlar birbirini arar.

2.  **NodePort:**
    - **Erişim:** Cluster dışından, herhangi bir Node'un IP'si ve statik bir Port (30000-32767 arası) üzerinden erişim sağlar.
    - **Kullanım:** Geliştirme ortamları, demo gösterimleri. Production'da güvenlik ve port yönetimi zorluğu nedeniyle pek tercih edilmez.
    - **Metafor:** Şirketin resepsiyonunu değil, doğrudan bir çalışanın cep telefonunu aramak gibi.

3.  **LoadBalancer:**
    - **Erişim:** Cloud Provider (AWS, Azure, Google, DigitalOcean) üzerinde gerçek, public bir Load Balancer cihazı kiralar.
    - **Kullanım:** Production ortamında internete açılacak Frontend uygulamaları için standarttır. Size gerçek bir "Dış IP" (Public IP) verir.
    - **Metafor:** Şirketin 444'lü müşteri hizmetleri numarası. Dünyanın her yerinden aranabilir.

### Service YAML Analizi (Detaylı)

Her servis türü için ayrı bir YAML örneği aşağıdadır.

#### A. ClusterIP (Dahili Servis)
Varsayılan türdür. Sadece içeriden erişim içindir.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-backend-service  # DNS Adı: my-backend-service.default.svc.cluster.local
spec:
  type: ClusterIP           # TÜR: ClusterIP
  selector:                 # HEDEF: Hangi podlara gidecek?
    app: backend-api        # (Deployment etiketleriyle eşleşmeli)
  ports:
    - protocol: TCP
      port: 80              # Service Portu: Diğer podlar bu porta istek atar (http://my-backend-service:80)
      targetPort: 8080      # Pod Portu: Uygulamanın konteyner içinde dinlediği gerçek port.
```

#### B. NodePort (Harici Erişim - Node Üzerinden)
Her Node üzerinde bir port açar. `http://<NodeIP>:30007` şeklinde erişilir.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-nodeport-service
spec:
  type: NodePort            # TÜR: NodePort
  selector:
    app: frontend-web
  ports:
    - protocol: TCP
      port: 80              # Service Portu (Cluster içinden erişim için)
      targetPort: 80        # Pod Portu (Konteynerin portu)
      nodePort: 30007       # NODE PORTU: Dışarıdan erişim için statik port (30000-32767).
                            # (Belirtmezseniz Kubernetes rastgele atar).
```

#### C. LoadBalancer (Harici Erişim - Cloud LB)
Gerçek bir IP adresi kiralar.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-lb-service
spec:
  type: LoadBalancer        # TÜR: LoadBalancer
  selector:
    app: public-web
  ports:
    - protocol: TCP
      port: 80              # Dış dünyadan (LB üzerinden) gelen istek bu porta gelir.
      targetPort: 80        # Arkadaki poda iletilen port.
```

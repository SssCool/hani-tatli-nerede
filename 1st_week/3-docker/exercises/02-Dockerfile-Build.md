# Uygulama 2: Kendi İmajımızı Oluşturmak (Dockerfile)

Hazır imaj kullanmak kolaydır. Şimdi kendi Python uygulamamızı paketleyip bir imaj haline getireceğiz.

## Amaç
*   `Dockerfile` yazmayı öğrenmek.
*   `docker build` komutu ile imaj üretmek.
*   Kendi ürettiğimiz imajı çalıştırmak.

## Adım 1: Dosyaları Hazırlama
Bir klasör oluşturun ve içine şu iki dosyayı koyun.

**1. app.py** (Basit bir Python scripti)
```python
import os
print("Merhaba! Ben Docker içinden çalışan bir Python koduyum.")
print("Versiyon: " + os.environ.get("VERSIYON", "v1"))
```

**2. Dockerfile** (Reçetemiz)
```dockerfile
# Python 3.9 kurulu hafif bir Linux (Slim) kullan
FROM python:3.9-slim

# Çalışma klasörünü ayarla
WORKDIR /uygulama

# Kodumuzu içeri kopyala
COPY app.py .

# Konteyner başlayınca bu komutu çalıştır
CMD ["python", "app.py"]
```

## Adım 2: İmajı İnşa Etme (Build)
Terminali bu klasörde açın ve şu komutu girin. Sondaki **noktayı (.)** unutmayın!

```bash
# -t: Tag (İsim veriyoruz)
docker build -t benim-python-uygulamam:v1 .
```

## Adım 3: Çalıştırma
Ürettiğimiz imajı çalıştıralım. Ayrıca bir ortam değişkeni (ENV) gönderelim.

```bash
docker run -e VERSIYON="v2.0" benim-python-uygulamam:v1
```

**Çıktı:**
`Merhaba! Ben Docker içinden çalışan bir Python koduyum.`
`Versiyon: v2.0`
